CREATE OR REPLACE PACKAGE model
   AUTHID CURRENT_USER
/*---------------------------------------------------------------------------------------------
  Beschreibung: Code Genrator für Tabellenerstellungs-Skripte und
                zugehörige Sequencen, Synonyme und eine Table API

  Autor:        André Borngräber

  TODOs:
  - Tabellennamen auf Länge prüfen
  - wrapperprocedure create_or_update_row, um nur einen call für die Anwendung zu haben
  - Bei Löschen eines Records sollten alle Altwerte in old_value eingetragen werden
  - Bei Anlegen eines Records sollten alle Neuwerte in new_value gespeichert werden
  - Spalten mit _id, _date, _yn brauchen keine Datentypdeklaration, diese wird implizit vergeben
    bei _yn muß auch ein checkconstraint angelegt werden
  - Klappt unique constraint anlage mit mehreren Spalten (split to table function fehlt wohl noch)
  - Kommentare auf Tabellen und Spalten sollten immer überschrieben werden
  - create synonym & create sequence als Prozedur anlegen wie create_index
  - alle Aufrufe so umbauen, daß nur Scripte erstellt werden, wenn ein Directory angegeben wurde

  - PK wird als single column angenommen - muß gefixt werden (wirklich? ist eigentlich immer eine Sequenz)
  - UK implementieren analog PK - ABO: erledigt (get_pk_by_unique_cols)
  - Codegenerator verwenden macht definitiv Sinn (Sequenz, API, Synonym...), Namenskonventionen können wir uns noch überlegen
  - bei Parametern das Tabellenkürzel im Parametername weglassen, aus dem gleichen Grund
  - Update bei zusammengesetzter Primärschlüssel??? Ich denke, ein zusammengesetzter PK fuktioniert m Moment nicht richtig --> Code anpassen
  - Macht es Sinn pro Tabelle ein API Package und ein Business Logic Package zu haben --> Migration ist einfacher!!! und man hat eine klare Trennung!!!
  erledigt - überlegen, ob man bei read... update... usw. das Kürzel des Obektes weglässt
  erledigt - Schema <Qualifier>_ eher weglassen beim Package, Parameter usw., denn es kostet Zeichenanzahl
  --------------------------------------------------------------------------------------------*/



IS
   PROCEDURE generate_api (
      p_table_name                   IN VARCHAR2,
      p_directory                    IN VARCHAR2 DEFAULT NULL,
      p_enable_generic_logging       IN BOOLEAN DEFAULT FALSE,
      p_enable_deletion_of_records   IN BOOLEAN DEFAULT FALSE,
      p_col_prefix_in_method_names   IN BOOLEAN DEFAULT FALSE);

   PROCEDURE drop_object (p_object_type   IN VARCHAR2,
                          p_object_name   IN VARCHAR2);

   FUNCTION get_table_column_prefix (p_table_name IN VARCHAR2)
      RETURN VARCHAR2;

   /* Returns the column_name before the first underscore from all table_columns.
    * Returns null, if column_prefix is not unique.
    */

   FUNCTION get_column_prefix (p_column_name IN VARCHAR2)
      RETURN VARCHAR2;

   /* Returns the column_name before the first underscore from the given string.
    * Returns the whole string if no underscore is found.
    */

   PROCEDURE create_index (p_index_name   IN VARCHAR2,
                           p_table_name   IN VARCHAR2,
                           p_columns      IN VARCHAR2);

   PROCEDURE add_constraint (
      p_table_name         IN VARCHAR2,
      p_constraint_name    IN VARCHAR2,
      p_constraint_type    IN VARCHAR2,
      p_pk_column_name     IN VARCHAR2 DEFAULT NULL,
      p_fk_column_name     IN VARCHAR2 DEFAULT NULL,
      p_fk_r_owner         IN VARCHAR2 DEFAULT NULL,
      p_fk_r_table_name    IN VARCHAR2 DEFAULT NULL,
      p_fk_r_column_name   IN VARCHAR2 DEFAULT NULL,
      p_fk_delete_rule     IN VARCHAR2 DEFAULT NULL,
      p_uq_columns         IN VARCHAR2 DEFAULT NULL,
      p_ck_condition       IN VARCHAR2 DEFAULT NULL,
      p_status             IN VARCHAR2 DEFAULT 'ENABLED');

   /* CONSTRAINT_TYPE: 'PK' 'FK' 'UQ' 'CK' --> Primary Key, Foreign Key, UniQue, ChecK
    * DELETE_RULE:     'CASCADE'  'NO ACTION'
    * STATUS:          'DISABLED' 'ENABLED'
    */

   PROCEDURE add_column (p_table_name              IN VARCHAR2,
                         p_column_name             IN VARCHAR2,
                         p_data_type               IN VARCHAR2,
                         p_length                  IN INTEGER DEFAULT NULL,
                         p_decimal_places          IN INTEGER DEFAULT NULL,
                         p_default                 IN VARCHAR2 DEFAULT NULL,
                         p_nullable                IN BOOLEAN DEFAULT TRUE,
                         p_table_comment           IN VARCHAR2 DEFAULT NULL,
                         p_column_comment          IN VARCHAR2 DEFAULT NULL,
                         p_table_index_organized   IN BOOLEAN DEFAULT FALSE);
END model;
/