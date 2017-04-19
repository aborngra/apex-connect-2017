CREATE OR REPLACE PACKAGE zip
   AUTHID CURRENT_USER
IS
   PROCEDURE add1file (p_zipped_blob   IN OUT NOCOPY BLOB,
                       p_name          IN            VARCHAR2,
                       p_content       IN            BLOB);

   PROCEDURE finish_zip (p_zipped_blob IN OUT NOCOPY BLOB);

   PROCEDURE save_zip (p_zipped_blob   IN BLOB,
                       p_dir           IN VARCHAR2,
                       p_filename      IN VARCHAR2);

   /*  Die Prozedur apex_download_ziped_clobs stellt die Funktionalität bereit, um innerhalb
       einer APEX Anwendung einen Download Dialog zu erhalten für ein Zip-Archiv.
       Der Inhalt des Zip-Archivs ergibt sich folgendermaßen:
       Aus der CLOB Spalte (p_source_clob_column_name)  von einer
       Quelltabelle (p_source_table_name) wird eine Datei erzeugt, mit dem
       Dateinamen, der sich anhand einer Namensregel ergibt (p_source_filename_rule).
       Diese Namensregel ist ein SQL Ausdruck, der sich auf die Quelltabelle bezieht.
       Bei mehreren Datensätzen der Quelltabelle enthält das Zip-Archiv also
       mehrere Dateien. Alle Dateien werden zu einem Archiv gepakt. Das gesamte
       Zip-File erhält einen Namen (p_target_zip_file_name).
       Die Anzahl der Datensätze der Quelltabelle kann über ein dynamisches WHERE
       Kriterium (p_source_sql_criteria) eingeschränkt werden.

       Beispielaufruf aus einer APEX Anwendung heraus:
       BEGIN
         tools.zip.apex_download_ziped_clobs( p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
                                                , p_source_filename_rule    => 'upper(SVN_NAME) || ''.sql'''
                                                , p_source_clob_column_name => 'SVN_SCRIPT'
                                                , p_source_sql_criteria     => 'SVN_OBJECT=''TABLE'''
                                                , p_target_zip_file_name    => 'SVN.zip' );
       END;
   */

   PROCEDURE apex_download_ziped_clobs (
      p_source_table_name         IN user_tables.table_name%TYPE,
      p_source_clob_column_name   IN user_tab_cols.column_name%TYPE,
      p_source_filename_rule      IN VARCHAR2,
      p_source_sql_criteria       IN VARCHAR2 DEFAULT '1 = 1',
      p_target_zip_file_name      IN VARCHAR2,
      p_target_mime_type          IN VARCHAR2 DEFAULT 'text',
      p_target_file_charset       IN VARCHAR2 DEFAULT 'ASCII');

                                   /*  Die Prozedur apex_download_ziped_clobs stellt die Funktionalität bereit, um innerhalb
    einer APEX Anwendung einen Download Dialog zu erhalten für ein Zip-Archiv.
    Der Inhalt des Zip-Archivs ergibt sich folgendermaßen:
    Aus der BLOB Spalte (p_source_blob_column_name)  von einer
    Quelltabelle (p_source_table_name) wird eine Datei erzeugt, mit dem
    Dateinamen, der sich anhand einer Namensregel ergibt (p_source_filename_rule).
    Diese Namensregel ist ein SQL Ausdruck, der sich auf die Quelltabelle bezieht.
    Bei mehreren Datensätzen der Quelltabelle enthält das Zip-Archiv also
    mehrere Dateien. Alle Dateien werden zu einem Archiv gepakt. Das gesamte
    Zip-File erhält einen Namen (p_target_zip_file_name).
    Die Anzahl der Datensätze der Quelltabelle kann über ein dynamisches WHERE
    Kriterium (p_source_sql_criteria) eingeschränkt werden.

    Beispielaufruf aus einer APEX Anwendung heraus:
    BEGIN
      tools.zip.apex_download_ziped_blobs( p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
                                             , p_source_filename_rule    => 'upper(SVN_NAME) || ''.sql'''
                                             , p_source_blob_column_name => 'SVN_SCRIPT'
                                             , p_source_sql_criteria     => 'SVN_OBJECT=''TABLE'''
                                             , p_target_zip_file_name    => 'SVN.zip' );
    END;
*/

   PROCEDURE apex_download_ziped_blobs (
      p_source_table_name         IN user_tables.table_name%TYPE,
      p_source_blob_column_name   IN user_tab_cols.column_name%TYPE,
      p_source_filename_rule      IN VARCHAR2,
      p_source_sql_criteria       IN VARCHAR2 DEFAULT '1 = 1',
      p_target_zip_file_name      IN VARCHAR2,
      p_target_mime_type          IN VARCHAR2 DEFAULT 'text',
      p_target_file_charset       IN VARCHAR2 DEFAULT 'ASCII');

   FUNCTION encrypt_blob (p_src BLOB, p_pw VARCHAR2)
      RETURN BLOB;
END zip;
/