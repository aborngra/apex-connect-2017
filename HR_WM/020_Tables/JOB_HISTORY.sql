/* This anonymous block creates a table named JOB_HISTORY
   PL/SQL Block is restartable, so it can be executed n times, but
   only creates the table if it does not exist.
   %author  ABO
   %created 2017-04-19 22:34:31
 */

BEGIN
   FOR i IN (SELECT 'JOB_HISTORY' AS table_name FROM DUAL
             MINUS
             SELECT table_name FROM user_tables)
   LOOP
      EXECUTE IMMEDIATE q'[
  CREATE TABLE "JOB_HISTORY" 
   (	
    "EMPLOYEE_ID" NUMBER(6,0) CONSTRAINT "JOB_HISTORY_NN01" NOT NULL ENABLE, 
	"START_DATE" DATE CONSTRAINT "JOB_HISTORY_NN04" NOT NULL ENABLE, 
	"END_DATE" DATE CONSTRAINT "JOB_HISTORY_NN02" NOT NULL ENABLE, 
	"JOB_ID" VARCHAR2(10) CONSTRAINT "JOB_HISTORY_NN03" NOT NULL ENABLE, 
	"DEPARTMENT_ID" NUMBER(4,0), 
	 CONSTRAINT "JOB_HISTORY_CK" CHECK (end_date > start_date) ENABLE, 
	 CONSTRAINT "JOB_HISTORY_PK" PRIMARY KEY ("EMPLOYEE_ID", "START_DATE")
  USING INDEX  ENABLE, 
	 CONSTRAINT "JOB_HISTORY_FK" FOREIGN KEY ("JOB_ID")
	  REFERENCES "JOBS" ("JOB_ID") ENABLE
   ) 
   ]';
   END LOOP;
END;
/