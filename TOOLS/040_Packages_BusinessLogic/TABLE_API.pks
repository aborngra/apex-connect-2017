CREATE OR REPLACE PACKAGE table_api
   AUTHID CURRENT_USER
/*
# ToDo's
* ist die durchgehende nutzung von p_test_id default null ok? auch bei updates?
* test really long table name
* test really long column name
--
BEGIN
tools.table_api.generate_table_api( p_table_name => 'TEST_MODEL'
, p_enable_generic_logging     => FALSE
, p_enable_deletion_of_records => TRUE
, p_col_prefix_in_method_names => TRUE );
END;
--
BEGIN
tools.model_pkg.generate_api( p_table_name => 'TEST_MODEL'
, p_enable_generic_logging     => FALSE
, p_enable_deletion_of_records => TRUE
, p_col_prefix_in_method_names => TRUE );
END;
*/
IS
   --------------------------------------------------------------------------------
   TYPE columns_rowtype IS RECORD
   (
      column_name      user_tab_columns.column_name%TYPE,
      column_name_26   user_tab_columns.column_name%TYPE,
      column_name_28   user_tab_columns.column_name%TYPE,
      data_type        user_tab_cols.data_type%TYPE
   );

   --------------------------------------------------------------------------------
   TYPE columns_tabtype IS TABLE OF columns_rowtype
      INDEX BY BINARY_INTEGER;

   --------------------------------------------------------------------------------
   TYPE tapi_options_rectype IS RECORD
   (
      enable_generic_logging       BOOLEAN,
      enable_deletion_of_records   BOOLEAN,
      col_prefix_in_method_names   BOOLEAN,
      delimiter                    VARCHAR2 (2 CHAR),
      xmltype_column_present       BOOLEAN
   );

   --------------------------------------------------------------------------------
   TYPE tapi_collections_rectype IS RECORD
   (
      table_columns   columns_tabtype
   );

   --------------------------------------------------------------------------------
   TYPE tapi_substitutions_rectype IS RECORD
   (
      created_by                       VARCHAR2 (100),
      created_on                       VARCHAR2 (20),
      table_name                       user_tables.table_name%TYPE,
      table_name_h                     user_tables.table_name%TYPE,
      table_name_24                    user_tables.table_name%TYPE,
      table_name_26                    user_tables.table_name%TYPE,
      table_column_prefix              user_tables.table_name%TYPE,
      table_pk                         user_tab_cols.column_name%TYPE,
      table_pk_28                      user_tab_cols.column_name%TYPE,
      sequence_name                    user_sequences.sequence_name%TYPE,
      delete_or_throw_exception        VARCHAR2 (200 CHAR),
      i_column_name                    user_tab_cols.column_name%TYPE,
      i_column_name_26                 user_tab_cols.column_name%TYPE,
      i_column_name_28                 user_tab_cols.column_name%TYPE,
      i_column_compare                 VARCHAR2 (500 CHAR),
      i_column_compare_list_unique     VARCHAR2 (32767 CHAR),
      i_param_list_unique              VARCHAR2 (32767 CHAR),
      column_compare_list_wo_pk        VARCHAR2 (32767 CHAR),
      column_list_w_pk                 VARCHAR2 (32767 CHAR),
      param_list_wo_pk                 VARCHAR2 (32767 CHAR),
      param_definition_w_pk            VARCHAR2 (32767 CHAR),
      param_io_definition_w_pk         VARCHAR2 (32767 CHAR),
      map_new_to_param_w_pk            VARCHAR2 (32767 CHAR),
      map_param_to_param_w_pk          VARCHAR2 (32767 CHAR),
      map_rowtype_col_to_param_w_pk    VARCHAR2 (32767 CHAR),
      set_param_to_column_wo_pk        VARCHAR2 (32767 CHAR),
      set_rowtype_col_to_param_wo_pk   VARCHAR2 (32767 CHAR)
   );

   --------------------------------------------------------------------------------
   TYPE tapi_code_rectype IS RECORD
   (
      template                 VARCHAR2 (32767 CHAR),
      api_spec                 CLOB,
      api_spec_varchar_cache   VARCHAR2 (32767 CHAR),
      api_body                 CLOB,
      api_body_varchar_cache   VARCHAR2 (32767 CHAR),
      dml_view                 VARCHAR2 (32767 CHAR),
      dml_view_trigger         VARCHAR2 (32767 CHAR)
   );

   --------------------------------------------------------------------------------
   TYPE global_package_vars IS RECORD
   (
      OPTIONS         tapi_options_rectype,
      collections     tapi_collections_rectype,
      substitutions   tapi_substitutions_rectype,
      code            tapi_code_rectype
   );

   g   global_package_vars;

   --------------------------------------------------------------------------------
   CURSOR g_cur_table_exists
   IS
      SELECT table_name
        FROM user_tables
       WHERE LOWER (table_name) = g.substitutions.table_name;

   --------------------------------------------------------------------------------
   CURSOR g_cur_sequence_exists
   IS
      SELECT sequence_name
        FROM user_sequences
       WHERE LOWER (sequence_name) = LOWER (g.substitutions.sequence_name);

   --------------------------------------------------------------------------------
   CURSOR g_cur_history_table (p_table_name IN user_tables.table_name%TYPE)
   IS
      SELECT LOWER (table_name) AS table_name
        FROM user_tables
       WHERE LOWER (table_name) = LOWER (g.substitutions.table_name || '_h');

   --------------------------------------------------------------------------------
   CURSOR g_cur_columns
   IS
        SELECT LOWER (column_name) AS column_name,
               NULL AS column_name_26,
               NULL AS column_name_28,
               data_type
          FROM user_tab_cols
         WHERE     LOWER (table_name) = LOWER (g.substitutions.table_name)
               AND hidden_column = 'NO'
      ORDER BY column_id;

   --------------------------------------------------------------------------------
   PROCEDURE generate_table_api (
      p_table_name                   IN user_tables.table_name%TYPE,
      p_sequence_name                IN user_sequences.sequence_name%TYPE DEFAULT NULL,
      p_enable_generic_logging       IN BOOLEAN DEFAULT FALSE,
      p_enable_deletion_of_records   IN BOOLEAN DEFAULT FALSE,
      p_col_prefix_in_method_names   IN BOOLEAN DEFAULT FALSE);
--------------------------------------------------------------------------------
END table_api;