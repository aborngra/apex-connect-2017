CREATE OR REPLACE EDITIONABLE TRIGGER "SECURE_EMPLOYEES"
   BEFORE INSERT OR UPDATE OR DELETE
   ON employees
BEGIN
   secure_dml;
END secure_employees;

ALTER TRIGGER "SECURE_EMPLOYEES" DISABLE