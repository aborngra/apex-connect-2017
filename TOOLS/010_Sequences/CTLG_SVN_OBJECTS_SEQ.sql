BEGIN
   FOR i IN ( SELECT 'CTLG_SVN_OBJECTS_SEQ' AS sequence_name FROM DUAL
              MINUS
              SELECT sequence_name FROM user_sequences ) LOOP
      EXECUTE IMMEDIATE
            ' CREATE SEQUENCE '
         || i.sequence_name
         || ' MINVALUE 0 
                 MAXVALUE 999999999999999999999999999 
                 INCREMENT BY 1 
                 START WITH 1 
                 NOCACHE
                 NOORDER
                 NOCYCLE ';
   END LOOP;
END;
/