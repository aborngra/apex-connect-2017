CREATE OR REPLACE EDITIONABLE PACKAGE "LOCATIONS_API"
IS
   /**
    * This is the API for the table LOCATIONS.
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
    *   p_table_name="LOCATIONS"
    *   p_reuse_existing_api_params="TRUE"
    *   p_col_prefix_in_method_names="TRUE"
    *   p_enable_insertion_of_rows="TRUE"
    *   p_enable_update_of_rows="TRUE"
    *   p_enable_deletion_of_rows="TRUE"
    *   p_enable_generic_change_log="FALSE"
    *   p_enable_dml_view="FALSE"
    *   p_sequence_name="LOCATIONS_SEQ"/>
    *
    * This API provides DML functionality that can be easily called from APEX.
    * Target of the table API is to encapsulate the table DML source code for
    * security (UI schema needs only the execute right for the API and the
    * read/write right for the LOCATIONS_dml_v, tables can be hidden in
    * extra data schema) and easy readability of the business logic (all DML is
    * then written in the same style). For APEX automatic row processing like
    * tabular forms you can optionally use the LOCATIONS_dml_v, which has
    * an instead of trigger who is also calling the LOCATIONS_api.
    */
   ----------------------------------------
   FUNCTION row_exists(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN BOOLEAN;

   ----------------------------------------
   FUNCTION row_exists_yn(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN VARCHAR2;

   ----------------------------------------
   FUNCTION create_row(
      p_location_id    IN locations."LOCATION_ID"%TYPE DEFAULT NULL
    , p_street_address IN locations."STREET_ADDRESS"%TYPE
    , p_postal_code    IN locations."POSTAL_CODE"%TYPE
    , p_city           IN locations."CITY"%TYPE
    , p_state_province IN locations."STATE_PROVINCE"%TYPE
    , p_country_id     IN locations."COUNTRY_ID"%TYPE)
      RETURN locations."LOCATION_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_row(
      p_location_id    IN locations."LOCATION_ID"%TYPE DEFAULT NULL
    , p_street_address IN locations."STREET_ADDRESS"%TYPE
    , p_postal_code    IN locations."POSTAL_CODE"%TYPE
    , p_city           IN locations."CITY"%TYPE
    , p_state_province IN locations."STATE_PROVINCE"%TYPE
    , p_country_id     IN locations."COUNTRY_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_row(p_row IN locations%ROWTYPE)
      RETURN locations."LOCATION_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_row(p_row IN locations%ROWTYPE);

   ----------------------------------------
   FUNCTION read_row(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN locations%ROWTYPE;

   ----------------------------------------
   PROCEDURE read_row(
      p_location_id    IN            locations."LOCATION_ID"%TYPE
    , p_street_address    OUT NOCOPY locations."STREET_ADDRESS"%TYPE
    , p_postal_code       OUT NOCOPY locations."POSTAL_CODE"%TYPE
    , p_city              OUT NOCOPY locations."CITY"%TYPE
    , p_state_province    OUT NOCOPY locations."STATE_PROVINCE"%TYPE
    , p_country_id        OUT NOCOPY locations."COUNTRY_ID"%TYPE);

   ----------------------------------------
   PROCEDURE update_row(
      p_location_id    IN locations."LOCATION_ID"%TYPE DEFAULT NULL
    , p_street_address IN locations."STREET_ADDRESS"%TYPE
    , p_postal_code    IN locations."POSTAL_CODE"%TYPE
    , p_city           IN locations."CITY"%TYPE
    , p_state_province IN locations."STATE_PROVINCE"%TYPE
    , p_country_id     IN locations."COUNTRY_ID"%TYPE);

   ----------------------------------------
   PROCEDURE update_row(p_row IN locations%ROWTYPE);

   ----------------------------------------
   PROCEDURE delete_row(p_location_id IN locations."LOCATION_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_or_update_row(
      p_location_id    IN locations."LOCATION_ID"%TYPE DEFAULT NULL
    , p_street_address IN locations."STREET_ADDRESS"%TYPE
    , p_postal_code    IN locations."POSTAL_CODE"%TYPE
    , p_city           IN locations."CITY"%TYPE
    , p_state_province IN locations."STATE_PROVINCE"%TYPE
    , p_country_id     IN locations."COUNTRY_ID"%TYPE)
      RETURN locations."LOCATION_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_or_update_row(
      p_location_id    IN locations."LOCATION_ID"%TYPE DEFAULT NULL
    , p_street_address IN locations."STREET_ADDRESS"%TYPE
    , p_postal_code    IN locations."POSTAL_CODE"%TYPE
    , p_city           IN locations."CITY"%TYPE
    , p_state_province IN locations."STATE_PROVINCE"%TYPE
    , p_country_id     IN locations."COUNTRY_ID"%TYPE);

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN locations%ROWTYPE)
      RETURN locations."LOCATION_ID"%TYPE;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN locations%ROWTYPE);

   ----------------------------------------
   FUNCTION get_street_address(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN locations."STREET_ADDRESS"%TYPE;

   ----------------------------------------
   FUNCTION get_postal_code(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN locations."POSTAL_CODE"%TYPE;

   ----------------------------------------
   FUNCTION get_city(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN locations."CITY"%TYPE;

   ----------------------------------------
   FUNCTION get_state_province(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN locations."STATE_PROVINCE"%TYPE;

   ----------------------------------------
   FUNCTION get_country_id(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN locations."COUNTRY_ID"%TYPE;

   ----------------------------------------
   PROCEDURE set_street_address(
      p_location_id    IN locations."LOCATION_ID"%TYPE
    , p_street_address IN locations."STREET_ADDRESS"%TYPE);

   ----------------------------------------
   PROCEDURE set_postal_code(p_location_id IN locations."LOCATION_ID"%TYPE
                           , p_postal_code IN locations."POSTAL_CODE"%TYPE);

   ----------------------------------------
   PROCEDURE set_city(p_location_id IN locations."LOCATION_ID"%TYPE
                    , p_city        IN locations."CITY"%TYPE);

   ----------------------------------------
   PROCEDURE set_state_province(
      p_location_id    IN locations."LOCATION_ID"%TYPE
    , p_state_province IN locations."STATE_PROVINCE"%TYPE);

   ----------------------------------------
   PROCEDURE set_country_id(p_location_id IN locations."LOCATION_ID"%TYPE
                          , p_country_id  IN locations."COUNTRY_ID"%TYPE);
----------------------------------------
END locations_api;