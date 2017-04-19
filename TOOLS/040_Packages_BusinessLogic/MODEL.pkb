CREATE OR REPLACE PACKAGE BODY model
/**-----------------------------------------------------------------------------
  %description:  Code generator for DML operations for tables.
                 Standard APIs are provided and if required generic logging or a
                 technical versioning can be activated. DML operations are
                 optimized in regard to performance, because most of them are
                 working based on the table primary key. An addition to that
                 UPDATE is optimized and will only be executed when minimum one
                 column value changed.
  %requirements: Table must have a single column primary key
                 Table must have one column in addition to the primary key
                 Column datatypes supported:
                 - VARCHAR2
                 - CHAR
                 - Number
                 - Date
                 - Timestamp
                 - BLOB
                 - CLOB
                 - XMLType

  %author:       André Borngräber
------------------------------------------------------------------------------*/



IS
   co_create_change_log_spec        CONSTANT CLOB
      := q'[PROCEDURE create_change_log_entry( p_table      VARCHAR2
                                   , p_column     VARCHAR2
                                   , p_pk_id      NUMBER
                                   , p_old_value  VARCHAR2
                                   , p_new_value  VARCHAR2 );]' ;

   co_create_change_log_body        CONSTANT CLOB
      := q'[PROCEDURE create_change_log_entry( p_table      VARCHAR2
                                   , p_column     VARCHAR2
                                   , p_pk_id      NUMBER
                                   , p_old_value  VARCHAR2
                                   , p_new_value  VARCHAR2 )
  IS
  BEGIN
     INSERT INTO generic_change_log( gcl_id
                                   , gcl_table
                                   , gcl_column
                                   , gcl_pk_id
                                   , gcl_old_value
                                   , gcl_new_value
                                   , gcl_user )
     VALUES ( generic_change_log_seq.NEXTVAL
            , UPPER(p_table)
            , UPPER(p_column)
            , p_pk_id
            , p_old_value
            , p_new_value
            , UPPER(COALESCE(v('APP_USER'), SYS_CONTEXT('USERENV', 'OS_USER'))) );
  END;]' ;

   co_create_change_log             CONSTANT CLOB
      := q'[create_change_log_entry( p_table       => '#TABLE_NAME#'
                           , p_column      => 'record created'
                           , p_pk_id       => v_pk
                           , p_old_value   => NULL
                           , p_new_value   => NULL );]' ;

   co_row_exists_func_spec          CONSTANT CLOB
      := q'[FUNCTION row_exists(p_#PK_COLUMN# IN #TABLE_NAME#.#PK_COLUMN#%TYPE)
    RETURN BOOLEAN;]' ;

   co_row_exists_func_body          CONSTANT CLOB
      := q'[FUNCTION row_exists(p_#PK_COLUMN# IN #TABLE_NAME#.#PK_COLUMN#%TYPE)
    RETURN BOOLEAN
    IS
    BEGIN
      g_row_search_by_pk := get_row_by_pk( p_#PK_COLUMN# => p_#PK_COLUMN# );
      RETURN g_row_search_by_pk.#PK_COLUMN# IS NOT NULL;
    END;]' ;

   co_create_func_spec              CONSTANT CLOB
      := q'[FUNCTION create_row(#IN_PARAMETER_LIST#)
    RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE;]' ;

   co_create_func_body              CONSTANT CLOB
      := q'[FUNCTION create_row(#IN_PARAMETER_LIST#)
    RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE 
  IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
  BEGIN
    IF (p_#PK_COLUMN# IS NULL) THEN
      v_pk := #TABLE_NAME#_seq.nextval;
    ELSE
      v_pk := p_#PK_COLUMN#;
    END IF;
    
    INSERT INTO #TABLE_NAME# (#ORDERED_COLUMN_LIST#)
    VALUES (v_pk, #ORDERED_PARAMETER_LIST#);

    #CREATE_CHANGE_LOG_ENTRY#

    RETURN v_pk;
  END create_row;]' ;

   co_create_proc_spec              CONSTANT CLOB
      := q'[PROCEDURE create_row(#IN_PARAMETER_LIST#);]' ;

   co_create_proc_body              CONSTANT CLOB
      := q'[PROCEDURE create_row(#IN_PARAMETER_LIST#)
  IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;

  BEGIN
    v_pk := create_row(#CALL_PARAMETER_LIST#);
  END create_row;]' ;

   co_create_rowtype_proc_spec      CONSTANT CLOB
      := q'[PROCEDURE create_row(p_row IN #TABLE_NAME#%ROWTYPE);]' ;

   co_create_rowtype_proc_body      CONSTANT CLOB
      := q'[PROCEDURE create_row(p_row IN #TABLE_NAME#%ROWTYPE)
  IS
  BEGIN
    create_row(#CALL_PARAMETER_LIST#);
  END create_row;]' ;

   co_update_func_spec              CONSTANT CLOB
      := q'[FUNCTION update_row(#IN_PARAMETER_LIST#)
    RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE;]' ;

   co_update_func_body              CONSTANT CLOB
      := q'[FUNCTION update_row(#IN_PARAMETER_LIST#)
    RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE
  IS
    v_pk           #TABLE_NAME#.#PK_COLUMN#%TYPE;
    v_existing_row #TABLE_NAME#%ROWTYPE;
    v_count        PLS_INTEGER := 0;
  BEGIN
    v_existing_row := get_row_by_pk(p_#PK_COLUMN# => p_#PK_COLUMN#);

    -- wurde existierende Zeile gefunden
    IF (v_existing_row.#PK_COLUMN# IS NOT NULL) THEN

      -- handelt es sich um echte UPDATES, d.h. weicht mind. ein Spaltenwert ab
        #COLUMN_COMPARE_LIST#
        IF v_count > 0 THEN
          UPDATE #TABLE_NAME#
          SET #SET_LIST#
          WHERE #PK_COLUMN# = v_existing_row.#PK_COLUMN#;
        END IF;    

      -- Rückgabeparameter füllen
      v_pk := v_existing_row.#PK_COLUMN#;
    END IF;

  RETURN v_pk;
  END update_row;]' ;

   co_update_proc_spec              CONSTANT CLOB
      := q'[PROCEDURE update_row(#IN_PARAMETER_LIST#);]' ;

   co_update_proc_body              CONSTANT CLOB
      := q'[PROCEDURE update_row(#IN_PARAMETER_LIST#)
  IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
  BEGIN
    v_pk := update_row(#CALL_PARAMETER_LIST#);
  END update_row;]' ;

   co_update_rowtype_proc_spec      CONSTANT CLOB
      := q'[PROCEDURE update_row(p_row IN #TABLE_NAME#%ROWTYPE);]' ;

   co_update_rowtype_proc_body      CONSTANT CLOB
      := q'[PROCEDURE update_row(p_row IN #TABLE_NAME#%ROWTYPE)
  IS
  BEGIN
    update_row(#CALL_PARAMETER_LIST_WITH_PK#);
  END update_row;]' ;

   co_create_or_update_func_spec    CONSTANT CLOB
      := q'[FUNCTION create_or_update_row(#IN_PARAMETER_LIST#)
    RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE;]' ;

   co_create_or_update_func_body    CONSTANT CLOB
      := q'[FUNCTION create_or_update_row(#IN_PARAMETER_LIST#)
    RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE
  IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
    v_existing_row #TABLE_NAME#%ROWTYPE;
  BEGIN
    IF (p_#PK_COLUMN# IS NULL) THEN
      v_pk :=  create_row(#CALL_PARAMETER_LIST_WITH_PK#);
    ELSE
      -- find out record
      v_existing_row := get_row_by_pk(p_#PK_COLUMN# => p_#PK_COLUMN#);
           
      -- check if record exists
      IF (v_existing_row.#PK_COLUMN# IS NOT NULL) THEN
        -- record exists
        v_pk := update_row(#CALL_PARAMETER_LIST_WITH_PK#);
      ELSE
        -- record does not exist
        v_pk :=  create_row(#CALL_PARAMETER_LIST_WITH_PK#);
      END IF;
    END IF;

    RETURN v_pk;
  END create_or_update_row;]' ;

   co_create_or_update_proc_spec    CONSTANT CLOB
      := q'[PROCEDURE create_or_update_row(#IN_PARAMETER_LIST#);]' ;

   co_create_or_update_proc_body    CONSTANT CLOB
      := q'[PROCEDURE create_or_update_row(#IN_PARAMETER_LIST#)
  IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
  BEGIN
    v_pk := create_or_update_row(#CALL_PARAMETER_LIST_WITH_PK#);
  END create_or_update_row;]' ;

   co_create_or_update_r_proc_spe   CONSTANT CLOB
      := q'[PROCEDURE create_or_update_row(p_row IN #TABLE_NAME#%ROWTYPE);]' ;

   co_create_or_update_r_proc_bod   CONSTANT CLOB
      := q'[PROCEDURE create_or_update_row(p_row IN #TABLE_NAME#%ROWTYPE)
  IS
  BEGIN
    create_or_update_row(#CALL_PARAMETER_LIST_WITH_PK#);
  END create_or_update_row;]' ;

   co_delete_proc_spec              CONSTANT CLOB
      := q'[PROCEDURE delete_row(p_#PK_COLUMN# IN #TABLE_NAME#.#PK_COLUMN#%TYPE);]' ;

   co_delete_proc_body              CONSTANT CLOB
      := q'[PROCEDURE delete_row(p_#PK_COLUMN# IN #TABLE_NAME#.#PK_COLUMN#%TYPE)
  IS
  BEGIN
    DELETE FROM #TABLE_NAME# WHERE #PK_COLUMN# = p_#PK_COLUMN#;
    
    #CREATE_CHANGE_LOG_ENTRY#
    
  END delete_row;]' ;

   co_delete_proc_change_log        CONSTANT CLOB
      := q'[create_change_log_entry( p_table       => '#TABLE_NAME#'
                           , p_column      => 'record deleted'
                           , p_pk_id       => p_#PK_COLUMN#
                           , p_old_value   => NULL
                           , p_new_value   => NULL );]' ;

   co_get_by_pk_func_spec           CONSTANT CLOB
      := q'[FUNCTION get_row_by_pk(p_#PK_COLUMN# IN #TABLE_NAME#.#PK_COLUMN#%TYPE)
    RETURN #TABLE_NAME#%ROWTYPE;]' ;

   co_get_by_pk_func_body           CONSTANT CLOB
      := q'[FUNCTION get_row_by_pk(p_#PK_COLUMN# IN #TABLE_NAME#.#PK_COLUMN#%TYPE)
    RETURN #TABLE_NAME#%ROWTYPE
  IS
  BEGIN
    g_row_search_by_pk := null;
    OPEN g_cur_search_by_pk(p_#PK_COLUMN#);
    FETCH g_cur_search_by_pk INTO g_row_search_by_pk;
    CLOSE g_cur_search_by_pk;

    RETURN g_row_search_by_pk;
  END get_row_by_pk;]' ;

   co_get_by_pk_and_fill_prc_spc    CONSTANT CLOB
      := q'[PROCEDURE get_row_by_pk_and_fill(
    p_#PK_COLUMN# IN #TABLE_NAME#.#PK_COLUMN#%TYPE
  , #OUT_PARAMETER_LIST#);]' ;

   co_get_by_pk_and_fill_prc_bdy    CONSTANT CLOB
      := q'[PROCEDURE get_row_by_pk_and_fill(
      p_#PK_COLUMN# IN #TABLE_NAME#.#PK_COLUMN#%TYPE
    , #OUT_PARAMETER_LIST#)
  IS
  BEGIN
    OPEN g_cur_search_by_pk(p_#PK_COLUMN#);
    FETCH g_cur_search_by_pk INTO g_row_search_by_pk;
 
    IF (g_cur_search_by_pk%FOUND) THEN
      #FETCH_PARAMETER_LIST#
    END IF;

    CLOSE g_cur_search_by_pk;
  END get_row_by_pk_and_fill;]' ;

   co_get_column_by_id_spec         CONSTANT CLOB
      := q'[
  FUNCTION get_#COLUMN_NAME_26#(p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN_ORIGINAL#%TYPE)
    RETURN #TABLE_NAME#.#COLUMN_NAME_ORIGINAL#%TYPE;
]'   ;

   co_get_column_by_id_body         CONSTANT CLOB
      := q'[
  FUNCTION get_#COLUMN_NAME_26#(p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN_ORIGINAL#%TYPE)
    RETURN #TABLE_NAME#.#COLUMN_NAME_ORIGINAL#%TYPE 
  IS
  BEGIN
    g_row_search_by_pk := get_row_by_pk(p_#PK_COLUMN_28# => p_#PK_COLUMN_28#);
    return g_row_search_by_pk.#COLUMN_NAME_ORIGINAL#;
  END get_#COLUMN_NAME_26#;
]'   ;

   co_set_column_by_id_spec         CONSTANT CLOB
      := q'[
  PROCEDURE set_#COLUMN_NAME_26#(p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN_ORIGINAL#%TYPE,
                              p_#COLUMN_NAME_28# IN #TABLE_NAME#.#COLUMN_NAME_ORIGINAL#%TYPE);
]'   ;

   co_set_column_by_id_body         CONSTANT CLOB
      := q'[
  PROCEDURE set_#COLUMN_NAME_26#(p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN_ORIGINAL#%TYPE,
                              p_#COLUMN_NAME_28# IN #TABLE_NAME#.#COLUMN_NAME_ORIGINAL#%TYPE)
  IS
    v_existing_row #TABLE_NAME#%ROWTYPE;
  BEGIN
    v_existing_row := get_row_by_pk(p_#PK_COLUMN_28# => p_#PK_COLUMN_28#);

    -- wurde existierende Zeile gefunden
    IF (v_existing_row.#PK_COLUMN_ORIGINAL# IS NOT NULL) THEN
      IF #COLUMN_COMPARE# THEN -- update only if value differs
        #CREATE_CHANGE_LOG_ENTRY#
        UPDATE #TABLE_NAME#
           SET #COLUMN_NAME_ORIGINAL# = p_#COLUMN_NAME_28#
         WHERE #PK_COLUMN_ORIGINAL# = p_#PK_COLUMN_28#;
      END IF;
    END IF;
  END set_#COLUMN_NAME_26#;
]'   ;

   co_get_pk_by_unique_cols_spec    CONSTANT CLOB := q'[
  FUNCTION get_pk_by_unique_cols(#UNIQUE_COLS_PARAM_LIST#)
    return #TABLE_NAME#.#PK_COLUMN#%TYPE;
]';

   co_get_pk_by_unique_cols_body    CONSTANT CLOB := q'[
  FUNCTION get_pk_by_unique_cols(#UNIQUE_COLS_PARAM_LIST#)
    return #TABLE_NAME#.#PK_COLUMN#%TYPE
  IS
    CURSOR v_cur_existing_row IS
    SELECT * from #TABLE_NAME#
     WHERE #UNIQUE_COLS_COMPARE_LIST#;
     
    v_existing_row v_cur_existing_row%ROWTYPE;
  BEGIN
    OPEN v_cur_existing_row;
    FETCH v_cur_existing_row INTO v_existing_row;
    CLOSE v_cur_existing_row;
    
    RETURN v_existing_row.#PK_COLUMN#;
  END get_pk_by_unique_cols;
]';

   co_generate_install_script       CONSTANT CLOB := q'[
@#TABLE_ABBREVIATION#_API.spc;
@#TABLE_ABBREVIATION#_API_BODY.bdy;
]';

   co_generate_synonym              CONSTANT CLOB := q'[
