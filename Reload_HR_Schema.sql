BEGIN
   --------------------------------------------------------------------------
   --> Create DB Link
   --------------------------------------------------------------------------
   FOR db_link IN (SELECT 'TEMP_DB_LINK_HR.LOCALHOST.INT' AS db_link FROM DUAL
                   MINUS
                   SELECT db_link FROM user_db_links)
   LOOP
      EXECUTE IMMEDIATE
         q'[ 
             CREATE DATABASE LINK TEMP_DB_LINK_HR.LOCALHOST.INT
             CONNECT TO HR
             IDENTIFIED BY "&password_prod"
             USING '(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=playground.localhost.int)))'
           ]';
   END LOOP;
END;
/

DECLARE
   v_db_name      VARCHAR2(50);
   v_session_user VARCHAR2(50);
   v_dp_handle    NUMBER;
   v_job_state    VARCHAR2(4000);
   v_start_time   NUMBER := DBMS_UTILITY.get_time;
BEGIN
   v_db_name      := SYS_CONTEXT('USERENV', 'DB_NAME');
   v_session_user := SYS_CONTEXT('USERENV', 'SESSION_USER');

   -----------------------------------------------------------------------------
   --> Ensure that it is not executed on PROD or other schemas
   -----------------------------------------------------------------------------
   IF (v_session_user NOT IN ('HR_WM'))
   THEN
      raise_application_error(
         -20000
       ,    'Script can not be executed on PROD or other '
         || ' schemas than HR_WM');
   -----------------------------------------------------------------------------
   --> Ensure that it is not executed on PROD or other schemas
   -----------------------------------------------------------------------------
   ELSE
      --------------------------------------------------------------------------
      --> Execute data pump import over DB link
      --------------------------------------------------------------------------
      BEGIN
         v_dp_handle      :=
            DBMS_DATAPUMP.open(operation   => 'IMPORT'
                             , job_mode    => 'SCHEMA'
                             , remote_link => 'TEMP_DB_LINK_HR.LOCALHOST.INT'
                             , version     => 'LATEST');

         DBMS_DATAPUMP.add_file(
            handle    => v_dp_handle
          , filename  => 'copy_hr_to_hr_wm.log'
          , directory => 'DATA_PUMP_DIR'
          , filetype  => DBMS_DATAPUMP.ku$_file_type_log_file);

         IF v_session_user = 'HR_WM'
         THEN
            DBMS_DATAPUMP.metadata_remap(handle    => v_dp_handle
                                       , name      => 'REMAP_SCHEMA'
                                       , old_value => 'HR'
                                       , VALUE     => v_session_user);
         END IF;

         DBMS_DATAPUMP.metadata_filter(
            handle      => v_dp_handle
          , name        => 'NAME_EXPR'
          , VALUE       => 'NOT IN (''ABO_TEST'', ''ANALYSE_QUADRANT'', ''T1'',''T2'',''TESTCASES'')'
          , object_type => 'TABLE');

         -- datapump includes OID on types that causes problems, so
         -- IOD must be avoided for types
         DBMS_DATAPUMP.metadata_transform(handle      => v_dp_handle
                                        , name        => 'OID'
                                        , VALUE       => 0
                                        , object_type => 'TYPE');

         DBMS_DATAPUMP.set_parameter(handle => v_dp_handle
                                   , name   => 'TABLE_EXISTS_ACTION'
                                   , VALUE  => 'REPLACE');

         -- ensure referential integrity by defining timestamp of table consistency
         DBMS_DATAPUMP.set_parameter(handle => v_dp_handle
                                   , name   => 'FLASHBACK_TIME'
                                   , VALUE  => 'SYSTIMESTAMP');

         DBMS_DATAPUMP.start_job(v_dp_handle);
         DBMS_DATAPUMP.wait_for_job(v_dp_handle, v_job_state);
         DBMS_OUTPUT.put_line(' ');
         DBMS_OUTPUT.put_line(' ');
         DBMS_OUTPUT.put_line(
            '--------------------------------------------------------------------------------');
         DBMS_OUTPUT.put_line('S U M M E R Y');
         DBMS_OUTPUT.put_line(
            '--------------------------------------------------------------------------------');
         DBMS_OUTPUT.put_line(' ');

         DBMS_OUTPUT.put_line('DP handle: ' || v_dp_handle);
         DBMS_OUTPUT.put_line('Job state: ' || v_job_state);
         DBMS_OUTPUT.put_line(
               'Runtime:   '
            || (DBMS_UTILITY.get_time - v_start_time) / 100
            || ' seconds');
         DBMS_OUTPUT.put_line(' ');
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_DATAPUMP.stop_job(v_dp_handle);
            RAISE;
      END;
   END IF;

   --------------------------------------------------------------------------
   --> Show logfile
   --------------------------------------------------------------------------
   DECLARE
      v_file UTL_FILE.file_type;
      v_line VARCHAR2(32000);
   BEGIN
      v_file := UTL_FILE.fopen('DATA_PUMP_DIR', 'copy_hr_to_hr_wm.log', 'R');

      LOOP
         UTL_FILE.get_line(v_file, v_line);
         DBMS_OUTPUT.put_line(v_line);
      END LOOP;

      UTL_FILE.fclose(v_file);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
   END;
END;
/

BEGIN
   -----------------------------------------------------------------------------
   --> Delete DB link
   -----------------------------------------------------------------------------
   FOR db_link IN (SELECT db_link
                     FROM user_db_links
                    WHERE db_link = 'TEMP_DB_LINK_HR.LOCALHOST.INT')
   LOOP
      EXECUTE IMMEDIATE q'[ 
             DROP DATABASE LINK TEMP_DB_LINK_HR.LOCALHOST.INT
           ]';
   END LOOP;
END;
/

DECLARE
   v_schema user_users.username%TYPE;
BEGIN
   v_schema := SYS_CONTEXT('USERENV', 'SESSION_USER');
   -----------------------------------------------------------------------------
   --> Gather statistics
   -----------------------------------------------------------------------------
   DBMS_STATS.gather_schema_stats(ownname          => USER
                                , estimate_percent => 100
                                , granularity      => 'ALL'
                                , cascade          => TRUE
                                , force            => TRUE);
END;
/