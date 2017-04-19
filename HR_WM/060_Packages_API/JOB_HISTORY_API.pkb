CREATE OR REPLACE EDITIONABLE PACKAGE BODY "JOB_HISTORY_API"
IS
   ----------------------------------------
   FUNCTION row_exists(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN BOOLEAN
   IS
      v_return BOOLEAN := FALSE;
   BEGIN
      FOR i IN (SELECT 1
                  FROM job_history
                 WHERE "EMPLOYEE_ID" = p_employee_id)
      LOOP
         v_return := TRUE;
      END LOOP;

      RETURN v_return;
   END;

   ----------------------------------------
   FUNCTION row_exists_yn(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN CASE
                WHEN row_exists(p_employee_id => p_employee_id) THEN 'Y'
                ELSE 'N'
             END;
   END;

   ----------------------------------------
   FUNCTION create_row(p_employee_id   IN job_history."EMPLOYEE_ID"%TYPE
                     , p_start_date    IN job_history."START_DATE"%TYPE
                     , p_end_date      IN job_history."END_DATE"%TYPE
                     , p_job_id        IN job_history."JOB_ID"%TYPE
                     , p_department_id IN job_history."DEPARTMENT_ID"%TYPE)
      RETURN job_history."EMPLOYEE_ID"%TYPE
   IS
      v_pk job_history."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk := COALESCE(p_employee_id, job_history_seq.NEXTVAL);

      INSERT INTO job_history("EMPLOYEE_ID"
                            , "START_DATE"
                            , "END_DATE"
                            , "JOB_ID"
                            , "DEPARTMENT_ID")
           VALUES (v_pk
                 , p_start_date
                 , p_end_date
                 , p_job_id
                 , p_department_id);

      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(p_employee_id   IN job_history."EMPLOYEE_ID"%TYPE
                      , p_start_date    IN job_history."START_DATE"%TYPE
                      , p_end_date      IN job_history."END_DATE"%TYPE
                      , p_job_id        IN job_history."JOB_ID"%TYPE
                      , p_department_id IN job_history."DEPARTMENT_ID"%TYPE)
   IS
      v_pk job_history."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_employee_id   => p_employee_id
                  , p_start_date    => p_start_date
                  , p_end_date      => p_end_date
                  , p_job_id        => p_job_id
                  , p_department_id => p_department_id);
   END create_row;

   ----------------------------------------
   FUNCTION create_row(p_row IN job_history%ROWTYPE)
      RETURN job_history."EMPLOYEE_ID"%TYPE
   IS
      v_pk job_history."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_employee_id   => p_row."EMPLOYEE_ID"
                  , p_start_date    => p_row."START_DATE"
                  , p_end_date      => p_row."END_DATE"
                  , p_job_id        => p_row."JOB_ID"
                  , p_department_id => p_row."DEPARTMENT_ID");
      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(p_row IN job_history%ROWTYPE)
   IS
      v_pk job_history."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_employee_id   => p_row."EMPLOYEE_ID"
                  , p_start_date    => p_row."START_DATE"
                  , p_end_date      => p_row."END_DATE"
                  , p_job_id        => p_row."JOB_ID"
                  , p_department_id => p_row."DEPARTMENT_ID");
   END create_row;

   ----------------------------------------
   FUNCTION read_row(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN job_history%ROWTYPE
   IS
      CURSOR cur_row_by_pk(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      IS
         SELECT *
           FROM job_history
          WHERE "EMPLOYEE_ID" = p_employee_id;

      v_row job_history%ROWTYPE;
   BEGIN
      OPEN cur_row_by_pk(p_employee_id);

      FETCH cur_row_by_pk INTO v_row;

      CLOSE cur_row_by_pk;

      RETURN v_row;
   END read_row;

   ----------------------------------------
   PROCEDURE read_row(
      p_employee_id      OUT NOCOPY job_history."EMPLOYEE_ID"%TYPE
    , p_start_date       OUT NOCOPY job_history."START_DATE"%TYPE
    , p_end_date         OUT NOCOPY job_history."END_DATE"%TYPE
    , p_job_id           OUT NOCOPY job_history."JOB_ID"%TYPE
    , p_department_id    OUT NOCOPY job_history."DEPARTMENT_ID"%TYPE)
   IS
      v_row job_history%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         p_employee_id   := v_row."EMPLOYEE_ID";
         p_start_date    := v_row."START_DATE";
         p_end_date      := v_row."END_DATE";
         p_job_id        := v_row."JOB_ID";
         p_department_id := v_row."DEPARTMENT_ID";
      END IF;
   END read_row;

   ----------------------------------------
   PROCEDURE update_row(p_employee_id   IN job_history."EMPLOYEE_ID"%TYPE
                      , p_start_date    IN job_history."START_DATE"%TYPE
                      , p_end_date      IN job_history."END_DATE"%TYPE
                      , p_job_id        IN job_history."JOB_ID"%TYPE
                      , p_department_id IN job_history."DEPARTMENT_ID"%TYPE)
   IS
      v_row job_history%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column values really differ
         IF COALESCE(v_row."EMPLOYEE_ID", -999999999999999.999999999999999) <>
               COALESCE(p_employee_id, -999999999999999.999999999999999)
         OR COALESCE(v_row."START_DATE", TO_DATE('01.01.1900', 'DD.MM.YYYY')) <>
               COALESCE(p_start_date, TO_DATE('01.01.1900', 'DD.MM.YYYY'))
         OR COALESCE(v_row."END_DATE", TO_DATE('01.01.1900', 'DD.MM.YYYY')) <>
               COALESCE(p_end_date, TO_DATE('01.01.1900', 'DD.MM.YYYY'))
         OR COALESCE(v_row."JOB_ID", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_job_id, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."DEPARTMENT_ID", -999999999999999.999999999999999) <>
               COALESCE(p_department_id, -999999999999999.999999999999999)
         THEN
            UPDATE job_history
               SET "EMPLOYEE_ID"   = p_employee_id
                 , "START_DATE"    = p_start_date
                 , "END_DATE"      = p_end_date
                 , "JOB_ID"        = p_job_id
                 , "DEPARTMENT_ID" = p_department_id
             WHERE "EMPLOYEE_ID" = v_row."EMPLOYEE_ID";
         END IF;
      END IF;
   END update_row;

   ----------------------------------------
   PROCEDURE update_row(p_row IN job_history%ROWTYPE)
   IS
   BEGIN
      update_row(p_employee_id   => p_row."EMPLOYEE_ID"
               , p_start_date    => p_row."START_DATE"
               , p_end_date      => p_row."END_DATE"
               , p_job_id        => p_row."JOB_ID"
               , p_department_id => p_row."DEPARTMENT_ID");
   END update_row;

   ----------------------------------------
   PROCEDURE delete_row(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
   IS
   BEGIN
      DELETE FROM job_history
            WHERE "EMPLOYEE_ID" = p_employee_id;
   END delete_row;

   ----------------------------------------
   FUNCTION create_or_update_row(
      p_employee_id   IN job_history."EMPLOYEE_ID"%TYPE
    , p_start_date    IN job_history."START_DATE"%TYPE
    , p_end_date      IN job_history."END_DATE"%TYPE
    , p_job_id        IN job_history."JOB_ID"%TYPE
    , p_department_id IN job_history."DEPARTMENT_ID"%TYPE)
      RETURN job_history."EMPLOYEE_ID"%TYPE
   IS
      v_pk job_history."EMPLOYEE_ID"%TYPE;
   BEGIN
      IF p_employee_id IS NULL
      THEN
         v_pk      :=
            create_row(p_employee_id   => p_employee_id
                     , p_start_date    => p_start_date
                     , p_end_date      => p_end_date
                     , p_job_id        => p_job_id
                     , p_department_id => p_department_id);
      ELSE
         IF row_exists(p_employee_id => p_employee_id)
         THEN
            v_pk := p_employee_id;
            update_row(p_employee_id   => p_employee_id
                     , p_start_date    => p_start_date
                     , p_end_date      => p_end_date
                     , p_job_id        => p_job_id
                     , p_department_id => p_department_id);
         ELSE
            v_pk      :=
               create_row(p_employee_id   => p_employee_id
                        , p_start_date    => p_start_date
                        , p_end_date      => p_end_date
                        , p_job_id        => p_job_id
                        , p_department_id => p_department_id);
         END IF;
      END IF;

      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(
      p_employee_id   IN job_history."EMPLOYEE_ID"%TYPE
    , p_start_date    IN job_history."START_DATE"%TYPE
    , p_end_date      IN job_history."END_DATE"%TYPE
    , p_job_id        IN job_history."JOB_ID"%TYPE
    , p_department_id IN job_history."DEPARTMENT_ID"%TYPE)
   IS
      v_pk job_history."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_employee_id   => p_employee_id
                            , p_start_date    => p_start_date
                            , p_end_date      => p_end_date
                            , p_job_id        => p_job_id
                            , p_department_id => p_department_id);
   END create_or_update_row;

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN job_history%ROWTYPE)
      RETURN job_history."EMPLOYEE_ID"%TYPE
   IS
      v_pk job_history."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_employee_id   => p_row."EMPLOYEE_ID"
                            , p_start_date    => p_row."START_DATE"
                            , p_end_date      => p_row."END_DATE"
                            , p_job_id        => p_row."JOB_ID"
                            , p_department_id => p_row."DEPARTMENT_ID");
      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN job_history%ROWTYPE)
   IS
      v_pk job_history."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_employee_id   => p_row."EMPLOYEE_ID"
                            , p_start_date    => p_row."START_DATE"
                            , p_end_date      => p_row."END_DATE"
                            , p_job_id        => p_row."JOB_ID"
                            , p_department_id => p_row."DEPARTMENT_ID");
   END create_or_update_row;

   ----------------------------------------
   FUNCTION get_employee_id(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN job_history."EMPLOYEE_ID"%TYPE
   IS
      v_row job_history%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."EMPLOYEE_ID";
   END get_employee_id;

   ----------------------------------------
   FUNCTION get_start_date(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN job_history."START_DATE"%TYPE
   IS
      v_row job_history%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."START_DATE";
   END get_start_date;

   ----------------------------------------
   FUNCTION get_end_date(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN job_history."END_DATE"%TYPE
   IS
      v_row job_history%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."END_DATE";
   END get_end_date;

   ----------------------------------------
   FUNCTION get_job_id(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN job_history."JOB_ID"%TYPE
   IS
      v_row job_history%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."JOB_ID";
   END get_job_id;

   ----------------------------------------
   FUNCTION get_department_id(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
      RETURN job_history."DEPARTMENT_ID"%TYPE
   IS
      v_row job_history%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."DEPARTMENT_ID";
   END get_department_id;

   ----------------------------------------
   PROCEDURE set_employee_id(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE)
   IS
      v_row job_history%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."EMPLOYEE_ID", -999999999999999.999999999999999) <>
               COALESCE(p_employee_id, -999999999999999.999999999999999)
         THEN
            UPDATE job_history
               SET "EMPLOYEE_ID" = p_employee_id
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_employee_id;

   ----------------------------------------
   PROCEDURE set_start_date(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE
                          , p_start_date  IN job_history."START_DATE"%TYPE)
   IS
      v_row job_history%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."START_DATE", TO_DATE('01.01.1900', 'DD.MM.YYYY')) <>
               COALESCE(p_start_date, TO_DATE('01.01.1900', 'DD.MM.YYYY'))
         THEN
            UPDATE job_history
               SET "START_DATE" = p_start_date
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_start_date;

   ----------------------------------------
   PROCEDURE set_end_date(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE
                        , p_end_date    IN job_history."END_DATE"%TYPE)
   IS
      v_row job_history%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."END_DATE", TO_DATE('01.01.1900', 'DD.MM.YYYY')) <>
               COALESCE(p_end_date, TO_DATE('01.01.1900', 'DD.MM.YYYY'))
         THEN
            UPDATE job_history
               SET "END_DATE" = p_end_date
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_end_date;

   ----------------------------------------
   PROCEDURE set_job_id(p_employee_id IN job_history."EMPLOYEE_ID"%TYPE
                      , p_job_id      IN job_history."JOB_ID"%TYPE)
   IS
      v_row job_history%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."JOB_ID", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_job_id, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE job_history
               SET "JOB_ID" = p_job_id
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_job_id;

   ----------------------------------------
   PROCEDURE set_department_id(
      p_employee_id   IN job_history."EMPLOYEE_ID"%TYPE
    , p_department_id IN job_history."DEPARTMENT_ID"%TYPE)
   IS
      v_row job_history%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."DEPARTMENT_ID", -999999999999999.999999999999999) <>
               COALESCE(p_department_id, -999999999999999.999999999999999)
         THEN
            UPDATE job_history
               SET "DEPARTMENT_ID" = p_department_id
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_department_id;
----------------------------------------
END job_history_api;