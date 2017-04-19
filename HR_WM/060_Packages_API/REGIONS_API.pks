CREATE OR REPLACE EDITIONABLE PACKAGE "REGIONS_API"
IS
   /**
    * This is the API for the table REGIONS.
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
    *   p_table_name="REGIONS"
    *   p_reuse_existing_api_params="TRUE"
    *   p_col_prefix_in_method_names="TRUE"
    *   p_enable_insertion_of_rows="TRUE"
    *   p_enable_update_of_rows="TRUE"
    *   p_enable_deletion_of_rows="TRUE"
    *   p_enable_generic_change_log="FALSE"
    *   p_enable_dml_view="FALSE"
    *   p_sequence_name="REGIONS_SEQ"/>
    *
    * This API provides DML functionality that can be easily called from APEX.
    * Target of the table API is to encapsulate the table DML source code for
    * security (UI schema needs only the execute right for the API and the
    * read/write right for the REGIONS_dml_v, tables can be hidden in
    * extra data schema) and easy readability of the business logic (all DML is
    * then written in the same style). For APEX automatic row processing like
    * tabular forms you can optionally use the REGIONS_dml_v, which has
    * an instead of trigger who is also calling the REGIONS_api.
    */
   ----------------------------------------
   FUNCTION row_exists(p_region_id IN regions."REGION_ID"%TYPE)
      RETURN BOOLEAN;

   ----------------------------------------
   FUNCTION row_exists_yn(p_region_id IN regions."REGION_ID"%TYPE)
      RETURN VARCHAR2;

   ----------------------------------------
   FUNCTION create_row(p_region_id   IN regions."REGION_ID"%TYPE DEFAULT NULL
                     , p_region_name IN regions."REGION_NAME"%TYPE)
      RETURN regions."REGION_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_row(p_region_id   IN regions."REGION_ID"%TYPE DEFAULT NULL
                      , p_region_name IN regions."REGION_NAME"%TYPE);

   ----------------------------------------
   FUNCTION create_row(p_row IN regions%ROWTYPE)
      RETURN regions."REGION_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_row(p_row IN regions%ROWTYPE);

   ----------------------------------------
   FUNCTION read_row(p_region_id IN regions."REGION_ID"%TYPE)
      RETURN regions%ROWTYPE;

   ----------------------------------------
   PROCEDURE read_row(p_region_id   IN            regions."REGION_ID"%TYPE
                    , p_region_name    OUT NOCOPY regions."REGION_NAME"%TYPE);

   ----------------------------------------
   PROCEDURE update_row(p_region_id   IN regions."REGION_ID"%TYPE DEFAULT NULL
                      , p_region_name IN regions."REGION_NAME"%TYPE);

   ----------------------------------------
   PROCEDURE update_row(p_row IN regions%ROWTYPE);

   ----------------------------------------
   PROCEDURE delete_row(p_region_id IN regions."REGION_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_or_update_row(
      p_region_id   IN regions."REGION_ID"%TYPE DEFAULT NULL
    , p_region_name IN regions."REGION_NAME"%TYPE)
      RETURN regions."REGION_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_or_update_row(
      p_region_id   IN regions."REGION_ID"%TYPE DEFAULT NULL
    , p_region_name IN regions."REGION_NAME"%TYPE);

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN regions%ROWTYPE)
      RETURN regions."REGION_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN regions%ROWTYPE);

   ----------------------------------------
   FUNCTION get_region_name(p_region_id IN regions."REGION_ID"%TYPE)
      RETURN regions."REGION_NAME"%TYPE;

   ----------------------------------------
   PROCEDURE set_region_name(p_region_id   IN regions."REGION_ID"%TYPE
                           , p_region_name IN regions."REGION_NAME"%TYPE);
----------------------------------------
END regions_api;