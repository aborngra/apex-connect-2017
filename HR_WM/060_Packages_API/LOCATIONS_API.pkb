CREATE OR REPLACE EDITIONABLE PACKAGE BODY "LOCATIONS_API"
IS
   ----------------------------------------
   FUNCTION row_exists(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN BOOLEAN
   IS
      v_return BOOLEAN := FALSE;
   BEGIN
      FOR i IN (SELECT 1
                  FROM locations
                 WHERE "LOCATION_ID" = p_location_id)
      LOOP
         v_return := TRUE;
      END LOOP;

      RETURN v_return;
   END;

   ----------------------------------------
   FUNCTION row_exists_yn(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN CASE
                WHEN row_exists(p_location_id => p_location_id) THEN 'Y'
                ELSE 'N'
             END;
   END;

   ----------------------------------------
   FUNCTION create_row(
      p_location_id    IN locations."LOCATION_ID"%TYPE DEFAULT NULL
    , p_street_address IN locations."STREET_ADDRESS"%TYPE
    , p_postal_code    IN locations."POSTAL_CODE"%TYPE
    , p_city           IN locations."CITY"%TYPE
    , p_state_province IN locations."STATE_PROVINCE"%TYPE
    , p_country_id     IN locations."COUNTRY_ID"%TYPE)
      RETURN locations."LOCATION_ID"%TYPE
   IS
      v_pk locations."LOCATION_ID"%TYPE;
   BEGIN
      v_pk := COALESCE(p_location_id, locations_seq.NEXTVAL);

      INSERT INTO locations("LOCATION_ID"
                          , "STREET_ADDRESS"
                          , "POSTAL_CODE"
                          , "CITY"
                          , "STATE_PROVINCE"
                          , "COUNTRY_ID")
           VALUES (v_pk
                 , p_street_address
                 , p_postal_code
                 , p_city
                 , p_state_province
                 , p_country_id);

      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(
      p_location_id    IN locations."LOCATION_ID"%TYPE DEFAULT NULL
    , p_street_address IN locations."STREET_ADDRESS"%TYPE
    , p_postal_code    IN locations."POSTAL_CODE"%TYPE
    , p_city           IN locations."CITY"%TYPE
    , p_state_province IN locations."STATE_PROVINCE"%TYPE
    , p_country_id     IN locations."COUNTRY_ID"%TYPE)
   IS
      v_pk locations."LOCATION_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_location_id    => p_location_id
                  , p_street_address => p_street_address
                  , p_postal_code    => p_postal_code
                  , p_city           => p_city
                  , p_state_province => p_state_province
                  , p_country_id     => p_country_id);
   END create_row;

   ----------------------------------------
   FUNCTION create_row(p_row IN locations%ROWTYPE)
      RETURN locations."LOCATION_ID"%TYPE
   IS
      v_pk locations."LOCATION_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_location_id    => p_row."LOCATION_ID"
                  , p_street_address => p_row."STREET_ADDRESS"
                  , p_postal_code    => p_row."POSTAL_CODE"
                  , p_city           => p_row."CITY"
                  , p_state_province => p_row."STATE_PROVINCE"
                  , p_country_id     => p_row."COUNTRY_ID");
      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(p_row IN locations%ROWTYPE)
   IS
      v_pk locations."LOCATION_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_location_id    => p_row."LOCATION_ID"
                  , p_street_address => p_row."STREET_ADDRESS"
                  , p_postal_code    => p_row."POSTAL_CODE"
                  , p_city           => p_row."CITY"
                  , p_state_province => p_row."STATE_PROVINCE"
                  , p_country_id     => p_row."COUNTRY_ID");
   END create_row;

   ----------------------------------------
   FUNCTION read_row(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN locations%ROWTYPE
   IS
      CURSOR cur_row_by_pk(p_location_id IN locations."LOCATION_ID"%TYPE)
      IS
         SELECT *
           FROM locations
          WHERE "LOCATION_ID" = p_location_id;

      v_row locations%ROWTYPE;
   BEGIN
      OPEN cur_row_by_pk(p_location_id);

      FETCH cur_row_by_pk INTO v_row;

      CLOSE cur_row_by_pk;

      RETURN v_row;
   END read_row;

   ----------------------------------------
   PROCEDURE read_row(
      p_location_id    IN            locations."LOCATION_ID"%TYPE
    , p_street_address    OUT NOCOPY locations."STREET_ADDRESS"%TYPE
    , p_postal_code       OUT NOCOPY locations."POSTAL_CODE"%TYPE
    , p_city              OUT NOCOPY locations."CITY"%TYPE
    , p_state_province    OUT NOCOPY locations."STATE_PROVINCE"%TYPE
    , p_country_id        OUT NOCOPY locations."COUNTRY_ID"%TYPE)
   IS
      v_row locations%ROWTYPE;
   BEGIN
      v_row := read_row(p_location_id => p_location_id);

      IF v_row."LOCATION_ID" IS NOT NULL
      THEN
         p_street_address := v_row."STREET_ADDRESS";
         p_postal_code    := v_row."POSTAL_CODE";
         p_city           := v_row."CITY";
         p_state_province := v_row."STATE_PROVINCE";
         p_country_id     := v_row."COUNTRY_ID";
      END IF;
   END read_row;

   ----------------------------------------
   PROCEDURE update_row(
      p_location_id    IN locations."LOCATION_ID"%TYPE DEFAULT NULL
    , p_street_address IN locations."STREET_ADDRESS"%TYPE
    , p_postal_code    IN locations."POSTAL_CODE"%TYPE
    , p_city           IN locations."CITY"%TYPE
    , p_state_province IN locations."STATE_PROVINCE"%TYPE
    , p_country_id     IN locations."COUNTRY_ID"%TYPE)
   IS
      v_row locations%ROWTYPE;
   BEGIN
      v_row := read_row(p_location_id => p_location_id);

      IF v_row."LOCATION_ID" IS NOT NULL
      THEN
         -- update only, if the column values really differ
         IF COALESCE(v_row."STREET_ADDRESS", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_street_address, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."POSTAL_CODE", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_postal_code, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."CITY", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_city, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."STATE_PROVINCE", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_state_province, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."COUNTRY_ID", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_country_id, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE locations
               SET "STREET_ADDRESS" = p_street_address
                 , "POSTAL_CODE"    = p_postal_code
                 , "CITY"           = p_city
                 , "STATE_PROVINCE" = p_state_province
                 , "COUNTRY_ID"     = p_country_id
             WHERE "LOCATION_ID" = v_row."LOCATION_ID";
         END IF;
      END IF;
   END update_row;

   ----------------------------------------
   PROCEDURE update_row(p_row IN locations%ROWTYPE)
   IS
   BEGIN
      update_row(p_location_id    => p_row."LOCATION_ID"
               , p_street_address => p_row."STREET_ADDRESS"
               , p_postal_code    => p_row."POSTAL_CODE"
               , p_city           => p_row."CITY"
               , p_state_province => p_row."STATE_PROVINCE"
               , p_country_id     => p_row."COUNTRY_ID");
   END update_row;

   ----------------------------------------
   PROCEDURE delete_row(p_location_id IN locations."LOCATION_ID"%TYPE)
   IS
   BEGIN
      DELETE FROM locations
            WHERE "LOCATION_ID" = p_location_id;
   END delete_row;

   ----------------------------------------
   FUNCTION create_or_update_row(
      p_location_id    IN locations."LOCATION_ID"%TYPE DEFAULT NULL
    , p_street_address IN locations."STREET_ADDRESS"%TYPE
    , p_postal_code    IN locations."POSTAL_CODE"%TYPE
    , p_city           IN locations."CITY"%TYPE
    , p_state_province IN locations."STATE_PROVINCE"%TYPE
    , p_country_id     IN locations."COUNTRY_ID"%TYPE)
      RETURN locations."LOCATION_ID"%TYPE
   IS
      v_pk locations."LOCATION_ID"%TYPE;
   BEGIN
      IF p_location_id IS NULL
      THEN
         v_pk      :=
            create_row(p_location_id    => p_location_id
                     , p_street_address => p_street_address
                     , p_postal_code    => p_postal_code
                     , p_city           => p_city
                     , p_state_province => p_state_province
                     , p_country_id     => p_country_id);
      ELSE
         IF row_exists(p_location_id => p_location_id)
         THEN
            v_pk := p_location_id;
            update_row(p_location_id    => p_location_id
                     , p_street_address => p_street_address
                     , p_postal_code    => p_postal_code
                     , p_city           => p_city
                     , p_state_province => p_state_province
                     , p_country_id     => p_country_id);
         ELSE
            v_pk      :=
               create_row(p_location_id    => p_location_id
                        , p_street_address => p_street_address
                        , p_postal_code    => p_postal_code
                        , p_city           => p_city
                        , p_state_province => p_state_province
                        , p_country_id     => p_country_id);
         END IF;
      END IF;

      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(
      p_location_id    IN locations."LOCATION_ID"%TYPE DEFAULT NULL
    , p_street_address IN locations."STREET_ADDRESS"%TYPE
    , p_postal_code    IN locations."POSTAL_CODE"%TYPE
    , p_city           IN locations."CITY"%TYPE
    , p_state_province IN locations."STATE_PROVINCE"%TYPE
    , p_country_id     IN locations."COUNTRY_ID"%TYPE)
   IS
      v_pk locations."LOCATION_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_location_id    => p_location_id
                            , p_street_address => p_street_address
                            , p_postal_code    => p_postal_code
                            , p_city           => p_city
                            , p_state_province => p_state_province
                            , p_country_id     => p_country_id);
   END create_or_update_row;

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN locations%ROWTYPE)
      RETURN locations."LOCATION_ID"%TYPE
   IS
      v_pk locations."LOCATION_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_location_id    => p_row."LOCATION_ID"
                            , p_street_address => p_row."STREET_ADDRESS"
                            , p_postal_code    => p_row."POSTAL_CODE"
                            , p_city           => p_row."CITY"
                            , p_state_province => p_row."STATE_PROVINCE"
                            , p_country_id     => p_row."COUNTRY_ID");
      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN locations%ROWTYPE)
   IS
      v_pk locations."LOCATION_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_location_id    => p_row."LOCATION_ID"
                            , p_street_address => p_row."STREET_ADDRESS"
                            , p_postal_code    => p_row."POSTAL_CODE"
                            , p_city           => p_row."CITY"
                            , p_state_province => p_row."STATE_PROVINCE"
                            , p_country_id     => p_row."COUNTRY_ID");
   END create_or_update_row;

   ----------------------------------------
   FUNCTION get_street_address(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN locations."STREET_ADDRESS"%TYPE
   IS
      v_row locations%ROWTYPE;
   BEGIN
      v_row := read_row(p_location_id => p_location_id);
      RETURN v_row."STREET_ADDRESS";
   END get_street_address;

   ----------------------------------------
   FUNCTION get_postal_code(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN locations."POSTAL_CODE"%TYPE
   IS
      v_row locations%ROWTYPE;
   BEGIN
      v_row := read_row(p_location_id => p_location_id);
      RETURN v_row."POSTAL_CODE";
   END get_postal_code;

   ----------------------------------------
   FUNCTION get_city(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN locations."CITY"%TYPE
   IS
      v_row locations%ROWTYPE;
   BEGIN
      v_row := read_row(p_location_id => p_location_id);
      RETURN v_row."CITY";
   END get_city;

   ----------------------------------------
   FUNCTION get_state_province(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN locations."STATE_PROVINCE"%TYPE
   IS
      v_row locations%ROWTYPE;
   BEGIN
      v_row := read_row(p_location_id => p_location_id);
      RETURN v_row."STATE_PROVINCE";
   END get_state_province;

   ----------------------------------------
   FUNCTION get_country_id(p_location_id IN locations."LOCATION_ID"%TYPE)
      RETURN locations."COUNTRY_ID"%TYPE
   IS
      v_row locations%ROWTYPE;
   BEGIN
      v_row := read_row(p_location_id => p_location_id);
      RETURN v_row."COUNTRY_ID";
   END get_country_id;

   ----------------------------------------
   PROCEDURE set_street_address(
      p_location_id    IN locations."LOCATION_ID"%TYPE
    , p_street_address IN locations."STREET_ADDRESS"%TYPE)
   IS
      v_row locations%ROWTYPE;
   BEGIN
      v_row := read_row(p_location_id => p_location_id);

      IF v_row."LOCATION_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."STREET_ADDRESS", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_street_address, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE locations
               SET "STREET_ADDRESS" = p_street_address
             WHERE "LOCATION_ID" = p_location_id;
         END IF;
      END IF;
   END set_street_address;

   ----------------------------------------
   PROCEDURE set_postal_code(p_location_id IN locations."LOCATION_ID"%TYPE
                           , p_postal_code IN locations."POSTAL_CODE"%TYPE)
   IS
      v_row locations%ROWTYPE;
   BEGIN
      v_row := read_row(p_location_id => p_location_id);

      IF v_row."LOCATION_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."POSTAL_CODE", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_postal_code, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE locations
               SET "POSTAL_CODE" = p_postal_code
             WHERE "LOCATION_ID" = p_location_id;
         END IF;
      END IF;
   END set_postal_code;

   ----------------------------------------
   PROCEDURE set_city(p_location_id IN locations."LOCATION_ID"%TYPE
                    , p_city        IN locations."CITY"%TYPE)
   IS
      v_row locations%ROWTYPE;
   BEGIN
      v_row := read_row(p_location_id => p_location_id);

      IF v_row."LOCATION_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."CITY", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_city, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE locations
               SET "CITY" = p_city
             WHERE "LOCATION_ID" = p_location_id;
         END IF;
      END IF;
   END set_city;

   ----------------------------------------
   PROCEDURE set_state_province(
      p_location_id    IN locations."LOCATION_ID"%TYPE
    , p_state_province IN locations."STATE_PROVINCE"%TYPE)
   IS
      v_row locations%ROWTYPE;
   BEGIN
      v_row := read_row(p_location_id => p_location_id);

      IF v_row."LOCATION_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."STATE_PROVINCE", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_state_province, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE locations
               SET "STATE_PROVINCE" = p_state_province
             WHERE "LOCATION_ID" = p_location_id;
         END IF;
      END IF;
   END set_state_province;

   ----------------------------------------
   PROCEDURE set_country_id(p_location_id IN locations."LOCATION_ID"%TYPE
                          , p_country_id  IN locations."COUNTRY_ID"%TYPE)
   IS
      v_row locations%ROWTYPE;
   BEGIN
      v_row := read_row(p_location_id => p_location_id);

      IF v_row."LOCATION_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."COUNTRY_ID", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_country_id, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE locations
               SET "COUNTRY_ID" = p_country_id
             WHERE "LOCATION_ID" = p_location_id;
         END IF;
      END IF;
   END set_country_id;
----------------------------------------
END locations_api;