CREATE OR REPLACE SYNONYM #TABLE_ABBREVIATION# FOR #TABLE_NAME#;
]';

   co_generate_sequence             CONSTANT CLOB := q'[
BEGIN
   FOR i IN ( SELECT '#TABLE_NAME#_SEQ' AS sequence_name FROM DUAL
              MINUS
              SELECT sequence_name
                FROM user_sequences
               WHERE sequence_name = '#TABLE_NAME#_SEQ' ) LOOP
      EXECUTE IMMEDIATE
            'CREATE SEQUENCE '
         || i.sequence_name
         || ' START WITH 1 '
         || ' MAXVALUE 999999999999999999999999999 '
         || ' MINVALUE 1 '
         || ' NOCYCLE '
         || ' NOCACHE '
         || ' NOORDER';
   END LOOP;
END;
]';

   co_generate_api_spec             CONSTANT CLOB
      := q'[
CREATE OR REPLACE PACKAGE #TABLE_NAME#_API IS
/* This package #TABLE_NAME#_API is the table API for the 
   table #TABLE_NAME# and provides DML functionality that can be easily 
   called from APEX. Target of the table API is to encapsulate the complexity 
   of table DML source code including logging, history, performance 
   optimisation, ... from APEX and to reduce the source code.
   %author  #AUTHOR# 
   %created #CREATED_AT#
 */
  CURSOR g_cur_search_by_pk(p_#PK_COLUMN# IN #TABLE_NAME#.#PK_COLUMN#%TYPE)
  IS
  SELECT * FROM #TABLE_NAME# WHERE #PK_COLUMN# = p_#PK_COLUMN#;

  g_row_search_by_pk #TABLE_NAME#%ROWTYPE;
  
  #CREATE_CHANGE_LOG_ENTRY_SPEC#

  #ROW_EXISTS_FUNCTION#
  
  #CREATE_FUNCTION#

  #CREATE_PROCEDURE#
  
  #CREATE_ROWTYPE_PROCEDURE#

  #UPDATE_FUNCTION#

  #UPDATE_PROCEDURE#
  
  #UPDATE_ROWTYPE_PROCEDURE#

  #CREATE_OR_UPDATE_FUNCTION#

  #CREATE_OR_UPDATE_PROCEDURE#
  
  #CREATE_OR_UPDATE_ROWTYPE_PROCEDURE#

  #DELETE_PROCEDURE_SPEC#

  #READ_BY_PK_FUNCTION#

  #READ_BY_PK_AND_FILL_PROCEDURE#

  #GET_COLUMN_FUNCTIONS#

  #SET_COLUMN_PROCEDURES#
  
  #GET_PK_BY_UNIQUE_COLS_FUNCTION#
  
END #TABLE_NAME#_API;
]'   ;

   co_generate_api_body             CONSTANT CLOB := q'[
CREATE OR REPLACE PACKAGE BODY #TABLE_NAME#_API
IS
  #CREATE_CHANGE_LOG_ENTRY_BODY#

  #ROW_EXISTS_FUNCTION#
  
  #CREATE_FUNCTION#

  #CREATE_PROCEDURE#
  
  #CREATE_ROWTYPE_PROCEDURE#

  #UPDATE_FUNCTION#

  #UPDATE_PROCEDURE#
  
  #UPDATE_ROWTYPE_PROCEDURE#

  #CREATE_OR_UPDATE_FUNCTION#

  #CREATE_OR_UPDATE_PROCEDURE#
  
  #CREATE_OR_UPDATE_ROWTYPE_PROCEDURE#

  #DELETE_PROCEDURE_BODY#

  #READ_BY_PK_FUNCTION#

  #READ_BY_PK_AND_FILL_PROCEDURE#

  #GET_COLUMN_FUNCTIONS#
  
  #SET_COLUMN_PROCEDURES#
  
  #GET_PK_BY_UNIQUE_COLS_FUNCTION#

