CREATE OR REPLACE PACKAGE BODY table_api
IS
   --------------------------------------------------------------------------------
   PROCEDURE util_clob_append (
      p_clob                 IN OUT NOCOPY CLOB,
      p_clob_varchar_cache   IN OUT NOCOPY VARCHAR2,
      p_varchar_to_append    IN            VARCHAR2,
      p_final_call           IN            BOOLEAN DEFAULT FALSE)
   IS
   BEGIN
      p_clob_varchar_cache := p_clob_varchar_cache || p_varchar_to_append;

      IF p_final_call
      THEN
         IF p_clob IS NULL
         THEN
            p_clob := p_clob_varchar_cache;
         ELSE
            DBMS_LOB.append (p_clob, p_clob_varchar_cache);
         END IF;

         --> clear cache on final call
         p_clob_varchar_cache := NULL;
      END IF;
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         IF p_clob IS NULL
         THEN
            p_clob := p_clob_varchar_cache;
         ELSE
            DBMS_LOB.append (p_clob, p_clob_varchar_cache);
         END IF;

         p_clob_varchar_cache := p_varchar_to_append;

         IF p_final_call
         THEN
            DBMS_LOB.append (p_clob, p_clob_varchar_cache);
            --> clear cache on final call
            p_clob_varchar_cache := NULL;
         END IF;
   END;

   --------------------------------------------------------------------------------
   PROCEDURE util_template_replace (p_scope IN VARCHAR2 DEFAULT NULL)
   IS
      v_pattern   VARCHAR2 (30) := '#\w+#';
      v_match     VARCHAR2 (50);
      v_sql       VARCHAR2 (32767);
   BEGIN
      v_match := REGEXP_SUBSTR (g.code.template, v_pattern);

      WHILE v_match IS NOT NULL
      LOOP
         v_sql :=
               'BEGIN :1 := REPLACE(:2, :3, table_api.g.substitutions.'
            || LTRIM (RTRIM (v_match, '#'), '#')
            || ' ); END;';

         EXECUTE IMMEDIATE v_sql
            USING OUT g.code.template, IN g.code.template, IN v_match;

         v_match := REGEXP_SUBSTR (g.code.template, v_pattern);
      END LOOP;

      IF p_scope = 'SPEC'
      THEN
         util_clob_append (g.code.api_spec,
                           g.code.api_spec_varchar_cache,
                           g.code.template);
      ELSIF p_scope = 'BODY'
      THEN
         util_clob_append (g.code.api_body,
                           g.code.api_body_varchar_cache,
                           g.code.template);
      ELSIF p_scope = 'VIEW'
      THEN
         g.code.dml_view := g.code.template;
      ELSIF p_scope = 'TRIGGER'
      THEN
         g.code.dml_view_trigger := g.code.template;
      END IF;
   END;

   --------------------------------------------------------------------------------
   PROCEDURE util_execute_sql (p_sql IN OUT NOCOPY VARCHAR2)
   IS
      v_cursor        NUMBER;
      v_exec_result   PLS_INTEGER;
   BEGIN
      BEGIN
         v_cursor := DBMS_SQL.open_cursor;
         DBMS_SQL.parse (v_cursor, p_sql, DBMS_SQL.native);
         v_exec_result := DBMS_SQL.execute (v_cursor);
         DBMS_SQL.close_cursor (v_cursor);
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_SQL.close_cursor (v_cursor);
            RAISE;
      END;
   END;

   --------------------------------------------------------------------------------
   PROCEDURE util_execute_sql (p_sql IN OUT NOCOPY CLOB)
   IS
      v_cursor        NUMBER;
      v_exec_result   PLS_INTEGER;
   BEGIN
      v_cursor := DBMS_SQL.open_cursor;
      DBMS_SQL.parse (v_cursor, p_sql, DBMS_SQL.native);
      v_exec_result := DBMS_SQL.execute (v_cursor);
      DBMS_SQL.close_cursor (v_cursor);
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_SQL.close_cursor (v_cursor);
         RAISE;
   END;

   --------------------------------------------------------------------------------
   FUNCTION util_get_identifier_short_name (p_identifier_name    VARCHAR2,
                                            p_length             INTEGER)
      RETURN VARCHAR2
      DETERMINISTIC
   IS
      v_return   VARCHAR2 (100);
   BEGIN
      IF LENGTH (p_identifier_name) > p_length
      THEN
         v_return := SUBSTR (p_identifier_name, 1, p_length - 1) || '~';
      ELSE
         v_return := p_identifier_name;
      END IF;

      RETURN v_return;
   END;

   --------------------------------------------------------------------------------
   FUNCTION util_get_table_key (
      p_table_name   IN user_tables.table_name%TYPE,
      p_key_type     IN user_constraints.constraint_type%TYPE DEFAULT 'P',
      p_delimiter    IN VARCHAR2 DEFAULT ', ')
      RETURN VARCHAR2
   IS
      v_table_pk   VARCHAR2 (4000 CHAR);
   BEGIN
      FOR i
         IN (WITH cons
                  AS (SELECT *
                        FROM user_constraints
                       WHERE     table_name = UPPER (p_table_name)
                             AND constraint_type = p_key_type),
                  cols
                  AS (SELECT *
                        FROM user_cons_columns
                       WHERE table_name = UPPER (p_table_name))
               SELECT column_name
                 FROM cons
                      JOIN cols ON cons.constraint_name = cols.constraint_name
             ORDER BY position)
      LOOP
         v_table_pk := v_table_pk || p_delimiter || i.column_name;
      END LOOP;

      RETURN LTRIM (v_table_pk, p_delimiter);
   END util_get_table_key;

   --------------------------------------------------------------------------------
   FUNCTION util_get_table_column_prefix (p_table_name IN VARCHAR2)
      RETURN VARCHAR2
   IS
      v_count    PLS_INTEGER := 0;
      v_return   VARCHAR2 (30);
   BEGIN
      FOR i
         IN (SELECT DISTINCT
                    SUBSTR (
                       column_name,
                       1,
                       CASE
                          WHEN INSTR (column_name, '_') = 0
                          THEN
                             LENGTH (column_name)
                          ELSE
                             INSTR (column_name, '_') - 1
                       END)
                       AS prefix
               FROM user_tab_cols
              WHERE     table_name = UPPER (p_table_name)
                    AND hidden_column = 'NO')
      LOOP
         v_count := v_count + 1;

         IF v_count > 1
         THEN
            v_return := NULL;
            EXIT;
         END IF;

         v_return := i.prefix;
      END LOOP;

      RETURN v_return;
   END;

   --------------------------------------------------------------------------------
   FUNCTION util_get_api_column_name (
      p_column_name                   VARCHAR2,
      p_length                        INTEGER,
      p_col_prefix_in_method_names    BOOLEAN)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN NULL;
   END;

   --------------------------------------------------------------------------------
   FUNCTION util_get_attribute_surrogate (
      p_data_type   IN user_tab_cols.data_type%TYPE)
      RETURN VARCHAR2
   IS
      v_return   VARCHAR2 (100 CHAR);
   BEGIN
      v_return :=
         CASE
            WHEN p_data_type = 'NUMBER'
            THEN
               '-999999999999999.999999999999999'
            WHEN p_data_type LIKE '%CHAR%'
            THEN
               q'['@@@@@@@@@@@@@@@']'
            WHEN p_data_type = 'DATE'
            THEN
               q'[TO_DATE( '01.01.1900', 'DD.MM.YYYY' )]'
            WHEN p_data_type LIKE 'TIMESTAMP%'
            THEN
               q'[TO_TIMESTAMP( '01.01.1900', 'dd.mm.yyyy' )]'
            WHEN p_data_type = 'CLOB'
            THEN
               q'[TO_CLOB( '@@@@@@@@@@@@@@@' )]'
            WHEN p_data_type = 'BLOB'
            THEN
               q'[TO_BLOB( UTL_RAW.cast_to_raw( '@@@@@@@@@@@@@@@' ) )]'
            WHEN p_data_type = 'XMLTYPE'
            THEN
               q'[XMLTYPE( '<NULL/>' )]'
            ELSE
               q'['@@@@@@@@@@@@@@@']'
         END;
      RETURN v_return;
   END util_get_attribute_surrogate;

   --------------------------------------------------------------------------------
   FUNCTION util_get_attribute_compare (
      p_data_type           IN user_tab_cols.data_type%TYPE,
      p_first_attribute     IN VARCHAR2,
      p_second_attribute    IN VARCHAR2,
      p_compare_operation   IN VARCHAR2 DEFAULT '<>')
      RETURN VARCHAR2
   IS
      v_surrogate   VARCHAR2 (100 CHAR);
      v_return      VARCHAR2 (1000 CHAR);
   BEGIN
      v_surrogate := util_get_attribute_surrogate (p_data_type);
      v_return :=
         CASE
            WHEN p_data_type = 'XMLTYPE'
            THEN
                  'util_xml_compare( COALESCE( '
               || p_first_attribute
               || ', '
               || v_surrogate
               || ' ), COALESCE( '
               || p_second_attribute
               || ', '
               || v_surrogate
               || ' ) ) '
               || p_compare_operation
               || ' 0'
            WHEN p_data_type IN ('BLOB', 'CLOB')
            THEN
                  'DBMS_LOB.compare( COALESCE( '
               || p_first_attribute
               || ', '
               || v_surrogate
               || ' ), COALESCE( '
               || p_second_attribute
               || ', '
               || v_surrogate
               || ' ) ) '
               || p_compare_operation
               || ' 0'
            ELSE
                  'COALESCE( '
               || p_first_attribute
               || ', '
               || v_surrogate
               || ' ) '
               || p_compare_operation
               || ' COALESCE( '
               || p_second_attribute
               || ', '
               || v_surrogate
               || ' )'
         END;
      RETURN v_return;
   END util_get_attribute_compare;

   --------------------------------------------------------------------------------
   PROCEDURE gen_header
   IS
   BEGIN
      g.code.template :=
         ' 
