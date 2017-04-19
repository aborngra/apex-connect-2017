---------------------------------------------------------------------------------------
-- SPECIFICATION
---------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE lob
   AUTHID CURRENT_USER
IS
   FUNCTION blob_to_clob (p_blob BLOB)
      RETURN CLOB;

   FUNCTION clob_to_blob (p_clob CLOB)
      RETURN BLOB;

   PROCEDURE replace_clob (p_clob   IN OUT NOCOPY CLOB,
                           p_what   IN            VARCHAR2,
                           p_with   IN            VARCHAR2);

   FUNCTION replace_clob (p_lob IN CLOB, p_what IN VARCHAR2, p_with IN CLOB)
      RETURN CLOB;

   FUNCTION get_file (p_directory   IN all_directories.directory_name%TYPE,
                      p_filename    IN VARCHAR2)
      RETURN CLOB;
END lob;
/