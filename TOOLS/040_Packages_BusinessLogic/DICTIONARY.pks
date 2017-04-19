---------------------------------------------------------------------------------------
-- SPECIFICATION
---------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE dictionary
  AUTHID CURRENT_USER
IS
  CURSOR g_cur_table_prefix
  IS
    WITH schema_tables
         AS (  SELECT *
                 FROM user_tables
                WHERE table_name NOT LIKE '%\_H' ESCAPE '\')
       , table_pks
         AS (  SELECT c.table_name, c.constraint_name, cc.column_name
                 FROM user_constraints c
                      JOIN user_cons_columns cc
                        ON     c.table_name = cc.table_name
                           AND c.constraint_name = cc.constraint_name
                WHERE constraint_type = 'P')
      SELECT tab.table_name
           , SUBSTR( pk.column_name, 1, INSTR( pk.column_name, '_' ) - 1 )
               AS table_prefix
        FROM schema_tables tab
             LEFT JOIN table_pks pk ON tab.table_name = pk.table_name;

  TYPE g_cur_table_prefix_tab IS TABLE OF g_cur_table_prefix%ROWTYPE;

  FUNCTION get_column_datatype( p_schema      IN all_tab_cols.owner%TYPE DEFAULT USER
                              , p_table_name  IN all_tab_cols.table_name%TYPE
                              , p_column_name IN all_tab_cols.table_name%TYPE )
    RETURN user_tab_cols.data_type%TYPE;

  FUNCTION get_constraint_column_list( p_schema          IN all_cons_columns.owner%TYPE DEFAULT USER
                                     , p_constraint_name IN all_cons_columns.constraint_name%TYPE
                                     , p_delimiter       IN VARCHAR2 DEFAULT ', ' )
    RETURN VARCHAR2;

  FUNCTION get_constraint_column_table( p_schema          IN all_cons_columns.owner%TYPE DEFAULT USER
                                      , p_constraint_name IN all_cons_columns.constraint_name%TYPE )
    RETURN t_str_array
    PIPELINED;

  FUNCTION get_column_surrogate( p_schema      IN all_tab_cols.owner%TYPE DEFAULT USER
                               , p_table_name  IN all_tab_cols.table_name%TYPE
                               , p_column_name IN all_tab_cols.table_name%TYPE )
    RETURN VARCHAR2;

  FUNCTION get_column_coalesce( p_schema              IN all_tab_cols.owner%TYPE DEFAULT USER
                              , p_table_name          IN all_tab_cols.table_name%TYPE
                              , p_column_name         IN all_tab_cols.table_name%TYPE
                              , p_left_coalesce_side  IN VARCHAR2
                              , p_right_coalesce_side IN VARCHAR2
                              , p_compare_operation   IN VARCHAR2 DEFAULT '<>' )
    RETURN VARCHAR2;

  FUNCTION get_table_key( p_table_name IN user_tables.table_name%TYPE
                        , p_key_type   IN user_constraints.constraint_type%TYPE DEFAULT 'P'
                        , p_delimiter  IN VARCHAR2 DEFAULT ', ' )
    RETURN VARCHAR2;

  PROCEDURE adapt_sequence_value( p_sequence_name IN user_sequences.sequence_name%TYPE
                                , p_table_name    IN user_tables.table_name%TYPE
                                , p_pk_column     IN user_tab_cols.column_name%TYPE );

  FUNCTION get_long_search_condition( p_constraint_name IN VARCHAR2 )
    RETURN VARCHAR2;

  PROCEDURE manage_constraint_names( p_table_name         IN user_constraints.table_name%TYPE
                                   , p_primary_key_naming IN user_constraints.constraint_name%TYPE DEFAULT '#TABLE_NAME#_PK'
                                   , p_foreign_key_naming IN user_constraints.constraint_name%TYPE DEFAULT '#TABLE_NAME#_FK'
                                   , p_not_null_naming    IN user_constraints.constraint_name%TYPE DEFAULT '#TABLE_NAME#_NN'
                                   , p_check_naming       IN user_constraints.constraint_name%TYPE DEFAULT '#TABLE_NAME#_CK'
                                   , p_unique_naming      IN user_constraints.constraint_name%TYPE DEFAULT '#TABLE_NAME#_UQ' );

  PROCEDURE rename_constraint( p_table_name              IN user_constraints.table_name%TYPE
                             , p_constraint_name_current IN user_constraints.constraint_name%TYPE
                             , p_constraint_name_new     IN user_constraints.constraint_name%TYPE );

  PROCEDURE rename_index( p_index_name_current IN user_indexes.index_name%TYPE
                        , p_index_name_new     IN user_indexes.index_name%TYPE );

  FUNCTION get_table_prefixes
    RETURN g_cur_table_prefix_tab
    PIPELINED;
END dictionary;
/