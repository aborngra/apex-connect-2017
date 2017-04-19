---------------------------------------------------------------------------------------
-- IMPLEMENTATION
---------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY string
IS
   FUNCTION split_to_table (p_string      IN VARCHAR2,
                            p_delimiter   IN VARCHAR2 DEFAULT ',')
      RETURN t_str_array
      PIPELINED
   IS
      v_offset                   PLS_INTEGER := 1;
      v_index                    PLS_INTEGER := INSTR (p_string, p_delimiter, v_offset);
      v_delimiter_length         PLS_INTEGER := LENGTH (p_delimiter);
      v_string_length   CONSTANT PLS_INTEGER := LENGTH (p_string);
   BEGIN
      WHILE v_index > 0
      LOOP
         PIPE ROW (TRIM (SUBSTR (p_string, v_offset, v_index - v_offset)));
         v_offset := v_index + v_delimiter_length;
         v_index := INSTR (p_string, p_delimiter, v_offset);
      END LOOP;

      IF v_string_length - v_offset + 1 > 0
      THEN
         PIPE ROW (TRIM (
                      SUBSTR (p_string,
                              v_offset,
                              v_string_length - v_offset + 1)));
      END IF;

      RETURN;
   END split_to_table;

   FUNCTION join_to_varchar (p_cursor      IN typ_ref_cursor,
                             p_delimiter   IN VARCHAR2 DEFAULT ',')
      RETURN VARCHAR2
   IS
      v_return   VARCHAR2 (32767);
      v_value    VARCHAR2 (32767);
   BEGIN
      LOOP
         FETCH p_cursor INTO v_value;

         EXIT WHEN p_cursor%NOTFOUND;

         v_return :=
               v_return
            || CASE WHEN v_return IS NULL THEN NULL ELSE p_delimiter END
            || v_value;
      END LOOP;

      RETURN v_return;
   END join_to_varchar;

   FUNCTION split (p_string         IN VARCHAR2,
                   p_split_string   IN VARCHAR2,
                   p_index          IN NUMBER)
      RETURN VARCHAR2
   IS
      v_ret   VARCHAR2 (4000 CHAR);
   BEGIN
      FOR i
         IN (SELECT COLUMN_VALUE
               FROM (SELECT ROWNUM AS split_index, t.*
                       FROM TABLE (
                               split_to_table (
                                  p_string      => p_string,
                                  p_delimiter   => p_split_string)) t))
      LOOP
         v_ret := v_ret || p_split_string || i.COLUMN_VALUE;
      END LOOP;

      RETURN LTRIM (v_ret, p_split_string);
   END split;
END string;
/