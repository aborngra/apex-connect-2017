BEGIN
   -----------------------------------------------------------------------------
   -- only enable versioning if tables are not already versionenabled
   -----------------------------------------------------------------------------
   FOR i IN (SELECT COUNT(*)
               FROM all_wm_versioned_tables
              WHERE table_name IN ('DEPARTMENTS'
                                 , 'EMPLOYEES'
                                 , 'JOBS'
                                 , 'JOB_HISTORY'
                                 , 'LOCATIONS')
             HAVING COUNT(*) = 5)
   LOOP
      DBMS_WM.disableversioning(
         table_name => 'DEPARTMENTS,EMPLOYEES,JOBS,JOB_HISTORY,LOCATIONS');
   END LOOP;
END;
/


--------------------------------------------------------------------------------
-- synchronize EMPLOYEES
--------------------------------------------------------------------------------

MERGE INTO employees dest
     USING (SELECT * FROM hr.employees) src
        ON (src.employee_id = dest.employee_id)
WHEN MATCHED
THEN
   UPDATE SET dest.first_name     = src.first_name
            , dest.last_name      = src.last_name
            , dest.email          = src.email
            , dest.phone_number   = src.phone_number
            , dest.hire_date      = src.hire_date
            , dest.job_id         = src.job_id
            , dest.salary         = src.salary
            , dest.commission_pct = src.commission_pct
            , dest.manager_id     = src.manager_id
            , dest.department_id  = src.department_id
WHEN NOT MATCHED
THEN
   INSERT     (employee_id
             , first_name
             , last_name
             , email
             , phone_number
             , hire_date
             , job_id
             , salary
             , commission_pct
             , manager_id
             , department_id)
       VALUES (src.employee_id
             , src.first_name
             , src.last_name
             , src.email
             , src.phone_number
             , src.hire_date
             , src.job_id
             , src.salary
             , src.commission_pct
             , src.manager_id
             , src.department_id);

DELETE FROM employees
      WHERE employee_id NOT IN (SELECT employee_id
                                  FROM hr.employees);

--------------------------------------------------------------------------------
-- synchronize DEPARTMENTS
--------------------------------------------------------------------------------

MERGE INTO departments dest
     USING (SELECT * FROM hr.departments) src
        ON (src.department_id = dest.department_id)
WHEN MATCHED
THEN
   UPDATE SET
      dest.department_name = src.department_name
    , dest.manager_id      = src.manager_id
    , dest.location_id     = src.location_id
WHEN NOT MATCHED
THEN
   INSERT     (department_id
             , department_name
             , manager_id
             , location_id)
       VALUES (src.department_id
             , src.department_name
             , src.manager_id
             , src.location_id);

DELETE FROM departments
      WHERE department_id NOT IN (SELECT department_id
                                    FROM hr.departments);

--------------------------------------------------------------------------------
-- synchronize JOBS
--------------------------------------------------------------------------------

MERGE INTO jobs dest
     USING (SELECT * FROM hr.jobs) src
        ON (src.job_id = dest.job_id)
WHEN MATCHED
THEN
   UPDATE SET
      dest.job_title  = src.job_title
    , dest.min_salary = src.min_salary
    , dest.max_salary = src.max_salary
WHEN NOT MATCHED
THEN
   INSERT     (job_id
             , job_title
             , min_salary
             , max_salary)
       VALUES (src.job_id
             , src.job_title
             , src.min_salary
             , src.max_salary);

DELETE FROM jobs
      WHERE job_id NOT IN (SELECT job_id
                             FROM hr.jobs);

--------------------------------------------------------------------------------
-- synchronize JOB_HISTORY
--------------------------------------------------------------------------------

DELETE FROM job_history;

MERGE INTO job_history dest
     USING (SELECT * FROM hr.job_history) src
        ON (src.employee_id = dest.employee_id
        AND src.start_date = dest.start_date)
WHEN MATCHED
THEN
   UPDATE SET
      dest.end_date      = src.end_date
    , dest.job_id        = src.job_id
    , dest.department_id = src.department_id
WHEN NOT MATCHED
THEN
   INSERT     (employee_id
             , start_date
             , end_date
             , job_id
             , department_id)
       VALUES (src.employee_id
             , src.start_date
             , src.end_date
             , src.job_id
             , src.department_id);


--------------------------------------------------------------------------------
-- synchronize LOCATIONS
--------------------------------------------------------------------------------

MERGE INTO locations dest
     USING (SELECT * FROM hr.locations) src
        ON (src.location_id = dest.location_id)
WHEN MATCHED
THEN
   UPDATE SET dest.street_address = src.street_address
            , dest.postal_code    = src.postal_code
            , dest.city           = src.city
            , dest.state_province = src.state_province
            , dest.country_id     = src.country_id
WHEN NOT MATCHED
THEN
   INSERT     (location_id
             , street_address
             , postal_code
             , city
             , state_province
             , country_id)
       VALUES (src.location_id
             , src.street_address
             , src.postal_code
             , src.city
             , src.state_province
             , src.country_id);

DELETE FROM locations
      WHERE location_id NOT IN (SELECT location_id
                                  FROM hr.locations);

COMMIT;

BEGIN
   DBMS_WM.enableversioning(
      table_name => 'DEPARTMENTS,EMPLOYEES,JOBS,JOB_HISTORY,LOCATIONS'
    , hist       => 'VIEW_WO_OVERWRITE');
END;
/