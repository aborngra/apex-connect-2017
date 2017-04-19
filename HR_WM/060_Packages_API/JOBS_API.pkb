CREATE OR REPLACE EDITIONABLE PACKAGE BODY "JOBS_API"
IS
   ----------------------------------------
   FUNCTION row_exists(p_job_id IN jobs."JOB_ID"%TYPE)
      RETURN BOOLEAN
   IS
      v_return BOOLEAN := FALSE;
   BEGIN
      FOR i IN (SELECT 1
                  FROM jobs
                 WHERE "JOB_ID" = p_job_id)
      LOOP
         v_return := TRUE;
      END LOOP;

      RETURN v_return;
   END;

   ----------------------------------------
   FUNCTION row_exists_yn(p_job_id IN jobs."JOB_ID"%TYPE)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN CASE WHEN row_exists(p_job_id => p_job_id) THEN 'Y' ELSE 'N' END;
   END;

   ----------------------------------------
   FUNCTION create_row(p_job_id     IN jobs."JOB_ID"%TYPE DEFAULT NULL
                     , p_job_title  IN jobs."JOB_TITLE"%TYPE
                     , p_min_salary IN jobs."MIN_SALARY"%TYPE
                     , p_max_salary IN jobs."MAX_SALARY"%TYPE)
      RETURN jobs."JOB_ID"%TYPE
   IS
      v_pk jobs."JOB_ID"%TYPE;
   BEGIN
      v_pk := COALESCE(p_job_id, jobs_seq.NEXTVAL);

      INSERT INTO jobs("JOB_ID"
                     , "JOB_TITLE"
                     , "MIN_SALARY"
                     , "MAX_SALARY")
           VALUES (v_pk
                 , p_job_title
                 , p_min_salary
                 , p_max_salary);

      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(p_job_id     IN jobs."JOB_ID"%TYPE DEFAULT NULL
                      , p_job_title  IN jobs."JOB_TITLE"%TYPE
                      , p_min_salary IN jobs."MIN_SALARY"%TYPE
                      , p_max_salary IN jobs."MAX_SALARY"%TYPE)
   IS
      v_pk jobs."JOB_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_job_id     => p_job_id
                  , p_job_title  => p_job_title
                  , p_min_salary => p_min_salary
                  , p_max_salary => p_max_salary);
   END create_row;

   ----------------------------------------
   FUNCTION create_row(p_row IN jobs%ROWTYPE)
      RETURN jobs."JOB_ID"%TYPE
   IS
      v_pk jobs."JOB_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_job_id     => p_row."JOB_ID"
                  , p_job_title  => p_row."JOB_TITLE"
                  , p_min_salary => p_row."MIN_SALARY"
                  , p_max_salary => p_row."MAX_SALARY");
      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(p_row IN jobs%ROWTYPE)
   IS
      v_pk jobs."JOB_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_job_id     => p_row."JOB_ID"
                  , p_job_title  => p_row."JOB_TITLE"
                  , p_min_salary => p_row."MIN_SALARY"
                  , p_max_salary => p_row."MAX_SALARY");
   END create_row;

   ----------------------------------------
   FUNCTION read_row(p_job_id IN jobs."JOB_ID"%TYPE)
      RETURN jobs%ROWTYPE
   IS
      CURSOR cur_row_by_pk(p_job_id IN jobs."JOB_ID"%TYPE)
      IS
         SELECT *
           FROM jobs
          WHERE "JOB_ID" = p_job_id;

      v_row jobs%ROWTYPE;
   BEGIN
      OPEN cur_row_by_pk(p_job_id);

      FETCH cur_row_by_pk INTO v_row;

      CLOSE cur_row_by_pk;

      RETURN v_row;
   END read_row;

   ----------------------------------------
   PROCEDURE read_row(p_job_id     IN            jobs."JOB_ID"%TYPE
                    , p_job_title     OUT NOCOPY jobs."JOB_TITLE"%TYPE
                    , p_min_salary    OUT NOCOPY jobs."MIN_SALARY"%TYPE
                    , p_max_salary    OUT NOCOPY jobs."MAX_SALARY"%TYPE)
   IS
      v_row jobs%ROWTYPE;
   BEGIN
      v_row := read_row(p_job_id => p_job_id);

      IF v_row."JOB_ID" IS NOT NULL
      THEN
         p_job_title  := v_row."JOB_TITLE";
         p_min_salary := v_row."MIN_SALARY";
         p_max_salary := v_row."MAX_SALARY";
      END IF;
   END read_row;

   ----------------------------------------
   PROCEDURE update_row(p_job_id     IN jobs."JOB_ID"%TYPE DEFAULT NULL
                      , p_job_title  IN jobs."JOB_TITLE"%TYPE
                      , p_min_salary IN jobs."MIN_SALARY"%TYPE
                      , p_max_salary IN jobs."MAX_SALARY"%TYPE)
   IS
      v_row jobs%ROWTYPE;
   BEGIN
      v_row := read_row(p_job_id => p_job_id);

      IF v_row."JOB_ID" IS NOT NULL
      THEN
         -- update only, if the column values really differ
         IF COALESCE(v_row."JOB_TITLE", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_job_title, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."MIN_SALARY", -999999999999999.999999999999999) <>
               COALESCE(p_min_salary, -999999999999999.999999999999999)
         OR COALESCE(v_row."MAX_SALARY", -999999999999999.999999999999999) <>
               COALESCE(p_max_salary, -999999999999999.999999999999999)
         THEN
            UPDATE jobs
               SET "JOB_TITLE"  = p_job_title
                 , "MIN_SALARY" = p_min_salary
                 , "MAX_SALARY" = p_max_salary
             WHERE "JOB_ID" = v_row."JOB_ID";
         END IF;
      END IF;
   END update_row;

   ----------------------------------------
   PROCEDURE update_row(p_row IN jobs%ROWTYPE)
   IS
   BEGIN
      update_row(p_job_id     => p_row."JOB_ID"
               , p_job_title  => p_row."JOB_TITLE"
               , p_min_salary => p_row."MIN_SALARY"
               , p_max_salary => p_row."MAX_SALARY");
   END update_row;

   ----------------------------------------
   PROCEDURE delete_row(p_job_id IN jobs."JOB_ID"%TYPE)
   IS
   BEGIN
      DELETE FROM jobs
            WHERE "JOB_ID" = p_job_id;
   END delete_row;

   ----------------------------------------
   FUNCTION create_or_update_row(p_job_id     IN jobs."JOB_ID"%TYPE DEFAULT NULL
                               , p_job_title  IN jobs."JOB_TITLE"%TYPE
                               , p_min_salary IN jobs."MIN_SALARY"%TYPE
                               , p_max_salary IN jobs."MAX_SALARY"%TYPE)
      RETURN jobs."JOB_ID"%TYPE
   IS
      v_pk jobs."JOB_ID"%TYPE;
   BEGIN
      IF p_job_id IS NULL
      THEN
         v_pk      :=
            create_row(p_job_id     => p_job_id
                     , p_job_title  => p_job_title
                     , p_min_salary => p_min_salary
                     , p_max_salary => p_max_salary);
      ELSE
         IF row_exists(p_job_id => p_job_id)
         THEN
            v_pk := p_job_id;
            update_row(p_job_id     => p_job_id
                     , p_job_title  => p_job_title
                     , p_min_salary => p_min_salary
                     , p_max_salary => p_max_salary);
         ELSE
            v_pk      :=
               create_row(p_job_id     => p_job_id
                        , p_job_title  => p_job_title
                        , p_min_salary => p_min_salary
                        , p_max_salary => p_max_salary);
         END IF;
      END IF;

      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_job_id     IN jobs."JOB_ID"%TYPE DEFAULT NULL
                                , p_job_title  IN jobs."JOB_TITLE"%TYPE
                                , p_min_salary IN jobs."MIN_SALARY"%TYPE
                                , p_max_salary IN jobs."MAX_SALARY"%TYPE)
   IS
      v_pk jobs."JOB_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_job_id     => p_job_id
                            , p_job_title  => p_job_title
                            , p_min_salary => p_min_salary
                            , p_max_salary => p_max_salary);
   END create_or_update_row;

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN jobs%ROWTYPE)
      RETURN jobs."JOB_ID"%TYPE
   IS
      v_pk jobs."JOB_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_job_id     => p_row."JOB_ID"
                            , p_job_title  => p_row."JOB_TITLE"
                            , p_min_salary => p_row."MIN_SALARY"
                            , p_max_salary => p_row."MAX_SALARY");
      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN jobs%ROWTYPE)
   IS
      v_pk jobs."JOB_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_job_id     => p_row."JOB_ID"
                            , p_job_title  => p_row."JOB_TITLE"
                            , p_min_salary => p_row."MIN_SALARY"
                            , p_max_salary => p_row."MAX_SALARY");
   END create_or_update_row;

   ----------------------------------------
   FUNCTION get_job_title(p_job_id IN jobs."JOB_ID"%TYPE)
      RETURN jobs."JOB_TITLE"%TYPE
   IS
      v_row jobs%ROWTYPE;
   BEGIN
      v_row := read_row(p_job_id => p_job_id);
      RETURN v_row."JOB_TITLE";
   END get_job_title;

   ----------------------------------------
   FUNCTION get_min_salary(p_job_id IN jobs."JOB_ID"%TYPE)
      RETURN jobs."MIN_SALARY"%TYPE
   IS
      v_row jobs%ROWTYPE;
   BEGIN
      v_row := read_row(p_job_id => p_job_id);
      RETURN v_row."MIN_SALARY";
   END get_min_salary;

   ----------------------------------------
   FUNCTION get_max_salary(p_job_id IN jobs."JOB_ID"%TYPE)
      RETURN jobs."MAX_SALARY"%TYPE
   IS
      v_row jobs%ROWTYPE;
   BEGIN
      v_row := read_row(p_job_id => p_job_id);
      RETURN v_row."MAX_SALARY";
   END get_max_salary;

   ----------------------------------------
   PROCEDURE set_job_title(p_job_id    IN jobs."JOB_ID"%TYPE
                         , p_job_title IN jobs."JOB_TITLE"%TYPE)
   IS
      v_row jobs%ROWTYPE;
   BEGIN
      v_row := read_row(p_job_id => p_job_id);

      IF v_row."JOB_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."JOB_TITLE", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_job_title, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE jobs
               SET "JOB_TITLE" = p_job_title
             WHERE "JOB_ID" = p_job_id;
         END IF;
      END IF;
   END set_job_title;

   ----------------------------------------
   PROCEDURE set_min_salary(p_job_id     IN jobs."JOB_ID"%TYPE
                          , p_min_salary IN jobs."MIN_SALARY"%TYPE)
   IS
      v_row jobs%ROWTYPE;
   BEGIN
      v_row := read_row(p_job_id => p_job_id);

      IF v_row."JOB_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."MIN_SALARY", -999999999999999.999999999999999) <>
               COALESCE(p_min_salary, -999999999999999.999999999999999)
         THEN
            UPDATE jobs
               SET "MIN_SALARY" = p_min_salary
             WHERE "JOB_ID" = p_job_id;
         END IF;
      END IF;
   END set_min_salary;

   ----------------------------------------
   PROCEDURE set_max_salary(p_job_id     IN jobs."JOB_ID"%TYPE
                          , p_max_salary IN jobs."MAX_SALARY"%TYPE)
   IS
      v_row jobs%ROWTYPE;
   BEGIN
      v_row := read_row(p_job_id => p_job_id);

      IF v_row."JOB_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."MAX_SALARY", -999999999999999.999999999999999) <>
               COALESCE(p_max_salary, -999999999999999.999999999999999)
         THEN
            UPDATE jobs
               SET "MAX_SALARY" = p_max_salary
             WHERE "JOB_ID" = p_job_id;
         END IF;
      END IF;
   END set_max_salary;
----------------------------------------
END jobs_api;