CREATE OR REPLACE EDITIONABLE PACKAGE BODY "EMPLOYEES_API"
IS
   ----------------------------------------
   FUNCTION row_exists(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN BOOLEAN
   IS
      v_return BOOLEAN := FALSE;
   BEGIN
      FOR i IN (SELECT 1
                  FROM employees
                 WHERE "EMPLOYEE_ID" = p_employee_id)
      LOOP
         v_return := TRUE;
      END LOOP;

      RETURN v_return;
   END;

   ----------------------------------------
   FUNCTION row_exists_yn(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN CASE
                WHEN row_exists(p_employee_id => p_employee_id) THEN 'Y'
                ELSE 'N'
             END;
   END;

   ----------------------------------------
   FUNCTION get_pk_by_unique_cols(p_email employees."EMAIL"%TYPE)
      RETURN employees."EMPLOYEE_ID"%TYPE
   IS
      v_pk employees."EMPLOYEE_ID"%TYPE;

      CURSOR cur_row
      IS
         SELECT "EMPLOYEE_ID"
           FROM employees
          WHERE COALESCE("EMAIL", '@@@@@@@@@@@@@@@') =
                   COALESCE(p_email, '@@@@@@@@@@@@@@@');
   BEGIN
      OPEN cur_row;

      FETCH cur_row INTO v_pk;

      CLOSE cur_row;

      RETURN v_pk;
   END get_pk_by_unique_cols;

   ----------------------------------------
   FUNCTION create_row(
      p_employee_id    IN employees."EMPLOYEE_ID"%TYPE DEFAULT NULL
    , p_first_name     IN employees."FIRST_NAME"%TYPE
    , p_last_name      IN employees."LAST_NAME"%TYPE
    , p_email          IN employees."EMAIL"%TYPE
    , p_phone_number   IN employees."PHONE_NUMBER"%TYPE
    , p_hire_date      IN employees."HIRE_DATE"%TYPE
    , p_job_id         IN employees."JOB_ID"%TYPE
    , p_salary         IN employees."SALARY"%TYPE
    , p_commission_pct IN employees."COMMISSION_PCT"%TYPE
    , p_manager_id     IN employees."MANAGER_ID"%TYPE
    , p_department_id  IN employees."DEPARTMENT_ID"%TYPE)
      RETURN employees."EMPLOYEE_ID"%TYPE
   IS
      v_pk employees."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk := COALESCE(p_employee_id, employees_seq.NEXTVAL);

      INSERT INTO employees("EMPLOYEE_ID"
                          , "FIRST_NAME"
                          , "LAST_NAME"
                          , "EMAIL"
                          , "PHONE_NUMBER"
                          , "HIRE_DATE"
                          , "JOB_ID"
                          , "SALARY"
                          , "COMMISSION_PCT"
                          , "MANAGER_ID"
                          , "DEPARTMENT_ID")
           VALUES (v_pk
                 , p_first_name
                 , p_last_name
                 , p_email
                 , p_phone_number
                 , p_hire_date
                 , p_job_id
                 , p_salary
                 , p_commission_pct
                 , p_manager_id
                 , p_department_id);

      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(
      p_employee_id    IN employees."EMPLOYEE_ID"%TYPE DEFAULT NULL
    , p_first_name     IN employees."FIRST_NAME"%TYPE
    , p_last_name      IN employees."LAST_NAME"%TYPE
    , p_email          IN employees."EMAIL"%TYPE
    , p_phone_number   IN employees."PHONE_NUMBER"%TYPE
    , p_hire_date      IN employees."HIRE_DATE"%TYPE
    , p_job_id         IN employees."JOB_ID"%TYPE
    , p_salary         IN employees."SALARY"%TYPE
    , p_commission_pct IN employees."COMMISSION_PCT"%TYPE
    , p_manager_id     IN employees."MANAGER_ID"%TYPE
    , p_department_id  IN employees."DEPARTMENT_ID"%TYPE)
   IS
      v_pk employees."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_employee_id    => p_employee_id
                  , p_first_name     => p_first_name
                  , p_last_name      => p_last_name
                  , p_email          => p_email
                  , p_phone_number   => p_phone_number
                  , p_hire_date      => p_hire_date
                  , p_job_id         => p_job_id
                  , p_salary         => p_salary
                  , p_commission_pct => p_commission_pct
                  , p_manager_id     => p_manager_id
                  , p_department_id  => p_department_id);
   END create_row;

   ----------------------------------------
   FUNCTION create_row(p_row IN employees%ROWTYPE)
      RETURN employees."EMPLOYEE_ID"%TYPE
   IS
      v_pk employees."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_employee_id    => p_row."EMPLOYEE_ID"
                  , p_first_name     => p_row."FIRST_NAME"
                  , p_last_name      => p_row."LAST_NAME"
                  , p_email          => p_row."EMAIL"
                  , p_phone_number   => p_row."PHONE_NUMBER"
                  , p_hire_date      => p_row."HIRE_DATE"
                  , p_job_id         => p_row."JOB_ID"
                  , p_salary         => p_row."SALARY"
                  , p_commission_pct => p_row."COMMISSION_PCT"
                  , p_manager_id     => p_row."MANAGER_ID"
                  , p_department_id  => p_row."DEPARTMENT_ID");
      RETURN v_pk;
   END create_row;

   ----------------------------------------
   PROCEDURE create_row(p_row IN employees%ROWTYPE)
   IS
      v_pk employees."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_row(p_employee_id    => p_row."EMPLOYEE_ID"
                  , p_first_name     => p_row."FIRST_NAME"
                  , p_last_name      => p_row."LAST_NAME"
                  , p_email          => p_row."EMAIL"
                  , p_phone_number   => p_row."PHONE_NUMBER"
                  , p_hire_date      => p_row."HIRE_DATE"
                  , p_job_id         => p_row."JOB_ID"
                  , p_salary         => p_row."SALARY"
                  , p_commission_pct => p_row."COMMISSION_PCT"
                  , p_manager_id     => p_row."MANAGER_ID"
                  , p_department_id  => p_row."DEPARTMENT_ID");
   END create_row;

   ----------------------------------------
   FUNCTION read_row(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees%ROWTYPE
   IS
      CURSOR cur_row_by_pk(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      IS
         SELECT *
           FROM employees
          WHERE "EMPLOYEE_ID" = p_employee_id;

      v_row employees%ROWTYPE;
   BEGIN
      OPEN cur_row_by_pk(p_employee_id);

      FETCH cur_row_by_pk INTO v_row;

      CLOSE cur_row_by_pk;

      RETURN v_row;
   END read_row;

   ----------------------------------------
   PROCEDURE read_row(
      p_employee_id    IN            employees."EMPLOYEE_ID"%TYPE
    , p_first_name        OUT NOCOPY employees."FIRST_NAME"%TYPE
    , p_last_name         OUT NOCOPY employees."LAST_NAME"%TYPE
    , p_email             OUT NOCOPY employees."EMAIL"%TYPE
    , p_phone_number      OUT NOCOPY employees."PHONE_NUMBER"%TYPE
    , p_hire_date         OUT NOCOPY employees."HIRE_DATE"%TYPE
    , p_job_id            OUT NOCOPY employees."JOB_ID"%TYPE
    , p_salary            OUT NOCOPY employees."SALARY"%TYPE
    , p_commission_pct    OUT NOCOPY employees."COMMISSION_PCT"%TYPE
    , p_manager_id        OUT NOCOPY employees."MANAGER_ID"%TYPE
    , p_department_id     OUT NOCOPY employees."DEPARTMENT_ID"%TYPE)
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         p_first_name     := v_row."FIRST_NAME";
         p_last_name      := v_row."LAST_NAME";
         p_email          := v_row."EMAIL";
         p_phone_number   := v_row."PHONE_NUMBER";
         p_hire_date      := v_row."HIRE_DATE";
         p_job_id         := v_row."JOB_ID";
         p_salary         := v_row."SALARY";
         p_commission_pct := v_row."COMMISSION_PCT";
         p_manager_id     := v_row."MANAGER_ID";
         p_department_id  := v_row."DEPARTMENT_ID";
      END IF;
   END read_row;

   ----------------------------------------
   FUNCTION read_row(p_email employees."EMAIL"%TYPE)
      RETURN employees%ROWTYPE
   IS
      v_pk employees."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk := get_pk_by_unique_cols(p_email => p_email);
      RETURN read_row(p_employee_id => v_pk);
   END read_row;

   ----------------------------------------
   PROCEDURE update_row(
      p_employee_id    IN employees."EMPLOYEE_ID"%TYPE DEFAULT NULL
    , p_first_name     IN employees."FIRST_NAME"%TYPE
    , p_last_name      IN employees."LAST_NAME"%TYPE
    , p_email          IN employees."EMAIL"%TYPE
    , p_phone_number   IN employees."PHONE_NUMBER"%TYPE
    , p_hire_date      IN employees."HIRE_DATE"%TYPE
    , p_job_id         IN employees."JOB_ID"%TYPE
    , p_salary         IN employees."SALARY"%TYPE
    , p_commission_pct IN employees."COMMISSION_PCT"%TYPE
    , p_manager_id     IN employees."MANAGER_ID"%TYPE
    , p_department_id  IN employees."DEPARTMENT_ID"%TYPE)
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column values really differ
         IF COALESCE(v_row."FIRST_NAME", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_first_name, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."LAST_NAME", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_last_name, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."EMAIL", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_email, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."PHONE_NUMBER", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_phone_number, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."HIRE_DATE", TO_DATE('01.01.1900', 'DD.MM.YYYY')) <>
               COALESCE(p_hire_date, TO_DATE('01.01.1900', 'DD.MM.YYYY'))
         OR COALESCE(v_row."JOB_ID", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_job_id, '@@@@@@@@@@@@@@@')
         OR COALESCE(v_row."SALARY", -999999999999999.999999999999999) <>
               COALESCE(p_salary, -999999999999999.999999999999999)
         OR COALESCE(v_row."COMMISSION_PCT", -999999999999999.999999999999999) <>
               COALESCE(p_commission_pct, -999999999999999.999999999999999)
         OR COALESCE(v_row."MANAGER_ID", -999999999999999.999999999999999) <>
               COALESCE(p_manager_id, -999999999999999.999999999999999)
         OR COALESCE(v_row."DEPARTMENT_ID", -999999999999999.999999999999999) <>
               COALESCE(p_department_id, -999999999999999.999999999999999)
         THEN
            UPDATE employees
               SET "FIRST_NAME"     = p_first_name
                 , "LAST_NAME"      = p_last_name
                 , "EMAIL"          = p_email
                 , "PHONE_NUMBER"   = p_phone_number
                 , "HIRE_DATE"      = p_hire_date
                 , "JOB_ID"         = p_job_id
                 , "SALARY"         = p_salary
                 , "COMMISSION_PCT" = p_commission_pct
                 , "MANAGER_ID"     = p_manager_id
                 , "DEPARTMENT_ID"  = p_department_id
             WHERE "EMPLOYEE_ID" = v_row."EMPLOYEE_ID";
         END IF;
      END IF;
   END update_row;

   ----------------------------------------
   PROCEDURE update_row(p_row IN employees%ROWTYPE)
   IS
   BEGIN
      update_row(p_employee_id    => p_row."EMPLOYEE_ID"
               , p_first_name     => p_row."FIRST_NAME"
               , p_last_name      => p_row."LAST_NAME"
               , p_email          => p_row."EMAIL"
               , p_phone_number   => p_row."PHONE_NUMBER"
               , p_hire_date      => p_row."HIRE_DATE"
               , p_job_id         => p_row."JOB_ID"
               , p_salary         => p_row."SALARY"
               , p_commission_pct => p_row."COMMISSION_PCT"
               , p_manager_id     => p_row."MANAGER_ID"
               , p_department_id  => p_row."DEPARTMENT_ID");
   END update_row;

   ----------------------------------------
   PROCEDURE delete_row(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
   IS
   BEGIN
      DELETE FROM employees
            WHERE "EMPLOYEE_ID" = p_employee_id;
   END delete_row;

   ----------------------------------------
   FUNCTION create_or_update_row(
      p_employee_id    IN employees."EMPLOYEE_ID"%TYPE DEFAULT NULL
    , p_first_name     IN employees."FIRST_NAME"%TYPE
    , p_last_name      IN employees."LAST_NAME"%TYPE
    , p_email          IN employees."EMAIL"%TYPE
    , p_phone_number   IN employees."PHONE_NUMBER"%TYPE
    , p_hire_date      IN employees."HIRE_DATE"%TYPE
    , p_job_id         IN employees."JOB_ID"%TYPE
    , p_salary         IN employees."SALARY"%TYPE
    , p_commission_pct IN employees."COMMISSION_PCT"%TYPE
    , p_manager_id     IN employees."MANAGER_ID"%TYPE
    , p_department_id  IN employees."DEPARTMENT_ID"%TYPE)
      RETURN employees."EMPLOYEE_ID"%TYPE
   IS
      v_pk employees."EMPLOYEE_ID"%TYPE;
   BEGIN
      IF p_employee_id IS NULL
      THEN
         v_pk      :=
            create_row(p_employee_id    => p_employee_id
                     , p_first_name     => p_first_name
                     , p_last_name      => p_last_name
                     , p_email          => p_email
                     , p_phone_number   => p_phone_number
                     , p_hire_date      => p_hire_date
                     , p_job_id         => p_job_id
                     , p_salary         => p_salary
                     , p_commission_pct => p_commission_pct
                     , p_manager_id     => p_manager_id
                     , p_department_id  => p_department_id);
      ELSE
         IF row_exists(p_employee_id => p_employee_id)
         THEN
            v_pk := p_employee_id;
            update_row(p_employee_id    => p_employee_id
                     , p_first_name     => p_first_name
                     , p_last_name      => p_last_name
                     , p_email          => p_email
                     , p_phone_number   => p_phone_number
                     , p_hire_date      => p_hire_date
                     , p_job_id         => p_job_id
                     , p_salary         => p_salary
                     , p_commission_pct => p_commission_pct
                     , p_manager_id     => p_manager_id
                     , p_department_id  => p_department_id);
         ELSE
            v_pk      :=
               create_row(p_employee_id    => p_employee_id
                        , p_first_name     => p_first_name
                        , p_last_name      => p_last_name
                        , p_email          => p_email
                        , p_phone_number   => p_phone_number
                        , p_hire_date      => p_hire_date
                        , p_job_id         => p_job_id
                        , p_salary         => p_salary
                        , p_commission_pct => p_commission_pct
                        , p_manager_id     => p_manager_id
                        , p_department_id  => p_department_id);
         END IF;
      END IF;

      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(
      p_employee_id    IN employees."EMPLOYEE_ID"%TYPE DEFAULT NULL
    , p_first_name     IN employees."FIRST_NAME"%TYPE
    , p_last_name      IN employees."LAST_NAME"%TYPE
    , p_email          IN employees."EMAIL"%TYPE
    , p_phone_number   IN employees."PHONE_NUMBER"%TYPE
    , p_hire_date      IN employees."HIRE_DATE"%TYPE
    , p_job_id         IN employees."JOB_ID"%TYPE
    , p_salary         IN employees."SALARY"%TYPE
    , p_commission_pct IN employees."COMMISSION_PCT"%TYPE
    , p_manager_id     IN employees."MANAGER_ID"%TYPE
    , p_department_id  IN employees."DEPARTMENT_ID"%TYPE)
   IS
      v_pk employees."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_employee_id    => p_employee_id
                            , p_first_name     => p_first_name
                            , p_last_name      => p_last_name
                            , p_email          => p_email
                            , p_phone_number   => p_phone_number
                            , p_hire_date      => p_hire_date
                            , p_job_id         => p_job_id
                            , p_salary         => p_salary
                            , p_commission_pct => p_commission_pct
                            , p_manager_id     => p_manager_id
                            , p_department_id  => p_department_id);
   END create_or_update_row;

   ----------------------------------------
   FUNCTION create_or_update_row(p_row IN employees%ROWTYPE)
      RETURN employees."EMPLOYEE_ID"%TYPE
   IS
      v_pk employees."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_employee_id    => p_row."EMPLOYEE_ID"
                            , p_first_name     => p_row."FIRST_NAME"
                            , p_last_name      => p_row."LAST_NAME"
                            , p_email          => p_row."EMAIL"
                            , p_phone_number   => p_row."PHONE_NUMBER"
                            , p_hire_date      => p_row."HIRE_DATE"
                            , p_job_id         => p_row."JOB_ID"
                            , p_salary         => p_row."SALARY"
                            , p_commission_pct => p_row."COMMISSION_PCT"
                            , p_manager_id     => p_row."MANAGER_ID"
                            , p_department_id  => p_row."DEPARTMENT_ID");
      RETURN v_pk;
   END create_or_update_row;

   ----------------------------------------
   PROCEDURE create_or_update_row(p_row IN employees%ROWTYPE)
   IS
      v_pk employees."EMPLOYEE_ID"%TYPE;
   BEGIN
      v_pk      :=
         create_or_update_row(p_employee_id    => p_row."EMPLOYEE_ID"
                            , p_first_name     => p_row."FIRST_NAME"
                            , p_last_name      => p_row."LAST_NAME"
                            , p_email          => p_row."EMAIL"
                            , p_phone_number   => p_row."PHONE_NUMBER"
                            , p_hire_date      => p_row."HIRE_DATE"
                            , p_job_id         => p_row."JOB_ID"
                            , p_salary         => p_row."SALARY"
                            , p_commission_pct => p_row."COMMISSION_PCT"
                            , p_manager_id     => p_row."MANAGER_ID"
                            , p_department_id  => p_row."DEPARTMENT_ID");
   END create_or_update_row;

   ----------------------------------------
   FUNCTION get_first_name(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."FIRST_NAME"%TYPE
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."FIRST_NAME";
   END get_first_name;

   ----------------------------------------
   FUNCTION get_last_name(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."LAST_NAME"%TYPE
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."LAST_NAME";
   END get_last_name;

   ----------------------------------------
   FUNCTION get_email(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."EMAIL"%TYPE
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."EMAIL";
   END get_email;

   ----------------------------------------
   FUNCTION get_phone_number(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."PHONE_NUMBER"%TYPE
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."PHONE_NUMBER";
   END get_phone_number;

   ----------------------------------------
   FUNCTION get_hire_date(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."HIRE_DATE"%TYPE
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."HIRE_DATE";
   END get_hire_date;

   ----------------------------------------
   FUNCTION get_job_id(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."JOB_ID"%TYPE
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."JOB_ID";
   END get_job_id;

   ----------------------------------------
   FUNCTION get_salary(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."SALARY"%TYPE
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."SALARY";
   END get_salary;

   ----------------------------------------
   FUNCTION get_commission_pct(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."COMMISSION_PCT"%TYPE
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."COMMISSION_PCT";
   END get_commission_pct;

   ----------------------------------------
   FUNCTION get_manager_id(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."MANAGER_ID"%TYPE
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."MANAGER_ID";
   END get_manager_id;

   ----------------------------------------
   FUNCTION get_department_id(p_employee_id IN employees."EMPLOYEE_ID"%TYPE)
      RETURN employees."DEPARTMENT_ID"%TYPE
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);
      RETURN v_row."DEPARTMENT_ID";
   END get_department_id;

   ----------------------------------------
   PROCEDURE set_first_name(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                          , p_first_name  IN employees."FIRST_NAME"%TYPE)
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."FIRST_NAME", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_first_name, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE employees
               SET "FIRST_NAME" = p_first_name
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_first_name;

   ----------------------------------------
   PROCEDURE set_last_name(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                         , p_last_name   IN employees."LAST_NAME"%TYPE)
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."LAST_NAME", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_last_name, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE employees
               SET "LAST_NAME" = p_last_name
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_last_name;

   ----------------------------------------
   PROCEDURE set_email(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                     , p_email       IN employees."EMAIL"%TYPE)
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."EMAIL", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_email, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE employees
               SET "EMAIL" = p_email
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_email;

   ----------------------------------------
   PROCEDURE set_phone_number(p_employee_id  IN employees."EMPLOYEE_ID"%TYPE
                            , p_phone_number IN employees."PHONE_NUMBER"%TYPE)
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."PHONE_NUMBER", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_phone_number, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE employees
               SET "PHONE_NUMBER" = p_phone_number
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_phone_number;

   ----------------------------------------
   PROCEDURE set_hire_date(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                         , p_hire_date   IN employees."HIRE_DATE"%TYPE)
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."HIRE_DATE", TO_DATE('01.01.1900', 'DD.MM.YYYY')) <>
               COALESCE(p_hire_date, TO_DATE('01.01.1900', 'DD.MM.YYYY'))
         THEN
            UPDATE employees
               SET "HIRE_DATE" = p_hire_date
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_hire_date;

   ----------------------------------------
   PROCEDURE set_job_id(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                      , p_job_id      IN employees."JOB_ID"%TYPE)
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."JOB_ID", '@@@@@@@@@@@@@@@') <>
               COALESCE(p_job_id, '@@@@@@@@@@@@@@@')
         THEN
            UPDATE employees
               SET "JOB_ID" = p_job_id
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_job_id;

   ----------------------------------------
   PROCEDURE set_salary(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                      , p_salary      IN employees."SALARY"%TYPE)
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."SALARY", -999999999999999.999999999999999) <>
               COALESCE(p_salary, -999999999999999.999999999999999)
         THEN
            UPDATE employees
               SET "SALARY" = p_salary
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_salary;

   ----------------------------------------
   PROCEDURE set_commission_pct(
      p_employee_id    IN employees."EMPLOYEE_ID"%TYPE
    , p_commission_pct IN employees."COMMISSION_PCT"%TYPE)
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."COMMISSION_PCT", -999999999999999.999999999999999) <>
               COALESCE(p_commission_pct, -999999999999999.999999999999999)
         THEN
            UPDATE employees
               SET "COMMISSION_PCT" = p_commission_pct
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_commission_pct;

   ----------------------------------------
   PROCEDURE set_manager_id(p_employee_id IN employees."EMPLOYEE_ID"%TYPE
                          , p_manager_id  IN employees."MANAGER_ID"%TYPE)
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."MANAGER_ID", -999999999999999.999999999999999) <>
               COALESCE(p_manager_id, -999999999999999.999999999999999)
         THEN
            UPDATE employees
               SET "MANAGER_ID" = p_manager_id
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_manager_id;

   ----------------------------------------
   PROCEDURE set_department_id(
      p_employee_id   IN employees."EMPLOYEE_ID"%TYPE
    , p_department_id IN employees."DEPARTMENT_ID"%TYPE)
   IS
      v_row employees%ROWTYPE;
   BEGIN
      v_row := read_row(p_employee_id => p_employee_id);

      IF v_row."EMPLOYEE_ID" IS NOT NULL
      THEN
         -- update only, if the column value really differs
         IF COALESCE(v_row."DEPARTMENT_ID", -999999999999999.999999999999999) <>
               COALESCE(p_department_id, -999999999999999.999999999999999)
         THEN
            UPDATE employees
               SET "DEPARTMENT_ID" = p_department_id
             WHERE "EMPLOYEE_ID" = p_employee_id;
         END IF;
      END IF;
   END set_department_id;
----------------------------------------
END employees_api;