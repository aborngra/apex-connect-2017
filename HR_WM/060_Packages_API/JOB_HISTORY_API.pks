CREATE OR REPLACE EDITIONABLE PACKAGE "JOB_HISTORY_API"
IS
   /**
    * This is the API for the table JOB_HISTORY.
    *
    * GENERATION OPTIONS
    * - must be in the lines 5-25 to be reusable by the generator
    * - DO NOT TOUCH THIS until you know what you do - read the
    *   docs under github.com/OraMUC/table-api-generator ;-)
    * <options
    *   generator="OM_TAPIGEN"
    *   generator_version="0.4.0"
    *   generator_action="COMPILE_API"
    *   generated_at="2017-04-19 22:05:40"
    *   generated_by="OCGM\ABO"
    *   p_table_name="JOB_HISTORY"
    *   p_reuse_existing_api_params="TRUE"
    *   p_col_prefix_in_method_names="TRUE"
    *   p_enable_insertion_of_rows="TRUE"
    *   p_enable_update_of_rows="TRUE"
    *   p_enable_deletion_of_rows="TRUE"
    *   p_enable_generic_change_log="FALSE"
    *   p_enable_dml_view="FALSE"
    *   p_sequence_name="JOB_HISTORY_SEQ"/>
    *
    * This API provides DML functionality that can be easily called from APEX.
    * Target of the table API is to encapsulate the table DML source code for
    * security (UI schema needs only the execute right for the API and the
    * read/write right for the JOB_HISTORY_dml_v, tables can be hidden in
    * extra data schema) and easy readability of the business logic (all DML is
    * then written in the same style). For APEX automatic row processing like
    * tabular forms you can optionally use the JOB_HISTORY_dml_v, which has
    * an instead of trigger who is also calling the JOB_HISTORY_api.
    */
   ----------------------------------------
   FUNCTION row_exists(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN BOOLEAN;

   ----------------------------------------
   FUNCTION row_exists_yn(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN VARCHAR2;

   ----------------------------------------
   FUNCTION create_row(p_employee_id   IN job_history."EMPLOYEE_ID"%TYPE
                     , p_start_date    IN job_history."START_DATE"%TYPE
                     , p_end_date      IN job_history."END_DATE"%TYPE
                     , p_job_id        IN job_history."JOB_ID"%TYPE
                     , p_department_id IN job_history."DEPARTMENT_ID"%TYPE)
      RETURN job_history."EMPLOYEE_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_row(p_employee_id   IN job_history."EMPLOYEE_ID"%TYPE
                      , p_start_date    IN job_history."START_DATE"%TYPE
                      , p_end_date      IN job_history."END_DATE"%TYPE
                      , p_job_id        IN job_history."JOB_ID"%TYPE
                      , p_department_id IN job_history."DEPARTMENT_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_row(p_row IN job_history%ROWTYPE)
      RETURN job_history."EMPLOYEE_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_row(p_row IN job_history%ROWTYPE);

   ----------------------------------------
   FUNCTION read_row(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN job_history%ROWTYPE;

   ----------------------------------------
   PROCEDURE read_row(
      p_employee_id      OUT NOCOPY job_history."EMPLOYEE_ID"%TYPE
    , p_start_date       OUT NOCOPY job_history."START_DATE"%TYPE
    , p_end_date         OUT NOCOPY job_history."END_DATE"%TYPE
    , p_job_id           OUT NOCOPY job_history."JOB_ID"%TYPE
    , p_department_id    OUT NOCOPY job_history."DEPARTMENT_ID"%TYPE);

   ----------------------------------------
   PROCEDURE update_row(p_employee_id   IN job_history."EMPLOYEE_ID"%TYPE
                      , p_start_date    IN job_history."START_DATE"%TYPE
                      , p_end_date      IN job_history."END_DATE"%TYPE
                      , p_job_id        IN job_history."JOB_ID"%TYPE
                      , p_department_id IN job_history."DEPARTMENT_ID"%TYPE);

   ----------------------------------------
   PROCEDURE update_row(p_row IN job_history%ROWTYPE);

   ----------------------------------------
   PROCEDURE delete_row(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_or_update_row(
      p_employee_id   IN job_history."EMPLOYEE_ID"%TYPE
    , p_start_date    IN job_history."START_DATE"%TYPE
    , p_end_date      IN job_history."END_DATE"%TYPE
    , p_job_id        IN job_history."JOB_ID"%TYPE
    , p_department_id IN job_history."DEPARTMENT_ID"%TYPE)
      RETURN job_history."EMPLOYEE_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_or_update_row(
      p_employee_id   IN job_history."EMPLOYEE_ID"%TYPE
    , p_start_date    IN job_history."START_DATE"%TYPE
    , p_end_date      IN job_history."END_DATE"%TYPE
    , p_job_id        IN job_history."JOB_ID"%TYPE
    , p_department_id IN job_history."DEPARTMENT_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN job_history%ROWTYPE)
      RETURN job_history."EMPLOYEE_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN job_history%ROWTYPE);

   ----------------------------------------
   FUNCTION get_employee_id(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN job_history."EMPLOYEE_ID"%TYPE;

   ----------------------------------------
   FUNCTION get_start_date(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN job_history."START_DATE"%TYPE;

   ----------------------------------------
   FUNCTION get_end_date(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN job_history."END_DATE"%TYPE;

   ----------------------------------------
   FUNCTION get_job_id(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN job_history."JOB_ID"%TYPE;

   ----------------------------------------
   FUNCTION get_department_id(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN job_history."DEPARTMENT_ID"%TYPE;

   ----------------------------------------
   PROCEDURE set_start_date(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE
                          , p_start_date  IN job_history."START_DATE"%TYPE);

   ----------------------------------------
   PROCEDURE set_end_date(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE
                        , p_end_date    IN job_history."END_DATE"%TYPE);

   ----------------------------------------
   PROCEDURE set_job_id(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE
                      , p_job_id      IN job_history."JOB_ID"%TYPE);

   ----------------------------------------
   PROCEDURE set_department_id(
      p_employee_id   IN job_history."EMPLOYEE_ID"%TYPE
    , p_department_id IN job_history."DEPARTMENT_ID"%TYPE);
----------------------------------------
END job_history_api;