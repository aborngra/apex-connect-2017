/* This anonymous block creates a table named DEPARTMENTS
   PL/SQL Block is restartable, so it can be executed n times, but
   only creates the table if it does not exist.
   %author  ABO
   %created 2017-04-19 22:34:31
 */

BEGIN
   FOR i IN (SELECT 'DEPARTMENTS' AS table_name FROM DUAL
             MINUS
             SELECT table_name FROM user_tables)
   LOOP
      EXECUTE IMMEDIATE q'[
  CREATE TABLE "DEPARTMENTS" 
   (	
    "DEPARTMENT_ID" NUMBER(4,0), 
	"DEPARTMENT_NAME" VARCHAR2(30) CONSTRAINT "DEPARTMENTS_NN" NOT NULL ENABLE, 
	"MANAGER_ID" NUMBER(6,0), 
	"LOCATION_ID" NUMBER(4,0), 
	 CONSTRAINT "DEPARTMENTS_PK" PRIMARY KEY ("DEPARTMENT_ID")
  USING INDEX  ENABLE, 
	 CONSTRAINT "DEPARTMENTS_FK" FOREIGN KEY ("LOCATION_ID")
	  REFERENCES "LOCATIONS" ("LOCATION_ID") ENABLE
   ) 
   ]'  ;
   END LOOP;
END;
/