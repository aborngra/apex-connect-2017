/* This anonymous block creates a table named COUNTRIES
   PL/SQL Block is restartable, so it can be executed n times, but
   only creates the table if it does not exist.
   %author  ABO
   %created 2017-04-19 22:34:31
 */

BEGIN
   FOR i IN (SELECT 'COUNTRIES' AS table_name FROM DUAL
             MINUS
             SELECT table_name FROM user_tables)
   LOOP
      EXECUTE IMMEDIATE q'[
  CREATE TABLE "COUNTRIES" 
   (	
    "COUNTRY_ID" CHAR(2) CONSTRAINT "COUNTRIES_NN" NOT NULL ENABLE, 
	"COUNTRY_NAME" VARCHAR2(40), 
	"REGION_ID" NUMBER, 
	 CONSTRAINT "COUNTRIES_PK" PRIMARY KEY ("COUNTRY_ID") ENABLE, 
	 CONSTRAINT "COUNTRIES_FK" FOREIGN KEY ("REGION_ID")
	  REFERENCES "REGIONS" ("REGION_ID") ENABLE
   ) ORGANIZATION INDEX NOCOMPRESS 
   ]';
   END LOOP;
END;
/