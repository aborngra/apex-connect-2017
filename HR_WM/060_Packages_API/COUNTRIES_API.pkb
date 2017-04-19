CREATE OR REPLACE EDITIONABLE PACKAGE BODY "COUNTRIES_API"
IS
   ----------------------------------------
   FUNCTION row_exists(p_country_id IN countries."COUNTRY_ID"%TYPE)
      RETURN BOOLEAN
   IS
      v_return BOOLEAN := FALSE;
   BEGIN
      FOR i IN (SELECT 1
                  FROM countries
                 WHERE "COUNTRY_ID" = p_country_id)
      LOOP
         v_return := TRUE;
      END LOOP;

      RETURN v_return;
   END;

   ----------------------------------------
   FUNCTION row_exists_yn(p_country_id IN countries."COUNTRY_ID"%TYPE)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN CASE
                WHEN row_exists(p_country_id => p_country_id) THEN 'Y'
                ELSE 'N'
             END;
   END;

   ----------------------------------------
   FUNCTION create_row(p_country_id   IN countries."COUNTRY_ID"%TYPE DEFAULT NULL
                     , p_country_name IN countries."COUNTRY_NAME"%TYPE
                     , p_region_id    IN countries."REGION_ID"%TYPE)
      RETURN countries."COUNTRY_ID"%TYPE
   IS
      v_pk countries."COUNTRY_ID"%TYPE;
   BEGIN
      v_pk := COALESCE(p_country_id, countries_seq.NEXTVAL);

      INSERT INTO countries("COUNTRY_ID", "COUNTRY_NAME", "REGION_ID")
           VALUES (v_pk, p_country_name, p_region_id);

      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(
      p_country_id   IN countries."COUNTRY_ID"%TYPE DEFAULT NULL
    , p_country_name IN countries."COUNTRY_NAME"%TYPE
    , p_region_id    IN countries."REGION_ID"%TYPE)
   IS
      v_pk countries."COUNTRY_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_country_id   => p_country_id
                  , p_country_name => p_country_name
                  , p_region_id    => p_region_id);
   END create_row;

   ----------------------------------------
   FUNCTION create_row(p_row IN countries%ROWTYPE)
      RETURN countries."COUNTRY_ID"%TYPE
   IS
      v_pk countries."COUNTRY_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_country_id   => p_row."COUNTRY_ID"
                  , p_country_name => p_row."COUNTRY_NAME"
                  , p_region_id    => p_row."REGION_ID");
      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(p_row IN countries%ROWTYPE)
   IS
      v_pk countries."COUNTRY_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_country_id   => p_row."COUNTRY_ID"
                  , p_country_name => p_row."COUNTRY_NAME"
                  , p_region_id    => p_row."REGION_ID");
   END create_row;

   ----------------------------------------
   FUNCTION read_row(p_country_id IN countries."COUNTRY_ID"%TYPE)
      RETURN countries%ROWTYPE
   IS
      CURSOR cur_row_by_pk(p_country_id IN countries."COUNTRY_ID"%TYPE)
      IS
         SELECT *
           FROM countries
          WHERE "COUNTRY_ID" = p_country_id;

      v_row countries%ROWTYPE;
   BEGIN
      OPEN cur_row_by_pk(p_country_id);

      FETCH cur_row_by_pk INTO v_row;

      CLOSE cur_row_by_pk;

      RETURN v_row;
   END read_row;

   ----------------------------------------
   PROCEDURE read_row(
      p_country_id   IN            countries."COUNTRY_ID"%TYPE
    , p_country_name    OUT NOCOPY countries."COUNTRY_NAME"%TYPE
    , p_region_id       OUT NOCOPY countries."REGION_ID"%TYPE)
   IS
      v_row countries%ROWTYPE;
   BEGIN
      v_row := read_row(p_country_id => p_country_id);

      IF v_row."COUNTRY_ID" IS NOT NULL
      THEN
         p_country_name := v_row."COUNTRY_NAME";
         p_region_id    := v_row."REGION_ID";
      END IF;
   END read_row;

   ----------------------------------------
   PROCEDURE update_row(
      p_country_id   IN countries."COUNTRY_ID"%TYPE DEFAULT NULL
    , p_country_name IN countries."COUNTRY_NAME"%TYPE
    , p_region_id    IN countries."REGION_ID"%TYPE)
   IS
      v_row countries%ROWTYPE;
   BEGIN
      v_row := read_row(p_country_id => p_country_id);

      IF v_row."COUNTRY_ID" IS NOT NULL
      THEN
         -- update only, if the column values really differ
         IF COALESCE(v_row."COUNTRY_NAME", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_country_name, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."REGION_ID", -999999999999999.999999999999999) <>
               COALESCE(p_region_id, -999999999999999.999999999999999)
         THEN
            UPDATE countries
               SET "COUNTRY_NAME" = p_country_name, "REGION_ID" = p_region_id
             WHERE "COUNTRY_ID" = v_row."COUNTRY_ID";
         END IF;
      END IF;
   END update_row;

   ----------------------------------------
   PROCEDURE update_row(p_row IN countries%ROWTYPE)
   IS
   BEGIN
      update_row(p_country_id   => p_row."COUNTRY_ID"
               , p_country_name => p_row."COUNTRY_NAME"
               , p_region_id    => p_row."REGION_ID");
   END update_row;

   ----------------------------------------
   PROCEDURE delete_row(p_country_id IN countries."COUNTRY_ID"%TYPE)
   IS
   BEGIN
      DELETE FROM countries
            WHERE "COUNTRY_ID" = p_country_id;
   END delete_row;

   ----------------------------------------
   FUNCTION create_or_update_row(
      p_country_id   IN countries."COUNTRY_ID"%TYPE DEFAULT NULL
    , p_country_name IN countries."COUNTRY_NAME"%TYPE
    , p_region_id    IN countries."REGION_ID"%TYPE)
      RETURN countries."COUNTRY_ID"%TYPE
   IS
      v_pk countries."COUNTRY_ID"%TYPE;
   BEGIN
      IF p_country_id IS NULL
      THEN
         v_pk      :=
            create_row(p_country_id   => p_country_id
                     , p_country_name => p_country_name
                     , p_region_id    => p_region_id);
      ELSE
         IF row_exists(p_country_id => p_country_id)
         THEN
            v_pk := p_country_id;
            update_row(p_country_id   => p_country_id
                     , p_country_name => p_country_name
                     , p_region_id    => p_region_id);
         ELSE
            v_pk      :=
               create_row(p_country_id   => p_country_id
                        , p_country_name => p_country_name
                        , p_region_id    => p_region_id);
         END IF;
      END IF;

      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(
      p_country_id   IN countries."COUNTRY_ID"%TYPE DEFAULT NULL
    , p_country_name IN countries."COUNTRY_NAME"%TYPE
    , p_region_id    IN countries."REGION_ID"%TYPE)
   IS
      v_pk countries."COUNTRY_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_country_id   => p_country_id
                            , p_country_name => p_country_name
                            , p_region_id    => p_region_id);
   END create_or_update_row;

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN countries%ROWTYPE)
      RETURN countries."COUNTRY_ID"%TYPE
   IS
      v_pk countries."COUNTRY_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_country_id   => p_row."COUNTRY_ID"
                            , p_country_name => p_row."COUNTRY_NAME"
                            , p_region_id    => p_row."REGION_ID");
      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN countries%ROWTYPE)
   IS
      v_pk countries."COUNTRY_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_country_id   => p_row."COUNTRY_ID"
                            , p_country_name => p_row."COUNTRY_NAME"
                            , p_region_id    => p_row."REGION_ID");
   END create_or_update_row;

   ----------------------------------------
   FUNCTION get_country_name(p_country_id IN countries."COUNTRY_ID"%TYPE)
      RETURN countries."COUNTRY_NAME"%TYPE
   IS
      v_row countries%ROWTYPE;
   BEGIN
      v_row := read_row(p_country_id => p_country_id);
      RETURN v_row."COUNTRY_NAME";
   END get_country_name;

   ----------------------------------------
   FUNCTION get_region_id(p_country_id IN countries."COUNTRY_ID"%TYPE)
      RETURN countries."REGION_ID"%TYPE
   IS
      v_row countries%ROWTYPE;
   BEGIN
      v_row := read_row(p_country_id => p_country_id);
      RETURN v_row."REGION_ID";
   END get_region_id;

   ----------------------------------------
   PROCEDURE set_country_name(p_country_id   IN countries."COUNTRY_ID"%TYPE
                            , p_country_name IN countries."COUNTRY_NAME"%TYPE)
   IS
      v_row countries%ROWTYPE;
   BEGIN
      v_row := read_row(p_country_id => p_country_id);

      IF v_row."COUNTRY_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."COUNTRY_NAME", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_country_name, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE countries
               SET "COUNTRY_NAME" = p_country_name
             WHERE "COUNTRY_ID" = p_country_id;
         END IF;
      END IF;
   END set_country_name;

   ----------------------------------------
   PROCEDURE set_region_id(p_country_id IN countries."COUNTRY_ID"%TYPE
                         , p_region_id  IN countries."REGION_ID"%TYPE)
   IS
      v_row countries%ROWTYPE;
   BEGIN
      v_row := read_row(p_country_id => p_country_id);

      IF v_row."COUNTRY_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."REGION_ID", -999999999999999.999999999999999) <>
               COALESCE(p_region_id, -999999999999999.999999999999999)
         THEN
            UPDATE countries
               SET "REGION_ID" = p_region_id
             WHERE "COUNTRY_ID" = p_country_id;
         END IF;
      END IF;
   END set_region_id;
----------------------------------------
END countries_api;