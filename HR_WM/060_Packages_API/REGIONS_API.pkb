CREATE OR REPLACE EDITIONABLE PACKAGE BODY "REGIONS_API"
IS
   ----------------------------------------
   FUNCTION row_exists(p_region_id IN regions."REGION_ID"%TYPE)
      RETURN BOOLEAN
   IS
      v_return BOOLEAN := FALSE;
   BEGIN
      FOR i IN (SELECT 1
                  FROM regions
                 WHERE "REGION_ID" = p_region_id)
      LOOP
         v_return := TRUE;
      END LOOP;

      RETURN v_return;
   END;

   ----------------------------------------
   FUNCTION row_exists_yn(p_region_id IN regions."REGION_ID"%TYPE)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN CASE
                WHEN row_exists(p_region_id => p_region_id) THEN 'Y'
                ELSE 'N'
             END;
   END;

   ----------------------------------------
   FUNCTION create_row(p_region_id   IN regions."REGION_ID"%TYPE DEFAULT NULL
                     , p_region_name IN regions."REGION_NAME"%TYPE)
      RETURN regions."REGION_ID"%TYPE
   IS
      v_pk regions."REGION_ID"%TYPE;
   BEGIN
      v_pk := COALESCE(p_region_id, regions_seq.NEXTVAL);

      INSERT INTO regions("REGION_ID", "REGION_NAME")
           VALUES (v_pk, p_region_name);

      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(p_region_id   IN regions."REGION_ID"%TYPE DEFAULT NULL
                      , p_region_name IN regions."REGION_NAME"%TYPE)
   IS
      v_pk regions."REGION_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_region_id => p_region_id, p_region_name => p_region_name);
   END create_row;

   ----------------------------------------
   FUNCTION create_row(p_row IN regions%ROWTYPE)
      RETURN regions."REGION_ID"%TYPE
   IS
      v_pk regions."REGION_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_region_id   => p_row."REGION_ID"
                  , p_region_name => p_row."REGION_NAME");
      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(p_row IN regions%ROWTYPE)
   IS
      v_pk regions."REGION_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_region_id   => p_row."REGION_ID"
                  , p_region_name => p_row."REGION_NAME");
   END create_row;

   ----------------------------------------
   FUNCTION read_row(p_region_id IN regions."REGION_ID"%TYPE)
      RETURN regions%ROWTYPE
   IS
      CURSOR cur_row_by_pk(p_region_id IN regions."REGION_ID"%TYPE)
      IS
         SELECT *
           FROM regions
          WHERE "REGION_ID" = p_region_id;

      v_row regions%ROWTYPE;
   BEGIN
      OPEN cur_row_by_pk(p_region_id);

      FETCH cur_row_by_pk INTO v_row;

      CLOSE cur_row_by_pk;

      RETURN v_row;
   END read_row;

   ----------------------------------------
   PROCEDURE read_row(p_region_id   IN            regions."REGION_ID"%TYPE
                    , p_region_name    OUT NOCOPY regions."REGION_NAME"%TYPE)
   IS
      v_row regions%ROWTYPE;
   BEGIN
      v_row := read_row(p_region_id => p_region_id);

      IF v_row."REGION_ID" IS NOT NULL
      THEN
         p_region_name := v_row."REGION_NAME";
      END IF;
   END read_row;

   ----------------------------------------
   PROCEDURE update_row(p_region_id   IN regions."REGION_ID"%TYPE DEFAULT NULL
                      , p_region_name IN regions."REGION_NAME"%TYPE)
   IS
      v_row regions%ROWTYPE;
   BEGIN
      v_row := read_row(p_region_id => p_region_id);

      IF v_row."REGION_ID" IS NOT NULL
      THEN
         -- update only, if the column values really differ
         IF COALESCE(v_row."REGION_NAME", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_region_name, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE regions
               SET "REGION_NAME" = p_region_name
             WHERE "REGION_ID" = v_row."REGION_ID";
         END IF;
      END IF;
   END update_row;

   ----------------------------------------
   PROCEDURE update_row(p_row IN regions%ROWTYPE)
   IS
   BEGIN
      update_row(p_region_id   => p_row."REGION_ID"
               , p_region_name => p_row."REGION_NAME");
   END update_row;

   ----------------------------------------
   PROCEDURE delete_row(p_region_id IN regions."REGION_ID"%TYPE)
   IS
   BEGIN
      DELETE FROM regions
            WHERE "REGION_ID" = p_region_id;
   END delete_row;

   ----------------------------------------
   FUNCTION create_or_update_row(
      p_region_id   IN regions."REGION_ID"%TYPE DEFAULT NULL
    , p_region_name IN regions."REGION_NAME"%TYPE)
      RETURN regions."REGION_ID"%TYPE
   IS
      v_pk regions."REGION_ID"%TYPE;
   BEGIN
      IF p_region_id IS NULL
      THEN
         v_pk      :=
            create_row(p_region_id   => p_region_id
                     , p_region_name => p_region_name);
      ELSE
         IF row_exists(p_region_id => p_region_id)
         THEN
            v_pk := p_region_id;
            update_row(p_region_id   => p_region_id
                     , p_region_name => p_region_name);
         ELSE
            v_pk      :=
               create_row(p_region_id   => p_region_id
                        , p_region_name => p_region_name);
         END IF;
      END IF;

      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(
      p_region_id   IN regions."REGION_ID"%TYPE DEFAULT NULL
    , p_region_name IN regions."REGION_NAME"%TYPE)
   IS
      v_pk regions."REGION_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_region_id   => p_region_id
                            , p_region_name => p_region_name);
   END create_or_update_row;

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN regions%ROWTYPE)
      RETURN regions."REGION_ID"%TYPE
   IS
      v_pk regions."REGION_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_region_id   => p_row."REGION_ID"
                            , p_region_name => p_row."REGION_NAME");
      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN regions%ROWTYPE)
   IS
      v_pk regions."REGION_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_region_id   => p_row."REGION_ID"
                            , p_region_name => p_row."REGION_NAME");
   END create_or_update_row;

   ----------------------------------------
   FUNCTION get_region_name(p_region_id IN regions."REGION_ID"%TYPE)
      RETURN regions."REGION_NAME"%TYPE
   IS
      v_row regions%ROWTYPE;
   BEGIN
      v_row := read_row(p_region_id => p_region_id);
      RETURN v_row."REGION_NAME";
   END get_region_name;

   ----------------------------------------
   PROCEDURE set_region_name(p_region_id   IN regions."REGION_ID"%TYPE
                           , p_region_name IN regions."REGION_NAME"%TYPE)
   IS
      v_row regions%ROWTYPE;
   BEGIN
      v_row := read_row(p_region_id => p_region_id);

      IF v_row."REGION_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."REGION_NAME", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_region_name, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE regions
               SET "REGION_NAME" = p_region_name
             WHERE "REGION_ID" = p_region_id;
         END IF;
      END IF;
   END set_region_name;
----------------------------------------
END regions_api;