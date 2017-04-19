/* This anonymous block creates a table named CTLG_SVN_OBJECTS
   PL/SQL Block is restartable, so it can be executed n times, but 
   only creates the table if it does not exist.
   %author  André Borngräber
   %created 2015-09-09 13:43:07
*/

BEGIN
   FOR i IN ( SELECT 'CTLG_SVN_OBJECTS' AS table_name FROM DUAL
              MINUS
              SELECT table_name FROM user_tables ) LOOP
      EXECUTE IMMEDIATE
         q'[
  CREATE TABLE "CTLG_SVN_OBJECTS" 
   (    "SVN_ID" NUMBER, 
    "SVN_SCHEMA" VARCHAR2(30 CHAR) CONSTRAINT "CTLG_SVN_OBJECTS_NN01" NOT NULL ENABLE, 
    "SVN_OBJECT" VARCHAR2(30 CHAR) CONSTRAINT "CTLG_SVN_OBJECTS_NN02" NOT NULL ENABLE, 
    "SVN_NAME" VARCHAR2(30 CHAR) CONSTRAINT "CTLG_SVN_OBJECTS_NN03" NOT NULL ENABLE, 
    "SVN_SCRIPT" CLOB CONSTRAINT "CTLG_SVN_OBJECTS_NN04" NOT NULL ENABLE, 
     CONSTRAINT "CTLG_SVN_OBJECTS_CK01" CHECK ( svn_object IN ('SEQUENCE'
                                                 , 'TABLE'
                                                 , 'VIEW'
                                                 , 'MATERIALIZED VIEW'
                                                 , 'INDEX'
                                                 , 'SYNONYM'
                                                 , 'PACKAGE'
                                                 , 'PACKAGE BODY'
                                                 , 'FUNCTION'
                                                 , 'PROCEDURE'
                                                 , 'TRIGGER'
                                                 , 'TYPE') ) ENABLE, 
     CONSTRAINT "CTLG_SVN_OBJECTS_PK" PRIMARY KEY ("SVN_ID") ENABLE,
     "SVN_CREATED_AT" DATE CONSTRAINT "CTLG_SVN_OBJECTS_NN06" NOT NULL ENABLE
   ) 
   LOB (SVN_SCRIPT) STORE AS (INDEX "CTLG_SVN_OBJECTS_LOB01")
           ]';
   END LOOP;
END;
/