/* This anonymous block creates a table named REGIONS
   PL/SQL Block is restartable, so it can be executed n times, but
   only creates the table if it does not exist.
   %author  ABO
   %created 2017-04-19 22:34:31
 */

BEGIN
   FOR i IN (SELECT 'REGIONS' AS table_name FROM DUAL
             MINUS
             SELECT table_name FROM user_tables)
   LOOP
      EXECUTE IMMEDIATE q'[
  CREATE TABLE "REGIONS" 
   (	
    "REGION_ID" NUMBER CONSTRAINT "REGIONS_NN" NOT NULL ENABLE, 
	"REGION_NAME" VARCHAR2(25), 
	 CONSTRAINT "REGIONS_PK" PRIMARY KEY ("REGION_ID")
  USING INDEX  ENABLE
   ) 
   ]';
   END LOOP;
END;
/