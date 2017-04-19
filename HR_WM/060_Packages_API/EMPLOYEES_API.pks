CREATE OR REPLACE EDITIONABLE PACKAGE "EMPLOYEES_API"
IS
   /**
    * This is the API for the table EMPLOYEES.
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
    *   p_table_name="EMPLOYEES"
    *   p_reuse_existing_api_params="TRUE"
    *   p_col_prefix_in_method_names="TRUE"
    *   p_enable_insertion_of_rows="TRUE"
    *   p_enable_update_of_rows="TRUE"
    *   p_enable_deletion_of_rows="TRUE"
    *   p_enable_generic_change_log="FALSE"
    *   p_enable_dml_view="FALSE"
    *   p_sequence_name="EMPLOYEES_SEQ"/>
    *
    * This API provides DML functionality that can be easily called from APEX.
    * Target of the table API is to encapsulate the table DML source code for
    * security (UI schema needs only the execute right for the API and the
    * read/write right for the EMPLOYEES_dml_v, tables can be hidden in
    * extra data schema) and easy readability of the business logic (all DML is
    * then written in the same style). For APEX automatic row processing like
    * tabular forms you can optionally use the EMPLOYEES_dml_v, which has
    * an instead of trigger who is also calling the EMPLOYEES_api.
    */
   ----------------------------------------
   FUNCTION row_exists(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN BOOLEAN;

   ----------------------------------------
   FUNCTION row_exists_yn(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN VARCHAR2;

   ----------------------------------------
   FUNCTION get_pk_by_unique_cols(p_email employees."EMAIL"%TYPE)
      RETURN employees."EMPLOYEE_ID"%TYPE;

   ----------------------------------------
   FUNCTION create_row(
      p_employee_id    IN employees."EMPLOYEE_ID"%TYPE DEFAULT NULL
    , p_first_name     IN employees."FIRST_NAME"%TYPE
    , p_last_name      IN employees."LAST_NAME"%TYPE
    , p_email          IN employees."EMAIL"%TYPE
    , p_phone_number   IN employees."PHONE_NUMBER"%TYPE
    , p_hire_date      IN employees."HIRE_DATE"%TYPE
    , p_job_id         IN employees."JOB_ID"%TYPE
    , p_salary         IN employees."SALARY"%TYPE
    , p_commission_pct IN employees."COMMISSION_PCT"%TYPE
    , p_manager_id     IN employees."MANAGER_ID"%TYPE
    , p_department_id  IN employees."DEPARTMENT_ID"%TYPE)
      RETURN employees."EMPLOYEE_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_row(
      p_employee_id    IN employees."EMPLOYEE_ID"%TYPE DEFAULT NULL
    , p_first_name     IN employees."FIRST_NAME"%TYPE
    , p_last_name      IN employees."LAST_NAME"%TYPE
    , p_email          IN employees."EMAIL"%TYPE
    , p_phone_number   IN employees."PHONE_NUMBER"%TYPE
    , p_hire_date      IN employees."HIRE_DATE"%TYPE
    , p_job_id         IN employees."JOB_ID"%TYPE
    , p_salary         IN employees."SALARY"%TYPE
    , p_commission_pct IN employees."COMMISSION_PCT"%TYPE
    , p_manager_id     IN employees."MANAGER_ID"%TYPE
    , p_department_id  IN employees."DEPARTMENT_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_row(p_row IN employees%ROWTYPE)
      RETURN employees."EMPLOYEE_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_row(p_row IN employees%ROWTYPE);

   ----------------------------------------
   FUNCTION read_row(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees%ROWTYPE;

   ----------------------------------------
   PROCEDURE read_row(
      p_employee_id    IN            employees."EMPLOYEE_ID"%TYPE
    , p_first_name        OUT NOCOPY employees."FIRST_NAME"%TYPE
    , p_last_name         OUT NOCOPY employees."LAST_NAME"%TYPE
    , p_email             OUT NOCOPY employees."EMAIL"%TYPE
    , p_phone_number      OUT NOCOPY employees."PHONE_NUMBER"%TYPE
    , p_hire_date         OUT NOCOPY employees."HIRE_DATE"%TYPE
    , p_job_id            OUT NOCOPY employees."JOB_ID"%TYPE
    , p_salary            OUT NOCOPY employees."SALARY"%TYPE
    , p_commission_pct    OUT NOCOPY employees."COMMISSION_PCT"%TYPE
    , p_manager_id        OUT NOCOPY employees."MANAGER_ID"%TYPE
    , p_department_id     OUT NOCOPY employees."DEPARTMENT_ID"%TYPE);

   ----------------------------------------
   FUNCTION read_row(p_email employees."EMAIL"%TYPE)
      RETURN employees%ROWTYPE;

   ----------------------------------------
   PROCEDURE update_row(
      p_employee_id    IN employees."EMPLOYEE_ID"%TYPE DEFAULT NULL
    , p_first_name     IN employees."FIRST_NAME"%TYPE
    , p_last_name      IN employees."LAST_NAME"%TYPE
    , p_email          IN employees."EMAIL"%TYPE
    , p_phone_number   IN employees."PHONE_NUMBER"%TYPE
    , p_hire_date      IN employees."HIRE_DATE"%TYPE
    , p_job_id         IN employees."JOB_ID"%TYPE
    , p_salary         IN employees."SALARY"%TYPE
    , p_commission_pct IN employees."COMMISSION_PCT"%TYPE
    , p_manager_id     IN employees."MANAGER_ID"%TYPE
    , p_department_id  IN employees."DEPARTMENT_ID"%TYPE);

   ----------------------------------------
   PROCEDURE update_row(p_row IN employees%ROWTYPE);

   ----------------------------------------
   PROCEDURE delete_row(p_employee_id IN employees."EMPLOYEE_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_or_update_row(
      p_employee_id    IN employees."EMPLOYEE_ID"%TYPE DEFAULT NULL
    , p_first_name     IN employees."FIRST_NAME"%TYPE
    , p_last_name      IN employees."LAST_NAME"%TYPE
    , p_email          IN employees."EMAIL"%TYPE
    , p_phone_number   IN employees."PHONE_NUMBER"%TYPE
    , p_hire_date      IN employees."HIRE_DATE"%TYPE
    , p_job_id         IN employees."JOB_ID"%TYPE
    , p_salary         IN employees."SALARY"%TYPE
    , p_commission_pct IN employees."COMMISSION_PCT"%TYPE
    , p_manager_id     IN employees."MANAGER_ID"%TYPE
    , p_department_id  IN employees."DEPARTMENT_ID"%TYPE)
      RETURN employees."EMPLOYEE_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_or_update_row(
      p_employee_id    IN employees."EMPLOYEE_ID"%TYPE DEFAULT NULL
    , p_first_name     IN employees."FIRST_NAME"%TYPE
    , p_last_name      IN employees."LAST_NAME"%TYPE
    , p_email          IN employees."EMAIL"%TYPE
    , p_phone_number   IN employees."PHONE_NUMBER"%TYPE
    , p_hire_date      IN employees."HIRE_DATE"%TYPE
    , p_job_id         IN employees."JOB_ID"%TYPE
    , p_salary         IN employees."SALARY"%TYPE
    , p_commission_pct IN employees."COMMISSION_PCT"%TYPE
    , p_manager_id     IN employees."MANAGER_ID"%TYPE
    , p_department_id  IN employees."DEPARTMENT_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN employees%ROWTYPE)
      RETURN employees."EMPLOYEE_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN employees%ROWTYPE);

   ----------------------------------------
   FUNCTION get_first_name(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."FIRST_NAME"%TYPE;

   ----------------------------------------
   FUNCTION get_last_name(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."LAST_NAME"%TYPE;

   ----------------------------------------
   FUNCTION get_email(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."EMAIL"%TYPE;

   ----------------------------------------
   FUNCTION get_phone_number(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."PHONE_NUMBER"%TYPE;

   ----------------------------------------
   FUNCTION get_hire_date(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."HIRE_DATE"%TYPE;

   ----------------------------------------
   FUNCTION get_job_id(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."JOB_ID"%TYPE;

   ----------------------------------------
   FUNCTION get_salary(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."SALARY"%TYPE;

   ----------------------------------------
   FUNCTION get_commission_pct(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."COMMISSION_PCT"%TYPE;

   ----------------------------------------
   FUNCTION get_manager_id(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."MANAGER_ID"%TYPE;

   ----------------------------------------
   FUNCTION get_department_id(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."DEPARTMENT_ID"%TYPE;

   ----------------------------------------
   PROCEDURE set_first_name(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                          , p_first_name  IN employees."FIRST_NAME"%TYPE);

   ----------------------------------------
   PROCEDURE set_last_name(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                         , p_last_name   IN employees."LAST_NAME"%TYPE);

   ----------------------------------------
   PROCEDURE set_email(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                     , p_email       IN employees."EMAIL"%TYPE);

   ----------------------------------------
   PROCEDURE set_phone_number(p_employee_id  IN employees."EMPLOYEE_ID"%TYPE
                            , p_phone_number IN employees."PHONE_NUMBER"%TYPE);

   ----------------------------------------
   PROCEDURE set_hire_date(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                         , p_hire_date   IN employees."HIRE_DATE"%TYPE);

   ----------------------------------------
   PROCEDURE set_job_id(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                      , p_job_id      IN employees."JOB_ID"%TYPE);

   ----------------------------------------
   PROCEDURE set_salary(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                      , p_salary      IN employees."SALARY"%TYPE);

   ----------------------------------------
   PROCEDURE set_commission_pct(
      p_employee_id    IN employees."EMPLOYEE_ID"%TYPE
    , p_commission_pct IN employees."COMMISSION_PCT"%TYPE);

   ----------------------------------------
   PROCEDURE set_manager_id(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                          , p_manager_id  IN employees."MANAGER_ID"%TYPE);

   ----------------------------------------
   PROCEDURE set_department_id(
      p_employee_id   IN employees."EMPLOYEE_ID"%TYPE
    , p_department_id IN employees."DEPARTMENT_ID"%TYPE);
----------------------------------------
END employees_api;