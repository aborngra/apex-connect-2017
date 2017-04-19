--------------------------------------------------------------------------------
-- IMPLEMENTATION
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY history
IS
   PROCEDURE create_history_sequences
   IS
   BEGIN
      FOR i IN (SELECT 'HISTORY_TRANSACTION_SEQ' AS sequence_name FROM DUAL
                UNION ALL
                SELECT 'HISTORY_CHANGE_SEQ' AS sequence_name FROM DUAL
                MINUS
                SELECT sequence_name FROM user_sequences)
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
   END create_history_sequences;

   PROCEDURE create_transaction_temp_table
   IS
   BEGIN
      FOR i IN (SELECT 'GLOBAL_TEMP_TRANSACTION' AS table_name FROM DUAL
                MINUS
                SELECT table_name FROM user_tables)
      LOOP
         EXECUTE IMMEDIATE
            ' CREATE GLOBAL TEMPORARY TABLE ' || i.table_name || ' 
                 ( 
                    transaction_id NUMBER 
                 )
                 ON COMMIT DELETE ROWS';
      END LOOP;
   END create_transaction_temp_table;

   PROCEDURE create_history_table
   IS
      v_current_month                DATE := TRUNC (SYSDATE, 'MM');
      v_create_hist_table_template   VARCHAR2 (32667 CHAR)
         := q'[
             CREATE TABLE #TABLE_NAME_28_CHAR#_H                 
             (  
               "VERSION_IS_ACTIVE_YN"   VARCHAR2( 1 CHAR )  CONSTRAINT #TABLE_NAME_23_CHAR#_H_NN01 NOT NULL
             , "VERSION_TRANSACTION_ID" NUMBER              CONSTRAINT #TABLE_NAME_23_CHAR#_H_NN02 NOT NULL
             , "VERSION_CHANGE_ID"      NUMBER              CONSTRAINT #TABLE_NAME_23_CHAR#_H_NN03 NOT NULL
             , "VERSION_OPERATION"      VARCHAR2( 1 CHAR )  CONSTRAINT #TABLE_NAME_23_CHAR#_H_NN04 NOT NULL
             , "VERSION_VALID_FROM"     TIMESTAMP           CONSTRAINT #TABLE_NAME_23_CHAR#_H_NN05 NOT NULL
             , "VERSION_VALID_TO"       TIMESTAMP           CONSTRAINT #TABLE_NAME_23_CHAR#_H_NN06 NOT NULL
             , "VERSION_IS_DELETED_YN"  VARCHAR2( 1 CHAR )  CONSTRAINT #TABLE_NAME_23_CHAR#_H_NN07 NOT NULL
             , "VERSION_MANIPULATED_AT" DATE                CONSTRAINT #TABLE_NAME_23_CHAR#_H_NN08 NOT NULL
             , "VERSION_MANIPULATED_BY" VARCHAR2( 32 CHAR ) CONSTRAINT #TABLE_NAME_23_CHAR#_H_NN09 NOT NULL
             , #COLUMN_DEFINITION#
             , CONSTRAINT #TABLE_NAME_23_CHAR#_H_CK01 CHECK( version_operation IN ('I', 'U', 'D') )
             , CONSTRAINT #TABLE_NAME_23_CHAR#_H_CK02 CHECK( version_is_active_yn IN ('Y', 'N') )
             , CONSTRAINT #TABLE_NAME_23_CHAR#_H_CK03 CHECK( version_valid_from <= version_valid_to )
             , CONSTRAINT #TABLE_NAME_23_CHAR#_H_CK04 CHECK( version_is_deleted_yn IN ('Y', 'N') )
             , CONSTRAINT #TABLE_NAME_23_CHAR#_H_PK   PRIMARY KEY
                            ( "#PK_COLUMN#", "VERSION_IS_ACTIVE_YN", "VERSION_VALID_FROM" )
             )
             PARTITION BY RANGE (version_valid_from)
             INTERVAL(NUMTOYMINTERVAL(1, 'MONTH'))
             ( 
               PARTITION "P_#DATE_01#" VALUES LESS THAN (TO_DATE('#DATE_01#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_02#" VALUES LESS THAN (TO_DATE('#DATE_02#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_03#" VALUES LESS THAN (TO_DATE('#DATE_03#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_04#" VALUES LESS THAN (TO_DATE('#DATE_04#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_05#" VALUES LESS THAN (TO_DATE('#DATE_05#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_06#" VALUES LESS THAN (TO_DATE('#DATE_06#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_07#" VALUES LESS THAN (TO_DATE('#DATE_07#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_08#" VALUES LESS THAN (TO_DATE('#DATE_08#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_09#" VALUES LESS THAN (TO_DATE('#DATE_09#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_10#" VALUES LESS THAN (TO_DATE('#DATE_10#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_11#" VALUES LESS THAN (TO_DATE('#DATE_11#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_12#" VALUES LESS THAN (TO_DATE('#DATE_12#', 'YYYY-MM-DD')),    
               PARTITION "P_#DATE_13#" VALUES LESS THAN (TO_DATE('#DATE_13#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_14#" VALUES LESS THAN (TO_DATE('#DATE_14#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_15#" VALUES LESS THAN (TO_DATE('#DATE_15#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_16#" VALUES LESS THAN (TO_DATE('#DATE_16#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_17#" VALUES LESS THAN (TO_DATE('#DATE_17#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_18#" VALUES LESS THAN (TO_DATE('#DATE_18#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_19#" VALUES LESS THAN (TO_DATE('#DATE_19#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_20#" VALUES LESS THAN (TO_DATE('#DATE_20#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_21#" VALUES LESS THAN (TO_DATE('#DATE_21#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_22#" VALUES LESS THAN (TO_DATE('#DATE_22#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_23#" VALUES LESS THAN (TO_DATE('#DATE_23#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_24#" VALUES LESS THAN (TO_DATE('#DATE_24#', 'YYYY-MM-DD')),      
               PARTITION "P_#DATE_25#" VALUES LESS THAN (TO_DATE('#DATE_25#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_26#" VALUES LESS THAN (TO_DATE('#DATE_26#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_27#" VALUES LESS THAN (TO_DATE('#DATE_27#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_28#" VALUES LESS THAN (TO_DATE('#DATE_28#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_29#" VALUES LESS THAN (TO_DATE('#DATE_29#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_30#" VALUES LESS THAN (TO_DATE('#DATE_30#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_31#" VALUES LESS THAN (TO_DATE('#DATE_31#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_32#" VALUES LESS THAN (TO_DATE('#DATE_32#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_33#" VALUES LESS THAN (TO_DATE('#DATE_33#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_34#" VALUES LESS THAN (TO_DATE('#DATE_34#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_35#" VALUES LESS THAN (TO_DATE('#DATE_35#', 'YYYY-MM-DD')),
               PARTITION "P_#DATE_36#" VALUES LESS THAN (TO_DATE('#DATE_36#', 'YYYY-MM-DD'))                
             )
             ]';
   BEGIN
      -- replace the table_name
      v_create_hist_table_template :=
         REPLACE (v_create_hist_table_template,
                  '#TABLE_NAME_28_CHAR#',
                  SUBSTR (g_table_name, 1, 28));

      -- replace the substr_table_name for constraint_names
      v_create_hist_table_template :=
         REPLACE (v_create_hist_table_template,
                  '#TABLE_NAME_23_CHAR#',
                  SUBSTR (g_table_name, 1, 23));

      -- replace the primary key column
      v_create_hist_table_template :=
         REPLACE (v_create_hist_table_template,
                  '#PK_COLUMN#',
                  g_columns_table (1).column_name);

      -- replace the column definitions
      v_create_hist_table_template :=
         REPLACE (v_create_hist_table_template,
                  '#COLUMN_DEFINITION#',
                  g_columns_definition);

      -- add 36 partitions for the next 3 years from now
      FOR months IN 1 .. 36
      LOOP
         v_create_hist_table_template :=
            REPLACE (
               v_create_hist_table_template,
               '#DATE_' || TO_CHAR (months, 'FM09') || '#',
               TO_CHAR (ADD_MONTHS (v_current_month, months - 1),
                        'YYYY-MM-DD'));
      END LOOP;

      DBMS_OUTPUT.put_line (v_create_hist_table_template);

      EXECUTE IMMEDIATE v_create_hist_table_template;
   END create_history_table;

   PROCEDURE alter_history_table_add_col
   IS
      v_alter_hist_table_template   VARCHAR2 (32667 CHAR) := q'[
              ALTER TABLE #TABLE_NAME_28_CHAR#_H ADD                
              ( 
                #COLUMN_DEFINITION#
              )
             ]';
   BEGIN
      -- _H table already exists, create ALTER TABLE ADD COLUMN statement
      v_alter_hist_table_template :=
         REPLACE (v_alter_hist_table_template,
                  '#TABLE_NAME_28_CHAR#',
                  SUBSTR (g_table_name, 1, 28));

      v_alter_hist_table_template :=
         REPLACE (v_alter_hist_table_template,
                  '#COLUMN_DEFINITION#',
                  g_columns_definition_to_add);

      IF (g_columns_definition_to_add IS NOT NULL)
      THEN
         DBMS_OUTPUT.put_line (v_alter_hist_table_template);

         EXECUTE IMMEDIATE v_alter_hist_table_template;
      END IF;
   END alter_history_table_add_col;

   PROCEDURE alter_history_table_modify_col
   IS
      v_alter_hist_table_template   VARCHAR2 (32667 CHAR) := q'[
              ALTER TABLE #TABLE_NAME_28_CHAR#_H MODIFY                
              ( 
                #COLUMN_DEFINITION#
              )
             ]';
   BEGIN
      -- _H table already exists, create ALTER TABLE MODIFY COLUMN statement
      v_alter_hist_table_template :=
         REPLACE (v_alter_hist_table_template,
                  '#TABLE_NAME_28_CHAR#',
                  SUBSTR (g_table_name, 1, 28));

      v_alter_hist_table_template :=
         REPLACE (v_alter_hist_table_template,
                  '#COLUMN_DEFINITION#',
                  g_columns_definition_to_modify);

      IF (g_columns_definition_to_modify IS NOT NULL)
      THEN
         DBMS_OUTPUT.put_line (v_alter_hist_table_template);

         EXECUTE IMMEDIATE v_alter_hist_table_template;
      END IF;
   END alter_history_table_modify_col;

   PROCEDURE create_history_trigger
   IS
      v_history_trigger_template   VARCHAR2 (32667 CHAR)
         := q'[
CREATE OR REPLACE TRIGGER #TABLE_NAME_25_CHAR#_AIUD
   AFTER INSERT OR UPDATE OR DELETE
   ON #TABLE_NAME#
   FOR EACH ROW
DECLARE
   v_timestamp      TIMESTAMP;
   v_user           VARCHAR2 (32 CHAR);

   CURSOR cur_transaction_id
   IS
      SELECT transaction_id FROM global_temp_transaction;
   v_transaction_id NUMBER;
BEGIN
   v_timestamp := SYSTIMESTAMP;
   v_user := UPPER(COALESCE (v ('APP_USER'), SYS_CONTEXT ('USERENV', 'OS_USER'), USER));

   -----------------------------------------------------------------------------
   -- Take existing TRANSACTION_ID or create a new one
   -----------------------------------------------------------------------------
   OPEN cur_transaction_id;

   FETCH cur_transaction_id INTO v_transaction_id;

   CLOSE cur_transaction_id;

   IF (v_transaction_id IS NULL) THEN
      v_transaction_id := history_transaction_seq.NEXTVAL;

      INSERT INTO global_temp_transaction (transaction_id)
           VALUES (v_transaction_id);
   END IF;

   -----------------------------------------------------------------------------
   -- Insert
   -----------------------------------------------------------------------------
   IF INSERTING THEN
      -- insert the new record
      INSERT INTO #TABLE_NAME_28_CHAR#_H (#COLUMN_LIST#
                                       , "VERSION_IS_ACTIVE_YN"
                                       , "VERSION_TRANSACTION_ID" 
                                       , "VERSION_CHANGE_ID"
                                       , "VERSION_OPERATION"
                                       , "VERSION_VALID_FROM"
                                       , "VERSION_VALID_TO"
                                       , "VERSION_IS_DELETED_YN"
                                       , "VERSION_MANIPULATED_AT"
                                       , "VERSION_MANIPULATED_BY")
                                 VALUES (#COLUMN_NEW_LIST#
                                       , 'Y'
                                       , v_transaction_id
                                       , history_change_seq.NEXTVAL
                                       , 'I'
                                       , v_timestamp
                                       , TO_TIMESTAMP ('9999-12-31 23:59:59.999999'
                                                     , 'YYYY-MM-DD HH24:MI:SS.FF')
                                       , 'N'
                                       , v_timestamp
                                       , v_user);
   END IF;

   -----------------------------------------------------------------------------
   -- Update
   -----------------------------------------------------------------------------

   IF UPDATING THEN
      -- close the old record
      UPDATE #TABLE_NAME_28_CHAR#_H
         SET version_is_active_yn = 'N'
           , version_valid_to = v_timestamp - INTERVAL '0.000001' SECOND
       WHERE #PK_COLUMN# = :old.#PK_COLUMN#
         AND version_is_active_yn = 'Y';

      -- insert the new record
      INSERT INTO #TABLE_NAME_28_CHAR#_H (#COLUMN_LIST#
                                       , "VERSION_IS_ACTIVE_YN"
                                       , "VERSION_TRANSACTION_ID" 
                                       , "VERSION_CHANGE_ID"
                                       , "VERSION_OPERATION"
                                       , "VERSION_VALID_FROM"
                                       , "VERSION_VALID_TO"
                                       , "VERSION_IS_DELETED_YN"
                                       , "VERSION_MANIPULATED_AT"
                                       , "VERSION_MANIPULATED_BY")
                                 VALUES (#COLUMN_NEW_LIST#
                                       , 'Y'
                                       , v_transaction_id
                                       , history_change_seq.NEXTVAL
                                       , 'U'
                                       , v_timestamp
                                       , TO_TIMESTAMP ('9999-12-31 23:59:59.999999'
                                                     , 'YYYY-MM-DD HH24:MI:SS.FF')
                                       , 'N'
                                       , v_timestamp
                                       , v_user);
   END IF;

   -----------------------------------------------------------------------------
   -- Delete
   -----------------------------------------------------------------------------
   IF DELETING THEN
      -- close the old record
      UPDATE #TABLE_NAME_28_CHAR#_H
         SET version_is_active_yn = 'N'
           , version_valid_to = v_timestamp - INTERVAL '0.000001' SECOND
       WHERE #PK_COLUMN# = :old.#PK_COLUMN#
         AND version_is_active_yn = 'Y';

      -- insert the new record
      INSERT INTO #TABLE_NAME_28_CHAR#_H (#COLUMN_LIST#
                                       , "VERSION_IS_ACTIVE_YN"
                                       , "VERSION_TRANSACTION_ID" 
                                       , "VERSION_CHANGE_ID"
                                       , "VERSION_OPERATION"
                                       , "VERSION_VALID_FROM"
                                       , "VERSION_VALID_TO"
                                       , "VERSION_IS_DELETED_YN"
                                       , "VERSION_MANIPULATED_AT"
                                       , "VERSION_MANIPULATED_BY")
                                 VALUES (#COLUMN_OLD_LIST#
                                       , 'N'
                                       , v_transaction_id
                                       , history_change_seq.NEXTVAL
                                       , 'D'
                                       , v_timestamp
                                       , v_timestamp + INTERVAL '0.000001' SECOND
                                       , 'Y'
                                       , v_timestamp
                                       , v_user);
   END IF;
