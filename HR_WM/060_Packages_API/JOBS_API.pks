CREATE OR REPLACE EDITIONABLE PACKAGE "JOBS_API"
IS
   /**
    * This is the API for the table JOBS.
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
    *   p_table_name="JOBS"
    *   p_reuse_existing_api_params="TRUE"
    *   p_col_prefix_in_method_names="TRUE"
    *   p_enable_insertion_of_rows="TRUE"
    *   p_enable_update_of_rows="TRUE"
    *   p_enable_deletion_of_rows="TRUE"
    *   p_enable_generic_change_log="FALSE"
    *   p_enable_dml_view="FALSE"
    *   p_sequence_name="JOBS_SEQ"/>
    *
    * This API provides DML functionality that can be easily called from APEX.
    * Target of the table API is to encapsulate the table DML source code for
    * security (UI schema needs only the execute right for the API and the
    * read/write right for the JOBS_dml_v, tables can be hidden in
    * extra data schema) and easy readability of the business logic (all DML is
    * then written in the same style). For APEX automatic row processing like
    * tabular forms you can optionally use the JOBS_dml_v, which has
    * an instead of trigger who is also calling the JOBS_api.
    */
   ----------------------------------------
   FUNCTION row_exists(p_job_id IN jobs."JOB_ID"%TYPE)
      RETURN BOOLEAN;

   ----------------------------------------
   FUNCTION row_exists_yn(p_job_id IN jobs."JOB_ID"%TYPE)
      RETURN VARCHAR2;

   ----------------------------------------
   FUNCTION create_row(p_job_id     IN jobs."JOB_ID"%TYPE DEFAULT NULL
                     , p_job_title  IN jobs."JOB_TITLE"%TYPE
                     , p_min_salary IN jobs."MIN_SALARY"%TYPE
                     , p_max_salary IN jobs."MAX_SALARY"%TYPE)
      RETURN jobs."JOB_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_row(p_job_id     IN jobs."JOB_ID"%TYPE DEFAULT NULL
                      , p_job_title  IN jobs."JOB_TITLE"%TYPE
                      , p_min_salary IN jobs."MIN_SALARY"%TYPE
                      , p_max_salary IN jobs."MAX_SALARY"%TYPE);

   ----------------------------------------
   FUNCTION create_row(p_row IN jobs%ROWTYPE)
      RETURN jobs."JOB_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_row(p_row IN jobs%ROWTYPE);

   ----------------------------------------
   FUNCTION read_row(p_job_id IN jobs."JOB_ID"%TYPE)
      RETURN jobs%ROWTYPE;

   ----------------------------------------
   PROCEDURE read_row(p_job_id     IN            jobs."JOB_ID"%TYPE
                    , p_job_title     OUT NOCOPY jobs."JOB_TITLE"%TYPE
                    , p_min_salary    OUT NOCOPY jobs."MIN_SALARY"%TYPE
                    , p_max_salary    OUT NOCOPY jobs."MAX_SALARY"%TYPE);

   ----------------------------------------
   PROCEDURE update_row(p_job_id     IN jobs."JOB_ID"%TYPE DEFAULT NULL
                      , p_job_title  IN jobs."JOB_TITLE"%TYPE
                      , p_min_salary IN jobs."MIN_SALARY"%TYPE
                      , p_max_salary IN jobs."MAX_SALARY"%TYPE);

   ----------------------------------------
   PROCEDURE update_row(p_row IN jobs%ROWTYPE);

   ----------------------------------------
   PROCEDURE delete_row(p_job_id IN jobs."JOB_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_or_update_row(p_job_id     IN jobs."JOB_ID"%TYPE DEFAULT NULL
                               , p_job_title  IN jobs."JOB_TITLE"%TYPE
                               , p_min_salary IN jobs."MIN_SALARY"%TYPE
                               , p_max_salary IN jobs."MAX_SALARY"%TYPE)
      RETURN jobs."JOB_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_job_id     IN jobs."JOB_ID"%TYPE DEFAULT NULL
                                , p_job_title  IN jobs."JOB_TITLE"%TYPE
                                , p_min_salary IN jobs."MIN_SALARY"%TYPE
                                , p_max_salary IN jobs."MAX_SALARY"%TYPE);

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN jobs%ROWTYPE)
      RETURN jobs."JOB_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN jobs%ROWTYPE);

   ----------------------------------------
   FUNCTION get_job_title(p_job_id IN jobs."JOB_ID"%TYPE)
      RETURN jobs."JOB_TITLE"%TYPE;

   ----------------------------------------
   FUNCTION get_min_salary(p_job_id IN jobs."JOB_ID"%TYPE)
      RETURN jobs."MIN_SALARY"%TYPE;

   ----------------------------------------
   FUNCTION get_max_salary(p_job_id IN jobs."JOB_ID"%TYPE)
      RETURN jobs."MAX_SALARY"%TYPE;

   ----------------------------------------
   PROCEDURE set_job_title(p_job_id    IN jobs."JOB_ID"%TYPE
                         , p_job_title IN jobs."JOB_TITLE"%TYPE);

   ----------------------------------------
   PROCEDURE set_min_salary(p_job_id     IN jobs."JOB_ID"%TYPE
                          , p_min_salary IN jobs."MIN_SALARY"%TYPE);

   ----------------------------------------
   PROCEDURE set_max_salary(p_job_id     IN jobs."JOB_ID"%TYPE
                          , p_max_salary IN jobs."MAX_SALARY"%TYPE);
----------------------------------------
END jobs_api;