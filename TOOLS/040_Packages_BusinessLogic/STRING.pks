---------------------------------------------------------------------------------------
-- SPECIFICATION
---------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE string
IS
   TYPE typ_ref_cursor IS REF CURSOR;

   FUNCTION split_to_table (p_string      IN VARCHAR2,
                            p_delimiter   IN VARCHAR2 DEFAULT ',')
      RETURN t_str_array
      PIPELINED;

   FUNCTION join_to_varchar (p_cursor      IN typ_ref_cursor,
                             p_delimiter   IN VARCHAR2 DEFAULT ',')
      RETURN VARCHAR2;

   FUNCTION split (p_string         IN VARCHAR2,
                   p_split_string   IN VARCHAR2,
                   p_index          IN NUMBER)
      RETURN VARCHAR2;
END string;
/