END #TABLE_NAME#_API;
]';

   PROCEDURE PRINT (p_text VARCHAR2)
   IS
   BEGIN
      DBMS_OUTPUT.put_line (p_text);
   END;

   PROCEDURE log_error (p_text VARCHAR2)
   IS
   BEGIN
      DBMS_OUTPUT.put_line ('ERROR: ' || p_text);
      raise_application_error (-20001, p_text);
   END;

   PROCEDURE log_warning (p_text VARCHAR2)
   IS
   BEGIN
      DBMS_OUTPUT.put_line ('WARNING: ' || p_text);
   END;

   PROCEDURE execute_sql (p_sql IN CLOB)
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

   FUNCTION get_table_key (p_table_name   IN VARCHAR2,
                           p_key_type     IN VARCHAR2 DEFAULT 'P',
                           p_delimiter       VARCHAR2 DEFAULT ', ')
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
   END get_table_key;

   FUNCTION get_sorted_table_cols (p_table_name   IN VARCHAR2,
                                   p_include_pk   IN VARCHAR2 DEFAULT 'N')
      RETURN VARCHAR2
   IS
      v_columns   VARCHAR2 (30000 CHAR);
      v_pk        user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      -- PK berücksichtigen oder eben nicht, abhängig vom Parameter
                      --> FIXME: PK kann mehrspaltig sein, v_pk muß umgebaut werden
                      AND (   p_include_pk = 'N' AND column_name <> v_pk
                           OR p_include_pk = 'Y')
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         v_columns := v_columns || '          , ' || i.column_name || CHR (10);
      END LOOP;

      RETURN RTRIM (LTRIM (v_columns, '          , '), CHR (10));
   END;

   FUNCTION get_call_param_list (p_table_name   IN VARCHAR2,
                                 p_include_pk   IN VARCHAR2 DEFAULT 'N')
      RETURN VARCHAR2
   IS
      v_columns   VARCHAR2 (32767 CHAR);
      v_pk        user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      -- PK berücksichtigen oder eben nicht, abhängig vom Parameter
                      AND (   p_include_pk = 'N' AND column_name <> v_pk
                           OR p_include_pk = 'Y')
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         v_columns :=
               v_columns
            || '          , p_'
            || SUBSTR (i.column_name, 1, 28)
            || ' => p_'
            || SUBSTR (i.column_name, 1, 28)
            || CHR (10);
      END LOOP;

      RETURN RTRIM (LTRIM (v_columns, '          , '), CHR (10));
   END get_call_param_list;

   FUNCTION get_value_param_list (p_table_name   IN VARCHAR2,
                                  p_include_pk   IN VARCHAR2 DEFAULT 'N')
      RETURN VARCHAR2
   IS
      v_columns   VARCHAR2 (32767 CHAR);
      v_pk        user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      -- PK berücksichtigen oder eben nicht, abhängig vom Parameter
                      AND (   p_include_pk = 'N' AND column_name <> v_pk
                           OR p_include_pk = 'Y')
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         v_columns :=
               v_columns
            || '          , p_'
            || SUBSTR (i.column_name, 1, 28)
            || CHR (10);
      END LOOP;

      RETURN RTRIM (LTRIM (v_columns, '          , '), CHR (10));
   END get_value_param_list;

   FUNCTION get_trigger_new_list (p_table_name   IN VARCHAR2,
                                  p_include_pk   IN VARCHAR2 DEFAULT 'Y')
      RETURN VARCHAR2
   IS
      v_columns   VARCHAR2 (32767 CHAR);
      v_pk        user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      -- PK berücksichtigen oder eben nicht, abhängig vom Parameter
                      AND (   p_include_pk = 'N' AND column_name <> v_pk
                           OR p_include_pk = 'Y')
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         v_columns :=
               v_columns
            || '          , p_'
            || SUBSTR (i.column_name, 1, 28)
            || ' => :new.'
            || i.column_name
            || CHR (10);
      END LOOP;

      RETURN RTRIM (LTRIM (v_columns, '          , '), CHR (10));
   END get_trigger_new_list;

   FUNCTION get_in_param_list (p_table_name   IN VARCHAR2,
                               p_include_pk   IN VARCHAR2 DEFAULT 'N')
      RETURN VARCHAR2
   IS
      v_columns   VARCHAR2 (32767 CHAR);
      v_pk        user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      -- PK berücksichtigen oder eben nicht, abhängig vom Parameter
                      AND (   p_include_pk = 'N' AND column_name <> v_pk
                           OR p_include_pk = 'Y')
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         v_columns :=
               v_columns
            || '          , p_'
            || SUBSTR (i.column_name, 1, 28)
            || ' IN '
            || p_table_name
            || '.'
            || i.column_name
            || '%TYPE'
            || CHR (10);
      END LOOP;

      RETURN RTRIM (LTRIM (v_columns, '          , '), CHR (10));
   END get_in_param_list;

   FUNCTION get_rowtype_param_list (p_table_name   IN VARCHAR2,
                                    p_include_pk   IN VARCHAR2 DEFAULT 'N')
      RETURN VARCHAR2
   IS
      v_columns   VARCHAR2 (32767 CHAR);
      v_pk        user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      -- PK berücksichtigen oder eben nicht, abhängig vom Parameter
                      AND (   p_include_pk = 'N' AND column_name <> v_pk
                           OR p_include_pk = 'Y')
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         v_columns :=
               v_columns
            || '          , p_'
            || SUBSTR (i.column_name, 1, 28)
            || ' => p_row.'
            || i.column_name
            || CHR (10);
      END LOOP;

      RETURN RTRIM (LTRIM (v_columns, '          , '), CHR (10));
   END get_rowtype_param_list;

   FUNCTION get_out_param_list (p_table_name   IN VARCHAR2,
                                p_include_pk   IN VARCHAR2 DEFAULT 'N')
      RETURN VARCHAR2
   IS
      v_columns   VARCHAR2 (32767 CHAR);
      v_pk        user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      -- PK berücksichtigen oder eben nicht, abhängig vom Parameter
                      AND (   p_include_pk = 'N' AND column_name <> v_pk
                           OR p_include_pk = 'Y')
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         v_columns :=
               v_columns
            || '          , p_'
            || SUBSTR (i.column_name, 1, 28)
            || ' OUT '
            || p_table_name
            || '.'
            || i.column_name
            || '%TYPE'
            || CHR (10);
      END LOOP;

      RETURN RTRIM (LTRIM (v_columns, '          , '), CHR (10));
   END get_out_param_list;

   FUNCTION get_search_param_list (p_table_name   IN VARCHAR2,
                                   p_include_pk   IN VARCHAR2 DEFAULT 'N')
      RETURN VARCHAR2
   IS
      v_columns   VARCHAR2 (32767 CHAR);
      v_pk        user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      -- PK berücksichtigen oder eben nicht, abhängig vom Parameter
                      AND (   p_include_pk = 'N' AND column_name <> v_pk
                           OR p_include_pk = 'Y')
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         v_columns :=
               v_columns
            || '          and '
            || CASE
                  WHEN i.data_type IN ('BLOB', 'CLOB')
                  THEN
                        'DBMS_LOB.compare( COALESCE('
                     || LOWER (i.column_name)
                     || ', '
                     || CASE
                           WHEN i.data_type = 'BLOB'
                           THEN
                              q'[to_blob( UTL_RAW.cast_to_raw( '$$$$' ) )]'
                           WHEN i.data_type = 'CLOB'
                           THEN
                              q'[to_clob( '$$$$' )]'
                           ELSE
                              q'['$$$$']'
                        END
                     || '), COALESCE(p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || ', '
                     || CASE
                           WHEN i.data_type = 'BLOB'
                           THEN
                              q'[to_blob( UTL_RAW.cast_to_raw( '$$$$' ) )]'
                           WHEN i.data_type = 'CLOB'
                           THEN
                              q'[to_clob( '$$$$' )]'
                           ELSE
                              q'['$$$$']'
                        END
                     || ')) = 0'
                  WHEN i.data_type = 'XMLTYPE'
                  THEN
                        'DBMS_LOB.compare( COALESCE( case when '
                     || LOWER (i.column_name)
                     || ' is null then null else '
                     || LOWER (i.column_name)
                     || q'[.getStringVal() end, to_clob( '$$$$' )]'
                     || '), COALESCE(case when p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || ' is null then null else p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || q'[.getStringVal() end, to_clob( '$$$$' )]'
                     || ')) = 0'
                  ELSE
                        'COALESCE('
                     || LOWER (i.column_name)
                     || ', '
                     || CASE
                           WHEN i.data_type = 'NUMBER'
                           THEN
                              '-9999.9999'
                           WHEN i.data_type = 'DATE'
                           THEN
                              q'[to_date('01.01.1900','dd.mm.yyyy')]'
                           WHEN i.data_type LIKE 'TIMESTAMP%'
                           THEN
                              q'[to_timestamp('01.01.1900','dd.mm.yyyy')]'
                           ELSE
                              q'['$$$$']'
                        END
                     || ')'
                     || ' = COALESCE(p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || ', '
                     || CASE
                           WHEN i.data_type = 'NUMBER'
                           THEN
                              '-9999.9999'
                           WHEN i.data_type = 'DATE'
                           THEN
                              q'[to_date('01.01.1900','dd.mm.yyyy')]'
                           WHEN i.data_type LIKE 'TIMESTAMP%'
                           THEN
                              q'[to_timestamp('01.01.1900','dd.mm.yyyy')]'
                           ELSE
                              q'['$$$$']'
                        END
                     || ')'
               END
            || CHR (10);
      END LOOP;

      RETURN RTRIM (LTRIM (v_columns, '          and '), CHR (10));
   END get_search_param_list;

   FUNCTION get_read_param_list (
      p_table_name           IN VARCHAR2,
      p_table_abbreviation   IN VARCHAR2,
      p_include_pk           IN VARCHAR2 DEFAULT 'N')
      RETURN VARCHAR2
   IS
      v_columns   VARCHAR2 (32767 CHAR);
      v_pk        user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      -- PK berücksichtigen oder eben nicht, abhängig vom Parameter
                      AND (   p_include_pk = 'N' AND column_name <> v_pk
                           OR p_include_pk = 'Y')
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         v_columns :=
               v_columns
            || '          p_'
            || SUBSTR (i.column_name, 1, 28)
            || ' := g_row_search_by_pk'
            || '.'
            || i.column_name
            || ';'
            || CHR (10);
      END LOOP;

      RETURN RTRIM (LTRIM (v_columns), CHR (10));
   END get_read_param_list;

   FUNCTION get_compare_param_list (
      p_table_name               IN VARCHAR2,
      p_include_pk               IN VARCHAR2 DEFAULT 'N',
      p_enable_generic_logging   IN BOOLEAN DEFAULT FALSE)
      RETURN VARCHAR2
   IS
      v_columns   VARCHAR2 (32767 CHAR);
      v_pk        user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      -- PK berücksichtigen oder eben nicht, abhängig vom Parameter
                      AND (   p_include_pk = 'N' AND column_name <> v_pk
                           OR p_include_pk = 'Y')
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         --      IF DBMS_LOB.compare( COALESCE( v_existing_row.ot_blob, to_blob( UTL_RAW.cast_to_raw( '$$$$' ) ) )
         --                              , COALESCE( p_ot_blob, to_blob( UTL_RAW.cast_to_raw( '$$$$' ) ) )
         --                              ) = 0

         --      IF DBMS_LOB.compare( COALESCE( v_existing_row.ot_clob, '$$$$' )
         --                              , COALESCE( p_ot_clob, '$$$$' )
         --                              ) = 0

         v_columns :=
               v_columns
            || '      IF '
            || CASE
                  WHEN i.data_type IN ('BLOB', 'CLOB')
                  THEN
                        'DBMS_LOB.compare( COALESCE( v_existing_row.'
                     || LOWER (i.column_name)
                     || ', '
                     || CASE
                           WHEN i.data_type = 'BLOB'
                           THEN
                              q'[to_blob( UTL_RAW.cast_to_raw( '$$$$' ) )]'
                           WHEN i.data_type = 'CLOB'
                           THEN
                              q'[to_clob( '$$$$' )]'
                           ELSE
                              q'['$$$$']'
                        END
                     || ')'
                     || CHR (10)
                     || '                           , COALESCE('
                     || ' p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || ', '
                     || CASE
                           WHEN i.data_type = 'BLOB'
                           THEN
                              q'[to_blob( UTL_RAW.cast_to_raw( '$$$$' ) )]'
                           WHEN i.data_type = 'CLOB'
                           THEN
                              q'[to_clob( '$$$$' )]'
                           ELSE
                              q'['$$$$']'
                        END
                     || ')'
                     || CHR (10)
                     || '                           ) <> 0'
                  WHEN i.data_type = 'XMLTYPE'
                  THEN
                        'DBMS_LOB.compare( COALESCE(case when v_existing_row.'
                     || LOWER (i.column_name)
                     || ' is null then null else v_existing_row.'
                     || LOWER (i.column_name)
                     || q'[.getStringVal() end, to_clob( '$$$$' )]'
                     || '), COALESCE(case when p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || ' is null then null else p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || q'[.getStringVal() end, to_clob( '$$$$' )]'
                     || ')) <> 0'
                  ELSE
                        'COALESCE( v_existing_row.'
                     || LOWER (i.column_name)
                     || ', '
                     || CASE
                           WHEN i.data_type = 'NUMBER'
                           THEN
                              '-9999.9999'
                           WHEN i.data_type = 'DATE'
                           THEN
                              q'[to_date('01.01.1900','dd.mm.yyyy')]'
                           WHEN i.data_type LIKE 'TIMESTAMP%'
                           THEN
                              q'[to_timestamp('01.01.1900','dd.mm.yyyy')]'
                           ELSE
                              q'['$$$$']'
                        END
                     || ') <> COALESCE( p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || ', '
                     || CASE
                           WHEN i.data_type = 'NUMBER'
                           THEN
                              '-9999.9999'
                           WHEN i.data_type = 'DATE'
                           THEN
                              q'[to_date('01.01.1900','dd.mm.yyyy')]'
                           WHEN i.data_type LIKE 'TIMESTAMP%'
                           THEN
                              q'[to_timestamp('01.01.1900','dd.mm.yyyy')]'
                           ELSE
                              q'['$$$$']'
                        END
                     || ' )'
               END
            || ' THEN'
            || CHR (10)
            || '        v_count := v_count + 1;'
            || CHR (10)
            || CASE
                  WHEN p_enable_generic_logging
                  THEN
                        '        create_change_log_entry( p_table       => '''
                     || LOWER (p_table_name)
                     || ''''
                     || CHR (10)
                     || '                               , p_column      => '''
                     || LOWER (i.column_name)
                     || ''''
                     || CHR (10)
                     || '                               , p_pk_id       => v_existing_row.'
                     || LOWER (v_pk)
                     || CHR (10)
                     || '                               , p_old_value   => '
                     || CASE
                           WHEN i.data_type IN ('NUMBER', 'FLOAT', 'INTEGER')
                           THEN
                                 ' to_char(v_existing_row.'
                              || LOWER (i.column_name)
                              || ')'
                           WHEN i.data_type = 'DATE'
                           THEN
                                 ' to_char(v_existing_row.'
                              || LOWER (i.column_name)
                              || q'[, 'yyyy.mm.dd hh24:mi:ss')]'
                           WHEN i.data_type LIKE 'TIMESTAMP%'
                           THEN
                                 ' to_char(v_existing_row.'
                              || LOWER (i.column_name)
                              || q'[, 'yyyy.mm.dd hh24:mi:ss.ffffff')]'
                           WHEN i.data_type = 'BLOB'
                           THEN
                              q'['Data type "BLOB" is not supported for generic logging']'
                           WHEN i.data_type = 'XMLTYPE'
                           THEN
                                 ' substr( case when v_existing_row.'
                              || LOWER (i.column_name)
                              || ' is null then null else v_existing_row.'
                              || LOWER (i.column_name)
                              || '.getStringVal() end,1,4000)'
                           ELSE
                                 ' substr(v_existing_row.'
                              || LOWER (i.column_name)
                              || ',1,4000)'
                        END
                     || CHR (10)
                     || '                               , p_new_value   => '
                     || CASE
                           WHEN i.data_type IN ('NUMBER', 'FLOAT', 'INTEGER')
                           THEN
                                 ' to_char(p_'
                              || SUBSTR (LOWER (i.column_name), 1, 28)
                              || ')'
                           WHEN i.data_type = 'DATE'
                           THEN
                                 ' to_char(p_'
                              || SUBSTR (LOWER (i.column_name), 1, 28)
                              || q'[, 'yyyy.mm.dd hh24:mi:ss')]'
                           WHEN i.data_type LIKE 'TIMESTAMP%'
                           THEN
                                 ' to_char(p_'
                              || SUBSTR (LOWER (i.column_name), 1, 28)
                              || q'[, 'yyyy.mm.dd hh24:mi:ss.ffffff')]'
                           WHEN i.data_type = 'BLOB'
                           THEN
                              q'['Data type "BLOB" is not supported for generic logging']'
                           WHEN i.data_type = 'XMLTYPE'
                           THEN
                                 ' substr(case when p_'
                              || SUBSTR (LOWER (i.column_name), 1, 28)
                              || ' is null then null else p_'
                              || SUBSTR (LOWER (i.column_name), 1, 28)
                              || '.getStringVal() end,1,4000)'
                           ELSE
                                 ' substr(p_'
                              || SUBSTR (LOWER (i.column_name), 1, 28)
                              || ',1,4000)'
                        END
                     || ' );'
                     || CHR (10)
               END
            || '      END IF;'
            || CHR (10);
      END LOOP;

      RETURN TRIM (RTRIM (v_columns, CHR (10)));
   END get_compare_param_list;

   FUNCTION get_create_change_log_list (p_table_name IN VARCHAR2)
      RETURN VARCHAR2
   IS
      v_columns   VARCHAR2 (32767 CHAR);
      v_pk        user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      AND column_name != v_pk
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         v_columns :=
               v_columns
            || '    create_change_log_entry( p_table       => '''
            || LOWER (p_table_name)
            || ''''
            || CHR (10)
            || '                           , p_column      => '''
            || LOWER (i.column_name)
            || ''''
            || CHR (10)
            || '                           , p_pk_id       => v_pk'
            || CHR (10)
            || '                           , p_old_value   => null'
            || CHR (10)
            || '                           , p_new_value   => '
            || CASE
                  WHEN i.data_type IN ('NUMBER', 'FLOAT', 'INTEGER')
                  THEN
                        ' to_char(p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || ')'
                  WHEN i.data_type = 'DATE'
                  THEN
                        ' to_char(p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || q'[, 'yyyy.mm.dd hh24:mi:ss')]'
                  WHEN i.data_type LIKE 'TIMESTAMP%'
                  THEN
                        ' to_char(p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || q'[, 'yyyy.mm.dd hh24:mi:ss.ffffff')]'
                  WHEN i.data_type = 'BLOB'
                  THEN
                     q'['Data type "BLOB" is not supported for generic logging']'
                  WHEN i.data_type = 'XMLTYPE'
                  THEN
                        ' substr(case when p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || ' is null then null else p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || '.getStringVal() end,1,4000)'
                  ELSE
                        ' substr(p_'
                     || SUBSTR (LOWER (i.column_name), 1, 28)
                     || ',1,4000)'
               END
            || ' );'
            || CHR (10);
      END LOOP;

      RETURN TRIM (RTRIM (v_columns, CHR (10)));
   END get_create_change_log_list;

   FUNCTION get_set_param_list (p_table_name   IN VARCHAR2,
                                p_include_pk   IN VARCHAR2 DEFAULT 'N')
      RETURN VARCHAR2
   IS
      v_columns   VARCHAR2 (32767 CHAR);
      v_pk        user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      -- PK berücksichtigen oder eben nicht, abhängig vom Parameter
                      AND (   p_include_pk = 'N' AND column_name <> v_pk
                           OR p_include_pk = 'Y')
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         v_columns :=
               v_columns
            || '          , '
            || i.column_name
            || ' = p_'
            || SUBSTR (i.column_name, 1, 28)
            || CHR (10);
      END LOOP;

      RETURN RTRIM (LTRIM (v_columns, '          , '), CHR (10));
   END get_set_param_list;

   FUNCTION get_read_column_by_id_spec (
      p_table_name                   IN VARCHAR2,
      p_table_abbreviation           IN VARCHAR2,
      p_col_prefix_in_method_names   IN BOOLEAN)
      RETURN CLOB
   IS
      v_sql           CLOB;
      v_sql_column    CLOB;
      v_column_name   user_tab_cols.column_name%TYPE;
      v_pk            user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      -- Loop über jede Spalte
      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      AND column_name <> v_pk
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         -- Template füllen
         v_sql_column := co_get_column_by_id_spec;

         IF NOT p_col_prefix_in_method_names
         THEN
            -- Tabellenkürzel wieder rausnehmen
            v_column_name :=
               REPLACE (i.column_name, p_table_abbreviation || '_', NULL);
         ELSE
            v_column_name := i.column_name;
         END IF;

         -- Ersetzungen im Template vornehmen
         v_sql_column :=
            REPLACE (v_sql_column,
                     'get_#COLUMN_NAME_26#',
                     SUBSTR ('get_' || v_column_name, 1, 30));

         v_sql_column :=
            REPLACE (v_sql_column, '#PK_COLUMN_28#', SUBSTR (v_pk, 1, 28));
         v_sql_column := REPLACE (v_sql_column, '#PK_COLUMN_ORIGINAL#', v_pk);

         v_sql_column := REPLACE (v_sql_column, '#TABLE_NAME#', i.table_name);
         v_sql_column :=
            REPLACE (v_sql_column, '#COLUMN_NAME_ORIGINAL#', i.column_name);

         v_sql := v_sql || ' ' || v_sql_column;
      END LOOP;

      RETURN v_sql;
   END get_read_column_by_id_spec;

   FUNCTION get_read_column_by_id_body (
      p_table_name                   IN VARCHAR2,
      p_table_abbreviation           IN VARCHAR2,
      p_col_prefix_in_method_names   IN BOOLEAN)
      RETURN CLOB
   IS
      v_sql           CLOB;
      v_sql_column    CLOB;
      v_pk            user_tab_cols.column_name%TYPE;
      v_column_name   user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      -- Loop über jede Spalte
      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      AND column_name <> v_pk
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         -- Template füllen
         v_sql_column := co_get_column_by_id_body;

         -- Ersetzungen im Template vornehmen
         IF NOT p_col_prefix_in_method_names
         THEN
            -- Tabellenkürzel wieder rausnehmen
            v_column_name :=
               REPLACE (i.column_name, p_table_abbreviation || '_', NULL);
         ELSE
            v_column_name := i.column_name;
         END IF;

         -- Ersetzungen im Template vornehmen
         -- Ersetzungen im Template vornehmen
         -- Ersetzungen im Template vornehmen
         v_sql_column :=
            REPLACE (v_sql_column,
                     'get_#COLUMN_NAME_26#',
                     SUBSTR ('get_' || v_column_name, 1, 30));

         v_sql_column :=
            REPLACE (v_sql_column, '#PK_COLUMN_28#', SUBSTR (v_pk, 1, 28));
         v_sql_column := REPLACE (v_sql_column, '#PK_COLUMN_ORIGINAL#', v_pk);

         v_sql_column := REPLACE (v_sql_column, '#TABLE_NAME#', i.table_name);
         v_sql_column :=
            REPLACE (v_sql_column, '#COLUMN_NAME_ORIGINAL#', i.column_name);
         v_sql_column :=
            REPLACE (v_sql_column,
                     '#TABLE_ABBREVIATION#',
                     p_table_abbreviation);

         v_sql := v_sql || ' ' || v_sql_column;
      END LOOP;

      RETURN v_sql;
   END get_read_column_by_id_body;

   FUNCTION get_set_column_by_id_spec (
      p_table_name                   IN VARCHAR2,
      p_table_abbreviation           IN VARCHAR2,
      p_col_prefix_in_method_names   IN BOOLEAN)
      RETURN CLOB
   IS
      v_sql           CLOB;
      v_sql_column    CLOB;
      v_pk            user_tab_cols.column_name%TYPE;
      v_column_name   user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      -- Loop über jede Spalte
      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      AND column_name <> v_pk
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         -- Template füllen
         v_sql_column := co_set_column_by_id_spec;

         -- Ersetzungen im Template vornehmen
         IF NOT p_col_prefix_in_method_names
         THEN
            -- Tabellenkürzel wieder rausnehmen
            v_column_name :=
               REPLACE (i.column_name, p_table_abbreviation || '_', NULL);
         ELSE
            v_column_name := i.column_name;
         END IF;

         -- Ersetzungen im Template vornehmen
         v_sql_column :=
            REPLACE (v_sql_column,
                     'set_#COLUMN_NAME_26#',
                     SUBSTR ('set_' || v_column_name, 1, 30));

         v_sql_column :=
            REPLACE (v_sql_column,
                     'p_#COLUMN_NAME_28#',
                     SUBSTR ('p_' || i.column_name, 1, 30));

         v_sql_column :=
            REPLACE (v_sql_column, '#PK_COLUMN_28#', SUBSTR (v_pk, 1, 28));
         v_sql_column := REPLACE (v_sql_column, '#PK_COLUMN_ORIGINAL#', v_pk);

         v_sql_column := REPLACE (v_sql_column, '#TABLE_NAME#', i.table_name);
         v_sql_column :=
            REPLACE (v_sql_column, '#COLUMN_NAME_ORIGINAL#', i.column_name);

         v_sql := v_sql || ' ' || v_sql_column;
      END LOOP;

      RETURN v_sql;
   END get_set_column_by_id_spec;

   FUNCTION get_set_column_by_id_body (
      p_table_name                   IN VARCHAR2,
      p_table_abbreviation           IN VARCHAR2,
      p_col_prefix_in_method_names   IN BOOLEAN,
      p_enable_generic_logging       IN BOOLEAN DEFAULT FALSE)
      RETURN CLOB
   IS
      v_sql                       CLOB;
      v_sql_column                CLOB;
      v_sql_compare               VARCHAR2 (1000);
      v_create_change_log_entry   VARCHAR2 (1000);
      v_pk                        user_tab_cols.column_name%TYPE;
      v_data_type                 user_tab_cols.data_type%TYPE;
      v_column_name               user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      -- Loop über jede Spalte
      FOR i
         IN (  SELECT *
                 FROM user_tab_cols
                WHERE     table_name = p_table_name
                      AND column_name <> v_pk
                      AND hidden_column = 'NO'
             ORDER BY column_id)
      LOOP
         -- Template füllen
         v_sql_column := co_set_column_by_id_body;

         v_sql_compare :=
            CASE
               WHEN i.data_type IN ('BLOB', 'CLOB')
               THEN
                     'DBMS_LOB.compare( COALESCE( '
                  || LOWER ('v_existing_row.' || i.column_name)
                  || ', '
                  || CASE
                        WHEN i.data_type = 'BLOB'
                        THEN
                           q'[to_blob( UTL_RAW.cast_to_raw( '$$$$' ) )]'
                        WHEN i.data_type = 'CLOB'
                        THEN
                           q'[to_clob( '$$$$' )]'
                        ELSE
                           q'['$$$$']'
                     END
                  || ')'
                  || CHR (10)
                  || '                           , COALESCE('
                  || ' p_'
                  || SUBSTR (LOWER (i.column_name), 1, 28)
                  || ', '
                  || CASE
                        WHEN i.data_type = 'BLOB'
                        THEN
                           q'[to_blob( UTL_RAW.cast_to_raw( '$$$$' ) )]'
                        WHEN i.data_type = 'CLOB'
                        THEN
                           q'[to_clob( '$$$$' )]'
                        ELSE
                           q'['$$$$']'
                     END
                  || ')'
                  || CHR (10)
                  || '                           ) <> 0'
               WHEN i.data_type = 'XMLTYPE'
               THEN
                     'DBMS_LOB.compare( COALESCE(case when v_existing_row.'
                  || LOWER (i.column_name)
                  || ' is null then null else v_existing_row.'
                  || LOWER (i.column_name)
                  || q'[.getStringVal() end, to_clob( '$$$$' )]'
                  || '), COALESCE(case when p_'
                  || SUBSTR (LOWER (i.column_name), 1, 28)
                  || ' is null then null else p_'
                  || SUBSTR (LOWER (i.column_name), 1, 28)
                  || q'[.getStringVal() end, to_clob( '$$$$' )]'
                  || ')) <> 0'
               ELSE
                     'COALESCE( '
                  || LOWER ('v_existing_row.' || i.column_name)
                  || ', '
                  || CASE
                        WHEN i.data_type = 'NUMBER'
                        THEN
                           '-9999.9999'
                        WHEN i.data_type = 'DATE'
                        THEN
                           q'[to_date('01.01.1900','dd.mm.yyyy')]'
                        WHEN i.data_type LIKE 'TIMESTAMP%'
                        THEN
                           q'[to_timestamp('01.01.1900','dd.mm.yyyy')]'
                        ELSE
                           q'['$$$$']'
                     END
                  || ') <> COALESCE( p_'
                  || SUBSTR (LOWER (i.column_name), 1, 28)
                  || ', '
                  || CASE
                        WHEN i.data_type = 'NUMBER'
                        THEN
                           '-9999.9999'
                        WHEN i.data_type = 'DATE'
                        THEN
                           q'[to_date('01.01.1900','dd.mm.yyyy')]'
                        WHEN i.data_type LIKE 'TIMESTAMP%'
                        THEN
                           q'[to_timestamp('01.01.1900','dd.mm.yyyy')]'
                        ELSE
                           q'['$$$$']'
                     END
                  || ' )'
            END;

         v_create_change_log_entry :=
               CASE
                  WHEN p_enable_generic_logging
                  THEN
                        'create_change_log_entry( p_table       => '''
                     || LOWER (p_table_name)
                     || ''''
                     || CHR (10)
                     || '                               , p_column      => '''
                     || LOWER (i.column_name)
                     || ''''
                     || CHR (10)
                     || '                               , p_pk_id       => v_existing_row.'
                     || LOWER (v_pk)
                     || CHR (10)
                     || '                               , p_old_value   => '
                     || CASE
                           WHEN i.data_type IN ('NUMBER', 'FLOAT', 'INTEGER')
                           THEN
                                 ' to_char(v_existing_row.'
                              || LOWER (i.column_name)
                              || ')'
                           WHEN i.data_type = 'DATE'
                           THEN
                                 ' to_char(v_existing_row.'
                              || LOWER (i.column_name)
                              || q'[, 'yyyy.mm.dd hh24:mi:ss')]'
                           WHEN i.data_type LIKE 'TIMESTAMP%'
                           THEN
                                 ' to_char(v_existing_row.'
                              || LOWER (i.column_name)
                              || q'[, 'yyyy.mm.dd hh24:mi:ss.ffffff')]'
                           WHEN i.data_type = 'BLOB'
                           THEN
                              q'['Data type "BLOB" is not supported for generic logging']'
                           WHEN i.data_type = 'XMLTYPE'
                           THEN
                                 ' substr(case when v_existing_row.'
                              || LOWER (i.column_name)
                              || ' is null then null else v_existing_row.'
                              || LOWER (i.column_name)
                              || '.getStringVal() end,1,4000)'
                           ELSE
                                 ' substr(v_existing_row.'
                              || LOWER (i.column_name)
                              || ',1,4000)'
                        END
                     || CHR (10)
                     || '                               , p_new_value   => '
                     || CASE
                           WHEN i.data_type IN ('NUMBER', 'FLOAT', 'INTEGER')
                           THEN
                                 ' to_char(p_'
                              || SUBSTR (LOWER (i.column_name), 1, 28)
                              || ')'
                           WHEN i.data_type = 'DATE'
                           THEN
                                 ' to_char(p_'
                              || SUBSTR (LOWER (i.column_name), 1, 28)
                              || q'[, 'yyyy.mm.dd hh24:mi:ss')]'
                           WHEN i.data_type LIKE 'TIMESTAMP%'
                           THEN
                                 ' to_char(p_'
                              || SUBSTR (LOWER (i.column_name), 1, 28)
                              || q'[, 'yyyy.mm.dd hh24:mi:ss.ffffff')]'
                           WHEN i.data_type = 'BLOB'
                           THEN
                              q'['Data type "BLOB" is not supported for generic logging']'
                           WHEN i.data_type = 'XMLTYPE'
                           THEN
                                 ' substr(case when p_'
                              || SUBSTR (LOWER (i.column_name), 1, 28)
                              || ' is null then null else p_'
                              || SUBSTR (LOWER (i.column_name), 1, 28)
                              || '.getStringVal() end,1,4000)'
                           ELSE
                                 ' substr(p_'
                              || SUBSTR (LOWER (i.column_name), 1, 28)
                              || ',1,4000)'
                        END
                     || ' );'
                     || CHR (10)
                  ELSE
                     NULL
               END
            || CHR (10);

         -- Ersetzungen im Template vornehmen
         IF NOT p_col_prefix_in_method_names
         THEN
            -- Tabellenkürzel wieder rausnehmen
            v_column_name :=
               REPLACE (i.column_name, p_table_abbreviation || '_', NULL);
         ELSE
            v_column_name := i.column_name;
         END IF;

         -- Ersetzungen im Template vornehmen
         v_sql_column :=
            REPLACE (v_sql_column,
                     'set_#COLUMN_NAME_26#',
                     SUBSTR ('set_' || v_column_name, 1, 30));

         v_sql_column :=
            REPLACE (v_sql_column,
                     'p_#COLUMN_NAME_28#',
                     SUBSTR ('p_' || i.column_name, 1, 30));

         v_sql_column :=
            REPLACE (v_sql_column, '#PK_COLUMN_28#', SUBSTR (v_pk, 1, 28));
         v_sql_column := REPLACE (v_sql_column, '#PK_COLUMN_ORIGINAL#', v_pk);

         v_sql_column := REPLACE (v_sql_column, '#TABLE_NAME#', i.table_name);
         v_sql_column :=
            REPLACE (v_sql_column, '#COLUMN_NAME_ORIGINAL#', i.column_name);
         v_sql_column :=
            REPLACE (v_sql_column,
                     '#TABLE_ABBREVIATION#',
                     p_table_abbreviation);

         v_sql_column :=
            REPLACE (v_sql_column, '#COLUMN_COMPARE#', v_sql_compare);
         v_sql_column :=
            REPLACE (v_sql_column,
                     '#CREATE_CHANGE_LOG_ENTRY#',
                     v_create_change_log_entry);

         v_sql := v_sql || ' ' || v_sql_column;
      END LOOP;

      RETURN v_sql;
   END get_set_column_by_id_body;

   FUNCTION get_get_pk_by_unique_cols_spec (p_table_name IN VARCHAR2)
      RETURN CLOB
   IS
      v_sql_single_constraint   CLOB;
      v_sql_all_constraints     CLOB;
      v_unique_cols_param       VARCHAR2 (4000 CHAR);
      v_pk                      user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      -- loop over constraints, if there are > 1 Unique Constraints
      FOR table_constraints
         IN (SELECT *
               FROM user_constraints c
              WHERE constraint_type = 'U' AND c.table_name = p_table_name)
      LOOP
         v_unique_cols_param := NULL;

         -- loop over columns of constraint
         FOR constraint_cols
            IN (  SELECT *
                    FROM user_cons_columns col
                   WHERE col.constraint_name =
                            table_constraints.constraint_name
                ORDER BY col.position)
         LOOP
            v_unique_cols_param :=
                  v_unique_cols_param
               || ', p_'
               || SUBSTR (constraint_cols.column_name, 1, 28)
               || ' '
               || p_table_name
               || '.'
               || constraint_cols.column_name
               || '%TYPE';
         END LOOP;

         IF (v_unique_cols_param IS NOT NULL)
         THEN
            v_sql_single_constraint := co_get_pk_by_unique_cols_spec;
            v_sql_single_constraint :=
               REPLACE (v_sql_single_constraint,
                        '#TABLE_NAME#',
                        p_table_name);
            v_sql_single_constraint :=
               REPLACE (v_sql_single_constraint, '#PK_COLUMN#', v_pk);
            v_sql_single_constraint :=
               REPLACE (v_sql_single_constraint,
                        '#UNIQUE_COLS_PARAM_LIST#',
                        LTRIM (v_unique_cols_param, ', '));
            v_sql_all_constraints :=
               v_sql_all_constraints || v_sql_single_constraint;
         END IF;
      END LOOP;

      RETURN v_sql_all_constraints;
   END get_get_pk_by_unique_cols_spec;

   FUNCTION get_get_pk_by_unique_cols_body (p_table_name IN VARCHAR2)
      RETURN CLOB
   IS
      v_sql_single_constraint   CLOB;
      v_sql_all_constraints     CLOB;
      v_unique_cols_param       VARCHAR2 (4000 CHAR);
      v_unique_cols_compare     VARCHAR2 (4000 CHAR);
      v_current_col_coalesce    VARCHAR2 (400 CHAR);
      v_pk                      user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);

      -- loop over constraints, if there are > 1 Unique Constraints
      FOR table_constraints
         IN (SELECT *
               FROM user_constraints c
              WHERE constraint_type = 'U' AND c.table_name = p_table_name)
      LOOP
         v_current_col_coalesce := NULL;
         v_unique_cols_param := NULL;
         v_unique_cols_compare := NULL;

         -- loop over columns of constraint
         FOR constraint_cols
            IN (  SELECT *
                    FROM user_cons_columns col
                   WHERE col.constraint_name =
                            table_constraints.constraint_name
                ORDER BY col.position)
         LOOP
            v_unique_cols_param :=
                  v_unique_cols_param
               || ', p_'
               || SUBSTR (constraint_cols.column_name, 1, 28)
               || ' '
               || p_table_name
               || '.'
               || constraint_cols.column_name
               || '%TYPE';

            v_current_col_coalesce :=
               tools.dictionary.get_column_coalesce (
                  p_schema                => USER,
                  p_table_name            => p_table_name,
                  p_column_name           => constraint_cols.column_name,
                  p_left_coalesce_side    => constraint_cols.column_name,
                  p_right_coalesce_side   =>    'p_'
                                             || SUBSTR (
                                                   constraint_cols.column_name,
                                                   1,
                                                   28),
                  p_compare_operation     => '=');
            v_unique_cols_compare :=
               v_unique_cols_compare || 'AND ' || v_current_col_coalesce;
         END LOOP;

         IF (v_unique_cols_param IS NOT NULL)
         THEN
            v_sql_single_constraint := co_get_pk_by_unique_cols_body;
            v_sql_single_constraint :=
               REPLACE (v_sql_single_constraint,
                        '#TABLE_NAME#',
                        p_table_name);
            v_sql_single_constraint :=
               REPLACE (v_sql_single_constraint, '#PK_COLUMN#', v_pk);
            v_sql_single_constraint :=
               REPLACE (v_sql_single_constraint,
                        '#UNIQUE_COLS_PARAM_LIST#',
                        LTRIM (v_unique_cols_param, ', '));
            v_sql_single_constraint :=
               REPLACE (v_sql_single_constraint,
                        '#UNIQUE_COLS_COMPARE_LIST#',
                        LTRIM (v_unique_cols_compare, 'AND '));
            v_sql_all_constraints :=
               v_sql_all_constraints || v_sql_single_constraint;
         END IF;
      END LOOP;

      RETURN v_sql_all_constraints;
   END get_get_pk_by_unique_cols_body;

   FUNCTION get_table_column_prefix (p_table_name IN VARCHAR2)
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

   FUNCTION get_column_prefix (p_column_name VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN SUBSTR (
                p_column_name,
                1,
                CASE
                   WHEN INSTR (p_column_name, '_') = 0
                   THEN
                      LENGTH (p_column_name)
                   ELSE
                      INSTR (p_column_name, '_') - 1
                END);
   END;

   FUNCTION generate_install_script (p_table_abbreviation IN VARCHAR2)
      RETURN CLOB
   IS
      v_sql   CLOB;
   BEGIN
      -- Template füllen
      v_sql := co_generate_install_script;
      -- Ersetzungen im Template vornehmen
      v_sql := REPLACE (v_sql, '#TABLE_ABBREVIATION#', p_table_abbreviation);

      RETURN v_sql;
   END generate_install_script;

   FUNCTION generate_synonym (p_table_name           IN VARCHAR2,
                              p_table_abbreviation   IN VARCHAR2)
      RETURN CLOB
   IS
      v_sql   CLOB;
   BEGIN
      -- Template füllen
      v_sql := co_generate_synonym;
      -- Ersetzungen im Template vornehmen
      v_sql := REPLACE (v_sql, '#TABLE_ABBREVIATION#', p_table_abbreviation);
      v_sql := REPLACE (v_sql, '#TABLE_NAME#', p_table_name);

      RETURN v_sql;
   END generate_synonym;

   FUNCTION generate_sequence (p_table_name           IN VARCHAR2,
                               p_table_abbreviation   IN VARCHAR2)
      RETURN CLOB
   IS
      v_sql   CLOB;
   BEGIN
      -- Template füllen
      v_sql := co_generate_sequence;
      -- Ersetzungen im Template vornehmen
      v_sql := REPLACE (v_sql, '#TABLE_NAME#', UPPER (p_table_name));

      RETURN v_sql;
   END generate_sequence;

   FUNCTION generate_dml_view (p_table_name IN VARCHAR2)
      RETURN VARCHAR2
   IS
      v_template_view   VARCHAR2 (32767 CHAR) := q'[
               CREATE OR REPLACE VIEW #TABLE_NAME_24#_DML_V
               AS
                 SELECT #COLUMN_LIST#
                   FROM #TABLE_NAME#
                                   ]';

      v_columns         VARCHAR2 (32767 CHAR);
   BEGIN
      -- Tabelenname
      v_template_view :=
         REPLACE (v_template_view,
                  '#TABLE_NAME_24#',
                  SUBSTR (p_table_name, 1, 24));

      v_template_view :=
         REPLACE (v_template_view, '#TABLE_NAME#', p_table_name);

      v_columns :=
         get_sorted_table_cols (p_table_name   => UPPER (p_table_name),
                                p_include_pk   => 'Y');
      -- Spalten
      v_template_view := REPLACE (v_template_view, '#COLUMN_LIST#', v_columns);

      RETURN v_template_view;
   END generate_dml_view;

   FUNCTION generate_dml_view_trigger (
      p_table_name                   IN VARCHAR2,
      p_enable_deletion_of_records   IN BOOLEAN DEFAULT FALSE)
      RETURN VARCHAR2
   IS
      v_template_trigger   CLOB
         :=    'CREATE OR REPLACE TRIGGER #TABLE_NAME_24#_IOIUD '
            || CHR (13)
            || '  INSTEAD OF INSERT OR UPDATE OR DELETE '
            || CHR (13)
            || '  ON #TABLE_NAME_24#_DML_V '
            || CHR (13)
            || '  FOR EACH ROW '
            || CHR (13)
            || 'BEGIN '
            || CHR (13)
            || '  IF INSERTING THEN '
            || CHR (13)
            || '    #TABLE_NAME#_API.create_row(#PARAMETER_COLUMN_LIST#); '
            || CHR (13)
            || '  ELSIF UPDATING THEN '
            || CHR (13)
            || '    #TABLE_NAME#_API.update_row(#PARAMETER_COLUMN_LIST#); '
            || CHR (13)
            || '  ELSIF DELETING THEN '
            || CHR (13)
            || '    #DELETE_IF_API_ALLOWS_ELSE_EXCEPT# '
            || CHR (13)
            || '  END IF; '
            || CHR (13)
            || 'END; ';
      v_new_columns        VARCHAR2 (32767 CHAR);
      v_pk                 user_tab_cols.column_name%TYPE;
   BEGIN
      -- PK ermitteln
      v_pk := get_table_key (p_table_name => p_table_name);
      -- Tabelenname
      v_template_trigger :=
         REPLACE (v_template_trigger,
                  '#TABLE_NAME_24#',
                  SUBSTR (p_table_name, 1, 24));

      v_template_trigger :=
         REPLACE (v_template_trigger, '#TABLE_NAME#', p_table_name);

      IF (p_enable_deletion_of_records)
      THEN
         v_template_trigger :=
            REPLACE (
               v_template_trigger,
               '#DELETE_IF_API_ALLOWS_ELSE_EXCEPT#',
                  p_table_name
               || '_API.delete_row(p_'
               || SUBSTR (v_pk, 1, 28)
               || ' => :old.'
               || v_pk
               || ');');
      ELSE
         v_template_trigger :=
            REPLACE (
               v_template_trigger,
               '#DELETE_IF_API_ALLOWS_ELSE_EXCEPT#',
               'Raise_Application_Error (-20001, ''Deletion of record is not allowed.'');');
      END IF;

      v_new_columns :=
         get_trigger_new_list (p_table_name => UPPER (p_table_name));
      -- Spalten
      v_template_trigger :=
         REPLACE (v_template_trigger,
                  '#PARAMETER_COLUMN_LIST#',
                  v_new_columns);

      RETURN v_template_trigger;
   END generate_dml_view_trigger;

   FUNCTION generate_api_spec (
      p_table_name                   IN VARCHAR2,
      p_table_abbreviation           IN VARCHAR2,
      p_enable_generic_logging       IN BOOLEAN DEFAULT FALSE,
      p_enable_deletion_of_records   IN BOOLEAN DEFAULT FALSE,
      p_col_prefix_in_method_names   IN BOOLEAN DEFAULT FALSE)
      RETURN CLOB
   IS
      v_pk                             user_tab_cols.column_name%TYPE;
      v_sql                            CLOB;

      -- get functions pro Tabellen-Attribut
      v_get_column_by_id_spec          CLOB;

      -- set procedures pro Tabellen-Attribut
      v_set_column_by_id_spec          CLOB;

      -- row_exists als function
      v_row_exists_func_spec           CLOB;

      -- create als procedure und function (PK wird zurückgegeben)
      v_create_proc_spec               CLOB;
      v_create_r_proc_spec             CLOB;

      v_create_func_spec               CLOB;

      -- update als procedure und function (PK wird zurückgegeben)
      v_update_proc_spec               CLOB;
      v_update_r_proc_spec             CLOB;
      v_update_func_spec               CLOB;

      -- create or update als procedure und function (PK wird zurückgegeben)
      v_create_or_update_proc_spec     CLOB;
      v_create_or_update_r_proc_spec   CLOB;
      v_create_or_update_func_spec     CLOB;

      -- Parameterlisten
      v_in_param_list                  VARCHAR2 (32767 CHAR);
      v_out_param_list                 VARCHAR2 (32767 CHAR);
      v_search_param_list              VARCHAR2 (32767 CHAR);

      -- Fetch functions/procedures
      v_read_by_cols_func_spec         CLOB;
      v_read_by_pk_func_spec           CLOB;
      v_read_by_pk_and_fill_prc_spc    CLOB;

      -- unique index get function
      v_get_pk_by_unique_cols_spec     CLOB;
   BEGIN
      -- Template füllen
      v_sql := co_generate_api_spec;

      -- Generisches Logging einschalten, falls konfiguriert
      v_sql :=
         REPLACE (
            v_sql,
            '#CREATE_CHANGE_LOG_ENTRY_SPEC#',
            CASE
               WHEN p_enable_generic_logging THEN co_create_change_log_spec
               ELSE NULL
            END);

      -- Löschen von Zeilen erlauben, falls konfiguriert
      v_sql :=
         REPLACE (
            v_sql,
            '#DELETE_PROCEDURE_SPEC#',
            CASE
               WHEN p_enable_deletion_of_records THEN co_delete_proc_spec
               ELSE NULL
            END);

      -- Ersetzungen im Template vornehmen
      v_sql := REPLACE (v_sql, '#TABLE_ABBREVIATION#', p_table_abbreviation);
      v_sql := REPLACE (v_sql, '#TABLE_NAME#', p_table_name);

      -- PK ermitteln und ersetzen
      v_pk := get_table_key (p_table_name => UPPER (p_table_name));

      v_sql := REPLACE (v_sql, '#PK_COLUMN#', v_pk);

      -- Get Functions ermitteln und ersetzen
      v_get_column_by_id_spec :=
         get_read_column_by_id_spec (
            p_table_name                   => UPPER (p_table_name),
            p_table_abbreviation           => p_table_abbreviation,
            p_col_prefix_in_method_names   => p_col_prefix_in_method_names);

      v_sql :=
         REPLACE (v_sql, ' #GET_COLUMN_FUNCTIONS#', v_get_column_by_id_spec);

      -- Set Functions ermitteln und ersetzen
      v_set_column_by_id_spec :=
         get_set_column_by_id_spec (
            p_table_name                   => UPPER (p_table_name),
            p_table_abbreviation           => p_table_abbreviation,
            p_col_prefix_in_method_names   => p_col_prefix_in_method_names);

      v_sql :=
         REPLACE (v_sql, ' #SET_COLUMN_PROCEDURES#', v_set_column_by_id_spec);

      -- Parameterliste für Cursor ermitteln und erstzen
      v_in_param_list :=
         get_in_param_list (p_table_name => UPPER (p_table_name));

      v_sql := REPLACE (v_sql, '#IN_PARAMETER_LIST#', v_in_param_list);

      -- Parametersuchliste für Cursor ermitteln und erstzen
      v_search_param_list :=
         get_search_param_list (p_table_name => UPPER (p_table_name));

      v_sql := REPLACE (v_sql, '#PARAMETER_SEARCH_LIST#', v_search_param_list);

      -- Parameterliste für row_exists Function erstzen
      v_row_exists_func_spec := co_row_exists_func_spec;

      v_row_exists_func_spec :=
         REPLACE (v_row_exists_func_spec, '#TABLE_NAME#', p_table_name);

      v_row_exists_func_spec :=
         REPLACE (v_row_exists_func_spec, '#PK_COLUMN#', v_pk);

      v_sql :=
         REPLACE (v_sql, '#ROW_EXISTS_FUNCTION#', v_row_exists_func_spec);

      -- Parameterliste für create Function erstzen
      v_create_func_spec := co_create_func_spec;

      v_in_param_list :=
         get_in_param_list (p_table_name   => UPPER (p_table_name),
                            p_include_pk   => 'Y');

      -- default null für PK
      v_in_param_list :=
         REPLACE (
            v_in_param_list,
            ' IN ' || p_table_name || '.' || v_pk || '%TYPE',
            ' IN ' || p_table_name || '.' || v_pk || '%TYPE DEFAULT NULL');

      v_create_func_spec :=
         REPLACE (v_create_func_spec, '#IN_PARAMETER_LIST#', v_in_param_list);

      v_create_func_spec :=
         REPLACE (v_create_func_spec,
                  '#TABLE_ABBREVIATION#',
                  p_table_abbreviation);

      v_create_func_spec :=
         REPLACE (v_create_func_spec, '#TABLE_NAME#', p_table_name);

      v_create_func_spec := REPLACE (v_create_func_spec, '#PK_COLUMN#', v_pk);

      v_sql := REPLACE (v_sql, '#CREATE_FUNCTION#', v_create_func_spec);

      -- Parameterliste für create Procedure erstzen
      v_create_proc_spec := co_create_proc_spec;

      v_create_proc_spec :=
         REPLACE (v_create_proc_spec, '#IN_PARAMETER_LIST#', v_in_param_list);

      v_create_proc_spec :=
         REPLACE (v_create_proc_spec,
                  '#TABLE_ABBREVIATION#',
                  p_table_abbreviation);

      v_sql := REPLACE (v_sql, '#CREATE_PROCEDURE#', v_create_proc_spec);

      -- Parameterliste für create Rowtype Procedure erstzen
      v_create_r_proc_spec := co_create_rowtype_proc_spec;

      v_create_r_proc_spec :=
         REPLACE (v_create_r_proc_spec, '#TABLE_NAME#', p_table_name);

      v_sql :=
         REPLACE (v_sql, '#CREATE_ROWTYPE_PROCEDURE#', v_create_r_proc_spec);

      -- Parameterliste für update Function erstzen
      v_update_func_spec := co_update_func_spec;

      v_in_param_list :=
         get_in_param_list (p_table_name   => UPPER (p_table_name),
                            p_include_pk   => 'Y');

      v_update_func_spec :=
         REPLACE (v_update_func_spec, '#IN_PARAMETER_LIST#', v_in_param_list);

      v_update_func_spec :=
         REPLACE (v_update_func_spec,
                  '#TABLE_ABBREVIATION#',
                  p_table_abbreviation);

      v_update_func_spec :=
         REPLACE (v_update_func_spec, '#TABLE_NAME#', p_table_name);

      v_update_func_spec := REPLACE (v_update_func_spec, '#PK_COLUMN#', v_pk);

      v_sql := REPLACE (v_sql, '#UPDATE_FUNCTION#', v_update_func_spec);

      -- Parameterliste für update Procedure erstzen
      v_update_proc_spec := co_update_proc_spec;

      v_in_param_list :=
         get_in_param_list (p_table_name   => UPPER (p_table_name),
                            p_include_pk   => 'Y');

      v_update_proc_spec :=
         REPLACE (v_update_proc_spec, '#IN_PARAMETER_LIST#', v_in_param_list);

      v_update_proc_spec :=
         REPLACE (v_update_proc_spec,
                  '#TABLE_ABBREVIATION#',
                  p_table_abbreviation);

      v_sql := REPLACE (v_sql, '#UPDATE_PROCEDURE#', v_update_proc_spec);

      -- Parameterliste für update Rowtype Procedure erstzen
      v_update_r_proc_spec := co_update_rowtype_proc_spec;

      v_update_r_proc_spec :=
         REPLACE (v_update_r_proc_spec, '#TABLE_NAME#', p_table_name);

      v_sql :=
         REPLACE (v_sql, '#UPDATE_ROWTYPE_PROCEDURE#', v_update_r_proc_spec);

      -- Parameterliste für create_or_update Function erstzen
      v_create_or_update_func_spec := co_create_or_update_func_spec;

      v_in_param_list :=
         get_in_param_list (p_table_name   => UPPER (p_table_name),
                            p_include_pk   => 'Y');

      v_create_or_update_func_spec :=
         REPLACE (v_create_or_update_func_spec,
                  '#IN_PARAMETER_LIST#',
                  v_in_param_list);

      v_create_or_update_func_spec :=
         REPLACE (v_create_or_update_func_spec,
                  '#TABLE_ABBREVIATION#',
                  p_table_abbreviation);

      v_create_or_update_func_spec :=
         REPLACE (v_create_or_update_func_spec, '#TABLE_NAME#', p_table_name);

      v_create_or_update_func_spec :=
         REPLACE (v_create_or_update_func_spec, '#PK_COLUMN#', v_pk);

      v_sql :=
         REPLACE (v_sql,
                  '#CREATE_OR_UPDATE_FUNCTION#',
                  v_create_or_update_func_spec);

      -- Parameterliste für create_or_update Procedure erstzen
      v_create_or_update_proc_spec := co_create_or_update_proc_spec;

      v_create_or_update_proc_spec :=
         REPLACE (v_create_or_update_proc_spec,
                  '#IN_PARAMETER_LIST#',
                  v_in_param_list);

      v_create_or_update_proc_spec :=
         REPLACE (v_create_or_update_proc_spec,
                  '#TABLE_ABBREVIATION#',
                  p_table_abbreviation);

      v_sql :=
         REPLACE (v_sql,
                  '#CREATE_OR_UPDATE_PROCEDURE#',
                  v_create_or_update_proc_spec);

      -- Parameterliste für create_or_update Rowtype Procedure erstzen
      v_create_or_update_r_proc_spec := co_create_or_update_r_proc_spe;

      v_create_or_update_r_proc_spec :=
         REPLACE (v_create_or_update_r_proc_spec,
                  '#TABLE_NAME#',
                  p_table_name);

      v_sql :=
         REPLACE (v_sql,
                  '#CREATE_OR_UPDATE_ROWTYPE_PROCEDURE#',
                  v_create_or_update_r_proc_spec);

      -- Parameterliste für fetch_by_pk Function erstzen
      v_read_by_pk_func_spec := co_get_by_pk_func_spec;

      v_read_by_pk_func_spec :=
         REPLACE (v_read_by_pk_func_spec, '#PK_COLUMN#', v_pk);

      v_read_by_pk_func_spec :=
         REPLACE (v_read_by_pk_func_spec, '#TABLE_NAME#', p_table_name);

      v_sql :=
         REPLACE (v_sql, '#READ_BY_PK_FUNCTION#', v_read_by_pk_func_spec);

      -- Parameterliste für fetchfill_by_pk Function erstzen
      v_read_by_pk_and_fill_prc_spc := co_get_by_pk_and_fill_prc_spc;

      v_read_by_pk_and_fill_prc_spc :=
         REPLACE (v_read_by_pk_and_fill_prc_spc, '#PK_COLUMN#', v_pk);

      v_read_by_pk_and_fill_prc_spc :=
         REPLACE (v_read_by_pk_and_fill_prc_spc,
                  '#TABLE_NAME#',
                  p_table_name);

      -- Parameterliste für Cursor ermitteln und erstzen
      v_out_param_list :=
         get_out_param_list (p_table_name => UPPER (p_table_name));

      v_read_by_pk_and_fill_prc_spc :=
         REPLACE (v_read_by_pk_and_fill_prc_spc,
                  '#OUT_PARAMETER_LIST#',
                  v_out_param_list);

      v_sql :=
         REPLACE (v_sql,
                  '#READ_BY_PK_AND_FILL_PROCEDURE#',
                  v_read_by_pk_and_fill_prc_spc);

      -- get_pk_by_unique_cols function
      v_get_pk_by_unique_cols_spec :=
         get_get_pk_by_unique_cols_spec (p_table_name => UPPER (p_table_name));
      v_sql :=
         REPLACE (v_sql,
                  '#GET_PK_BY_UNIQUE_COLS_FUNCTION#',
                  v_get_pk_by_unique_cols_spec);

      -- replace author and date metadata
      v_sql :=
         REPLACE (
            v_sql,
            '#AUTHOR#',
            UPPER (
               COALESCE (v ('APP_USER'), SYS_CONTEXT ('USERENV', 'OS_USER'))));

      v_sql :=
         REPLACE (v_sql,
                  '#CREATED_AT#',
                  TO_CHAR (SYSDATE, 'yyyy-mm-dd hh24:mi:ss'));

      RETURN v_sql;
   END generate_api_spec;

   FUNCTION generate_api_body (
      p_table_name                   IN VARCHAR2,
      p_table_abbreviation           IN VARCHAR2,
      p_enable_generic_logging       IN BOOLEAN DEFAULT FALSE,
      p_enable_deletion_of_records   IN BOOLEAN DEFAULT FALSE,
      p_col_prefix_in_method_names   IN BOOLEAN DEFAULT FALSE)
      RETURN CLOB
   IS
      v_pk                             user_tab_cols.column_name%TYPE;
      v_sql                            CLOB;

      -- get functions pro Tabellen-Attribut
      v_get_column_by_id_body          CLOB;

      -- set procedures pro Tabellen-Attribut
      v_set_column_by_id_body          CLOB;

      -- row_exists als function
      v_row_exists_func_body           CLOB;

      -- create als procedure und function (PK wird zurückgegeben)
      v_create_proc_body               CLOB;
      v_create_r_proc_body             CLOB;
      v_create_func_body               CLOB;

      -- update als procedure und function (PK wird zurückgegeben)
      v_update_proc_body               CLOB;
      v_update_r_proc_body             CLOB;
      v_update_func_body               CLOB;

      -- create or update als procedure und function (PK wird zurückgegeben)
      v_create_or_update_proc_body     CLOB;
      v_create_or_update_r_proc_body   CLOB;
      v_create_or_update_func_body     CLOB;

      -- Parameterlisten
      v_in_param_list                  CLOB;
      v_sorted_table_cols              CLOB;
      v_call_param_list                CLOB;
      v_value_param_list               CLOB;
      v_out_param_list                 CLOB;
      v_search_param_list              CLOB;
      v_set_param_list                 CLOB;
      v_read_param_list                CLOB;
      v_compare_param_list             CLOB;

      -- Fetch functions/procedures
      v_read_by_cols_func_body         CLOB;
      v_read_by_pk_func_body           CLOB;
      v_read_by_pk_and_fill_prc_bdy    CLOB;

      -- unique index get function
      v_get_pk_by_unique_cols_body     CLOB;
   BEGIN
      DBMS_LOB.createtemporary (lob_loc => v_sql, cache => FALSE);
      DBMS_LOB.createtemporary (lob_loc   => v_set_column_by_id_body,
                                cache     => FALSE);

      -- Template füllen
      DBMS_LOB.append (dest_lob => v_sql, src_lob => co_generate_api_body);

      -- Generisches Logging einschalten, falls konfiguriert
      v_sql :=
         REPLACE (
            v_sql,
            '#CREATE_CHANGE_LOG_ENTRY_BODY#',
            CASE
               WHEN p_enable_generic_logging THEN co_create_change_log_body
               ELSE NULL
            END);

      -- Löschen von Zeilen erlauben, falls konfiguriert
      v_sql :=
         REPLACE (
            v_sql,
            '#DELETE_PROCEDURE_BODY#',
            CASE
               WHEN p_enable_deletion_of_records
               THEN
                  REPLACE (
                     co_delete_proc_body,
                     '#CREATE_CHANGE_LOG_ENTRY#',
                     CASE
                        WHEN p_enable_generic_logging
                        THEN
                           co_delete_proc_change_log
                        ELSE
                           NULL
                     END)
               ELSE
                  NULL
            END);

      -- Ersetzungen im Template vornehmen
      v_sql := REPLACE (v_sql, '#TABLE_ABBREVIATION#', p_table_abbreviation);
      v_sql := REPLACE (v_sql, '#TABLE_NAME#', LOWER (p_table_name));

      -- PK ermitteln und ersetzen
      v_pk := get_table_key (p_table_name => UPPER (p_table_name));

      v_sql := REPLACE (v_sql, '#PK_COLUMN#', v_pk);

      -- Get Functions ermitteln und ersetzen
      v_get_column_by_id_body :=
         get_read_column_by_id_body (
            p_table_name                   => UPPER (p_table_name),
            p_table_abbreviation           => p_table_abbreviation,
            p_col_prefix_in_method_names   => p_col_prefix_in_method_names);

      v_sql :=
         REPLACE (v_sql, ' #GET_COLUMN_FUNCTIONS#', v_get_column_by_id_body);

      -- Set Procedures ermitteln und ersetzen
      DBMS_LOB.append (
         dest_lob   => v_set_column_by_id_body,
         src_lob    => get_set_column_by_id_body (
                         p_table_name                   => UPPER (p_table_name),
                         p_table_abbreviation           => p_table_abbreviation,
                         p_col_prefix_in_method_names   => p_col_prefix_in_method_names,
                         p_enable_generic_logging       => p_enable_generic_logging));

      v_sql :=
         lob.replace_clob (p_lob    => v_sql,
                           p_what   => '#SET_COLUMN_PROCEDURES#',
                           p_with   => v_set_column_by_id_body);

      --      v_sql                              := REPLACE( v_sql
      --                                                   , '#SET_COLUMN_PROCEDURES#'
      --                                                   , v_set_column_by_id_body );

      -- Parameterliste für Cursor ermitteln und erstzen
      v_in_param_list :=
         get_in_param_list (p_table_name => UPPER (p_table_name));

      v_sql := REPLACE (v_sql, '#IN_PARAMETER_LIST#', v_in_param_list);

      -- Parametersuchliste für Cursor ermitteln und erstzen
      v_search_param_list :=
         get_search_param_list (p_table_name => UPPER (p_table_name));

      v_sql := REPLACE (v_sql, '#PARAMETER_SEARCH_LIST#', v_search_param_list);

      -- Parameterliste für fetch_by_pk Function erstzen
      v_read_by_pk_func_body := co_get_by_pk_func_body;

      v_read_by_pk_func_body :=
         REPLACE (v_read_by_pk_func_body, '#PK_COLUMN#', v_pk);

      v_read_by_pk_func_body :=
         REPLACE (v_read_by_pk_func_body, '#TABLE_NAME#', p_table_name);

      v_read_by_pk_func_body :=
         REPLACE (v_read_by_pk_func_body,
                  '#TABLE_ABBREVIATION#',
                  p_table_abbreviation);

      v_sql :=
         REPLACE (v_sql, '#READ_BY_PK_FUNCTION#', v_read_by_pk_func_body);

      -- Parameterliste für v_fetchfill_procedure setzen
      v_read_by_pk_and_fill_prc_bdy := co_get_by_pk_and_fill_prc_bdy;

      v_read_by_pk_and_fill_prc_bdy :=
         REPLACE (v_read_by_pk_and_fill_prc_bdy, '#PK_COLUMN#', v_pk);

      v_read_by_pk_and_fill_prc_bdy :=
         REPLACE (v_read_by_pk_and_fill_prc_bdy,
                  '#TABLE_NAME#',
                  p_table_name);

      v_read_by_pk_and_fill_prc_bdy :=
         REPLACE (v_read_by_pk_and_fill_prc_bdy,
                  '#TABLE_ABBREVIATION#',
                  p_table_abbreviation);

      v_out_param_list :=
         get_out_param_list (p_table_name => UPPER (p_table_name));

      v_read_by_pk_and_fill_prc_bdy :=
         REPLACE (v_read_by_pk_and_fill_prc_bdy,
                  '#OUT_PARAMETER_LIST#',
                  v_out_param_list);

      v_read_param_list :=
         get_read_param_list (p_table_name           => UPPER (p_table_name),
                              p_table_abbreviation   => p_table_abbreviation);

      -- Füllen der OUT Parameter
      v_read_by_pk_and_fill_prc_bdy :=
         REPLACE (v_read_by_pk_and_fill_prc_bdy,
                  '#FETCH_PARAMETER_LIST#',
                  v_read_param_list);

      v_sql :=
         REPLACE (v_sql,
                  '#READ_BY_PK_AND_FILL_PROCEDURE#',
                  v_read_by_pk_and_fill_prc_bdy);

      -- Parameterliste für row_exists Function erstzen
      v_row_exists_func_body := co_row_exists_func_body;

      v_row_exists_func_body :=
         REPLACE (v_row_exists_func_body, '#TABLE_NAME#', p_table_name);

      v_row_exists_func_body :=
         REPLACE (v_row_exists_func_body, '#PK_COLUMN#', v_pk);

      v_sql :=
         REPLACE (v_sql, '#ROW_EXISTS_FUNCTION#', v_row_exists_func_body);

      -- Parameterliste für create Function erstzen
      v_create_func_body := co_create_func_body;

      -- Generisches Logging einschalten, falls konfiguriert
      IF p_enable_generic_logging
      THEN
         v_create_func_body :=
            REPLACE (
               v_create_func_body,
               '#CREATE_CHANGE_LOG_ENTRY#',
               get_create_change_log_list (
                  p_table_name   => UPPER (p_table_name)));
      ELSE
         v_create_func_body :=
            REPLACE (v_create_func_body, '#CREATE_CHANGE_LOG_ENTRY#', NULL);
      END IF;

      v_in_param_list :=
         get_in_param_list (p_table_name   => UPPER (p_table_name),
                            p_include_pk   => 'Y');

      -- default null für PK
      v_in_param_list :=
         REPLACE (
            v_in_param_list,
            ' IN ' || p_table_name || '.' || v_pk || '%TYPE',
            ' IN ' || p_table_name || '.' || v_pk || '%TYPE DEFAULT NULL');

      v_create_func_body :=
         REPLACE (v_create_func_body, '#IN_PARAMETER_LIST#', v_in_param_list);

      v_create_func_body :=
         REPLACE (v_create_func_body,
                  '#TABLE_ABBREVIATION#',
                  p_table_abbreviation);

      v_create_func_body :=
         REPLACE (v_create_func_body, '#TABLE_NAME#', LOWER (p_table_name));

      v_create_func_body := REPLACE (v_create_func_body, '#PK_COLUMN#', v_pk);

      v_value_param_list :=
         get_value_param_list (p_table_name => UPPER (p_table_name));

      v_create_func_body :=
         REPLACE (v_create_func_body,
                  '#ORDERED_PARAMETER_LIST#',
                  v_value_param_list);

      v_sorted_table_cols :=
         get_sorted_table_cols (p_table_name   => UPPER (p_table_name),
                                p_include_pk   => 'Y');

      v_create_func_body :=
         REPLACE (v_create_func_body,
                  '#ORDERED_COLUMN_LIST#',
                  v_sorted_table_cols);

      v_sql := REPLACE (v_sql, '#CREATE_FUNCTION#', v_create_func_body);

      -- Parameterliste für create Procedure erstzen
      v_create_proc_body := co_create_proc_body;

      v_in_param_list :=
         get_in_param_list (p_table_name   => UPPER (p_table_name),
                            p_include_pk   => 'Y');

      -- default null für PK
      v_in_param_list :=
         REPLACE (
            v_in_param_list,
            ' IN ' || p_table_name || '.' || v_pk || '%TYPE',
            ' IN ' || p_table_name || '.' || v_pk || '%TYPE DEFAULT NULL');

      v_call_param_list :=
         get_call_param_list (p_table_name   => UPPER (p_table_name),
                              p_include_pk   => 'Y');

      v_create_proc_body :=
         REPLACE (v_create_proc_body, '#IN_PARAMETER_LIST#', v_in_param_list);

      v_create_proc_body :=
         REPLACE (v_create_proc_body,
                  '#CALL_PARAMETER_LIST#',
                  v_call_param_list);

      v_create_proc_body :=
         REPLACE (v_create_proc_body,
                  '#TABLE_ABBREVIATION#',
                  p_table_abbreviation);

      v_create_proc_body :=
         REPLACE (v_create_proc_body, '#TABLE_NAME#', p_table_name);

      v_create_proc_body := REPLACE (v_create_proc_body, '#PK_COLUMN#', v_pk);

      v_sql := REPLACE (v_sql, '#CREATE_PROCEDURE#', v_create_proc_body);

      -- Parameterliste für create Rowtype Procedure erstzen
      v_create_r_proc_body := co_create_rowtype_proc_body;

      v_call_param_list :=
         get_rowtype_param_list (p_table_name   => UPPER (p_table_name),
                                 p_include_pk   => 'Y');

      v_create_r_proc_body :=
         REPLACE (v_create_r_proc_body,
                  '#CALL_PARAMETER_LIST#',
                  v_call_param_list);

      v_create_r_proc_body :=
         REPLACE (v_create_r_proc_body, '#TABLE_NAME#', p_table_name);

      v_sql :=
         REPLACE (v_sql, '#CREATE_ROWTYPE_PROCEDURE#', v_create_r_proc_body);

      -- Parameterliste für update Function erstzen
      v_update_func_body := co_update_func_body;

      v_in_param_list :=
         get_in_param_list (p_table_name   => UPPER (p_table_name),
                            p_include_pk   => 'Y');

      v_update_func_body :=
         REPLACE (v_update_func_body, '#IN_PARAMETER_LIST#', v_in_param_list);

      v_update_func_body :=
         REPLACE (v_update_func_body,
                  '#TABLE_ABBREVIATION#',
                  p_table_abbreviation);

      v_update_func_body :=
         REPLACE (v_update_func_body, '#TABLE_NAME#', p_table_name);

      v_update_func_body := REPLACE (v_update_func_body, '#PK_COLUMN#', v_pk);

      v_compare_param_list :=
         get_compare_param_list (
            p_table_name               => UPPER (p_table_name),
            p_enable_generic_logging   => p_enable_generic_logging);

      v_update_func_body :=
         REPLACE (v_update_func_body,
                  '#COLUMN_COMPARE_LIST#',
                  v_compare_param_list);

      v_set_param_list :=
         get_set_param_list (p_table_name => UPPER (p_table_name));

      v_update_func_body :=
         REPLACE (v_update_func_body, '#SET_LIST#', v_set_param_list);

      v_sql := REPLACE (v_sql, '#UPDATE_FUNCTION#', v_update_func_body);

      -- Parameterliste für update Procedure erstzen
      v_update_proc_body := co_update_proc_body;

      v_in_param_list :=
         get_in_param_list (p_table_name   => UPPER (p_table_name),
                            p_include_pk   => 'Y');

      v_update_proc_body :=
         REPLACE (v_update_proc_body, '#IN_PARAMETER_LIST#', v_in_param_list);

      v_call_param_list :=
         get_call_param_list (p_table_name   => UPPER (p_table_name),
                              p_include_pk   => 'Y');

      v_update_proc_body :=
         REPLACE (v_update_proc_body,
                  '#CALL_PARAMETER_LIST#',
                  v_call_param_list);

      v_update_proc_body :=
         REPLACE (v_update_proc_body,
                  '#TABLE_ABBREVIATION#',
                  p_table_abbreviation);

      v_update_proc_body :=
         REPLACE (v_update_proc_body, '#TABLE_NAME#', p_table_name);

      v_update_proc_body := REPLACE (v_update_proc_body, '#PK_COLUMN#', v_pk);

      v_sql := REPLACE (v_sql, '#UPDATE_PROCEDURE#', v_update_proc_body);

      -- Parameterliste für update Rowtype Procedure erstzen
      v_update_r_proc_body := co_update_rowtype_proc_body;

      v_call_param_list :=
         get_rowtype_param_list (p_table_name   => UPPER (p_table_name),
                                 p_include_pk   => 'Y');

      v_update_r_proc_body :=
         REPLACE (v_update_r_proc_body,
                  '#CALL_PARAMETER_LIST_WITH_PK#',
                  v_call_param_list);

      v_update_r_proc_body :=
         REPLACE (v_update_r_proc_body, '#TABLE_NAME#', p_table_name);

      v_sql :=
         REPLACE (v_sql, '#UPDATE_ROWTYPE_PROCEDURE#', v_update_r_proc_body);

      -- Parameterliste für create_or_update Function erstzen
      v_create_or_update_func_body := co_create_or_update_func_body;

      v_in_param_list :=
         get_in_param_list (p_table_name   => UPPER (p_table_name),
                            p_include_pk   => 'Y');

      v_create_or_update_func_body :=
         REPLACE (v_create_or_update_func_body,
                  '#IN_PARAMETER_LIST#',
                  v_in_param_list);

      --      v_create_or_update_func_body       := REPLACE( v_create_or_update_func_body
      --                                                   , '#TABLE_ABBREVIATION#'
      --                                                   , p_table_abbreviation );

      v_create_or_update_func_body :=
         REPLACE (v_create_or_update_func_body, '#TABLE_NAME#', p_table_name);

      v_create_or_update_func_body :=
         REPLACE (v_create_or_update_func_body, '#PK_COLUMN#', v_pk);

      v_call_param_list :=
         get_call_param_list (p_table_name   => UPPER (p_table_name),
                              p_include_pk   => 'Y');

      v_create_or_update_func_body :=
         REPLACE (v_create_or_update_func_body,
                  '#CALL_PARAMETER_LIST_WITH_PK#',
                  v_call_param_list);

      v_sql :=
         REPLACE (v_sql,
                  '#CREATE_OR_UPDATE_FUNCTION#',
                  v_create_or_update_func_body);

      -- Parameterliste für create_or_update Procedure erstzen
      v_create_or_update_proc_body := co_create_or_update_proc_body;

      v_in_param_list :=
         get_in_param_list (p_table_name   => UPPER (p_table_name),
                            p_include_pk   => 'Y');

      v_create_or_update_proc_body :=
         REPLACE (v_create_or_update_proc_body,
                  '#IN_PARAMETER_LIST#',
                  v_in_param_list);

      v_call_param_list :=
         get_call_param_list (p_table_name   => UPPER (p_table_name),
                              p_include_pk   => 'Y');

      v_create_or_update_proc_body :=
         REPLACE (v_create_or_update_proc_body,
                  '#CALL_PARAMETER_LIST_WITH_PK#',
                  v_call_param_list);

      v_create_or_update_proc_body :=
         REPLACE (v_create_or_update_proc_body, '#TABLE_NAME#', p_table_name);

      v_create_or_update_proc_body :=
         REPLACE (v_create_or_update_proc_body, '#PK_COLUMN#', v_pk);

      v_sql :=
         REPLACE (v_sql,
                  '#CREATE_OR_UPDATE_PROCEDURE#',
                  v_create_or_update_proc_body);

      -- Parameterliste für create_or_update Rowtype Procedure erstzen
      v_create_or_update_r_proc_body := co_create_or_update_r_proc_bod;

      v_call_param_list :=
         get_rowtype_param_list (p_table_name   => UPPER (p_table_name),
                                 p_include_pk   => 'Y');

      v_create_or_update_r_proc_body :=
         REPLACE (v_create_or_update_r_proc_body,
                  '#CALL_PARAMETER_LIST_WITH_PK#',
                  v_call_param_list);

      v_create_or_update_r_proc_body :=
         REPLACE (v_create_or_update_r_proc_body,
                  '#TABLE_NAME#',
                  p_table_name);

      v_sql :=
         REPLACE (v_sql,
                  '#CREATE_OR_UPDATE_ROWTYPE_PROCEDURE#',
                  v_create_or_update_r_proc_body);

      -- get_pk_by_unique_cols function
      v_get_pk_by_unique_cols_body :=
         get_get_pk_by_unique_cols_body (p_table_name => UPPER (p_table_name));
      v_sql :=
         REPLACE (v_sql,
                  '#GET_PK_BY_UNIQUE_COLS_FUNCTION#',
                  v_get_pk_by_unique_cols_body);
      RETURN v_sql;
   END generate_api_body;

   PROCEDURE generate_api (
      p_table_name                   IN VARCHAR2,
      p_directory                    IN VARCHAR2 DEFAULT NULL,
      p_enable_generic_logging       IN BOOLEAN DEFAULT FALSE,
      p_enable_deletion_of_records   IN BOOLEAN DEFAULT FALSE,
      p_col_prefix_in_method_names   IN BOOLEAN DEFAULT FALSE)
   IS
      v_table_name           VARCHAR2 (30);
      v_table_abbreviation   VARCHAR2 (30);
      v_cursor               NUMBER;
      v_count                PLS_INTEGER;
   BEGIN
      IF p_table_name IS NOT NULL
      THEN
         v_table_name := UPPER (p_table_name);
         v_table_abbreviation := get_table_column_prefix (v_table_name);

         IF v_table_abbreviation IS NOT NULL
         THEN
            IF p_enable_generic_logging
            THEN
               --> check for logging table

               SELECT COUNT (*)
                 INTO v_count
                 FROM user_tables
                WHERE table_name = 'GENERIC_CHANGE_LOG';

               IF v_count = 0
               THEN
                  model.add_column (
                     p_table_name       => 'generic_change_log',
                     p_column_name      => 'gcl_id',
                     p_data_type        => 'number',
                     p_length           => 20,
                     p_nullable         => FALSE,
                     p_column_comment   => 'Primary key of the table');
                  model.add_column (
                     p_table_name       => 'generic_change_log',
                     p_column_name      => 'gcl_table',
                     p_data_type        => 'varchar2',
                     p_length           => 30,
                     p_nullable         => FALSE,
                     p_column_comment   => 'Table on which the change occur');
                  model.add_column (
                     p_table_name       => 'generic_change_log',
                     p_column_name      => 'gcl_column',
                     p_data_type        => 'varchar2',
                     p_length           => 30,
                     p_nullable         => FALSE,
                     p_column_comment   => 'Column on which the change occur');
                  model.add_column (
                     p_table_name       => 'generic_change_log',
                     p_column_name      => 'gcl_pk_id',
                     p_data_type        => 'number',
                     p_length           => 20,
                     p_nullable         => FALSE,
                     p_column_comment   => 'We assume that the pk column of the changed table has a number type');
                  model.add_column (
                     p_table_name       => 'generic_change_log',
                     p_column_name      => 'gcl_old_value',
                     p_data_type        => 'varchar2',
                     p_length           => 4000,
                     p_column_comment   => 'The old value before the change');
                  model.add_column (
                     p_table_name       => 'generic_change_log',
                     p_column_name      => 'gcl_new_value',
                     p_data_type        => 'varchar2',
                     p_length           => 4000,
                     p_column_comment   => 'The new value after the change');
                  model.add_column (
                     p_table_name       => 'generic_change_log',
                     p_column_name      => 'gcl_user',
                     p_data_type        => 'varchar2',
                     p_length           => 20,
                     p_column_comment   => 'The user, who changed the data');
                  model.add_column (
                     p_table_name       => 'generic_change_log',
                     p_column_name      => 'gcl_timestamp',
                     p_data_type        => 'timestamp',
                     p_default          => 'systimestamp',
                     p_column_comment   => 'The time when the change occurs');
                  model.create_index (p_index_name   => 'gcl_pk_id_idx',
                                      p_table_name   => 'generic_change_log',
                                      p_columns      => 'gcl_pk_id');
               END IF;
            END IF;

            IF p_directory IS NOT NULL
            THEN
               -- install script
               DBMS_XSLPROCESSOR.clob2file (
                  generate_install_script (
                     p_table_abbreviation   => v_table_abbreviation),
                  p_directory,
                  v_table_abbreviation || '_1_INSTALL.sql');

               -- API spec
               DBMS_XSLPROCESSOR.clob2file (
                     generate_api_spec (
                        p_table_name                   => v_table_name,
                        p_table_abbreviation           => v_table_abbreviation,
                        p_enable_generic_logging       => p_enable_generic_logging,
                        p_enable_deletion_of_records   => p_enable_deletion_of_records,
                        p_col_prefix_in_method_names   => p_col_prefix_in_method_names)
                  || CHR (10)
                  || '/',
                  p_directory,
                  v_table_abbreviation || '_API.spc');

               -- API body
               DBMS_XSLPROCESSOR.clob2file (
                     generate_api_body (
                        p_table_name                   => v_table_name,
                        p_table_abbreviation           => v_table_abbreviation,
                        p_enable_generic_logging       => p_enable_generic_logging,
                        p_enable_deletion_of_records   => p_enable_deletion_of_records,
                        p_col_prefix_in_method_names   => p_col_prefix_in_method_names)
                  || CHR (10)
                  || '/',
                  p_directory,
                  v_table_abbreviation || '_API_BODY.bdy');
               /*
                -- synonym
                  DBMS_XSLPROCESSOR.clob2file( generate_synonym( p_table_name           => p_table_name
                                                               , p_table_abbreviation   => v_table_abbreviation )
                                             , p_directory
                                             , v_table_abbreviation || '_SYNONYM.sql' );
   */
               -- sequence
               DBMS_XSLPROCESSOR.clob2file (
                  generate_sequence (
                     p_table_name           => p_table_name,
                     p_table_abbreviation   => v_table_abbreviation),
                  p_directory,
                  v_table_abbreviation || '_SEQUENCE.sql');
            END IF;

            BEGIN
               DBMS_OUTPUT.put_line (
                  generate_sequence (
                     p_table_name           => p_table_name,
                     p_table_abbreviation   => v_table_abbreviation));

               execute_sql (
                  generate_sequence (
                     p_table_name           => p_table_name,
                     p_table_abbreviation   => v_table_abbreviation));

               execute_sql (
                  generate_api_spec (
                     p_table_name                   => v_table_name,
                     p_table_abbreviation           => v_table_abbreviation,
                     p_enable_generic_logging       => p_enable_generic_logging,
                     p_enable_deletion_of_records   => p_enable_deletion_of_records,
                     p_col_prefix_in_method_names   => p_col_prefix_in_method_names));

               execute_sql (
                  generate_api_body (
                     p_table_name                   => v_table_name,
                     p_table_abbreviation           => v_table_abbreviation,
                     p_enable_generic_logging       => p_enable_generic_logging,
                     p_enable_deletion_of_records   => p_enable_deletion_of_records,
                     p_col_prefix_in_method_names   => p_col_prefix_in_method_names));

               DBMS_OUTPUT.put_line (
                  generate_dml_view (p_table_name => v_table_name));
               execute_sql (generate_dml_view (p_table_name => v_table_name));

               DBMS_OUTPUT.put_line (
                  generate_dml_view_trigger (
                     p_table_name                   => v_table_name,
                     p_enable_deletion_of_records   => p_enable_deletion_of_records));

               execute_sql (
                  generate_dml_view_trigger (
                     p_table_name                   => v_table_name,
                     p_enable_deletion_of_records   => p_enable_deletion_of_records));
            EXCEPTION
               WHEN OTHERS
               THEN
                  PRINT (
                        'Error_Stack...'
                     || CHR (10)
                     || DBMS_UTILITY.format_error_stack
                     || 'Error_Backtrace...'
                     || CHR (10)
                     || DBMS_UTILITY.format_error_backtrace);
            END;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         PRINT (
               'Error_Stack...'
            || CHR (10)
            || DBMS_UTILITY.format_error_stack
            || 'Error_Backtrace...'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace);
         RAISE;
   END generate_api;

   PROCEDURE drop_object (p_object_type   IN VARCHAR2,
                          p_object_name   IN VARCHAR2)
   IS
      v_sql                   VARCHAR2 (1000);
      v_table_column_prefix   VARCHAR2 (30);
   BEGIN
      --> we have to save column prefix before we drop the table
      IF UPPER (p_object_type) = 'TABLE'
      THEN
         v_table_column_prefix := get_table_column_prefix (p_object_name);
      END IF;

      FOR i
         IN (SELECT DISTINCT object_type, object_name
               FROM user_objects
              WHERE     object_type NOT IN ('LOB', 'PACKAGE BODY')
                    AND object_type = UPPER (p_object_type)
                    AND object_name = UPPER (p_object_name))
      LOOP
         v_sql := 'DROP ' || i.object_type || ' ' || LOWER (i.object_name);
         PRINT (v_sql);

         EXECUTE IMMEDIATE v_sql;
      END LOOP;

      IF UPPER (p_object_type) = 'TABLE'
      THEN
         FOR i IN (SELECT *
                     FROM user_synonyms
                    WHERE synonym_name = UPPER (v_table_column_prefix))
         LOOP
            v_sql := 'DROP SYNONYM ' || LOWER (v_table_column_prefix);
            PRINT (v_sql);

            EXECUTE IMMEDIATE v_sql;
         END LOOP;

         FOR i IN (SELECT *
                     FROM user_sequences
                    WHERE sequence_name = UPPER (p_object_name) || '_SEQ')
         LOOP
            v_sql := 'DROP SEQUENCE ' || LOWER (p_object_name) || '_seq';
            PRINT (v_sql);

            EXECUTE IMMEDIATE v_sql;
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         PRINT (
               'Error_Stack...'
            || CHR (10)
            || DBMS_UTILITY.format_error_stack
            || 'Error_Backtrace...'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace);
         RAISE;
   END;

   PROCEDURE create_index (p_index_name   IN VARCHAR2,
                           p_table_name   IN VARCHAR2,
                           p_columns      IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (1000);
   BEGIN
      FOR i IN (SELECT UPPER (p_index_name) FROM DUAL
                MINUS
                SELECT index_name
                  FROM user_indexes
                 WHERE index_name = UPPER (p_index_name))
      LOOP
         v_sql :=
               'CREATE INDEX '
            || LOWER (p_index_name)
            || ' ON '
            || LOWER (p_table_name)
            || ' ('
            || LOWER (p_columns)
            || ')';

         PRINT (v_sql);

         EXECUTE IMMEDIATE v_sql;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         PRINT (
               'Error_Stack...'
            || CHR (10)
            || DBMS_UTILITY.format_error_stack
            || 'Error_Backtrace...'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace);
         RAISE;
   END;

   PROCEDURE add_constraint (
      p_table_name         IN VARCHAR2,
      p_constraint_name    IN VARCHAR2,
      p_constraint_type    IN VARCHAR2,
      p_pk_column_name     IN VARCHAR2 DEFAULT NULL,
      p_fk_column_name     IN VARCHAR2 DEFAULT NULL,
      p_fk_r_owner         IN VARCHAR2 DEFAULT NULL,
      p_fk_r_table_name    IN VARCHAR2 DEFAULT NULL,
      p_fk_r_column_name   IN VARCHAR2 DEFAULT NULL,
      p_fk_delete_rule     IN VARCHAR2 DEFAULT NULL,
      p_uq_columns         IN VARCHAR2 DEFAULT NULL,
      p_ck_condition       IN VARCHAR2 DEFAULT NULL,
      p_status             IN VARCHAR2 DEFAULT 'ENABLED')
   IS
      v_count   INTEGER;
      v_sql     VARCHAR2 (32000);
      v_error   VARCHAR2 (200);
   BEGIN
      SELECT COUNT (*)
        INTO v_count
        FROM user_tables t
       WHERE t.table_name = UPPER (p_table_name);

      IF v_count = 0
      THEN
         log_error ('Table ' || LOWER (p_table_name) || ' not existing');
      ELSE
         SELECT COUNT (*)
           INTO v_count
           FROM user_constraints t
          WHERE t.constraint_name = UPPER (p_constraint_name);

         IF v_count = 0
         THEN
            IF get_table_column_prefix (UPPER (p_table_name)) !=
                  get_column_prefix (UPPER (p_constraint_name))
            THEN
               log_error (
                     'Table column prefix and constraint prefix does not match for constraint name '
                  || LOWER (p_constraint_name));
            ELSE
               IF SUBSTR (UPPER (p_constraint_name), -2) !=
                     UPPER (p_constraint_type)
               THEN
                  log_error (
                        'Constraint suffix and constraint type does not match for constraint name '
                     || LOWER (p_constraint_name));
               ELSE
                  v_sql :=
                        'ALTER TABLE '
                     || LOWER (p_table_name)
                     || ' ADD CONSTRAINT '
                     || LOWER (p_constraint_name)
                     || CASE UPPER (p_constraint_type)
                           WHEN 'PK'
                           THEN
                                 ' PRIMARY KEY ('
                              || LOWER (p_pk_column_name)
                              || ')'
                           WHEN 'FK'
                           THEN
                                 ' FOREIGN KEY ('
                              || LOWER (p_fk_column_name)
                              || ') REFERENCES '
                              || CASE
                                    WHEN p_fk_r_owner IS NOT NULL
                                    THEN
                                       LOWER (p_fk_r_owner) || '.'
                                 END
                              || LOWER (p_fk_r_table_name)
                              || ' ('
                              || LOWER (p_fk_r_column_name)
                              || ')'
                           WHEN 'UQ'
                           THEN
                              ' UNIQUE (' || LOWER (p_uq_columns) || ')'
                           WHEN 'CK'
                           THEN
                              ' CHECK (' || p_ck_condition || ')'
                        END;

                  PRINT (v_sql);

                  EXECUTE IMMEDIATE v_sql;
               END IF;
            END IF;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         PRINT (
               'Error_Stack...'
            || CHR (10)
            || DBMS_UTILITY.format_error_stack
            || 'Error_Backtrace...'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace);
         RAISE;
   END;

   PROCEDURE add_column (p_table_name              IN VARCHAR2,
                         p_column_name             IN VARCHAR2,
                         p_data_type               IN VARCHAR2,
                         p_length                  IN INTEGER DEFAULT NULL,
                         p_decimal_places          IN INTEGER DEFAULT NULL,
                         p_default                 IN VARCHAR2 DEFAULT NULL,
                         p_nullable                IN BOOLEAN DEFAULT TRUE,
                         p_table_comment           IN VARCHAR2 DEFAULT NULL,
                         p_column_comment          IN VARCHAR2 DEFAULT NULL,
                         p_table_index_organized   IN BOOLEAN DEFAULT FALSE)
   IS
      v_count                      INTEGER;
      v_sql                        VARCHAR2 (32000);
      v_table_column_prefix        VARCHAR2 (100);
      v_fk_r_table_column_prefix   VARCHAR2 (100);
      v_fk_r_table_name            VARCHAR2 (100);
      v_sequence_max_value         VARCHAR2 (100);
      v_column_is_pk               BOOLEAN;
   BEGIN
      SELECT COUNT (*)
        INTO v_count
        FROM user_tables t
       WHERE t.table_name = UPPER (p_table_name);

      IF v_count = 1
      THEN
         v_table_column_prefix :=
            get_table_column_prefix (UPPER (p_table_name));
      ELSE
         v_table_column_prefix := get_column_prefix (UPPER (p_column_name));
      END IF;

      IF    v_table_column_prefix IS NULL
         OR v_table_column_prefix !=
               get_column_prefix (UPPER (p_column_name))
      THEN
         log_error (
               'Column prefix is not unique for '
            || LOWER (p_table_name)
            || '.'
            || LOWER (p_column_name));
      ELSIF LENGTH (p_table_name) > 25
      THEN
         log_error (
               'Table name '
            || LOWER (p_table_name)
            || ' is longer then 25 characters');
      ELSIF LENGTH (p_column_name) > 25
      THEN
         log_error (
               'Column name '
            || LOWER (p_column_name)
            || ' is longer then 25 characters');
      ELSE
         -----------------------------------------------------------------------
         -- create column (and table, if necessary)
         -----------------------------------------------------------------------

         --> check for primary key
         IF UPPER (p_column_name) = (v_table_column_prefix || '_ID')
         THEN
            IF    UPPER (p_data_type) = 'INTEGER'
               OR (    UPPER (p_data_type) = 'NUMBER'
                   AND NVL (p_length, 0) > 0
                   AND NVL (p_decimal_places, 0) = 0)
            THEN
               v_column_is_pk := TRUE;
            ELSE
               log_error (
                  'Your primary key should be of data type integer or number, length should be defined and decimal places should be null or zero');
            END IF;
         ELSE
            v_column_is_pk := FALSE;
         END IF;

         --> create column
         IF v_count = 0
         THEN
            v_sql := 'CREATE TABLE ' || LOWER (p_table_name) || ' ( ';
         ELSE
            v_sql := 'ALTER TABLE ' || LOWER (p_table_name) || ' ADD ( ';
         END IF;

         FOR i
            IN (                           --> This loop runs maximum one time
                SELECT UPPER (p_column_name) FROM DUAL
                MINUS
                SELECT t.column_name
                  FROM user_tab_cols t
                 WHERE     t.table_name = UPPER (p_table_name)
                       AND t.column_name = UPPER (p_column_name)
                       AND t.hidden_column = 'NO')
         LOOP
            v_sql :=
                  v_sql
               || LOWER (p_column_name)
               || ' '
               || UPPER (p_data_type)
               || CASE
                     WHEN UPPER (p_data_type) IN ('VARCHAR2', 'CHAR')
                     THEN
                        '(' || p_length || ' CHAR)'
                     WHEN UPPER (p_data_type) = 'NUMBER'
                     THEN
                        CASE
                           WHEN p_length IS NOT NULL
                           THEN
                                 '('
                              || p_length
                              || CASE
                                    WHEN p_decimal_places IS NOT NULL
                                    THEN
                                       ',' || p_decimal_places
                                 END
                              || ')'
                        END
                  END
               || CASE
                     WHEN p_default IS NOT NULL THEN ' DEFAULT ' || p_default
                  END
               || CASE
                     WHEN NOT p_nullable OR v_column_is_pk THEN ' NOT NULL'
                  END
               || CASE
                     WHEN v_column_is_pk
                     THEN
                           ', CONSTRAINT '
                        || LOWER (p_column_name)
                        || '_pk PRIMARY KEY('
                        || LOWER (p_column_name)
                        || ')'
                  END
               || ')'
               || CASE
                     WHEN p_table_index_organized THEN ' ORGANIZATION INDEX'
                  END;

            PRINT (v_sql);

            EXECUTE IMMEDIATE v_sql;

            --------------------------------------------------------------------
            -- create synonym
            --------------------------------------------------------------------

            --            IF v_count = 0 THEN
            --               v_sql      :=    'CREATE SYNONYM '
            --                             || LOWER( v_table_column_prefix )
            --                             || ' FOR '
            --                             || LOWER( p_table_name );
            --
            --               PRINT( v_sql );
            --
            --               EXECUTE IMMEDIATE v_sql;
            --            END IF;

            --------------------------------------------------------------------
            -- create sequence
            --------------------------------------------------------------------
            IF v_column_is_pk
            THEN
               FOR i
                  IN (SELECT UPPER (p_table_name) || '_SEQ' AS sequence_name
                        FROM DUAL
                      MINUS
                      SELECT sequence_name FROM user_sequences)
               LOOP
                  v_sql := '
            CREATE SEQUENCE ' || i.sequence_name || '
            MINVALUE 0 
            MAXVALUE 999999999999999999999999999 
            INCREMENT BY 1 
            START WITH 1 
            NOCACHE
            NOORDER
            NOCYCLE ';

                  PRINT (v_sql);

                  EXECUTE IMMEDIATE v_sql;
               END LOOP;
            END IF;

            --------------------------------------------------------------------
            -- create foreign key
            --------------------------------------------------------------------

            --> check substring after second underscore --> if like "_ID" we have a foreign key constraint
            IF SUBSTR (UPPER (p_column_name),
                       INSTR (p_column_name,
                              '_',
                              1,
                              2)) LIKE
                  '%\_ID' ESCAPE '\'
            THEN
               --> get substring before "_ID"
               v_fk_r_table_column_prefix :=
                  CASE
                     WHEN INSTR (p_column_name,
                                 '_',
                                 -1,
                                 2) = 0
                     THEN
                        NULL
                     ELSE
                        RTRIM (RTRIM (SUBSTR (UPPER (p_column_name),
                                                INSTR (p_column_name,
                                                       '_',
                                                       -1,
                                                       2)
                                              + 1),
                                      'ID'),
                               '_')
                  END;

               IF v_fk_r_table_column_prefix IS NOT NULL
               THEN
                  --> check, if table is existing with this column prefix

                  v_count := 0;

                  FOR i
                     IN (WITH t1
                              AS (SELECT object_name
                                    FROM user_objects
                                   WHERE     object_type = 'TABLE'
                                         -- exclude history tables created by history_pkg
                                         AND object_name NOT LIKE
                                                '%\_H' ESCAPE '\'),
                              t2
                              AS (SELECT DISTINCT
                                         table_name,
                                         SUBSTR (
                                            column_name,
                                            1,
                                            INSTR (column_name, '_', 1) - 1)
                                            column_prefix
                                    FROM user_tab_columns
                                         JOIN t1
                                            ON user_tab_columns.table_name =
                                                  t1.object_name
                                   -- exclude history tables created by history_pkg
                                   WHERE user_tab_columns.table_name NOT LIKE
                                            '%\_H' ESCAPE '\')
                         SELECT *
                           FROM t2
                          WHERE column_prefix =
                                   UPPER (v_fk_r_table_column_prefix))
                  LOOP
                     v_count := v_count + 1;

                     v_fk_r_table_name := i.table_name;

                     IF v_count > 1
                     THEN
                        log_warning (
                              'Unable to identify referential table for foreign key - more then one table in your model using the column prefix '
                           || v_fk_r_table_column_prefix);
                     END IF;

                     IF v_count = 1
                     THEN
                        add_constraint (
                           p_table_name         => UPPER (p_table_name),
                           p_constraint_name    => p_column_name || '_FK',
                           p_constraint_type    => 'FK',
                           p_fk_column_name     => p_column_name,
                           p_fk_r_table_name    => v_fk_r_table_name,
                           p_fk_r_column_name   =>    v_fk_r_table_column_prefix
                                                   || '_ID');

                        create_index (
                           p_index_name   => p_column_name || '_IDX',
                           p_table_name   => UPPER (p_table_name),
                           p_columns      => p_column_name);
                     END IF;
                  END LOOP;
               END IF;
            END IF;

            --------------------------------------------------------------------
            -- create comments
            --------------------------------------------------------------------

            IF p_table_comment IS NOT NULL
            THEN
               v_sql :=
                     'COMMENT ON TABLE '
                  || p_table_name
                  || ' IS '''
                  || p_table_comment
                  || '''';
               PRINT (v_sql);

               EXECUTE IMMEDIATE v_sql;
            END IF;

            IF p_column_comment IS NOT NULL
            THEN
               v_sql :=
                     'COMMENT ON COLUMN '
                  || p_table_name
                  || '.'
                  || p_column_name
                  || ' IS '''
                  || p_column_comment
                  || '''';
               PRINT (v_sql);

               EXECUTE IMMEDIATE v_sql;
            END IF;
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         PRINT (
               'Error_Stack...'
            || CHR (10)
            || DBMS_UTILITY.format_error_stack
            || 'Error_Backtrace...'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace);
         RAISE;
   END;
END model;
/