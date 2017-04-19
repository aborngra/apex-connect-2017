/* This anonymous block creates a index named LOC_CITY_IX
   PL/SQL Block is restartable, so it can be executed n times, but
   only creates the index if it does not exist.
   %author  ABO
   %created 2017-04-19 22:16:13
 */

DECLARE
   v_index_name user_indexes.index_name%TYPE := 'LOC_CITY_IX';
BEGIN
   FOR i IN (SELECT v_index_name FROM DUAL
             MINUS
             SELECT index_name FROM user_indexes)
   LOOP
      EXECUTE IMMEDIATE q'[
  CREATE INDEX "LOC_CITY_IX" ON "LOCATIONS" ("CITY") 
]'     ;
   END LOOP;
END;
/