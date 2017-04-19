--------------------------------------------------------------------------------
-- IMPLEMENTATION
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY svn
IS
   -----------------------------------------------------------------------------
   -- global private package variables
   -----------------------------------------------------------------------------
   g_user                    user_users.username%TYPE;

   CURSOR g_cur_sequences
   IS
      SELECT sequence_name FROM user_sequences;

   TYPE type_tab_user_sequences IS TABLE OF g_cur_sequences%ROWTYPE
      INDEX BY BINARY_INTEGER;

   g_tab_user_sequences      type_tab_user_sequences;

   CURSOR g_cur_tables
   IS
      SELECT * FROM user_tables;

   TYPE type_tab_user_tables IS TABLE OF g_cur_tables%ROWTYPE
      INDEX BY BINARY_INTEGER;

   g_tab_user_tables         type_tab_user_tables;

   CURSOR g_cur_indexes
   IS
      SELECT index_name
        FROM user_indexes
       -- only indexes, that are not used for constraints or LOB indexes
       WHERE uniqueness = 'NONUNIQUE';

   TYPE type_tab_user_indexes IS TABLE OF g_cur_indexes%ROWTYPE
      INDEX BY BINARY_INTEGER;

   g_tab_user_indexes        type_tab_user_indexes;

   CURSOR g_cur_packages
   IS
        SELECT *
          FROM user_objects
         WHERE object_type = 'PACKAGE'
      ORDER BY object_id;

   TYPE type_tab_user_packages IS TABLE OF g_cur_packages%ROWTYPE
      INDEX BY BINARY_INTEGER;

   g_tab_user_packages       type_tab_user_packages;

   CURSOR g_cur_package_bodies
   IS
        SELECT *
          FROM user_objects
         WHERE object_type = 'PACKAGE BODY'
      ORDER BY object_id;

   TYPE type_tab_user_package_bodies IS TABLE OF g_cur_package_bodies%ROWTYPE
      INDEX BY BINARY_INTEGER;

   g_tab_user_package_bodies type_tab_user_package_bodies;

   CURSOR g_cur_synonyms
   IS
      SELECT synonym_name FROM user_synonyms;

   TYPE type_tab_user_synonyms IS TABLE OF g_cur_synonyms%ROWTYPE
      INDEX BY BINARY_INTEGER;

   g_tab_user_synonyms       type_tab_user_synonyms;

   CURSOR g_cur_triggers
   IS
      SELECT trigger_name FROM user_triggers;

   TYPE type_tab_user_triggers IS TABLE OF g_cur_triggers%ROWTYPE
      INDEX BY BINARY_INTEGER;

   g_tab_user_triggers       type_tab_user_triggers;

   CURSOR g_cur_types
   IS
      SELECT type_name FROM user_types;

   TYPE type_tab_user_types IS TABLE OF g_cur_types%ROWTYPE
      INDEX BY BINARY_INTEGER;

   g_tab_user_types          type_tab_user_types;

   CURSOR g_cur_views
   IS
      SELECT view_name FROM user_views;

   TYPE type_tab_user_views IS TABLE OF g_cur_views%ROWTYPE
      INDEX BY BINARY_INTEGER;

   g_tab_user_views          type_tab_user_views;

   -----------------------------------------------------------------------------
   -- implementation of public and private procedures / functions
   -----------------------------------------------------------------------------
   PROCEDURE config_dbms_metadata(
      p_pretty_yn               IN BOOLEAN DEFAULT TRUE
    , p_constraints_yn          IN BOOLEAN DEFAULT TRUE
    , p_refconstraints_yn       IN BOOLEAN DEFAULT TRUE
    , p_partitioning_yn         IN BOOLEAN DEFAULT TRUE
    , p_tablespace_yn           IN BOOLEAN DEFAULT FALSE
    , p_storage_yn              IN BOOLEAN DEFAULT FALSE
    , p_segment_attr_yn         IN BOOLEAN DEFAULT FALSE
    , p_sqlterminator_yn        IN BOOLEAN DEFAULT TRUE
    , p_constraints_as_alter_yn IN BOOLEAN DEFAULT FALSE
    , p_emit_schema_yn          IN BOOLEAN DEFAULT FALSE)
   IS
   BEGIN
      DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform
                                      , 'PRETTY'
                                      , p_pretty_yn);

      DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform
                                      , 'CONSTRAINTS'
                                      , p_constraints_yn);

      DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform
                                      , 'REF_CONSTRAINTS'
                                      , p_refconstraints_yn);

      DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform
                                      , 'PARTITIONING'
                                      , p_partitioning_yn);

      DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform
                                      , 'TABLESPACE'
                                      , p_tablespace_yn);

      DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform
                                      , 'STORAGE'
                                      , p_storage_yn);

      DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform
                                      , 'SEGMENT_ATTRIBUTES'
                                      , p_segment_attr_yn);

      DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform
                                      , 'SQLTERMINATOR'
                                      , p_sqlterminator_yn);

      DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform
                                      , 'CONSTRAINTS_AS_ALTER'
                                      , p_constraints_as_alter_yn);

      DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform
                                      , 'EMIT_SCHEMA'
                                      , p_emit_schema_yn);
   END config_dbms_metadata;

   PROCEDURE initialise
   IS
   BEGIN
      --------------------------------------------------------------------------
      -- fill global package sequences
      --------------------------------------------------------------------------
      g_tab_user_sequences.delete;

      OPEN g_cur_sequences;

      FETCH g_cur_sequences BULK COLLECT INTO g_tab_user_sequences;

      CLOSE g_cur_sequences;

      --------------------------------------------------------------------------
      -- fill global package tables
      --------------------------------------------------------------------------
      g_tab_user_tables.delete;

      OPEN g_cur_tables;

      FETCH g_cur_tables BULK COLLECT INTO g_tab_user_tables;

      CLOSE g_cur_tables;

      --------------------------------------------------------------------------
      -- fill global package indexes
      --------------------------------------------------------------------------
      g_tab_user_indexes.delete;

      OPEN g_cur_indexes;

      FETCH g_cur_indexes BULK COLLECT INTO g_tab_user_indexes;

      CLOSE g_cur_indexes;

      --------------------------------------------------------------------------
      -- fill global package packages
      --------------------------------------------------------------------------
      g_tab_user_packages.delete;

      OPEN g_cur_packages;

      FETCH g_cur_packages BULK COLLECT INTO g_tab_user_packages;

      CLOSE g_cur_packages;

      --------------------------------------------------------------------------
      -- fill global package package bodies
      --------------------------------------------------------------------------
      g_tab_user_package_bodies.delete;

      OPEN g_cur_package_bodies;

      FETCH g_cur_package_bodies BULK COLLECT INTO g_tab_user_package_bodies;

      CLOSE g_cur_package_bodies;

      --------------------------------------------------------------------------
      -- fill global package synonyms
      --------------------------------------------------------------------------
      g_tab_user_synonyms.delete;

      OPEN g_cur_synonyms;

      FETCH g_cur_synonyms BULK COLLECT INTO g_tab_user_synonyms;

      CLOSE g_cur_synonyms;

      --------------------------------------------------------------------------
      -- fill global package triggers
      --------------------------------------------------------------------------
      g_tab_user_triggers.delete;

      OPEN g_cur_triggers;

      FETCH g_cur_triggers BULK COLLECT INTO g_tab_user_triggers;

      CLOSE g_cur_triggers;

      --------------------------------------------------------------------------
      -- fill global package types
      --------------------------------------------------------------------------
      g_tab_user_types.delete;

      OPEN g_cur_types;

      FETCH g_cur_types BULK COLLECT INTO g_tab_user_types;

      CLOSE g_cur_types;

      --------------------------------------------------------------------------
      -- fill global package views
      --------------------------------------------------------------------------
      g_tab_user_views.delete;

      OPEN g_cur_views;

      FETCH g_cur_views BULK COLLECT INTO g_tab_user_views;

      CLOSE g_cur_views;

      --------------------------------------------------------------------------
      -- configure DBMS_METADATA for table scripts with default properties
      --------------------------------------------------------------------------
      config_dbms_metadata;

      --------------------------------------------------------------------------
      -- delete SVN Objects Table
      --------------------------------------------------------------------------
      DELETE FROM tools.ctlg_svn_objects
            WHERE svn_schema = g_user;
   END initialise;

   PROCEDURE create_svn_sequences
   IS
      v_sequence_name     user_sequences.sequence_name%TYPE;
      v_sequence_template CLOB
         :=    '/* This anonymous block creates a sequence named ###SEQUENCE_NAME###'
            || CHR(13)
            || '   PL/SQL Block is restartable, so it can be executed n times, but'
            || CHR(13)
            || '   only creates the sequence if it does not exist.'
            || CHR(13)
            || '   %author  '
            || UPPER(
                  COALESCE(v('APP_USER'), SYS_CONTEXT('USERENV', 'OS_USER')))
            || CHR(13)
            || '   %created '
            || TO_CHAR(SYSDATE, 'yyyy-mm-dd hh24:mi:ss')
            || CHR(13)
            || ' */
                 DECLARE
                   v_sequence_name user_sequences.sequence_name%TYPE := ''###SEQUENCE_NAME###'';
                 BEGIN
                   FOR i IN (SELECT v_sequence_name FROM DUAL
                              MINUS
                             SELECT sequence_name FROM user_sequences)
                   LOOP
                     EXECUTE IMMEDIATE 
                       q''[
                       CREATE SEQUENCE ###SEQUENCE_NAME### 
                              MINVALUE 1 
                              MAXVALUE 999999999999999999999999999 
                              INCREMENT BY 1 
                              START WITH 1 
                              NOCACHE
                              NOORDER
                              NOCYCLE
                          ]'';
                   END LOOP;
                 END;
                 /';
      v_executed          CLOB;
   BEGIN
      -- generate SVN script for each sequence
      IF (g_tab_user_sequences.FIRST IS NOT NULL)
      THEN
         FOR i IN g_tab_user_sequences.FIRST .. g_tab_user_sequences.LAST
         LOOP
            v_sequence_name := g_tab_user_sequences(i).sequence_name;

            -- replace table_name
            v_executed      :=
               REPLACE(v_sequence_template
                     , '###SEQUENCE_NAME###'
                     , v_sequence_name);

            INSERT INTO tools.ctlg_svn_objects(svn_id
                                             , svn_schema
                                             , svn_object
                                             , svn_name
                                             , svn_script
                                             , svn_created_at)
                 VALUES (tools.ctlg_svn_objects_seq.NEXTVAL
                       , g_user
                       , 'SEQUENCE'
                       , v_sequence_name
                       , v_executed
                       , SYSDATE);
         END LOOP;
      END IF;
   END create_svn_sequences;

   PROCEDURE create_svn_tables
   IS
      v_table_name     user_tables.table_name%TYPE;
      v_table_template CLOB
         :=    '/* This anonymous block creates a table named ###TABLE_NAME###'
            || CHR(13)
            || '   PL/SQL Block is restartable, so it can be executed n times, but'
            || CHR(13)
            || '   only creates the table if it does not exist.'
            || CHR(13)
            || '   %author  '
            || UPPER(
                  COALESCE(v('APP_USER'), SYS_CONTEXT('USERENV', 'OS_USER')))
            || CHR(13)
            || '   %created '
            || TO_CHAR(SYSDATE, 'yyyy-mm-dd hh24:mi:ss')
            || CHR(13)
            || ' */
                 BEGIN
                   FOR i IN (SELECT ''###TABLE_NAME###'' AS table_name
                               FROM dual
                              MINUS
                             SELECT table_name
                               FROM user_tables)
                   LOOP
                     EXECUTE IMMEDIATE 
                       q''[###GENERATED_CODE### ###LOB_DEFINITION###]'';
                   END LOOP;
                 END;
                 /';

      v_lob_definition VARCHAR2(4000 CHAR);
      v_lob_counter    NUMBER := 0;
      v_generated      CLOB;
      v_executed       CLOB;
   BEGIN
      config_dbms_metadata(p_sqlterminator_yn => FALSE);

      -- generate SVN script for each table
      IF (g_tab_user_tables.FIRST IS NOT NULL)
      THEN
         FOR i IN g_tab_user_tables.FIRST .. g_tab_user_tables.LAST
         LOOP
            v_table_name     := g_tab_user_tables(i).table_name;

            v_generated      :=
               DBMS_METADATA.get_ddl(object_type => 'TABLE'
                                   , name        => v_table_name
                                   , schema      => g_user);

            -- replace table_name
            v_executed       :=
               REPLACE(v_table_template, '###TABLE_NAME###', v_table_name);

            -- replace code
            v_executed       :=
               REPLACE(v_executed, '###GENERATED_CODE###', TRIM(v_generated));

            -- LOB Definition (to avoid SYS0815 index_names for LOB columns)
            v_lob_counter    := 0;
            v_lob_definition := NULL;

            FOR lob_column IN (  SELECT *
                                   FROM user_tab_cols
                                  WHERE table_name = v_table_name
                                    AND data_type IN ('CLOB'
                                                    , 'BLOB'
                                                    , 'BFILE'
                                                    , 'NCLOB')
                               ORDER BY column_id)
            LOOP
               v_lob_counter := v_lob_counter + 1;
               v_lob_definition      :=
                     v_lob_definition
                  || ' LOB ('
                  || lob_column.column_name
                  || ')'
                  || ' STORE AS (INDEX "'
                  || SUBSTR(v_table_name, 1, 25)
                  || '_LOB'
                  || TO_CHAR(v_lob_counter, 'FM09')
                  || '")';
            END LOOP;

            v_executed       :=
               REPLACE(v_executed, '###LOB_DEFINITION###', v_lob_definition);

            INSERT INTO tools.ctlg_svn_objects(svn_id
                                             , svn_schema
                                             , svn_object
                                             , svn_name
                                             , svn_script
                                             , svn_created_at)
                 VALUES (tools.ctlg_svn_objects_seq.NEXTVAL
                       , g_user
                       , 'TABLE'
                       , v_table_name
                       , v_executed
                       , SYSDATE);
         END LOOP;
      END IF;

      config_dbms_metadata(p_sqlterminator_yn => TRUE);
   END create_svn_tables;

   PROCEDURE create_svn_indexes
   IS
      v_index_name     user_indexes.index_name%TYPE;
      v_index_template CLOB
         :=    '/* This anonymous block creates a index named ###INDEX_NAME###'
            || CHR(13)
            || '   PL/SQL Block is restartable, so it can be executed n times, but'
            || CHR(13)
            || '   only creates the index if it does not exist.'
            || CHR(13)
            || '   %author  '
            || UPPER(
                  COALESCE(v('APP_USER'), SYS_CONTEXT('USERENV', 'OS_USER')))
            || CHR(13)
            || '   %created '
            || TO_CHAR(SYSDATE, 'yyyy-mm-dd hh24:mi:ss')
            || CHR(13)
            || ' */
                 DECLARE
                   v_index_name user_indexes.index_name%TYPE := ''###INDEX_NAME###'';
                 BEGIN
                   FOR i IN (SELECT v_index_name FROM DUAL
                              MINUS
                             SELECT index_name FROM user_indexes)
                   LOOP
                     EXECUTE IMMEDIATE 
                       q''[###GENERATED_CODE###]'';
                   END LOOP;
                 END;
                 /';
      v_executed       CLOB;
      v_generated      CLOB;
   BEGIN
      config_dbms_metadata(p_sqlterminator_yn => FALSE);

      -- generate SVN script for each index
      IF (g_tab_user_indexes.FIRST IS NOT NULL)
      THEN
         FOR i IN g_tab_user_indexes.FIRST .. g_tab_user_indexes.LAST
         LOOP
            v_index_name := g_tab_user_indexes(i).index_name;

            -- replace table_name
            v_executed      :=
               REPLACE(v_index_template, '###INDEX_NAME###', v_index_name);

            v_generated      :=
               TRIM(
                  DBMS_METADATA.get_ddl(object_type => 'INDEX'
                                      , name        => v_index_name
                                      , schema      => g_user));

            -- replace table_name
            v_executed      :=
               REPLACE(v_index_template, '###INDEX_NAME###', v_index_name);

            -- replace code
            v_executed      :=
               REPLACE(v_executed, '###GENERATED_CODE###', v_generated);

            INSERT INTO tools.ctlg_svn_objects(svn_id
                                             , svn_schema
                                             , svn_object
                                             , svn_name
                                             , svn_script
                                             , svn_created_at)
                 VALUES (tools.ctlg_svn_objects_seq.NEXTVAL
                       , g_user
                       , 'INDEX'
                       , v_index_name
                       , v_executed
                       , SYSDATE);
         END LOOP;
      END IF;
   END create_svn_indexes;

   PROCEDURE create_svn_packages
   IS
      v_package_name      user_objects.object_name%TYPE;
      v_package_body_name user_objects.object_name%TYPE;
      v_generated         CLOB;
   BEGIN
      --      config_dbms_metadata( p_sqlterminator_yn => TRUE );

      -- generate SVN script for each package
      IF (g_tab_user_packages.FIRST IS NOT NULL)
      THEN
         FOR i IN g_tab_user_packages.FIRST .. g_tab_user_packages.LAST
         LOOP
            v_package_name := g_tab_user_packages(i).object_name;

            v_generated      :=
               TRIM(
                  DBMS_METADATA.get_ddl(object_type => 'PACKAGE_SPEC'
                                      , name        => v_package_name
                                      , schema      => g_user));

            INSERT INTO tools.ctlg_svn_objects(svn_id
                                             , svn_schema
                                             , svn_object
                                             , svn_name
                                             , svn_script
                                             , svn_created_at)
                 VALUES (tools.ctlg_svn_objects_seq.NEXTVAL
                       , g_user
                       , 'PACKAGE'
                       , v_package_name
                       , v_generated
                       , SYSDATE);
         END LOOP;
      END IF;

      -- generate SVN script for each package body
      IF (g_tab_user_package_bodies.FIRST IS NOT NULL)
      THEN
         FOR i IN g_tab_user_package_bodies.FIRST ..
                  g_tab_user_package_bodies.LAST
         LOOP
            v_package_body_name := g_tab_user_package_bodies(i).object_name;

            v_generated         :=
               TRIM(
                  DBMS_METADATA.get_ddl(object_type => 'PACKAGE_BODY'
                                      , name        => v_package_body_name
                                      , schema      => g_user));

            INSERT INTO tools.ctlg_svn_objects(svn_id
                                             , svn_schema
                                             , svn_object
                                             , svn_name
                                             , svn_script
                                             , svn_created_at)
                 VALUES (tools.ctlg_svn_objects_seq.NEXTVAL
                       , g_user
                       , 'PACKAGE BODY'
                       , v_package_body_name
                       , v_generated
                       , SYSDATE);
         END LOOP;
      END IF;
   END create_svn_packages;

   PROCEDURE create_svn_synonyms
   IS
      v_synonym_name user_synonyms.synonym_name%TYPE;
      v_generated    CLOB;
   BEGIN
      -- generate SVN script for each synonym
      IF (g_tab_user_synonyms.FIRST IS NOT NULL)
      THEN
         FOR i IN g_tab_user_synonyms.FIRST .. g_tab_user_synonyms.LAST
         LOOP
            v_synonym_name := g_tab_user_synonyms(i).synonym_name;

            v_generated      :=
               TRIM(
                  DBMS_METADATA.get_ddl(object_type => 'SYNONYM'
                                      , name        => v_synonym_name
                                      , schema      => g_user));

            INSERT INTO tools.ctlg_svn_objects(svn_id
                                             , svn_schema
                                             , svn_object
                                             , svn_name
                                             , svn_script
                                             , svn_created_at)
                 VALUES (tools.ctlg_svn_objects_seq.NEXTVAL
                       , g_user
                       , 'SYNONYM'
                       , v_synonym_name
                       , v_generated
                       , SYSDATE);
         END LOOP;
      END IF;
   END create_svn_synonyms;

   PROCEDURE create_svn_triggers
   IS
      v_trigger_name user_triggers.trigger_name%TYPE;
      v_generated    CLOB;
   BEGIN
      -- generate SVN script for each trigger
      IF (g_tab_user_triggers.FIRST IS NOT NULL)
      THEN
         FOR i IN g_tab_user_triggers.FIRST .. g_tab_user_triggers.LAST
         LOOP
            v_trigger_name := g_tab_user_triggers(i).trigger_name;

            v_generated      :=
               TRIM(
                  DBMS_METADATA.get_ddl(object_type => 'TRIGGER'
                                      , name        => v_trigger_name
                                      , schema      => g_user));

            lob.replace_clob(p_clob => v_generated
                           , p_what => ' END ' || v_trigger_name || ';'
                           , p_with => ' END ' || v_trigger_name || ';' || '/');

            INSERT INTO tools.ctlg_svn_objects(svn_id
                                             , svn_schema
                                             , svn_object
                                             , svn_name
                                             , svn_script
                                             , svn_created_at)
                 VALUES (tools.ctlg_svn_objects_seq.NEXTVAL
                       , g_user
                       , 'TRIGGER'
                       , v_trigger_name
                       , v_generated
                       , SYSDATE);
         END LOOP;
      END IF;
   END create_svn_triggers;

   PROCEDURE create_svn_types
   IS
      v_type_name user_types.type_name%TYPE;
      v_generated CLOB;
   BEGIN
      -- generate SVN script for each type
      IF (g_tab_user_types.FIRST IS NOT NULL)
      THEN
         FOR i IN g_tab_user_types.FIRST .. g_tab_user_types.LAST
         LOOP
            v_type_name := g_tab_user_types(i).type_name;

            v_generated      :=
               TRIM(
                  DBMS_METADATA.get_ddl(object_type => 'TYPE'
                                      , name        => v_type_name
                                      , schema      => g_user));

            INSERT INTO tools.ctlg_svn_objects(svn_id
                                             , svn_schema
                                             , svn_object
                                             , svn_name
                                             , svn_script
                                             , svn_created_at)
                 VALUES (tools.ctlg_svn_objects_seq.NEXTVAL
                       , g_user
                       , 'TYPE'
                       , v_type_name
                       , v_generated
                       , SYSDATE);
         END LOOP;
      END IF;
   END create_svn_types;

   PROCEDURE create_svn_views
   IS
      v_view_name user_views.view_name%TYPE;
      v_generated CLOB;
   BEGIN
      -- generate SVN script for each type
      IF (g_tab_user_views.FIRST IS NOT NULL)
      THEN
         FOR i IN g_tab_user_views.FIRST .. g_tab_user_views.LAST
         LOOP
            v_view_name := g_tab_user_views(i).view_name;

            v_generated      :=
               TRIM(
                  DBMS_METADATA.get_ddl(object_type => 'VIEW'
                                      , name        => v_view_name
                                      , schema      => g_user));

            INSERT INTO tools.ctlg_svn_objects(svn_id
                                             , svn_schema
                                             , svn_object
                                             , svn_name
                                             , svn_script
                                             , svn_created_at)
                 VALUES (tools.ctlg_svn_objects_seq.NEXTVAL
                       , g_user
                       , 'VIEW'
                       , v_view_name
                       , v_generated
                       , SYSDATE);
         END LOOP;
      END IF;
   END create_svn_views;

   PROCEDURE create_svn_objects(
      p_user IN user_users.username%TYPE DEFAULT USER)
   IS
   BEGIN
      g_user := p_user;

      initialise;
      create_svn_sequences;
      create_svn_tables;
      create_svn_indexes;
      create_svn_packages;
      create_svn_synonyms;
      create_svn_triggers;
      create_svn_types;
      create_svn_views;

      COMMIT;
   END create_svn_objects;
END svn;
/