END #TABLE_NAME_25_CHAR#_AIUD;
             ]';
   BEGIN
      v_history_trigger_template :=
         REPLACE (v_history_trigger_template, '#TABLE_NAME#', g_table_name);

      v_history_trigger_template :=
         REPLACE (v_history_trigger_template,
                  '#TABLE_NAME_25_CHAR#',
                  SUBSTR (g_table_name, 1, 25));

      v_history_trigger_template :=
         REPLACE (v_history_trigger_template,
                  '#TABLE_NAME_28_CHAR#',
                  SUBSTR (g_table_name, 1, 28));

      v_history_trigger_template :=
         REPLACE (v_history_trigger_template,
                  '#COLUMN_LIST#',
                  g_columns_list_pure);

      v_history_trigger_template :=
         REPLACE (v_history_trigger_template,
                  '#COLUMN_NEW_LIST#',
                  g_columns_list_new);

      v_history_trigger_template :=
         REPLACE (v_history_trigger_template,
                  '#COLUMN_OLD_LIST#',
                  g_columns_list_old);

      v_history_trigger_template :=
         REPLACE (v_history_trigger_template,
                  '#PK_COLUMN#',
                  g_columns_table (1).column_name);

      IF (v_history_trigger_template IS NOT NULL)
      THEN
         DBMS_OUTPUT.put_line (v_history_trigger_template);

         EXECUTE IMMEDIATE v_history_trigger_template;
      END IF;
   END create_history_trigger;

   FUNCTION get_column_definition (p_columns_table IN type_columns_table)
      RETURN VARCHAR2
   IS
      v_ret         VARCHAR2 (32667 CHAR);
      v_delimiter   VARCHAR2 (16 CHAR) := CHR (10) || '             , ';
   BEGIN
      FOR i IN p_columns_table.FIRST .. p_columns_table.LAST
      LOOP
         v_ret :=
               v_ret
            || v_delimiter
            || '"'
            || UPPER (p_columns_table (i).column_name)
            || '"'
            || ' '
            || p_columns_table (i).data_type;

         -- special cases for %char% and number data types
         IF (p_columns_table (i).data_type LIKE '%CHAR%')
         THEN
            v_ret :=
                  v_ret
               || '('
               || p_columns_table (i).char_length
               || ' '
               || CASE p_columns_table (i).char_used
                     WHEN 'B' THEN 'BYTE'
                     WHEN 'C' THEN 'CHAR'
                  END
               || ')';
         ELSIF (p_columns_table (i).data_type = 'NUMBER')
         THEN
            IF p_columns_table (i).data_precision IS NOT NULL
            THEN
               v_ret :=
                     v_ret
                  || '('
                  || p_columns_table (i).data_precision
                  || CASE
                        WHEN p_columns_table (i).data_scale > 0
                        THEN
                           ', ' || p_columns_table (i).data_scale
                     END
                  || ') ';
            END IF;
         END IF;
      END LOOP;

      RETURN LTRIM (v_ret, v_delimiter);
   END get_column_definition;

   PROCEDURE initialise
   IS
      v_table_counter   NUMBER;
      v_delimiter       VARCHAR2 (15 CHAR) := ', ';
   BEGIN
      -- reset global package variables
      g_columns_list_pure := NULL;
      g_columns_list_new := NULL;
      g_columns_list_old := NULL;
      g_columns_definition := NULL;
      g_columns_definition_to_add := NULL;
      g_columns_definition_to_modify := NULL;

      -- if not exists, then create sequences required for the history
      create_history_sequences;

      -- if not exist, then create global temporary table for transactions
      create_transaction_temp_table;

      -- fill global package variable g_columns_table that contains
      -- the column rows of user_tab_cols
      g_columns_table.delete;

      OPEN g_cur_columns;

      FETCH g_cur_columns BULK COLLECT INTO g_columns_table LIMIT 1000;

      CLOSE g_cur_columns;

      IF (g_columns_table.COUNT > 0)
      THEN
         g_columns_definition :=
            get_column_definition (p_columns_table => g_columns_table);
      END IF;

      -- fill global package variable g_columns_table_to_add that contains
      -- the column rows that are in g_table_name but not in history table
      g_columns_table_to_add.delete;

      OPEN g_cur_columns_add;

      FETCH g_cur_columns_add
         BULK COLLECT INTO g_columns_table_to_add
         LIMIT 1000;

      CLOSE g_cur_columns_add;

      IF (g_columns_table_to_add.COUNT > 0)
      THEN
         g_columns_definition_to_add :=
            get_column_definition (p_columns_table => g_columns_table_to_add);
      END IF;

      -- fill global package variable g_columns_table_to_modify that contains
      -- the column rows that are in g_table_name but with different data type
      -- than in the  history table
      g_columns_table_to_modify.delete;

      OPEN g_cur_columns_modify;

      FETCH g_cur_columns_modify
         BULK COLLECT INTO g_columns_table_to_modify
         LIMIT 1000;

      CLOSE g_cur_columns_modify;

      IF (g_columns_table_to_modify.COUNT > 0)
      THEN
         g_columns_definition_to_modify :=
            get_column_definition (
               p_columns_table   => g_columns_table_to_modify);
      END IF;

      FOR i IN g_columns_table.FIRST .. g_columns_table.LAST
      LOOP
         g_columns_list_pure :=
               g_columns_list_pure
            || v_delimiter
            || '"'
            || UPPER (g_columns_table (i).column_name)
            || '"';

         g_columns_list_new :=
               g_columns_list_new
            || v_delimiter
            || ':new.'
            || '"'
            || UPPER (g_columns_table (i).column_name)
            || '"';

         g_columns_list_old :=
               g_columns_list_old
            || v_delimiter
            || ':old.'
            || '"'
            || UPPER (g_columns_table (i).column_name)
            || '"';
      END LOOP;

      -- cut off the first delimiter of all lists
      g_columns_list_pure := LTRIM (g_columns_list_pure, v_delimiter);
      g_columns_list_new := LTRIM (g_columns_list_new, v_delimiter);
      g_columns_list_old := LTRIM (g_columns_list_old, v_delimiter);
      g_columns_definition := LTRIM (g_columns_definition, v_delimiter);
      g_columns_definition_to_add :=
         LTRIM (g_columns_definition_to_add, v_delimiter);
      g_columns_definition_to_modify :=
         LTRIM (g_columns_definition_to_modify, v_delimiter);

      SELECT COUNT (*)
        INTO v_table_counter
        FROM user_tables
       WHERE table_name = UPPER (g_table_name) || '_H';

      IF (v_table_counter = 0)
      THEN
         -- if not exist, then create the history table
         create_history_table;
      ELSE
         -- if already exist, then alter history table
         -- (add or modify column) if required
         alter_history_table_add_col;
         alter_history_table_modify_col;
      END IF;

      create_history_trigger;
   END initialise;

   -----------------------------------------------------------------------------
   -- implementation of public and private procedures / functions
   -----------------------------------------------------------------------------
   PROCEDURE enable_versioning (p_table_name IN user_tables.table_name%TYPE)
   IS
   BEGIN
      -- fill global package variable g_table_name as the base for all code
      g_table_name := p_table_name;

      -- fill the other global package variables, create
      -- transaction_temp_table and sequences
      initialise;
   END enable_versioning;
END history;
/