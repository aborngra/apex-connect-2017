CREATE OR REPLACE PACKAGE BODY qa
IS
   FUNCTION parse_apex_plsql (
      p_application_id   IN apex_applications.application_id%TYPE)
      RETURN t_apex_plsql_tab
      PIPELINED
   IS
      v_dbms_sql_cursor   INTEGER;
   BEGIN
      OPEN g_cur_apex_plsql (p_application_id => p_application_id);

      FETCH g_cur_apex_plsql BULK COLLECT INTO g_apex_plsql_tab;

      CLOSE g_cur_apex_plsql;

      IF (g_apex_plsql_tab.FIRST IS NOT NULL)
      THEN
         FOR i IN g_apex_plsql_tab.FIRST .. g_apex_plsql_tab.LAST
         LOOP
            ------------------------------------------------------------------------
            -- parse the source_code with DBMS_SQL. If an error occures,
            -- then write it into the same collection in column source_error
            ------------------------------------------------------------------------
            v_dbms_sql_cursor := DBMS_SQL.open_cursor;

            ------------------------------------------------------------------------
            -- check if v(...) calls are used in PL/SQL
            ------------------------------------------------------------------------
            IF (g_apex_plsql_tab (i).source_code LIKE '% v(%''%''%) %')
            THEN
               g_apex_plsql_tab (i).source_error :=
                     g_apex_plsql_tab (i).source_error
                  || 'Avoid v(...) notation in PL/SQL, better user bind-variables or parameter!'
                  || CHR (10);
            END IF;

            BEGIN
               DBMS_SQL.parse (
                  v_dbms_sql_cursor,
                  'BEGIN ' || g_apex_plsql_tab (i).source_code || ' END;',
                  DBMS_SQL.native);
            EXCEPTION
               WHEN OTHERS
               THEN
                  g_apex_plsql_tab (i).source_error :=
                        g_apex_plsql_tab (i).source_error
                     || DBMS_UTILITY.format_error_backtrace
                     || CHR (10);
            END;

            PIPE ROW (g_apex_plsql_tab (i));

            DBMS_SQL.close_cursor (v_dbms_sql_cursor);
         END LOOP;
      END IF;

      RETURN;
   END parse_apex_plsql;
END qa;
/