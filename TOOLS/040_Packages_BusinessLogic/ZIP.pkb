CREATE OR REPLACE PACKAGE BODY tools.zip
IS
   FUNCTION little_endian(p_big IN NUMBER, p_bytes IN PLS_INTEGER := 4)
      RETURN RAW
   IS
   BEGIN
      RETURN UTL_RAW.SUBSTR(
                UTL_RAW.cast_from_binary_integer(p_big, UTL_RAW.little_endian)
              , 1
              , p_bytes);
   END;

   --
   PROCEDURE add1file(p_zipped_blob IN OUT NOCOPY BLOB
                    , p_name        IN            VARCHAR2
                    , p_content     IN            BLOB)
   IS
      t_now  DATE;
      t_blob BLOB;
      t_clen INTEGER;
   BEGIN
      t_now  := SYSDATE;
      t_blob := UTL_COMPRESS.lz_compress(p_content);
      t_clen := DBMS_LOB.getlength(t_blob);

      IF p_zipped_blob IS NULL
      THEN
         DBMS_LOB.createtemporary(p_zipped_blob, TRUE);
      END IF;

      DBMS_LOB.append(p_zipped_blob
                    , UTL_RAW.CONCAT(
                         HEXTORAW('504B0304') -- Local file header signature
                       , HEXTORAW('1400') -- version 2.0
                       , HEXTORAW('0000') -- no General purpose bits
                       , HEXTORAW('0800') -- deflate
                       , little_endian(
                              TO_NUMBER(TO_CHAR(t_now, 'ss')) / 2
                            + TO_NUMBER(TO_CHAR(t_now, 'mi')) * 32
                            + TO_NUMBER(TO_CHAR(t_now, 'hh24')) * 2048
                          , 2) -- File last modification time
                       , little_endian(
                              TO_NUMBER(TO_CHAR(t_now, 'dd'))
                            + TO_NUMBER(TO_CHAR(t_now, 'mm')) * 32
                            + (TO_NUMBER(TO_CHAR(t_now, 'yyyy')) - 1980) * 512
                          , 2) -- File last modification date
                       , DBMS_LOB.SUBSTR(t_blob, 4, t_clen - 7) -- CRC-32
                       , little_endian(t_clen - 18) -- compressed size
                       , little_endian(DBMS_LOB.getlength(p_content)) -- uncompressed size
                       , little_endian(LENGTH(p_name), 2) -- File name length
                       , HEXTORAW('0000') -- Extra field length
                       , UTL_RAW.cast_to_raw(p_name) -- File name
                                                    ));
      DBMS_LOB.append(p_zipped_blob, DBMS_LOB.SUBSTR(t_blob, t_clen - 18, 11)); -- compressed content
      DBMS_LOB.freetemporary(t_blob);
   END;

   --
   PROCEDURE finish_zip(p_zipped_blob IN OUT NOCOPY BLOB)
   IS
      t_cnt             PLS_INTEGER := 0;
      t_offs            INTEGER;
      t_offs_dir_header INTEGER;
      t_offs_end_header INTEGER;
      t_comment         RAW(32767)
         := UTL_RAW.cast_to_raw('Implementation by Anton Scheffer');
   BEGIN
      t_offs_dir_header := DBMS_LOB.getlength(p_zipped_blob);
      t_offs            :=
         DBMS_LOB.INSTR(p_zipped_blob, HEXTORAW('504B0304'), 1);

      WHILE t_offs > 0
      LOOP
         t_cnt := t_cnt + 1;
         DBMS_LOB.append(p_zipped_blob
                       , UTL_RAW.CONCAT(
                            HEXTORAW('504B0102') -- Central directory file header signature
                          , HEXTORAW('1400') -- version 2.0
                          , DBMS_LOB.SUBSTR(p_zipped_blob, 26, t_offs + 4)
                          , HEXTORAW('0000') -- File comment length
                          , HEXTORAW('0000') -- Disk number where file starts
                          , HEXTORAW('0100') -- Internal file attributes
                          , HEXTORAW('2000B681') -- External file attributes
                          , little_endian(t_offs - 1) -- Relative offset of local file header
                          , DBMS_LOB.SUBSTR(
                               p_zipped_blob
                             , UTL_RAW.cast_to_binary_integer(
                                  DBMS_LOB.SUBSTR(p_zipped_blob
                                                , 2
                                                , t_offs + 26)
                                , UTL_RAW.little_endian)
                             , t_offs + 30) -- File name
                                           ));
         t_offs      :=
            DBMS_LOB.INSTR(p_zipped_blob, HEXTORAW('504B0304'), t_offs + 32);
      END LOOP;

      t_offs_end_header := DBMS_LOB.getlength(p_zipped_blob);
      DBMS_LOB.append(p_zipped_blob
                    , UTL_RAW.CONCAT(
                         HEXTORAW('504B0506') -- End of central directory signature
                       , HEXTORAW('0000') -- Number of this disk
                       , HEXTORAW('0000') -- Disk where central directory starts
                       , little_endian(t_cnt, 2) -- Number of central directory records on this disk
                       , little_endian(t_cnt, 2) -- Total number of central directory records
                       , little_endian(t_offs_end_header - t_offs_dir_header) -- Size of central directory
                       , little_endian(t_offs_dir_header) -- Relative offset of local file header
                       , little_endian(NVL(UTL_RAW.LENGTH(t_comment), 0), 2) -- ZIP file comment length
                       , t_comment));
   END;

   --
   PROCEDURE save_zip(p_zipped_blob IN BLOB
                    , p_dir         IN VARCHAR2
                    , p_filename    IN VARCHAR2)
   IS
      t_fh  UTL_FILE.file_type;
      t_len PLS_INTEGER := 32767;
   BEGIN
      t_fh := UTL_FILE.fopen(p_dir, p_filename, 'wb');

      FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(p_zipped_blob) - 1) / t_len)
      LOOP
         UTL_FILE.put_raw(t_fh
                        , DBMS_LOB.SUBSTR(p_zipped_blob, t_len, i * t_len + 1));
      END LOOP;

      UTL_FILE.fclose(t_fh);
   END;

   PROCEDURE apex_download_ziped_clobs(
      p_source_table_name       IN user_tables.table_name%TYPE
    , p_source_clob_column_name IN user_tab_cols.column_name%TYPE
    , p_source_filename_rule    IN VARCHAR2
    , p_source_sql_criteria     IN VARCHAR2 DEFAULT '1 = 1'
    , p_target_zip_file_name    IN VARCHAR2
    , p_target_mime_type        IN VARCHAR2 DEFAULT 'text'
    , p_target_file_charset     IN VARCHAR2 DEFAULT 'ASCII')
   IS
      -- Prozedur apex_download_ziped_clobs immer aus einer APEX Session heraus aufrufen!!!
      l_dyn_plsql_block VARCHAR2(32767 CHAR);
      l_ziped_lob       BLOB;
   BEGIN
      -- Über das Konstrukt der dynamischen CLOB-Ermittlung ist es auch möglich,
      -- ein Zip-Archiv zu erstellen, was mehrere Dateien (1 Datei pro CLOB Zeile) beinhaltet.
      l_ziped_lob := EMPTY_BLOB();
      DBMS_LOB.createtemporary(l_ziped_lob, FALSE);
      l_dyn_plsql_block      :=
            'DECLARE '
         || '  l_blob                  BLOB;'
         || 'BEGIN '
         || '  FOR i IN (SELECT '
         || p_source_clob_column_name
         || ', '
         || p_source_filename_rule
         || ' as filename'
         || '                  FROM '
         || p_source_table_name
         || '                WHERE '
         || p_source_sql_criteria
         || '               ) LOOP '
         || '    l_blob := EMPTY_BLOB();                                      '
         || '    DBMS_LOB.createtemporary(l_blob, TRUE, DBMS_LOB.session);    '
         || '    l_blob := tools.lob.clob_to_blob(i.'
         || p_source_clob_column_name
         || '              );'
         || '           '
         || '     INSERT INTO TOOLS.TEMPORARY_LOB_TABLE '
         || '     (CONTEXT, FILENAME, LOB_CONTENT, SYS_DATE) VALUES '
         || '     (''apex_download_ziped_clobs'', i.filename, l_blob, SYSDATE);'
         || '     DBMS_LOB.freetemporary(l_blob);'
         || '  END LOOP; '
         || 'END;';

      -- Füllen der temporären Tabelle TOOLBOX.TEMPORARY_LOB_TABLE
      -- mit den einzelnen LOB Inhalten
      EXECUTE IMMEDIATE l_dyn_plsql_block;

      -- Gesamt Zip-File erzeugen
      FOR i IN (SELECT *
                  FROM tools.temporary_lob_table)
      LOOP
         add1file(p_zipped_blob => l_ziped_lob
                , p_name        => i.filename
                , p_content     => i.lob_content);
      END LOOP;

      -- Gesamt Zip-File Erstellung abschließen
      finish_zip(p_zipped_blob => l_ziped_lob);

      --      wwv_flow_file_mgr.download_file(p_file_content    => l_ziped_lob
      --                                    , p_file_name       => p_target_zip_file_name
      --                                    , p_mime_type       => p_target_mime_type
      --                                    , p_file_charset    => p_target_file_charset
      --                                    , p_last_updated_on => SYSDATE
      --                                    , p_etag            => '');
      -- Im HTTP-Header wird der Dateityp gesetzt. Damit erkennt der Browser
      -- welche Applikation (bspw. MS Word) zu starten ist
      OWA_UTIL.mime_header(NVL(NULL, 'application/octet'), FALSE);

      -- Die Dateigröße wird dem Browser ebenfalls mitgeteilt
      -- htp.p('Content-length:'|| v_size);

      -- Das Datum (LETZTE_AENDERUNG) wird ebenfalls als HTTP-Header gesetzt
      HTP.p(
         'Date:' || TO_CHAR(SYSDATE, 'Dy, DD Mon RRRR hh24:mi:ss') || ' CET');

      -- Der Parameter p_display steuert, ob die Datei direkt dargestellt oder
      -- ob dem Anwender ein Download-Dialog angeboten werden soll. Wie man sehen
      -- kann, richtet sich der Browser nach den Feldern im HTTP Header.

      HTP.p(
         'Content-Disposition: attachment; filename=' || p_target_zip_file_name);


      -- Der Browser soll die Datei unter keinen Umständen aus dem Cache holen.
      HTP.p('Cache-Control: must-revalidate, max-age=0');
      HTP.p('Expires: Thu, 01 Jan 1970 01:00:00 CET');

      -- Die Datei bekommt eine ID - damit kann der Browser sie eindeutig erkennen.
      --htp.p('Etag: TAB_DATEIEN...'||p_id||'...'||to_char(v_lastchange, 'JHH24MISS'));

      -- Alle HTTP-Header-Felder sind gesetzt
      OWA_UTIL.http_header_close;


      WPG_DOCLOAD.download_file(p_blob => l_ziped_lob);

      -- Oracle APEX API Call zum Unterbrechen des Page Processings
      -- während des File-Downloads
      --APEX_APPLICATION.stop_apex_engine;

      -- temporary LOBs wieder freigeben
      DBMS_LOB.freetemporary(l_ziped_lob);
   END apex_download_ziped_clobs;

   PROCEDURE apex_download_ziped_blobs(
      p_source_table_name       IN user_tables.table_name%TYPE
    , p_source_blob_column_name IN user_tab_cols.column_name%TYPE
    , p_source_filename_rule    IN VARCHAR2
    , p_source_sql_criteria     IN VARCHAR2 DEFAULT '1 = 1'
    , p_target_zip_file_name    IN VARCHAR2
    , p_target_mime_type        IN VARCHAR2 DEFAULT 'text'
    , p_target_file_charset     IN VARCHAR2 DEFAULT 'ASCII')
   IS
      -- Prozedur apex_download_ziped_blobs immer aus einer APEX Session heraus aufrufen!!!
      l_dyn_plsql_block VARCHAR2(32767 CHAR);
      l_ziped_lob       BLOB;
   BEGIN
      -- Über das Konstrukt der dynamischen CLOB-Ermittlung ist es auch möglich,
      -- ein Zip-Archiv zu erstellen, was mehrere Dateien (1 Datei pro CLOB Zeile) beinhaltet.
      l_ziped_lob := EMPTY_BLOB();
      DBMS_LOB.createtemporary(l_ziped_lob, FALSE);

      l_dyn_plsql_block      :=
            'BEGIN '
         || '  FOR i IN (SELECT '
         || p_source_blob_column_name
         || ' as blob_column, '
         || p_source_filename_rule
         || ' as filename FROM '
         || p_source_table_name
         || '                WHERE '
         || p_source_sql_criteria
         || '               ) LOOP '
         || '           '
         || '     INSERT INTO TOOLS.TEMPORARY_LOB_TABLE '
         || '     (CONTEXT, FILENAME, LOB_CONTENT, SYS_DATE) VALUES '
         || '     (''apex_download_ziped_blobs'', i.filename, i.blob_column, SYSDATE);'
         || '  END LOOP; '
         || 'END;';

      -- Füllen der temporären Tabelle TOOLBOX.TEMPORARY_LOB_TABLE
      -- mit den einzelnen LOB Inhalten
      EXECUTE IMMEDIATE l_dyn_plsql_block;

      -- Gesamt Zip-File erzeugen
      FOR i IN (SELECT *
                  FROM tools.temporary_lob_table)
      LOOP
         add1file(p_zipped_blob => l_ziped_lob
                , p_name        => i.filename
                , p_content     => i.lob_content);
      END LOOP;

      -- Gesamt Zip-File Erstellung abschließen
      finish_zip(p_zipped_blob => l_ziped_lob);



      --      wwv_flow_file_mgr.download_file(p_file_content    => l_ziped_lob
      --                                    , p_file_name       => p_target_zip_file_name
      --                                    , p_mime_type       => p_target_mime_type
      --                                    , p_file_charset    => p_target_file_charset
      --                                    , p_last_updated_on => SYSDATE
      --                                    , p_etag            => '');

      -- Im HTTP-Header wird der Dateityp gesetzt. Damit erkennt der Browser
      -- welche Applikation (bspw. MS Word) zu starten ist
      OWA_UTIL.mime_header(NVL(NULL, 'application/octet'), FALSE);

      -- Die Dateigröße wird dem Browser ebenfalls mitgeteilt
      -- htp.p('Content-length:'|| v_size);

      -- Das Datum (LETZTE_AENDERUNG) wird ebenfalls als HTTP-Header gesetzt
      HTP.p(
         'Date:' || TO_CHAR(SYSDATE, 'Dy, DD Mon RRRR hh24:mi:ss') || ' CET');

      -- Der Parameter p_display steuert, ob die Datei direkt dargestellt oder
      -- ob dem Anwender ein Download-Dialog angeboten werden soll. Wie man sehen
      -- kann, richtet sich der Browser nach den Feldern im HTTP Header.

      HTP.p(
         'Content-Disposition: attachment; filename=' || p_target_zip_file_name);


      -- Der Browser soll die Datei unter keinen Umständen aus dem Cache holen.
      HTP.p('Cache-Control: must-revalidate, max-age=0');
      HTP.p('Expires: Thu, 01 Jan 1970 01:00:00 CET');

      -- Die Datei bekommt eine ID - damit kann der Browser sie eindeutig erkennen.
      --htp.p('Etag: TAB_DATEIEN...'||p_id||'...'||to_char(v_lastchange, 'JHH24MISS'));

      -- Alle HTTP-Header-Felder sind gesetzt
      OWA_UTIL.http_header_close;

      WPG_DOCLOAD.download_file(p_blob => l_ziped_lob);

      -- Oracle APEX API Call zum Unterbrechen des Page Processings
      -- während des File-Downloads
      --APEX_APPLICATION.stop_apex_engine;

      -- temporary LOBs wieder freigeben
      DBMS_LOB.freetemporary(l_ziped_lob);
   END apex_download_ziped_blobs;

   FUNCTION encrypt_blob(p_src BLOB, p_pw VARCHAR2)
      RETURN BLOB
   IS
      t_salt       RAW(16);
      t_key        RAW(32);
      t_pw         RAW(32767) := UTL_RAW.cast_to_raw(p_pw);
      t_key_bits   PLS_INTEGER := 256;
      t_key_length PLS_INTEGER := t_key_bits / 8 * 2 + 2;
      t_cnt        PLS_INTEGER := 1000;
      t_keys       RAW(32767);
      t_sum        RAW(32767);
      t_mac        RAW(20);
      t_iv         RAW(16);
      t_block      RAW(16);
      t_len        PLS_INTEGER;
      t_rv         BLOB;
      t_tmp        BLOB;
   BEGIN
      t_salt := DBMS_CRYPTO.randombytes(t_key_bits / 16);

      FOR i IN 1 .. CEIL(t_key_length / 20)
      LOOP
         t_mac      :=
            DBMS_CRYPTO.mac(UTL_RAW.CONCAT(t_salt, TO_CHAR(i, 'fm0xxxxxxx'))
                          , DBMS_CRYPTO.hmac_sh1
                          , t_pw);
         t_sum  := t_mac;

         FOR j IN 1 .. t_cnt - 1
         LOOP
            t_mac := DBMS_CRYPTO.mac(t_mac, DBMS_CRYPTO.hmac_sh1, t_pw);
            t_sum := UTL_RAW.bit_xor(t_mac, t_sum);
         END LOOP;

         t_keys := UTL_RAW.CONCAT(t_keys, t_sum);
      END LOOP;

      t_keys := UTL_RAW.SUBSTR(t_keys, 1, t_key_length);
      t_key  := UTL_RAW.SUBSTR(t_keys, 1, t_key_bits / 8);
      t_rv   := UTL_RAW.CONCAT(t_salt, UTL_RAW.SUBSTR(t_keys, -2, 2));

      --
      FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(p_src) - 1) / 16)
      LOOP
         t_block := DBMS_LOB.SUBSTR(p_src, 16, i * 16 + 1);
         t_len   := UTL_RAW.LENGTH(t_block);

         IF t_len < 16
         THEN
            t_block      :=
               UTL_RAW.CONCAT(t_block, UTL_RAW.copies('00', 16 - t_len));
         END IF;

         t_iv      :=
            UTL_RAW.reverse(
               TO_CHAR(i + 1, 'fm000000000000000000000000000000x'));
         DBMS_LOB.writeappend(t_rv
                            , t_len
                            , DBMS_CRYPTO.encrypt(
                                 t_block
                               ,   DBMS_CRYPTO.encrypt_aes256
                                 + DBMS_CRYPTO.chain_cfb
                                 + DBMS_CRYPTO.pad_none
                               , t_key
                               , t_iv));
      END LOOP;

      --
      DBMS_LOB.createtemporary(t_tmp, TRUE);
      DBMS_LOB.COPY(t_tmp
                  , t_rv
                  , DBMS_LOB.getlength(p_src)
                  , 1
                  , t_key_bits / 16 + 2 + 1);
      t_mac      :=
         DBMS_CRYPTO.mac(
            t_tmp
          , DBMS_CRYPTO.hmac_sh1
          , UTL_RAW.SUBSTR(t_keys, 1 + t_key_bits / 8, t_key_bits / 8));
      DBMS_LOB.writeappend(t_rv, 10, t_mac);
      DBMS_LOB.freetemporary(t_tmp);
      RETURN t_rv;
   END encrypt_blob;
END zip;
/