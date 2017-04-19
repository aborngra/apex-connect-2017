CREATE OR REPLACE PACKAGE qa
   AUTHID CURRENT_USER
IS
   CURSOR g_cur_apex_plsql (
      p_application_id   IN apex_applications.application_id%TYPE)
   IS
      SELECT 'APEX Application Process' AS source_type,
             workspace,
             application_id,
             application_name,
             NULL AS page_id,
             NULL AS page_name,
             process_name AS source_name,
             process AS source_code,
             TO_CHAR (NULL) AS source_error
        FROM apex_application_processes
       WHERE     application_id = p_application_id
             AND process_type_code = 'PLSQL'
      UNION ALL
      SELECT 'APEX Page Process' AS source_type,
             workspace,
             application_id,
             application_name,
             page_id,
             page_name,
             process_name AS source_name,
             process_source AS source_code,
             TO_CHAR (NULL) AS source_error
        FROM apex_application_page_proc
       WHERE     application_id = p_application_id
             AND process_type_code = 'PLSQL'
      UNION ALL
      SELECT 'APEX Dynamic Action' AS source_type,
             workspace,
             application_id,
             application_name,
             page_id,
             page_name,
             dynamic_action_name AS source_name,
             TO_CLOB (attribute_01) AS source_code,
             TO_CHAR (NULL) AS source_error
        FROM apex_application_page_da_acts
       WHERE     application_id = p_application_id
             AND (action_name LIKE '%PL/SQL%' OR action_code LIKE '%PLSQL%');

   --    UNION ALL
   --      SELECT 'APEX Validation' AS source_type
   --           , workspace
   --           , application_id
   --           , application_name
   --           , page_id
   --           , page_name
   --           , validation_name AS source_name
   --           , TO_CLOB( validation_expression1 ) AS source_code
   --           , TO_CHAR( NULL ) AS source_error
   --        FROM apex_application_page_val
   --       WHERE     application_id = p_application_id
   --             AND (   validation_type_code LIKE 'PLSQL%'
   --                  OR validation_type_code LIKE 'FUNC%' )

   TYPE t_apex_plsql_tab IS TABLE OF g_cur_apex_plsql%ROWTYPE;

   g_apex_plsql_tab   t_apex_plsql_tab;

   FUNCTION parse_apex_plsql (
      p_application_id   IN apex_applications.application_id%TYPE)
      RETURN t_apex_plsql_tab
      PIPELINED;
END qa;
/