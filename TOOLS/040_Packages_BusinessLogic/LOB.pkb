---------------------------------------------------------------------------------------
-- IMPLEMENTATION
---------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY lob
IS
   FUNCTION blob_to_clob( p_blob BLOB )
      RETURN CLOB
   IS
      v_clob         CLOB;
      v_dest_offsset INTEGER := 1;
      v_src_offsset  INTEGER := 1;
      v_lang_context INTEGER := DBMS_LOB.default_lang_ctx;
      v_warning      INTEGER;
   BEGIN
      IF p_blob IS NOT NULL THEN
         DBMS_LOB.createtemporary( lob_loc => v_clob, cache => FALSE );

         DBMS_LOB.converttoclob( dest_lob     => v_clob
                               , src_blob     => p_blob
                               , amount       => DBMS_LOB.lobmaxsize
                               , dest_offset  => v_dest_offsset
                               , src_offset   => v_src_offsset
                               , blob_csid    => DBMS_LOB.default_csid
                               , lang_context => v_lang_context
                               , warning      => v_warning );
      END IF;

      RETURN v_clob;
   END blob_to_clob;

   FUNCTION clob_to_blob( p_clob CLOB )
      RETURN BLOB
   IS
      v_blob         BLOB;
      v_dest_offsset INTEGER := 1;
      v_src_offsset  INTEGER := 1;
      v_lang_context INTEGER := DBMS_LOB.default_lang_ctx;
      v_warning      INTEGER;
   BEGIN
      IF p_clob IS NOT NULL THEN
         DBMS_LOB.createtemporary( lob_loc => v_blob, cache => FALSE );

         DBMS_LOB.converttoblob( dest_lob     => v_blob
                               , src_clob     => p_clob
                               , amount       => DBMS_LOB.lobmaxsize
                               , dest_offset  => v_dest_offsset
                               , src_offset   => v_src_offsset
                               , blob_csid    => DBMS_LOB.default_csid
                               , lang_context => v_lang_context
                               , warning      => v_warning );
      END IF;

      RETURN v_blob;
   END clob_to_blob;

   PROCEDURE replace_clob( p_clob IN OUT NOCOPY CLOB, p_what IN VARCHAR2, p_with IN VARCHAR2 )
   IS
      c_whatlen CONSTANT PLS_INTEGER := LENGTH( p_what );
      c_withlen CONSTANT PLS_INTEGER := NVL( LENGTH( p_with ), 0 );

      l_return           CLOB;
      l_segment          CLOB;
      l_pos              PLS_INTEGER := 1 - c_withlen;
      l_offset           PLS_INTEGER := 1;
   BEGIN
      IF p_what IS NOT NULL THEN
         WHILE l_offset < DBMS_LOB.getlength( p_clob ) LOOP
            l_segment := DBMS_LOB.SUBSTR( p_clob, 32767, l_offset );

            LOOP
               l_pos          := DBMS_LOB.INSTR( l_segment, p_what, l_pos + GREATEST( c_withlen, 1 ) );
               EXIT WHEN    ( NVL( l_pos, 0 ) = 0 )
                         OR ( l_pos = 32767 - c_withlen );
               l_segment      := TO_CLOB(    DBMS_LOB.SUBSTR( l_segment, l_pos - 1 )
                                          || p_with
                                          || DBMS_LOB.SUBSTR( l_segment
                                                            ,   32767
                                                              - c_whatlen
                                                              - l_pos
                                                              - c_whatlen
                                                              + 1
                                                            , l_pos + c_whatlen ) );
            END LOOP;

            l_return  := l_return || l_segment;
            l_offset  := l_offset + 32767 - c_whatlen;
         END LOOP;
      END IF;

      p_clob := l_return;
   END replace_clob;

   FUNCTION replace_clob( p_lob IN CLOB, p_what IN VARCHAR2, p_with IN CLOB )
      RETURN CLOB
   IS
      n        NUMBER;
      l_result CLOB := p_lob;
   BEGIN
      n := DBMS_LOB.INSTR( p_lob, p_what );

      IF ( NVL( n, 0 ) > 0 ) THEN
         DBMS_LOB.createtemporary( l_result, FALSE, DBMS_LOB.call );
         DBMS_LOB.COPY( l_result
                      , p_lob
                      , n - 1
                      , 1
                      , 1 );
         DBMS_LOB.COPY( l_result
                      , p_with
                      , DBMS_LOB.getlength( p_with )
                      , DBMS_LOB.getlength( l_result ) + 1
                      , 1 );
         DBMS_LOB.COPY( l_result
                      , p_lob
                      , DBMS_LOB.getlength( p_lob ) - ( n + LENGTH( p_what ) ) + 1
                      , DBMS_LOB.getlength( l_result ) + 1
                      , n + LENGTH( p_what ) );
      END IF;

      IF NVL( DBMS_LOB.INSTR( l_result, p_what ), 0 ) > 0 THEN
         RETURN replace_clob( l_result, p_what, p_with );
      END IF;

      RETURN l_result;
   END replace_clob;

   FUNCTION get_file( p_directory IN all_directories.directory_name%TYPE, p_filename IN VARCHAR2 )
      RETURN CLOB
   IS
      v_bfile             BFILE;
      v_file              CLOB;
      v_error_out         INTEGER;
      dest_offset         INTEGER := 1;
      src_offset          INTEGER := 1;
      bfile_csid          INTEGER := 0;
      lang_context        INTEGER := DBMS_LOB.default_lang_ctx;
      e_inconvertiblechar EXCEPTION;
   BEGIN
      v_bfile := BFILENAME( p_directory, p_filename );

      DBMS_LOB.fileopen( v_bfile, DBMS_LOB.file_readonly );

      DBMS_LOB.createtemporary( v_file, TRUE );

      DBMS_LOB.loadclobfromfile( v_file
                               , v_bfile
                               , DBMS_LOB.lobmaxsize
                               , dest_offset
                               , src_offset
                               , bfile_csid
                               , lang_context
                               , v_error_out );
      DBMS_LOB.fileclose( v_bfile );

      IF v_error_out = DBMS_LOB.warn_inconvertible_char THEN
         RAISE e_inconvertiblechar;
      ELSIF v_error_out != 0 THEN
         raise_application_error( -20001, 'Unknown errornumber ' || v_error_out, TRUE );
      END IF;

      RETURN v_file;
   EXCEPTION
      WHEN e_inconvertiblechar THEN
         raise_application_error( -20001, 'Inconvertible charset', TRUE );
         RETURN NULL;
   END get_file;
END lob;
/