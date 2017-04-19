/* This anonymous block creates a table named JOBS
   PL/SQL Block is restartable, so it can be executed n times, but
   only creates the table if it does not exist.
   %author  ABO
   %created 2017-04-19 22:34:31
 */

BEGIN
   FOR i IN (SELECT 'JOBS' AS table_name FROM DUAL
             MINUS
             SELECT table_name FROM user_tables)
   LOOP
      EXECUTE IMMEDIATE q'[
  CREATE TABLE "JOBS" 
   (	
    "JOB_ID" VARCHAR2(10), 
	"JOB_TITLE" VARCHAR2(35) CONSTRAINT "JOBS_NN" NOT NULL ENABLE, 
	"MIN_SALARY" NUMBER(6,0), 
	"MAX_SALARY" NUMBER(6,0), 
	 CONSTRAINT "JOBS_PK" PRIMARY KEY ("JOB_ID")
  USING INDEX  ENABLE
   ) 
   ]';
   END LOOP;
END;
/