CREATE OR REPLACE PACKAGE #table_name_26#_api IS
/** This package #TABLE_NAME_26#_api is the API for the table #TABLE_NAME# 
    and provides DML functionality that can be easily called from APEX. Target  
    of the table API is to encapsulate the table DML source code for security 
    (UI schema needs only the execute right for the API and the read/write right
    for the #TABLE_NAME_24#_dml_v, tables can be hidden in extra data schema) and 
    easy readability of the business logic (all DML is then written in the same 
    style). 
    For APEX automatic row processing like tabular forms you can use the 
    #TABLE_NAME_24#_dml_v, which has an instead of trigger who is also calling 
    the #TABLE_NAME_26#_api. If you do so, please use the option "existing trigger"
    when asked for the sequence, because the #TABLE_NAME_26#_api is also handling
    the sequence.
    Last created by: #CREATED_BY#  
    Last created on: #CREATED_ON# 
  */
----------------------------------------
CURSOR g_cur_search_by_pk(p_#TABLE_PK_28# IN #TABLE_NAME#.#TABLE_PK#%TYPE) IS
SELECT * FROM #TABLE_NAME# WHERE #TABLE_PK# = p_#TABLE_PK_28#;
--
g_row_search_by_pk #TABLE_NAME#%ROWTYPE;
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
CREATE OR REPLACE PACKAGE BODY #table_name_26#_api IS
----------------------------------------';

      IF g.options.xmltype_column_present
      THEN
         g.code.template :=
               g.code.template
            || ' 
FUNCTION util_xml_compare( p_doc1 XMLTYPE, p_doc2 XMLTYPE )   
RETURN NUMBER
--
IS   
v_return NUMBER;
--
BEGIN     
--
SELECT CASE WHEN XMLEXISTS( ''declare default element namespace "http://xmlns.oracle.com/xdb/xdiff.xsd"; /xdiff/*'' PASSING XMLDIFF( p_doc1, p_doc2 ) ) THEN 1 ELSE 0 END 
INTO v_return       
FROM DUAL;   
--
RETURN v_return;
--
END;
----------------------------------------';
      END IF;

      util_template_replace ('BODY');
   END gen_header;

   --------------------------------------------------------------------------------
   PROCEDURE gen_row_exists_fnc
   IS
   BEGIN
      g.code.template := ' 
FUNCTION row_exists( p_#TABLE_PK_28# IN #TABLE_NAME#.#TABLE_PK#%TYPE )
RETURN BOOLEAN;
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
FUNCTION row_exists( p_#TABLE_PK_28# IN #TABLE_NAME#.#TABLE_PK#%TYPE )
RETURN BOOLEAN
IS
--
BEGIN
g_row_search_by_pk := get_row_by_pk( p_#TABLE_PK_28# => p_#TABLE_PK_28# );
RETURN g_row_search_by_pk.#TABLE_PK# IS NOT NULL;
END;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_row_exists_fnc;

   --------------------------------------------------------------------------------

   PROCEDURE gen_api_sequence
   IS
   BEGIN
      FOR i
         IN (SELECT UPPER (g.substitutions.sequence_name) AS SEQUENCE_NAME
               FROM DUAL
             MINUS
             SELECT SEQUENCE_NAME FROM user_sequences)
      LOOP
         EXECUTE IMMEDIATE
            ' CREATE SEQUENCE ' || i.sequence_name || ' MINVALUE 0 
                 MAXVALUE 999999999999999999999999999 
                 INCREMENT BY 1 
                 START WITH 1 
                 NOCACHE
                 NOORDER
                 NOCYCLE ';
      END LOOP;
   END gen_api_sequence;

   PROCEDURE gen_create_row_fnc
   IS
   BEGIN
      g.code.template := ' 
FUNCTION create_row( #PARAM_DEFINITION_W_PK# )
RETURN #TABLE_NAME#.#TABLE_PK#%TYPE;
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
FUNCTION create_row( #PARAM_DEFINITION_W_PK# ) 
RETURN #TABLE_NAME#.#TABLE_PK#%TYPE
IS
v_pk #TABLE_NAME#.#TABLE_PK#%TYPE;
--
BEGIN
-- 
v_pk := NVL(p_#TABLE_PK_28#, #SEQUENCE_NAME#.nextval);
--
INSERT
INTO #TABLE_NAME# ( #COLUMN_LIST_W_PK# )
VALUES ( v_pk, #PARAM_LIST_WO_PK# );
--
RETURN v_pk;
--
END create_row;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_create_row_fnc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_create_row_prc
   IS
   BEGIN
      g.code.template := ' 
PROCEDURE create_row( #PARAM_DEFINITION_W_PK# );
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
PROCEDURE create_row( #PARAM_DEFINITION_W_PK# )
IS
v_pk #TABLE_NAME#.#TABLE_PK#%TYPE;
BEGIN
v_pk := create_row(#MAP_PARAM_TO_PARAM_W_PK#);

END create_row;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_create_row_prc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_create_rowtype_prc
   IS
   BEGIN
      g.code.template := ' 
PROCEDURE create_row(p_row IN #TABLE_NAME#%ROWTYPE);
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
PROCEDURE create_row(p_row IN #TABLE_NAME#%ROWTYPE)
IS
BEGIN
create_row(#MAP_ROWTYPE_COL_TO_PARAM_W_PK#);
END create_row;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_create_rowtype_prc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_update_row_fnc
   IS
   BEGIN
      g.code.template := ' 
FUNCTION update_row(#PARAM_DEFINITION_W_PK#)
RETURN #TABLE_NAME#.#TABLE_PK#%TYPE;
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
FUNCTION update_row(#PARAM_DEFINITION_W_PK#)
RETURN #TABLE_NAME#.#TABLE_PK#%TYPE
--
IS
v_pk           #TABLE_NAME#.#TABLE_PK#%TYPE;
v_existing_row #TABLE_NAME#%ROWTYPE;
v_count        PLS_INTEGER := 0;
--
BEGIN
--
v_existing_row := get_row_by_pk(p_#TABLE_PK_28# => p_#TABLE_PK_28#);
--
IF (v_existing_row.#TABLE_PK# IS NOT NULL) THEN
--
v_pk := v_existing_row.#TABLE_PK#;
IF #COLUMN_COMPARE_LIST_WO_PK# THEN
UPDATE #TABLE_NAME#
SET #SET_PARAM_TO_COLUMN_WO_PK#
WHERE #TABLE_PK# = v_existing_row.#TABLE_PK#;
END IF;
--
END IF;
--
RETURN v_pk;
--
END update_row;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_update_row_fnc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_update_row_prc
   IS
   BEGIN
      g.code.template := ' 
PROCEDURE update_row( #PARAM_DEFINITION_W_PK# );
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
PROCEDURE update_row( #PARAM_DEFINITION_W_PK# )
IS
v_pk #TABLE_NAME#.#TABLE_PK#%TYPE;
BEGIN
v_pk      := update_row( #MAP_PARAM_TO_PARAM_W_PK# );
END update_row;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_update_row_prc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_update_rowtype_prc
   IS
   BEGIN
      g.code.template := ' 
PROCEDURE update_row( p_row IN #TABLE_NAME#%ROWTYPE );
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
PROCEDURE update_row( p_row IN #TABLE_NAME#%ROWTYPE )
IS
BEGIN
update_row( #MAP_ROWTYPE_COL_TO_PARAM_W_PK# );
END update_row;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_update_rowtype_prc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_createorupdate_row_fnc
   IS
   BEGIN
      g.code.template := ' 
FUNCTION create_or_update_row( #PARAM_DEFINITION_W_PK# )
RETURN #TABLE_NAME#.#TABLE_PK#%TYPE;
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
FUNCTION create_or_update_row( #PARAM_DEFINITION_W_PK# )
RETURN #TABLE_NAME#.#TABLE_PK#%TYPE
IS
v_pk           #TABLE_NAME#.#TABLE_PK#%TYPE;
v_existing_row #TABLE_NAME#%ROWTYPE;
BEGIN
IF ( p_#TABLE_PK_28# IS NULL ) THEN
v_pk      := create_row( #MAP_PARAM_TO_PARAM_W_PK# );
ELSE
-- find out record
v_existing_row := get_row_by_pk( p_#TABLE_PK_28# => p_#TABLE_PK_28# );

-- check if record exists
IF ( v_existing_row.test_id IS NOT NULL ) THEN
-- record exists
v_pk      := update_row( #MAP_PARAM_TO_PARAM_W_PK# );
ELSE
-- record does not exist
v_pk      := create_row( #MAP_PARAM_TO_PARAM_W_PK# );
END IF;
END IF;

RETURN v_pk;
END create_or_update_row;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_createorupdate_row_fnc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_createorupdate_row_prc
   IS
   BEGIN
      g.code.template := ' 
PROCEDURE create_or_update_row( #PARAM_DEFINITION_W_PK# );
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
PROCEDURE create_or_update_row( #PARAM_DEFINITION_W_PK# )
IS
v_pk #TABLE_NAME#.#TABLE_PK#%TYPE;
BEGIN
v_pk      := create_or_update_row( #MAP_PARAM_TO_PARAM_W_PK# );
END create_or_update_row;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_createorupdate_row_prc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_createorupdate_rowtype_prc
   IS
   BEGIN
      g.code.template := ' 
PROCEDURE create_or_update_row( p_row IN #TABLE_NAME#%ROWTYPE );
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
PROCEDURE create_or_update_row( p_row IN #TABLE_NAME#%ROWTYPE )
IS
BEGIN
create_or_update_row( #MAP_ROWTYPE_COL_TO_PARAM_W_PK# );
END create_or_update_row;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_createorupdate_rowtype_prc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_delete_row_prc
   IS
   BEGIN
      g.code.template := ' 
PROCEDURE delete_row( p_#TABLE_PK_28# IN #TABLE_NAME#.#TABLE_PK#%TYPE );
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
PROCEDURE delete_row( p_#TABLE_PK_28# IN #TABLE_NAME#.#TABLE_pk#%TYPE )
IS
BEGIN
DELETE FROM #TABLE_NAME#
WHERE #TABLE_PK# = p_#TABLE_PK_28#;
END delete_row;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_delete_row_prc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_get_pk_by_unique_cols_fnc
   IS
   BEGIN
      FOR i
         IN (SELECT constraint_name
               FROM user_constraints
              WHERE     LOWER (table_name) =
                           LOWER (g.substitutions.table_name)
                    AND constraint_type = 'U')
      LOOP
         FOR j
            IN (  SELECT LOWER (ucc.column_name) AS column_name, utc.data_type
                    FROM user_cons_columns ucc
                         JOIN user_tab_columns utc
                            ON     ucc.table_name = utc.table_name
                               AND ucc.column_name = utc.column_name
                   WHERE ucc.constraint_name = i.constraint_name
                ORDER BY ucc.position)
         LOOP
            g.substitutions.i_param_list_unique :=
                  g.substitutions.i_param_list_unique
               || g.options.delimiter
               || 'p_'
               || util_get_identifier_short_name (j.column_name, 28)
               || ' '
               || g.substitutions.table_name
               || '.'
               || j.column_name
               || '%TYPE';
            g.substitutions.i_column_compare_list_unique :=
                  g.substitutions.i_column_compare_list_unique
               || 'AND '
               || util_get_attribute_compare (
                     p_data_type           => j.data_type,
                     p_first_attribute     => j.column_name,
                     p_second_attribute    =>    'p_'
                                              || util_get_identifier_short_name (
                                                    j.column_name,
                                                    28),
                     p_compare_operation   => '=');
         END LOOP;

         g.substitutions.i_param_list_unique :=
            LTRIM (g.substitutions.i_param_list_unique, g.options.delimiter);
         g.substitutions.i_column_compare_list_unique :=
            LTRIM (g.substitutions.i_column_compare_list_unique, 'AND ');
         g.code.template := ' 
FUNCTION get_pk_by_unique_cols( #I_PARAM_LIST_UNIQUE# )
RETURN #TABLE_NAME#.#TABLE_PK#%TYPE;
----------------------------------------';
         util_template_replace ('SPEC');
         g.code.template := ' 
FUNCTION get_pk_by_unique_cols( #I_PARAM_LIST_UNIQUE# )
RETURN #TABLE_NAME#.#TABLE_PK#%TYPE
IS
--
CURSOR v_cur_existing_row IS
SELECT * from #TABLE_NAME#
WHERE #I_COLUMN_COMPARE_LIST_UNIQUE#;
v_existing_row v_cur_existing_row%ROWTYPE;
--
BEGIN
--
OPEN v_cur_existing_row;
FETCH v_cur_existing_row INTO v_existing_row;
CLOSE v_cur_existing_row;
--   
RETURN v_existing_row.#TABLE_PK#;
--
END get_pk_by_unique_cols;
----------------------------------------';
         util_template_replace ('BODY');
      END LOOP;
   END gen_get_pk_by_unique_cols_fnc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_get_row_by_pk_fnc
   IS
   BEGIN
      g.code.template := ' 
FUNCTION get_row_by_pk(p_#TABLE_PK_28# IN #TABLE_NAME#.#TABLE_PK#%TYPE)
RETURN #TABLE_NAME#%ROWTYPE;
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
FUNCTION get_row_by_pk( p_#TABLE_PK_28# IN #TABLE_NAME#.#TABLE_PK#%TYPE )
RETURN #TABLE_NAME#%ROWTYPE
IS
BEGIN
g_row_search_by_pk := null;
OPEN g_cur_search_by_pk( p_#TABLE_PK_28# );
FETCH g_cur_search_by_pk INTO g_row_search_by_pk;
CLOSE g_cur_search_by_pk;
RETURN g_row_search_by_pk;
END get_row_by_pk;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_get_row_by_pk_fnc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_get_row_by_pk_and_fill_prc
   IS
   BEGIN
      g.code.template := ' 
PROCEDURE get_row_by_pk_and_fill( #PARAM_IO_DEFINITION_W_PK# );
----------------------------------------';
      util_template_replace ('SPEC');
      g.code.template := ' 
PROCEDURE get_row_by_pk_and_fill( #PARAM_IO_DEFINITION_W_PK# )
IS
--
BEGIN
--
OPEN g_cur_search_by_pk( p_#TABLE_PK_28# );
FETCH g_cur_search_by_pk INTO g_row_search_by_pk;
--
IF ( g_cur_search_by_pk%FOUND ) THEN #SET_ROWTYPE_COL_TO_PARAM_WO_PK#
END IF;
--
CLOSE g_cur_search_by_pk;
--
END get_row_by_pk_and_fill;
----------------------------------------';
      util_template_replace ('BODY');
   END gen_get_row_by_pk_and_fill_prc;

   --------------------------------------------------------------------------------
   PROCEDURE gen_getter_functions
   IS
   BEGIN
      FOR i IN g.collections.table_columns.FIRST ..
               g.collections.table_columns.LAST
      LOOP
         IF (g.collections.table_columns (i).column_name <>
                g.substitutions.table_pk)
         THEN
            g.substitutions.i_column_name :=
               g.collections.table_columns (i).column_name;
            g.substitutions.i_column_name_26 :=
               g.collections.table_columns (i).column_name_26;
            g.substitutions.i_column_name_28 :=
               g.collections.table_columns (i).column_name_28;
            g.code.template :=
               ' 
FUNCTION get_#I_COLUMN_NAME_26#( p_#TABLE_PK_28# IN #TABLE_NAME#.#TABLE_PK#%TYPE )
RETURN #TABLE_NAME#.#I_COLUMN_NAME#%TYPE;
----------------------------------------';
            util_template_replace ('SPEC');
            g.code.template :=
               ' 
FUNCTION get_#I_COLUMN_NAME_26#( p_#TABLE_PK_28# IN #TABLE_NAME#.#TABLE_PK#%TYPE )
RETURN #TABLE_NAME#.#I_COLUMN_NAME#%TYPE
-- 
IS
--
BEGIN
--
g_row_search_by_pk := get_row_by_pk(p_#TABLE_PK_28# => p_#TABLE_PK_28#);
--
return g_row_search_by_pk.#I_COLUMN_NAME#;
--
END get_#I_COLUMN_NAME_26#;
----------------------------------------';
            util_template_replace ('BODY');
         END IF;
      END LOOP;
   END gen_getter_functions;

   --------------------------------------------------------------------------------
   PROCEDURE gen_setter_procedures
   IS
   BEGIN
      FOR i IN g.collections.table_columns.FIRST ..
               g.collections.table_columns.LAST
      LOOP
         IF (g.collections.table_columns (i).column_name <>
                g.substitutions.table_pk)
         THEN
            g.substitutions.i_column_name :=
               g.collections.table_columns (i).column_name;
            g.substitutions.i_column_name_26 :=
               g.collections.table_columns (i).column_name_26;
            g.substitutions.i_column_name_28 :=
               g.collections.table_columns (i).column_name_28;
            g.substitutions.i_column_compare :=
               util_get_attribute_compare (
                  p_data_type           => g.collections.table_columns (i).data_type,
                  p_first_attribute     =>    'v_existing_row.'
                                           || g.collections.table_columns (i).column_name,
                  p_second_attribute    =>    'p_'
                                           || g.collections.table_columns (i).column_name_28,
                  p_compare_operation   => '<>');
            g.code.template :=
               ' 
PROCEDURE set_#I_COLUMN_NAME_26#(p_#TABLE_PK_28# IN #TABLE_NAME#.#TABLE_PK#%TYPE, p_#I_COLUMN_NAME_28# IN #TABLE_NAME#.#I_COLUMN_NAME#%TYPE);
----------------------------------------';
            util_template_replace ('SPEC');
            g.code.template :=
               ' 
PROCEDURE set_#I_COLUMN_NAME_26#(p_#TABLE_PK_28# IN #TABLE_NAME#.#TABLE_PK#%TYPE, p_#I_COLUMN_NAME_28# IN #TABLE_NAME#.#I_COLUMN_NAME#%TYPE)
--
IS
v_existing_row #TABLE_NAME#%ROWTYPE;
--
BEGIN
--
v_existing_row := get_row_by_pk(p_#TABLE_PK_28# => p_#TABLE_PK_28#);
--
IF (v_existing_row.#TABLE_PK# IS NOT NULL) THEN
--
IF #I_COLUMN_COMPARE# THEN
UPDATE #TABLE_NAME#
SET #I_COLUMN_NAME# = p_#I_COLUMN_NAME_28#
WHERE #TABLE_PK# = p_#TABLE_PK_28#;
END IF;
--
END IF;
--
END set_#I_COLUMN_NAME_26#;
----------------------------------------';
            util_template_replace ('BODY');
         END IF;
      END LOOP;
   END gen_setter_procedures;

   --------------------------------------------------------------------------------
   PROCEDURE gen_footer
   IS
   BEGIN
      g.code.template := ' 
END #table_name_26#_api;';
      util_template_replace ('SPEC');
      g.code.template := ' 
END #table_name_26#_api;';
      util_template_replace ('BODY');
   END gen_footer;

   --------------------------------------------------------------------------------
   PROCEDURE gen_dml_view
   IS
   BEGIN
      g.code.template := ' 
CREATE OR REPLACE VIEW #TABLE_NAME_24#_dml_v
AS
SELECT #COLUMN_LIST_W_PK#
FROM #TABLE_NAME#
----------------------------------------';
      util_template_replace ('VIEW');
   END gen_dml_view;

   --------------------------------------------------------------------------------
   PROCEDURE gen_dml_view_trigger
   IS
   BEGIN
      g.code.template := ' 
CREATE OR REPLACE TRIGGER #TABLE_NAME_24#_ioiud
INSTEAD OF INSERT OR UPDATE OR DELETE
ON #TABLE_NAME_24#_dml_v
FOR EACH ROW
--
BEGIN
--
IF INSERTING THEN
#table_name_26#_api.create_row( #MAP_NEW_TO_PARAM_W_PK# );
ELSIF UPDATING THEN
#table_name_26#_api.update_row( #MAP_NEW_TO_PARAM_W_PK# );
ELSIF DELETING THEN
#DELETE_OR_THROW_EXCEPTION#
END IF;
--
END;
----------------------------------------';
      util_template_replace ('TRIGGER');
   END gen_dml_view_trigger;

   --------------------------------------------------------------------------------
   PROCEDURE do_initialize
   IS
      v_object_exists   user_objects.object_name%TYPE;
   BEGIN
      -- check if table exists
      v_object_exists := NULL;

      OPEN g_cur_table_exists;

      FETCH g_cur_table_exists INTO v_object_exists;

      CLOSE g_cur_table_exists;

      IF (v_object_exists IS NULL)
      THEN
         raise_application_error (
            -20001,
            'Table ' || g.substitutions.table_name || ' does not exist.');
      END IF;

      --> check, if option "col_prefix_in_method_names" is set and check then if table's column prefix is unique
      g.substitutions.table_column_prefix :=
         util_get_table_column_prefix (g.substitutions.table_name);

      IF     g.options.col_prefix_in_method_names = FALSE
         AND g.substitutions.table_column_prefix IS NULL
      THEN
         raise_application_error (
            -20001,
            'The prefix of your table columns is not unique and you requested to cut off the prefix for method names. Please ensure either your column names are unique or switch the parameter p_col_prefix_in_method_names to true.');
      END IF;

      -- create temporary lobs
      DBMS_LOB.createtemporary (g.code.api_spec, TRUE);
      DBMS_LOB.createtemporary (g.code.api_body, TRUE);
      -- set global package variables
      g.options.delimiter := ', ';
      g.substitutions.table_name_24 :=
         util_get_identifier_short_name (g.substitutions.table_name, 24);
      g.substitutions.table_name_26 :=
         util_get_identifier_short_name (g.substitutions.table_name, 26);
      g.substitutions.table_pk :=
         LOWER (
            util_get_table_key (p_table_name => g.substitutions.table_name));
      g.substitutions.table_pk_28 :=
         util_get_identifier_short_name (
            CASE
               WHEN g.options.col_prefix_in_method_names
               THEN
                  g.substitutions.table_pk
               ELSE
                  SUBSTR (g.substitutions.table_pk,
                          LENGTH (g.substitutions.table_column_prefix) + 2)
            END,
            28);
      g.substitutions.created_by :=
         UPPER (
            COALESCE (v ('APP_USER'), SYS_CONTEXT ('USERENV', 'OS_USER')));
      g.substitutions.created_on := TO_CHAR (SYSDATE, 'yyyy-mm-dd hh24:mi:ss');

      --
      OPEN g_cur_history_table (p_table_name => g.substitutions.table_name);

      FETCH g_cur_history_table INTO g.substitutions.table_name_h;

      CLOSE g_cur_history_table;

      --
      g.substitutions.delete_or_throw_exception :=
         CASE
            WHEN g.options.enable_deletion_of_records
            THEN
                  g.substitutions.table_name_26
               || '_api.delete_row( p_'
               || g.substitutions.table_pk_28
               || ' => :old.'
               || g.substitutions.table_pk
               || ' );'
            ELSE
               'Raise_Application_Error (-20001, ''Deletion of record is not allowed.'');'
         END;

      --------------------------------------------------------------------------
      -- set global package collections
      --------------------------------------------------------------------------
      OPEN g_cur_columns;

      FETCH g_cur_columns BULK COLLECT INTO g.collections.table_columns; --> LIMIT 1000 --> FIXME: macht das Limit hier

      -- Sinn?
      -- Wenigstens das Schließen sollte dann später gemacht werden.
      CLOSE g_cur_columns;

      --------------------------------------------------------------------------
      -- create the required column based parameter lists used in generated API
      -- Packages, Views, Triggers... These lists are replaced into the code
      -- templates.
      -- Please notice the naming: global package variables have the
      -- same name as the substitution strings in the code template e.g.
      -- #COLUMN_LIST_W_PK# is replaced with variable g.substitutions.column_list_w_pk
      --------------------------------------------------------------------------
      FOR i IN g.collections.table_columns.FIRST ..
               g.collections.table_columns.LAST
      LOOP
         --> calculate column short names
         g.collections.table_columns (i).column_name_26 :=
            util_get_identifier_short_name (
               CASE
                  WHEN g.options.col_prefix_in_method_names
                  THEN
                     g.collections.table_columns (i).column_name
                  ELSE
                     SUBSTR (
                        g.collections.table_columns (i).column_name,
                        LENGTH (g.substitutions.table_column_prefix) + 2)
               END,
               26);
         g.collections.table_columns (i).column_name_28 :=
            util_get_identifier_short_name (
               CASE
                  WHEN g.options.col_prefix_in_method_names
                  THEN
                     g.collections.table_columns (i).column_name
                  ELSE
                     SUBSTR (
                        g.collections.table_columns (i).column_name,
                        LENGTH (g.substitutions.table_column_prefix) + 2)
               END,
               28);

         -- check, if we have a xmltype column present in our list
         -- if so, we have to provide a XML compare function
         IF g.collections.table_columns (i).data_type = 'XMLTYPE'
         THEN
            g.options.xmltype_column_present := TRUE;
         ELSE
            g.options.xmltype_column_present := FALSE;
         END IF;

         /* columns as flat list:
         #COLUMN_LIST_W_PK#
         e.g.
         col1
         , col2
         , col3
         , ... */
         g.substitutions.column_list_w_pk :=
               g.substitutions.column_list_w_pk
            || g.options.delimiter
            || g.collections.table_columns (i).column_name;
         /* map :new values to parameter for IOIUD-Trigger with PK:
         #MAP_NEW_TO_PARAM_W_PK#
         e.g. p_col1 => :new.col1
         , p_col2 => :new.col2
         , p_col3 => :new.col3
         , ... */
         g.substitutions.map_new_to_param_w_pk :=
               g.substitutions.map_new_to_param_w_pk
            || g.options.delimiter
            || 'p_'
            || g.collections.table_columns (i).column_name_28
            || ' => :new.'
            || g.collections.table_columns (i).column_name;
         /* map parameter to parameter as pass-through parameter with PK:
         #MAP_PARAM_TO_PARAM_W_PK#
         e.g. p_col1 => p_col1
         , p_col2 => p_col2
         , p_col3 => p_col3
         , ... */
         g.substitutions.map_param_to_param_w_pk :=
               g.substitutions.map_param_to_param_w_pk
            || g.options.delimiter
            || 'p_'
            || g.collections.table_columns (i).column_name_28
            || ' => p_'
            || g.collections.table_columns (i).column_name_28;
         /* map rowtype columns to parameter for rowtype handling with PK:
         #MAP_ROWTYPE_COL_TO_PARAM_W_PK#
         e.g. p_col1 => p_row.col1
         , p_col2 => p_row.col2
         , p_col3 => p_row.col3
         , ... */
         g.substitutions.map_rowtype_col_to_param_w_pk :=
               g.substitutions.map_rowtype_col_to_param_w_pk
            || g.options.delimiter
            || 'p_'
            || g.collections.table_columns (i).column_name_28
            || ' => p_row.'
            || g.collections.table_columns (i).column_name;
         /* columns as parameter definition for create_row, update_row with PK:
         #PARAM_DEFINITION_W_PK#
         e.g. p_col1 IN table.col1%TYPE
         , p_col2 IN table.col2%TYPE
         , p_col3 IN table.col3%TYPE
         , ... */
         g.substitutions.param_definition_w_pk :=
               g.substitutions.param_definition_w_pk
            || g.options.delimiter
            || 'p_'
            || g.collections.table_columns (i).column_name_28
            || ' IN '
            || g.substitutions.table_name
            || '.'
            || g.collections.table_columns (i).column_name
            || '%TYPE'
            || CASE
                  WHEN (g.collections.table_columns (i).column_name =
                           g.substitutions.table_pk)
                  THEN
                     ' DEFAULT NULL'
                  ELSE
                     NULL
               END;
         /* columns as parameter IN OUT definition for get_row_by_pk_and_fill with PK:
         #PARAM_IO_DEFINITION_W_PK#
         e.g. p_col1 IN            table.col1%TYPE
         , p_col2 IN OUT NOCOPY table.col2%TYPE
         , p_col3 IN OUT NOCOPY table.col3%TYPE
         , ... */
         g.substitutions.param_io_definition_w_pk :=
               g.substitutions.param_io_definition_w_pk
            || g.options.delimiter
            || 'p_'
            || g.collections.table_columns (i).column_name_28
            || CASE
                  WHEN g.collections.table_columns (i).column_name =
                          g.substitutions.table_pk
                  THEN
                     ' IN '
                  ELSE
                     ' IN OUT NOCOPY '
               END
            || g.substitutions.table_name
            || '.'
            || g.collections.table_columns (i).column_name
            || '%TYPE';

         /* columns as flat parameter list without PK e.g. col1 is PK:
         #PARAM_LIST_WO_PK#
         e.g. p_col2
         , p_col3
         , p_col4
         , ... */
         IF (g.collections.table_columns (i).column_name <>
                g.substitutions.table_pk)
         THEN
            g.substitutions.param_list_wo_pk :=
                  g.substitutions.param_list_wo_pk
               || g.options.delimiter
               || 'p_'
               || g.collections.table_columns (i).column_name_28;
         END IF;

         /* a column list for updating a row without PK:
         #SET_PARAM_TO_COLUMN_WO_PK#
         e.g. test_number   = p_test_number
         , test_varchar2 = p_test_varchar2
         , ... */
         IF (g.collections.table_columns (i).column_name <>
                g.substitutions.table_pk)
         THEN
            g.substitutions.set_param_to_column_wo_pk :=
                  g.substitutions.set_param_to_column_wo_pk
               || g.options.delimiter
               || g.collections.table_columns (i).column_name
               || ' = p_'
               || g.collections.table_columns (i).column_name_28;
         END IF;

         /* a column list without pk for setting parameter to row columns:
         #SET_ROWTYPE_COL_TO_PARAM_WO_PK#
         e.g.
         p_test_number   := g_row_search_by_pk.test_number;
         p_test_varchar2 := g_row_search_by_pk.test_varchar2;
         , ... */
         IF (g.collections.table_columns (i).column_name <>
                g.substitutions.table_pk)
         THEN
            g.substitutions.set_rowtype_col_to_param_wo_pk :=
                  g.substitutions.set_rowtype_col_to_param_wo_pk
               || 'p_'
               || g.collections.table_columns (i).column_name_28
               || ' := g_row_search_by_pk.'
               || g.collections.table_columns (i).column_name
               || '; ';
         END IF;

         /* a block of code who compares new and old column values (without PK column) and counts the number
         of differences:
         #COLUMN_COMPARE_LIST_WO_PK#
         e.g.:
         IF COALESCE( v_existing_row.test_number, -9999.9999 ) <>
         COALESCE( p_test_number, -9999.9999 ) THEN
         v_count := v_count + 1;
         END IF;
         IF DBMS_LOB.compare( COALESCE( v_existing_row.test_clob, TO_CLOB( '$$$$' ) )
         , COALESCE( p_test_clob, TO_CLOB( '$$$$' ) ) ) <> 0 THEN
         v_count := v_count + 1;
         END IF;
         ... */
         IF (g.collections.table_columns (i).column_name <>
                g.substitutions.table_pk)
         THEN
            g.substitutions.column_compare_list_wo_pk :=
                  g.substitutions.column_compare_list_wo_pk
               || 'OR '
               || util_get_attribute_compare (
                     p_data_type           => g.collections.table_columns (i).data_type,
                     p_first_attribute     =>    'v_existing_row.'
                                              || g.collections.table_columns (i).column_name,
                     p_second_attribute    =>    'p_'
                                              || g.collections.table_columns (
                                                    i).column_name_28,
                     p_compare_operation   => '<>')
               || CHR (10);
         END IF;
      END LOOP;

      --------------------------------------------------------------------------
      -- cut off the first and/or last delimiter
      --------------------------------------------------------------------------
      g.substitutions.set_param_to_column_wo_pk :=
         LTRIM (g.substitutions.set_param_to_column_wo_pk,
                g.options.delimiter);
      g.substitutions.column_list_w_pk :=
         LTRIM (g.substitutions.column_list_w_pk, g.options.delimiter);
      g.substitutions.map_new_to_param_w_pk :=
         LTRIM (g.substitutions.map_new_to_param_w_pk, g.options.delimiter);
      g.substitutions.map_param_to_param_w_pk :=
         LTRIM (g.substitutions.map_param_to_param_w_pk, g.options.delimiter);
      g.substitutions.map_rowtype_col_to_param_w_pk :=
         LTRIM (g.substitutions.map_rowtype_col_to_param_w_pk,
                g.options.delimiter);
      g.substitutions.param_definition_w_pk :=
         LTRIM (g.substitutions.param_definition_w_pk, g.options.delimiter);
      g.substitutions.param_io_definition_w_pk :=
         LTRIM (g.substitutions.param_io_definition_w_pk,
                g.options.delimiter);
      g.substitutions.param_list_wo_pk :=
         LTRIM (g.substitutions.param_list_wo_pk, g.options.delimiter);
      --
      g.substitutions.column_compare_list_wo_pk :=
         LTRIM (g.substitutions.column_compare_list_wo_pk, 'OR ');
      g.substitutions.column_compare_list_wo_pk :=
         RTRIM (g.substitutions.column_compare_list_wo_pk, CHR (10));
   END do_initialize;

   --------------------------------------------------------------------------------
   PROCEDURE do_finalize
   IS
   BEGIN
      --> finalize CLOB varchar caches
      util_clob_append (
         p_clob                 => g.code.api_spec,
         p_clob_varchar_cache   => g.code.api_spec_varchar_cache,
         p_varchar_to_append    => NULL,
         p_final_call           => TRUE);
      util_clob_append (
         p_clob                 => g.code.api_body,
         p_clob_varchar_cache   => g.code.api_body_varchar_cache,
         p_varchar_to_append    => NULL,
         p_final_call           => TRUE);
   END do_finalize;

   --------------------------------------------------------------------------------
   PROCEDURE do_compile
   IS
      PROCEDURE print_header (p_scope VARCHAR2)
      IS
      BEGIN
         DBMS_OUTPUT.put_line (
            '--==============================================================================');
         DBMS_OUTPUT.put_line (
               '-- CURRENT '
            || p_scope
            || ' CODE: '
            || TO_CHAR (SYSDATE, 'yyyy-mm-dd hh24:mi:ss'));
         DBMS_OUTPUT.put_line (
            '--==============================================================================');
      END;

      PROCEDURE print_footer_and_raise_error (p_scope VARCHAR2)
      IS
      BEGIN
         DBMS_OUTPUT.put_line (
            '--==============================================================================');
         DBMS_OUTPUT.put_line (
               '-- ERRROR while compiling '
            || p_scope
            || ': Please check the created code above.');
         DBMS_OUTPUT.put_line (
            '--==============================================================================');
         raise_application_error (
            -20001,
               'ERRROR while compiling '
            || p_scope
            || ': Please consult DBMS Output for more details.');
      END;
   BEGIN
      --> compile package spec
      BEGIN
         util_execute_sql (g.code.api_spec);
      EXCEPTION
         WHEN OTHERS
         THEN
            print_header ('SPEC');
            DBMS_OUTPUT.put_line (g.code.api_spec);
            print_footer_and_raise_error ('SPEC');
      END;

      --> compile package body
      BEGIN
         util_execute_sql (g.code.api_body);
      EXCEPTION
         WHEN OTHERS
         THEN
            print_header ('BODY');
            DBMS_OUTPUT.put_line (g.code.api_body);
            print_footer_and_raise_error ('BODY');
      END;

      --> compile DML view
      BEGIN
         util_execute_sql (g.code.dml_view);
      EXCEPTION
         WHEN OTHERS
         THEN
            print_header ('DML VIEW');
            DBMS_OUTPUT.put_line (g.code.dml_view);
            print_footer_and_raise_error ('DML VIEW');
      END;

      --> compile DML view trigger
      BEGIN
         util_execute_sql (g.code.dml_view_trigger);
      EXCEPTION
         WHEN OTHERS
         THEN
            print_header ('DML VIEW TRIGGER');
            DBMS_OUTPUT.put_line (g.code.dml_view_trigger);
            print_footer_and_raise_error ('DML VIEW TRIGGER');
      END;
   END do_compile;

   --------------------------------------------------------------------------------
   PROCEDURE generate_table_api (
      p_table_name                   IN user_tables.table_name%TYPE,
      p_sequence_name                IN user_sequences.sequence_name%TYPE DEFAULT NULL,
      p_enable_generic_logging       IN BOOLEAN DEFAULT FALSE,
      p_enable_deletion_of_records   IN BOOLEAN DEFAULT FALSE,
      p_col_prefix_in_method_names   IN BOOLEAN DEFAULT FALSE)
   IS
   BEGIN
      --> clear global package variable
      g := NULL;
      --> fill global package variable as the base for the generated code
      g.substitutions.table_name := LOWER (p_table_name);
      g.substitutions.sequence_name :=
         COALESCE (LOWER (p_sequence_name),
                   g.substitutions.table_name || '_seq');
      g.options.enable_generic_logging := p_enable_generic_logging;
      g.options.enable_deletion_of_records := p_enable_deletion_of_records;
      g.options.col_prefix_in_method_names := p_col_prefix_in_method_names;
      --> initialise other global package variables, collections, cursors ...
      do_initialize;
      --> generate code for API
      gen_header;
      gen_api_sequence;
      gen_row_exists_fnc;
      gen_create_row_fnc;
      gen_create_row_prc;
      gen_create_rowtype_prc;
      gen_update_row_fnc;
      gen_update_row_prc;
      gen_update_rowtype_prc;
      gen_createorupdate_row_fnc;
      gen_createorupdate_row_prc;
      gen_createorupdate_rowtype_prc;
      gen_delete_row_prc;
      gen_get_pk_by_unique_cols_fnc;
      gen_get_row_by_pk_fnc;
      gen_get_row_by_pk_and_fill_prc;
      gen_getter_functions;
      gen_setter_procedures;
      gen_footer;
      --> FIXME: remove, should be checked, if existing in initialize procedure
      --> generate API dependend objects
      --gen_table_sequence;
      gen_dml_view;
      gen_dml_view_trigger;
      --> finally generate API
      do_finalize;
      do_compile;
   END generate_table_api;
--------------------------------------------------------------------------------
END table_api;