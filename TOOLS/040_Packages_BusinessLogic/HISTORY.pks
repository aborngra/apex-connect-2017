--------------------------------------------------------------------------------
-- SPECIFICATION
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE history
   AUTHID CURRENT_USER
IS
   -----------------------------------------------------------------------------
   -- global package variables
   -----------------------------------------------------------------------------
   TYPE type_columns_table IS TABLE OF user_tab_cols%ROWTYPE
      INDEX BY BINARY_INTEGER;

   g_columns_table                  type_columns_table;
   g_columns_table_to_add           type_columns_table;
   g_columns_table_to_modify        type_columns_table;

   g_columns_list_pure              VARCHAR2 (32667 CHAR);
   g_columns_list_new               VARCHAR2 (32667 CHAR);
   g_columns_list_old               VARCHAR2 (32667 CHAR);
   g_columns_definition             VARCHAR2 (32667 CHAR);
   g_columns_definition_to_add      VARCHAR2 (32667 CHAR);
   g_columns_definition_to_modify   VARCHAR2 (32667 CHAR);

   g_table_name                     user_tables.table_name%TYPE;

   -----------------------------------------------------------------------------
   -- global package cursor
   -----------------------------------------------------------------------------
   CURSOR g_cur_columns
   IS
        SELECT *
          FROM user_tab_cols
         WHERE     table_name = UPPER (g_table_name)
               AND data_type NOT IN ('BLOB',
                                     'CLOB',
                                     'NCLOB',
                                     'BFILE')
      ORDER BY column_id;

   CURSOR g_cur_columns_add
   IS
      SELECT *
        FROM user_tab_cols
       WHERE     table_name = UPPER (g_table_name)
             AND data_type NOT IN ('BLOB',
                                   'CLOB',
                                   'NCLOB',
                                   'BFILE')
             AND column_name NOT IN
                    (SELECT column_name
                       FROM user_tab_cols
                      WHERE table_name = UPPER (g_table_name || '_H'));

   CURSOR g_cur_columns_modify
   IS
      WITH orig_table
           AS (SELECT *
                 FROM user_tab_cols
                WHERE     table_name = UPPER (g_table_name)
                      AND data_type NOT IN ('BLOB',
                                            'CLOB',
                                            'NCLOB',
                                            'BFILE')),
           h_table
           AS (SELECT *
                 FROM user_tab_cols
                WHERE table_name = UPPER (g_table_name) || '_H')
      SELECT orig_table.*
        FROM orig_table
             JOIN h_table ON orig_table.column_name = h_table.column_name
       WHERE    orig_table.data_type <> h_table.data_type
             OR orig_table.data_length <> h_table.data_length
             OR orig_table.data_precision <> h_table.data_precision
             OR orig_table.data_scale <> h_table.data_scale
             OR orig_table.char_used <> h_table.char_used;

   -----------------------------------------------------------------------------
   -- specification of public procedures / functions
   -----------------------------------------------------------------------------
   PROCEDURE enable_versioning (p_table_name IN user_tables.table_name%TYPE);
END history;
/