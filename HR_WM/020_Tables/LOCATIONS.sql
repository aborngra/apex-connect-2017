/* This anonymous block creates a table named LOCATIONS
   PL/SQL Block is restartable, so it can be executed n times, but
   only creates the table if it does not exist.
   %author  ABO
   %created 2017-04-19 22:34:31
 */

BEGIN
   FOR i IN (SELECT 'LOCATIONS' AS table_name FROM DUAL
             MINUS
             SELECT table_name FROM user_tables)
   LOOP
      EXECUTE IMMEDIATE q'[
  CREATE TABLE "LOCATIONS" 
   (	
    "LOCATION_ID" NUMBER(4,0), 
	"STREET_ADDRESS" VARCHAR2(40), 
	"POSTAL_CODE" VARCHAR2(12), 
	"CITY" VARCHAR2(30) CONSTRAINT "LOCATIONS_NN" NOT NULL ENABLE, 
	"STATE_PROVINCE" VARCHAR2(25), 
	"COUNTRY_ID" CHAR(2), 
	 CONSTRAINT "LOCATIONS_PK" PRIMARY KEY ("LOCATION_ID")
  USING INDEX  ENABLE, 
	 CONSTRAINT "LOCATIONS_FK" FOREIGN KEY ("COUNTRY_ID")
	  REFERENCES "COUNTRIES" ("COUNTRY_ID") ENABLE
   ) 
   ]';
   END LOOP;
END;
/