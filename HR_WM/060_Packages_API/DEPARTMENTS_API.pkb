CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DEPARTMENTS_API"
IS
   ----------------------------------------
   FUNCTION row_exists(p_department_id IN departments."DEPARTMENT_ID"%TYPE)
      RETURN BOOLEAN
   IS
      v_return BOOLEAN := FALSE;
   BEGIN
      FOR i IN (SELECT 1
                  FROM departments
                 WHERE "DEPARTMENT_ID" = p_department_id)
      LOOP
         v_return := TRUE;
      END LOOP;

      RETURN v_return;
   END;

   ----------------------------------------
   FUNCTION row_exists_yn(p_department_id IN departments."DEPARTMENT_ID"%TYPE)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN CASE
                WHEN row_exists(p_department_id => p_department_id) THEN 'Y'
                ELSE 'N'
             END;
   END;

   ----------------------------------------
   FUNCTION create_row(
      p_department_id   IN departments."DEPARTMENT_ID"%TYPE DEFAULT NULL
    , p_department_name IN departments."DEPARTMENT_NAME"%TYPE
    , p_manager_id      IN departments."MANAGER_ID"%TYPE
    , p_location_id     IN departments."LOCATION_ID"%TYPE)
      RETURN departments."DEPARTMENT_ID"%TYPE
   IS
      v_pk departments."DEPARTMENT_ID"%TYPE;
   BEGIN
      v_pk := COALESCE(p_department_id, departments_seq.NEXTVAL);

      INSERT INTO departments("DEPARTMENT_ID"
                            , "DEPARTMENT_NAME"
                            , "MANAGER_ID"
                            , "LOCATION_ID")
           VALUES (v_pk
                 , p_department_name
                 , p_manager_id
                 , p_location_id);

      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(
      p_department_id   IN departments."DEPARTMENT_ID"%TYPE DEFAULT NULL
    , p_department_name IN departments."DEPARTMENT_NAME"%TYPE
    , p_manager_id      IN departments."MANAGER_ID"%TYPE
    , p_location_id     IN departments."LOCATION_ID"%TYPE)
   IS
      v_pk departments."DEPARTMENT_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_department_id   => p_department_id
                  , p_department_name => p_department_name
                  , p_manager_id      => p_manager_id
                  , p_location_id     => p_location_id);
   END create_row;

   ----------------------------------------
   FUNCTION create_row(p_row IN departments%ROWTYPE)
      RETURN departments."DEPARTMENT_ID"%TYPE
   IS
      v_pk departments."DEPARTMENT_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_department_id   => p_row."DEPARTMENT_ID"
                  , p_department_name => p_row."DEPARTMENT_NAME"
                  , p_manager_id      => p_row."MANAGER_ID"
                  , p_location_id     => p_row."LOCATION_ID");
      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(p_row IN departments%ROWTYPE)
   IS
      v_pk departments."DEPARTMENT_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_department_id   => p_row."DEPARTMENT_ID"
                  , p_department_name => p_row."DEPARTMENT_NAME"
                  , p_manager_id      => p_row."MANAGER_ID"
                  , p_location_id     => p_row."LOCATION_ID");
   END create_row;

   ----------------------------------------
   FUNCTION read_row(p_department_id IN departments."DEPARTMENT_ID"%TYPE)
      RETURN departments%ROWTYPE
   IS
      CURSOR cur_row_by_pk(p_department_id IN departments."DEPARTMENT_ID"%TYPE)
      IS
         SELECT *
           FROM departments
          WHERE "DEPARTMENT_ID" = p_department_id;

      v_row departments%ROWTYPE;
   BEGIN
      OPEN cur_row_by_pk(p_department_id);

      FETCH cur_row_by_pk INTO v_row;

      CLOSE cur_row_by_pk;

      RETURN v_row;
   END read_row;

   ----------------------------------------
   PROCEDURE read_row(
      p_department_id   IN            departments."DEPARTMENT_ID"%TYPE
    , p_department_name    OUT NOCOPY departments."DEPARTMENT_NAME"%TYPE
    , p_manager_id         OUT NOCOPY departments."MANAGER_ID"%TYPE
    , p_location_id        OUT NOCOPY departments."LOCATION_ID"%TYPE)
   IS
      v_row departments%ROWTYPE;
   BEGIN
      v_row := read_row(p_department_id => p_department_id);

      IF v_row."DEPARTMENT_ID" IS NOT NULL
      THEN
         p_department_name := v_row."DEPARTMENT_NAME";
         p_manager_id      := v_row."MANAGER_ID";
         p_location_id     := v_row."LOCATION_ID";
      END IF;
   END read_row;

   ----------------------------------------
   PROCEDURE update_row(
      p_department_id   IN departments."DEPARTMENT_ID"%TYPE DEFAULT NULL
    , p_department_name IN departments."DEPARTMENT_NAME"%TYPE
    , p_manager_id      IN departments."MANAGER_ID"%TYPE
    , p_location_id     IN departments."LOCATION_ID"%TYPE)
   IS
      v_row departments%ROWTYPE;
   BEGIN
      v_row := read_row(p_department_id => p_department_id);

      IF v_row."DEPARTMENT_ID" IS NOT NULL
      THEN
         -- update only, if the column values really differ
         IF COALESCE(v_row."DEPARTMENT_NAME", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_department_name, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."MANAGER_ID", -999999999999999.999999999999999) <>
               COALESCE(p_manager_id, -999999999999999.999999999999999)
         OR COALESCE(v_row."LOCATION_ID", -999999999999999.999999999999999) <>
               COALESCE(p_location_id, -999999999999999.999999999999999)
         THEN
            UPDATE departments
               SET "DEPARTMENT_NAME" = p_department_name
                 , "MANAGER_ID"      = p_manager_id
                 , "LOCATION_ID"     = p_location_id
             WHERE "DEPARTMENT_ID" = v_row."DEPARTMENT_ID";
         END IF;
      END IF;
   END update_row;

   ----------------------------------------
   PROCEDURE update_row(p_row IN departments%ROWTYPE)
   IS
   BEGIN
      update_row(p_department_id   => p_row."DEPARTMENT_ID"
               , p_department_name => p_row."DEPARTMENT_NAME"
               , p_manager_id      => p_row."MANAGER_ID"
               , p_location_id     => p_row."LOCATION_ID");
   END update_row;

   ----------------------------------------
   PROCEDURE delete_row(p_department_id IN departments."DEPARTMENT_ID"%TYPE)
   IS
   BEGIN
      DELETE FROM departments
            WHERE "DEPARTMENT_ID" = p_department_id;
   END delete_row;

   ----------------------------------------
   FUNCTION create_or_update_row(
      p_department_id   IN departments."DEPARTMENT_ID"%TYPE DEFAULT NULL
    , p_department_name IN departments."DEPARTMENT_NAME"%TYPE
    , p_manager_id      IN departments."MANAGER_ID"%TYPE
    , p_location_id     IN departments."LOCATION_ID"%TYPE)
      RETURN departments."DEPARTMENT_ID"%TYPE
   IS
      v_pk departments."DEPARTMENT_ID"%TYPE;
   BEGIN
      IF p_department_id IS NULL
      THEN
         v_pk      :=
            create_row(p_department_id   => p_department_id
                     , p_department_name => p_department_name
                     , p_manager_id      => p_manager_id
                     , p_location_id     => p_location_id);
      ELSE
         IF row_exists(p_department_id => p_department_id)
         THEN
            v_pk := p_department_id;
            update_row(p_department_id   => p_department_id
                     , p_department_name => p_department_name
                     , p_manager_id      => p_manager_id
                     , p_location_id     => p_location_id);
         ELSE
            v_pk      :=
               create_row(p_department_id   => p_department_id
                        , p_department_name => p_department_name
                        , p_manager_id      => p_manager_id
                        , p_location_id     => p_location_id);
         END IF;
      END IF;

      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(
      p_department_id   IN departments."DEPARTMENT_ID"%TYPE DEFAULT NULL
    , p_department_name IN departments."DEPARTMENT_NAME"%TYPE
    , p_manager_id      IN departments."MANAGER_ID"%TYPE
    , p_location_id     IN departments."LOCATION_ID"%TYPE)
   IS
      v_pk departments."DEPARTMENT_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_department_id   => p_department_id
                            , p_department_name => p_department_name
                            , p_manager_id      => p_manager_id
                            , p_location_id     => p_location_id);
   END create_or_update_row;

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN departments%ROWTYPE)
      RETURN departments."DEPARTMENT_ID"%TYPE
   IS
      v_pk departments."DEPARTMENT_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_department_id   => p_row."DEPARTMENT_ID"
                            , p_department_name => p_row."DEPARTMENT_NAME"
                            , p_manager_id      => p_row."MANAGER_ID"
                            , p_location_id     => p_row."LOCATION_ID");
      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN departments%ROWTYPE)
   IS
      v_pk departments."DEPARTMENT_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_department_id   => p_row."DEPARTMENT_ID"
                            , p_department_name => p_row."DEPARTMENT_NAME"
                            , p_manager_id      => p_row."MANAGER_ID"
                            , p_location_id     => p_row."LOCATION_ID");
   END create_or_update_row;

   ----------------------------------------
   FUNCTION get_department_name(
      p_department_id IN departments."DEPARTMENT_ID"%TYPE)
      RETURN departments."DEPARTMENT_NAME"%TYPE
   IS
      v_row departments%ROWTYPE;
   BEGIN
      v_row := read_row(p_department_id => p_department_id);
      RETURN v_row."DEPARTMENT_NAME";
   END get_department_name;

   ----------------------------------------
   FUNCTION get_manager_id(p_department_id IN departments."DEPARTMENT_ID"%TYPE)
      RETURN departments."MANAGER_ID"%TYPE
   IS
      v_row departments%ROWTYPE;
   BEGIN
      v_row := read_row(p_department_id => p_department_id);
      RETURN v_row."MANAGER_ID";
   END get_manager_id;

   ----------------------------------------
   FUNCTION get_location_id(
      p_department_id IN departments."DEPARTMENT_ID"%TYPE)
      RETURN departments."LOCATION_ID"%TYPE
   IS
      v_row departments%ROWTYPE;
   BEGIN
      v_row := read_row(p_department_id => p_department_id);
      RETURN v_row."LOCATION_ID";
   END get_location_id;

   ----------------------------------------
   PROCEDURE set_department_name(
      p_department_id   IN departments."DEPARTMENT_ID"%TYPE
    , p_department_name IN departments."DEPARTMENT_NAME"%TYPE)
   IS
      v_row departments%ROWTYPE;
   BEGIN
      v_row := read_row(p_department_id => p_department_id);

      IF v_row."DEPARTMENT_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."DEPARTMENT_NAME", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_department_name, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE departments
               SET "DEPARTMENT_NAME" = p_department_name
             WHERE "DEPARTMENT_ID" = p_department_id;
         END IF;
      END IF;
   END set_department_name;

   ----------------------------------------
   PROCEDURE set_manager_id(p_department_id IN departments."DEPARTMENT_ID"%TYPE
                          , p_manager_id    IN departments."MANAGER_ID"%TYPE)
   IS
      v_row departments%ROWTYPE;
   BEGIN
      v_row := read_row(p_department_id => p_department_id);

      IF v_row."DEPARTMENT_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."MANAGER_ID", -999999999999999.999999999999999) <>
               COALESCE(p_manager_id, -999999999999999.999999999999999)
         THEN
            UPDATE departments
               SET "MANAGER_ID" = p_manager_id
             WHERE "DEPARTMENT_ID" = p_department_id;
         END IF;
      END IF;
   END set_manager_id;

   ----------------------------------------
   PROCEDURE set_location_id(
      p_department_id IN departments."DEPARTMENT_ID"%TYPE
    , p_location_id   IN departments."LOCATION_ID"%TYPE)
   IS
      v_row departments%ROWTYPE;
   BEGIN
      v_row := read_row(p_department_id => p_department_id);

      IF v_row."DEPARTMENT_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."LOCATION_ID", -999999999999999.999999999999999) <>
               COALESCE(p_location_id, -999999999999999.999999999999999)
         THEN
            UPDATE departments
               SET "LOCATION_ID" = p_location_id
             WHERE "DEPARTMENT_ID" = p_department_id;
         END IF;
      END IF;
   END set_location_id;
----------------------------------------
END departments_api;