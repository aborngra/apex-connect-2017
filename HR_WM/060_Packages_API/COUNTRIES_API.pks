CREATE OR REPLACE EDITIONABLE PACKAGE "COUNTRIES_API"
IS
   /**
    * This is the API for the table COUNTRIES.
    *
    * GENERATION OPTIONS
    * - must be in the lines 5-25 to be reusable by the generator
    * - DO NOT TOUCH THIS until you know what you do - read the
    *   docs under github.com/OraMUC/table-api-generator ;-)
    * <options
    *   generator="OM_TAPIGEN"
    *   generator_version="0.4.0"
    *   generator_action="COMPILE_API"
    *   generated_at="2017-04-19 22:05:39"
    *   generated_by="OCGM\ABO"
    *   p_table_name="COUNTRIES"
    *   p_reuse_existing_api_params="TRUE"
    *   p_col_prefix_in_method_names="TRUE"
    *   p_enable_insertion_of_rows="TRUE"
    *   p_enable_update_of_rows="TRUE"
    *   p_enable_deletion_of_rows="TRUE"
    *   p_enable_generic_change_log="FALSE"
    *   p_enable_dml_view="FALSE"
    *   p_sequence_name="COUNTRIES_SEQ"/>
    *
    * This API provides DML functionality that can be easily called from APEX.
    * Target of the table API is to encapsulate the table DML source code for
    * security (UI schema needs only the execute right for the API and the
    * read/write right for the COUNTRIES_dml_v, tables can be hidden in
    * extra data schema) and easy readability of the business logic (all DML is
    * then written in the same style). For APEX automatic row processing like
    * tabular forms you can optionally use the COUNTRIES_dml_v, which has
    * an instead of trigger who is also calling the COUNTRIES_api.
    */
   ----------------------------------------
   FUNCTION row_exists(p_country_id IN countries."COUNTRY_ID"%TYPE)
      RETURN BOOLEAN;

   ----------------------------------------
   FUNCTION row_exists_yn(p_country_id IN countries."COUNTRY_ID"%TYPE)
      RETURN VARCHAR2;

   ----------------------------------------
   FUNCTION create_row(p_country_id   IN countries."COUNTRY_ID"%TYPE DEFAULT NULL
                     , p_country_name IN countries."COUNTRY_NAME"%TYPE
                     , p_region_id    IN countries."REGION_ID"%TYPE)
      RETURN countries."COUNTRY_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_row(
      p_country_id   IN countries."COUNTRY_ID"%TYPE DEFAULT NULL
    , p_country_name IN countries."COUNTRY_NAME"%TYPE
    , p_region_id    IN countries."REGION_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_row(p_row IN countries%ROWTYPE)
      RETURN countries."COUNTRY_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_row(p_row IN countries%ROWTYPE);

   ----------------------------------------
   FUNCTION read_row(p_country_id IN countries."COUNTRY_ID"%TYPE)
      RETURN countries%ROWTYPE;

   ----------------------------------------
   PROCEDURE read_row(
      p_country_id   IN            countries."COUNTRY_ID"%TYPE
    , p_country_name    OUT NOCOPY countries."COUNTRY_NAME"%TYPE
    , p_region_id       OUT NOCOPY countries."REGION_ID"%TYPE);

   ----------------------------------------
   PROCEDURE update_row(
      p_country_id   IN countries."COUNTRY_ID"%TYPE DEFAULT NULL
    , p_country_name IN countries."COUNTRY_NAME"%TYPE
    , p_region_id    IN countries."REGION_ID"%TYPE);

   ----------------------------------------
   PROCEDURE update_row(p_row IN countries%ROWTYPE);

   ----------------------------------------
   PROCEDURE delete_row(p_country_id IN countries."COUNTRY_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_or_update_row(
      p_country_id   IN countries."COUNTRY_ID"%TYPE DEFAULT NULL
    , p_country_name IN countries."COUNTRY_NAME"%TYPE
    , p_region_id    IN countries."REGION_ID"%TYPE)
      RETURN countries."COUNTRY_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_or_update_row(
      p_country_id   IN countries."COUNTRY_ID"%TYPE DEFAULT NULL
    , p_country_name IN countries."COUNTRY_NAME"%TYPE
    , p_region_id    IN countries."REGION_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN countries%ROWTYPE)
      RETURN countries."COUNTRY_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN countries%ROWTYPE);

   ----------------------------------------
   FUNCTION get_country_name(p_country_id IN countries."COUNTRY_ID"%TYPE)
      RETURN countries."COUNTRY_NAME"%TYPE;

   ----------------------------------------
   FUNCTION get_region_id(p_country_id IN countries."COUNTRY_ID"%TYPE)
      RETURN countries."REGION_ID"%TYPE;

   ----------------------------------------
   PROCEDURE set_country_name(p_country_id   IN countries."COUNTRY_ID"%TYPE
                            , p_country_name IN countries."COUNTRY_NAME"%TYPE);

   ----------------------------------------
   PROCEDURE set_region_id(p_country_id IN countries."COUNTRY_ID"%TYPE
                         , p_region_id  IN countries."REGION_ID"%TYPE);
----------------------------------------
END countries_api;