BEGIN
   -- Wiederanlauffähigkeit sicherstellen
   FOR i IN (  SELECT table_name
                 FROM user_tables
                WHERE table_name = 'TEMPORARY_LOB_TABLE' ) LOOP
      EXECUTE IMMEDIATE 'DROP TABLE ' || i.table_name;
   END LOOP;

   -- Temporäre Tabelle anlegen
   EXECUTE IMMEDIATE
         'CREATE GLOBAL TEMPORARY TABLE '
      || 'TEMPORARY_LOB_TABLE '
      || '('
      || '  context VARCHAR2(255 CHAR)'
      || ', filename VARCHAR2(255 CHAR)'
      || ', lob_content BLOB'
      || ', sys_date DATE'
      || ') '
      || 'ON COMMIT DELETE ROWS';
END;
/

GRANT SELECT
    , INSERT
    , UPDATE
    , DELETE
   ON temporary_lob_table
   TO PUBLIC;