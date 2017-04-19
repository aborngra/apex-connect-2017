/* This anonymous block creates a sequence named JOB_HISTORY_SEQ
   PL/SQL Block is restartable, so it can be executed n times, but
   only creates the sequence if it does not exist.
   %author  ABO
   %created 2017-04-19 22:16:11
 */

DECLARE
   v_sequence_name user_sequences.sequence_name%TYPE := 'JOB_HISTORY_SEQ';
BEGIN
   FOR i IN (SELECT v_sequence_name FROM DUAL
             MINUS
             SELECT sequence_name FROM user_sequences)
   LOOP
      EXECUTE IMMEDIATE q'[
                       CREATE SEQUENCE JOB_HISTORY_SEQ 
                              MINVALUE 1 
                              MAXVALUE 999999999999999999999999999 
                              INCREMENT BY 1 
                              START WITH 1 
                              NOCACHE
                              NOORDER
                              NOCYCLE
                          ]';
   END LOOP;
END;
/