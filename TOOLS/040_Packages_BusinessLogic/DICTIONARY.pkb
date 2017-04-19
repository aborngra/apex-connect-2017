---------------------------------------------------------------------------------------
-- IMPLEMENTATION
---------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY dictionary
IS
   FUNCTION get_column_datatype (
      p_schema        IN all_tab_cols.owner%TYPE DEFAULT USER,
      p_table_name    IN all_tab_cols.table_name%TYPE,
      p_column_name   IN all_tab_cols.table_name%TYPE)
      RETURN user_tab_cols.data_type%TYPE
   IS
      CURSOR cur_column_datatype
      IS
         SELECT data_type
           FROM all_tab_cols
          WHERE     owner = p_schema
                AND table_name = p_table_name
                AND column_name = p_column_name;

      v_ret   user_tab_cols.data_type%TYPE;
   BEGIN
      OPEN cur_column_datatype;

      FETCH cur_column_datatype INTO v_ret;

      CLOSE cur_column_datatype;

      RETURN v_ret;
   END get_column_datatype;

   FUNCTION get_constraint_column_list (
      p_schema            IN all_cons_columns.owner%TYPE DEFAULT USER,
      p_constraint_name   IN all_cons_columns.constraint_name%TYPE,
      p_delimiter         IN VARCHAR2 DEFAULT ', ')
      RETURN VARCHAR2
   IS
      v_ret   VARCHAR2 (4000 CHAR);
   BEGIN
      FOR i
         IN (  SELECT *
                 FROM all_cons_columns
                WHERE owner = p_schema AND constraint_name = p_constraint_name
             ORDER BY position)
      LOOP
         v_ret := v_ret || p_delimiter || i.column_name;
      END LOOP;

      RETURN LTRIM (v_ret, p_delimiter);
   END get_constraint_column_list;

   FUNCTION get_constraint_column_table (
      p_schema            IN all_cons_columns.owner%TYPE DEFAULT USER,
      p_constraint_name   IN all_cons_columns.constraint_name%TYPE)
      RETURN t_str_array
      PIPELINED
   IS
   BEGIN
      FOR i
         IN (  SELECT *
                 FROM all_cons_columns
                WHERE owner = p_schema AND constraint_name = p_constraint_name
             ORDER BY position)
      LOOP
         PIPE ROW (i.column_name);
      END LOOP;

      RETURN;
   END get_constraint_column_table;

   FUNCTION get_column_surrogate (
      p_schema        IN all_tab_cols.owner%TYPE DEFAULT USER,
      p_table_name    IN all_tab_cols.table_name%TYPE,
      p_column_name   IN all_tab_cols.table_name%TYPE)
      RETURN VARCHAR2
   IS
      v_datatype   all_tab_cols.data_type%TYPE;
      v_ret        VARCHAR2 (100 CHAR);
   BEGIN
      v_datatype :=
         get_column_datatype (p_schema        => p_schema,
                              p_table_name    => p_table_name,
                              p_column_name   => p_column_name);

      v_ret :=
         CASE
            WHEN v_datatype = 'NUMBER'
            THEN
               '-999999999999999.999999999999999'
            WHEN v_datatype LIKE '%CHAR%'
            THEN
               q'['@@@@@@@@@@@@@@@']'
            WHEN v_datatype = 'BLOB'
            THEN
               q'[to_blob(UTL_RAW.cast_to_raw('@@@@@@@@@@@@@@@'))]'
            WHEN v_datatype = 'CLOB'
            THEN
               q'[to_clob('@@@@@@@@@@@@@@@')]'
            WHEN v_datatype = 'DATE'
            THEN
               q'[to_date('01.01.1900','dd.mm.yyyy')]'
            WHEN v_datatype LIKE 'TIMESTAMP%'
            THEN
               q'[to_timestamp('01.01.1900','dd.mm.yyyy')]'
            ELSE
               q'['@@@@@@@@@@@@@@@']'
         END;
      RETURN v_ret;
   END get_column_surrogate;

   FUNCTION get_column_coalesce (
      p_schema                IN all_tab_cols.owner%TYPE DEFAULT USER,
      p_table_name            IN all_tab_cols.table_name%TYPE,
      p_column_name           IN all_tab_cols.table_name%TYPE,
      p_left_coalesce_side    IN VARCHAR2,
      p_right_coalesce_side   IN VARCHAR2,
      p_compare_operation     IN VARCHAR2 DEFAULT '<>')
      RETURN VARCHAR2
   IS
      v_datatype    all_tab_cols.data_type%TYPE;
      v_surrogate   VARCHAR2 (100 CHAR);
      v_ret         VARCHAR2 (1000 CHAR);
   BEGIN
      v_datatype :=
         get_column_datatype (p_schema        => p_schema,
                              p_table_name    => p_table_name,
                              p_column_name   => p_column_name);

      v_surrogate :=
         get_column_surrogate (p_schema        => p_schema,
                               p_table_name    => p_table_name,
                               p_column_name   => p_column_name);

      v_ret :=
         CASE
            WHEN v_datatype IN ('BLOB', 'CLOB')
            THEN
                  'DBMS_LOB.compare ( COALESCE ( '
               || p_left_coalesce_side
               || ', '
               || v_surrogate
               || '), '
               || '  COALESCE ( '
               || p_right_coalesce_side
               || ', '
               || v_surrogate
               || ')) '
               || p_compare_operation
               || ' 0'
            ELSE
                  '  COALESCE ( '
               || p_left_coalesce_side
               || ', '
               || v_surrogate
               || ') '
               || p_compare_operation
               || ' '
               || '  COALESCE ( '
               || p_right_coalesce_side
               || ', '
               || v_surrogate
               || ')'
         END;
      RETURN v_ret;
   END get_column_coalesce;

   FUNCTION get_table_key (
      p_table_name   IN user_tables.table_name%TYPE,
      p_key_type     IN user_constraints.constraint_type%TYPE DEFAULT 'P',
      p_delimiter    IN VARCHAR2 DEFAULT ', ')
      RETURN VARCHAR2
   IS
      v_table_pk   VARCHAR2 (4000 CHAR);
   BEGIN
      FOR i
         IN (WITH cons
                  AS (SELECT *
                        FROM user_constraints
                       WHERE     table_name = UPPER (p_table_name)
                             AND constraint_type = p_key_type),
                  cols
                  AS (SELECT *
                        FROM user_cons_columns
                       WHERE table_name = UPPER (p_table_name))
               SELECT column_name
                 FROM cons
                      JOIN cols ON cons.constraint_name = cols.constraint_name
             ORDER BY position)
      LOOP
         v_table_pk := v_table_pk || p_delimiter || i.column_name;
      END LOOP;

      RETURN LTRIM (v_table_pk, p_delimiter);
   END get_table_key;

   PROCEDURE adapt_sequence_value (
      p_sequence_name   IN user_sequences.sequence_name%TYPE,
      p_table_name      IN user_tables.table_name%TYPE,
      p_pk_column       IN user_tab_cols.column_name%TYPE)
   IS
      v_max_pk_column   NUMBER;
      v_seq_currval     NUMBER;
   BEGIN
      -- get the max of pk column of the table
      EXECUTE IMMEDIATE
         'SELECT MAX(' || p_pk_column || ') FROM ' || p_table_name
         INTO v_max_pk_column;

      IF (v_max_pk_column IS NOT NULL AND v_max_pk_column > 0)
      THEN
         -- get the next sequence value
         EXECUTE IMMEDIATE
            'SELECT ' || p_sequence_name || '.NEXTVAL FROM DUAL'
            INTO v_seq_currval;

         -- adapt the sequence, if sequence value <> max of pk_column
         IF (v_seq_currval <> v_max_pk_column)
         THEN
            EXECUTE IMMEDIATE
                  'ALTER SEQUENCE '
               || p_sequence_name
               || ' INCREMENT BY '
               || (v_max_pk_column - v_seq_currval);

            EXECUTE IMMEDIATE
               'SELECT ' || p_sequence_name || '.NEXTVAL FROM DUAL'
               INTO v_seq_currval;

            EXECUTE IMMEDIATE
               'ALTER SEQUENCE ' || p_sequence_name || ' INCREMENT BY 1';
         END IF;
      END IF;
   END adapt_sequence_value;

   FUNCTION get_long_search_condition (p_constraint_name IN VARCHAR2)
      RETURN VARCHAR2
   AS
      v_return   LONG;

      CURSOR c_search_condition
      IS
         SELECT search_condition
           FROM user_constraints
          WHERE constraint_name = p_constraint_name;
   BEGIN
      OPEN c_search_condition;

      FETCH c_search_condition INTO v_return;

      CLOSE c_search_condition;

      RETURN SUBSTR (v_return, 1, 4000);
   END get_long_search_condition;

   PROCEDURE manage_constraint_names (
      p_table_name           IN user_constraints.table_name%TYPE,
      p_primary_key_naming   IN user_constraints.constraint_name%TYPE DEFAULT '#TABLE_NAME#_PK',
      p_foreign_key_naming   IN user_constraints.constraint_name%TYPE DEFAULT '#TABLE_NAME#_FK',
      p_not_null_naming      IN user_constraints.constraint_name%TYPE DEFAULT '#TABLE_NAME#_NN',
      p_check_naming         IN user_constraints.constraint_name%TYPE DEFAULT '#TABLE_NAME#_CK',
      p_unique_naming        IN user_constraints.constraint_name%TYPE DEFAULT '#TABLE_NAME#_UQ')
   IS
      v_constraint_name_tmp          user_constraints.constraint_name%TYPE
                                        := 'CONSTRAINT____TMP____';

      v_constraint_name_calculated   user_constraints.constraint_name%TYPE;

      CURSOR v_cur_constraints (
         p_tab_name   IN user_constraints.table_name%TYPE)
      IS
         WITH constraint_info
              AS (SELECT uc.table_name,
                         uc.constraint_name,
                         tc.column_id AS column_id,
                         ucc.column_name,
                         uc.constraint_type AS type_dictionary-- differentiate between pure NOT NULL constraints
                                                              -- (named NN) and check constraints (named CK)
                         ,
                         CASE
                            WHEN     uc.constraint_type = 'C'
                                 AND tools.dictionary.get_long_search_condition (
                                        p_constraint_name   => uc.constraint_name) =
                                           '"'
                                        || ucc.column_name
                                        || '" IS NOT NULL'
                            THEN
                               'NN'
                            ELSE
                               uc.constraint_type
                         END
                            AS type_naming,
                         ui.index_name
                    FROM user_constraints uc
                         JOIN user_cons_columns ucc
                            ON     UPPER (uc.table_name) =
                                      UPPER (ucc.table_name)
                               AND UPPER (uc.constraint_name) =
                                      UPPER (ucc.constraint_name)
                         -- JOIN with user_tab_cols to have the column order
                         JOIN user_tab_cols tc
                            ON     UPPER (ucc.table_name) =
                                      UPPER (tc.table_name)
                               AND UPPER (ucc.column_name) =
                                      UPPER (tc.column_name)
                         -- JOIN with USER_INDEXES for renaming parallel the indexes
                         LEFT JOIN user_indexes ui
                            ON     UPPER (uc.table_name) =
                                      UPPER (ui.table_name)
                               AND UPPER (uc.constraint_name) =
                                      UPPER (ui.index_name)
                   WHERE uc.table_name = p_tab_name),
              constraint_type_count
              AS (SELECT table_name,
                         type_naming,
                         constraint_name,
                         column_name,
                         column_id,
                         COUNT (DISTINCT constraint_name)
                            OVER (PARTITION BY table_name, type_naming)
                            AS constraint_type_counter
                    FROM constraint_info),
              constraint_position
              AS (SELECT table_name,
                         type_naming,
                         constraint_name,
                         column_name,
                         column_id,
                         DENSE_RANK ()
                         OVER (
                            PARTITION BY type_naming, constraint_type_counter
                            ORDER BY constraint_name)
                            AS constraint_type_position
                    FROM constraint_type_count)
           SELECT ci.*,
                  ctc.constraint_type_counter,
                  cp.constraint_type_position
             FROM constraint_info ci
                  JOIN constraint_type_count ctc
                     ON     ci.table_name = ctc.table_name
                        AND ci.constraint_name = ctc.constraint_name
                        AND ci.type_naming = ctc.type_naming
                        AND ci.column_name = ctc.column_name
                  JOIN constraint_position cp
                     ON     ci.column_id = cp.column_id
                        AND ci.constraint_name = cp.constraint_name
         ORDER BY ci.column_id;

      TYPE t_constraint_information IS RECORD
      (
         table_name                 user_constraints.table_name%TYPE,
         constraint_name            user_constraints.constraint_name%TYPE,
         column_id                  user_tab_cols.column_id%TYPE,
         column_name                user_cons_columns.column_name%TYPE,
         type_dictionary            user_constraints.constraint_type%TYPE,
         type_naming                VARCHAR2 (2 CHAR),
         index_name                 user_indexes.index_name%TYPE,
         constraint_type_counter    NUMBER,
         constraint_type_position   NUMBER
      );

      TYPE t_constraint_tab IS TABLE OF t_constraint_information;

      constraint_tab                 t_constraint_tab;
   BEGIN
      ----------------------------------------------------------------------------
      -- check params
      ----------------------------------------------------------------------------
      IF (    p_table_name IS NOT NULL
          AND p_primary_key_naming IS NOT NULL
          AND p_foreign_key_naming IS NOT NULL
          AND p_not_null_naming IS NOT NULL
          AND p_check_naming IS NOT NULL
          AND p_unique_naming IS NOT NULL)
      THEN
         --------------------------------------------------------------------------
         -- collect all constraint information of the given table
         --------------------------------------------------------------------------
         OPEN v_cur_constraints (p_tab_name => p_table_name);

         FETCH v_cur_constraints BULK COLLECT INTO constraint_tab LIMIT 1000;

         CLOSE v_cur_constraints;

         IF (constraint_tab.COUNT > 0)
         THEN
            ------------------------------------------------------------------------
            -- first step: rename constraint and indexes to temporary names
            ------------------------------------------------------------------------

            FOR i IN constraint_tab.FIRST .. constraint_tab.LAST
            LOOP
               rename_constraint (
                  p_table_name                => constraint_tab (i).table_name,
                  p_constraint_name_current   => constraint_tab (i).constraint_name,
                  p_constraint_name_new       =>    v_constraint_name_tmp
                                                 || TO_CHAR (i, 'FM09'));

               --          DBMS_OUTPUT.put_line(    'Constraint: '
               --                                || constraint_tab( i ).constraint_name
               --                                || ' temporary renamed to:'
               --                                || v_constraint_name_tmp
               --                                || TO_CHAR( i, 'FM09' ) );

               ----------------------------------------------------------------------
               -- rename also the index, if it exists
               ----------------------------------------------------------------------
               IF (constraint_tab (i).index_name IS NOT NULL)
               THEN
                  rename_index (
                     p_index_name_current   => constraint_tab (i).index_name,
                     p_index_name_new       =>    v_constraint_name_tmp
                                               || TO_CHAR (i, 'FM09'));
               --            DBMS_OUTPUT.put_line(    '       Index: '
               --                                  || constraint_tab( i ).index_name
               --                                  || ' temporary renamed to:'
               --                                  || v_constraint_name_tmp
               --                                  || TO_CHAR( i, 'FM09' ) );
               END IF;
            END LOOP;

            ------------------------------------------------------------------------
            -- second step: rename constraint and indexes to the given naming rules
            ------------------------------------------------------------------------

            FOR i IN constraint_tab.FIRST .. constraint_tab.LAST
            LOOP
               ----------------------------------------------------------------------
               -- take the new namings
               ----------------------------------------------------------------------
               v_constraint_name_calculated :=
                  CASE constraint_tab (i).type_naming
                     WHEN 'P' THEN p_primary_key_naming
                     WHEN 'R' THEN p_foreign_key_naming
                     WHEN 'NN' THEN p_not_null_naming
                     WHEN 'C' THEN p_check_naming
                     WHEN 'U' THEN p_unique_naming
                     ELSE NULL
                  END;

               ----------------------------------------------------------------------
               -- replace the table_name if #TABLE_NAME# substitution is used
               -- and limit the name to 30 character
               ----------------------------------------------------------------------
               v_constraint_name_calculated :=
                  SUBSTR (
                     REPLACE (
                        v_constraint_name_calculated,
                        '#TABLE_NAME#',
                        CASE
                           WHEN LENGTH (constraint_tab (i).table_name) <= 25
                           THEN
                              constraint_tab (i).table_name
                           ELSE
                              CASE
                                 WHEN constraint_tab (i).table_name LIKE
                                         '%\_H' ESCAPE '\'
                                 THEN
                                       SUBSTR (constraint_tab (i).table_name,
                                               1,
                                               22)
                                    || '~_H'
                                 ELSE
                                       SUBSTR (constraint_tab (i).table_name,
                                               1,
                                               24)
                                    || '~'
                              END
                        END),
                     1,
                     30);

               ----------------------------------------------------------------------
               -- add a postfix counter to the constraint_name, if > 1 constraint of
               -- one type exist
               ----------------------------------------------------------------------
               IF (constraint_tab (i).constraint_type_counter > 1)
               THEN
                  v_constraint_name_calculated :=
                        SUBSTR (v_constraint_name_calculated, 1, 28)
                     || TO_CHAR (constraint_tab (i).constraint_type_position,
                                 'FM09');
               END IF;

               rename_constraint (
                  p_table_name                => constraint_tab (i).table_name,
                  p_constraint_name_current   =>    v_constraint_name_tmp
                                                 || TO_CHAR (i, 'FM09'),
                  p_constraint_name_new       => v_constraint_name_calculated);

               --          DBMS_OUTPUT.put_line(    'Constraint: '
               --                                || v_constraint_name_tmp
               --                                || TO_CHAR( i, 'FM09' )
               --                                || ' renamed to:'
               --                                || v_constraint_name_calculated );

               ----------------------------------------------------------------------
               -- rename also the index, if it exists
               ----------------------------------------------------------------------
               IF (constraint_tab (i).index_name IS NOT NULL)
               THEN
                  rename_index (
                     p_index_name_current   =>    v_constraint_name_tmp
                                               || TO_CHAR (i, 'FM09'),
                     p_index_name_new       => v_constraint_name_calculated);
               --            DBMS_OUTPUT.put_line(    '       Index: '
               --                                  || v_constraint_name_tmp
               --                                  || TO_CHAR( i, 'FM09' )
               --                                  || ' renamed to:'
               --                                  || v_constraint_name_calculated );
               END IF;
            END LOOP;
         END IF;
      END IF;
   END manage_constraint_names;

   PROCEDURE rename_constraint (
      p_table_name                IN user_constraints.table_name%TYPE,
      p_constraint_name_current   IN user_constraints.constraint_name%TYPE,
      p_constraint_name_new       IN user_constraints.constraint_name%TYPE)
   IS
   BEGIN
      ----------------------------------------------------------------------------
      -- check params
      ----------------------------------------------------------------------------
      IF (    p_table_name IS NOT NULL
          AND p_constraint_name_current IS NOT NULL
          AND p_constraint_name_new IS NOT NULL
          AND p_constraint_name_current <> p_constraint_name_new)
      THEN
         --------------------------------------------------------------------------
         -- rename the constraint, if constraint exists for that table
         --------------------------------------------------------------------------
         FOR constr
            IN (SELECT 1
                  FROM user_constraints
                 WHERE     table_name = p_table_name
                       AND constraint_name = p_constraint_name_current)
         LOOP
            EXECUTE IMMEDIATE
                  'ALTER TABLE "'
               || p_table_name
               || '" RENAME CONSTRAINT "'
               || p_constraint_name_current
               || '" TO "'
               || p_constraint_name_new
               || '"';
         END LOOP;
      END IF;
   END rename_constraint;

   PROCEDURE rename_index (
      p_index_name_current   IN user_indexes.index_name%TYPE,
      p_index_name_new       IN user_indexes.index_name%TYPE)
   IS
   BEGIN
      ----------------------------------------------------------------------------
      -- check params
      ----------------------------------------------------------------------------
      IF (    p_index_name_current IS NOT NULL
          AND p_index_name_new IS NOT NULL
          AND p_index_name_current <> p_index_name_new)
      THEN
         --------------------------------------------------------------------------
         -- rename the index, if index exists
         --------------------------------------------------------------------------
         FOR ind IN (SELECT 1
                       FROM user_indexes
                      WHERE index_name = p_index_name_current)
         LOOP
            EXECUTE IMMEDIATE
                  'ALTER INDEX "'
               || p_index_name_current
               || '" RENAME TO "'
               || p_index_name_new
               || '"';
         END LOOP;
      END IF;
   END rename_index;

   FUNCTION get_table_prefixes
      RETURN g_cur_table_prefix_tab
      PIPELINED
   IS
      v_cur_table_prefix_tab   g_cur_table_prefix_tab;
   BEGIN
      OPEN g_cur_table_prefix;

      FETCH g_cur_table_prefix BULK COLLECT INTO v_cur_table_prefix_tab;

      CLOSE g_cur_table_prefix;

      IF (v_cur_table_prefix_tab.FIRST IS NOT NULL)
      THEN
         FOR i IN v_cur_table_prefix_tab.FIRST .. v_cur_table_prefix_tab.LAST
         LOOP
            PIPE ROW (v_cur_table_prefix_tab (i));
         END LOOP;
      END IF;

      RETURN;
   END get_table_prefixes;
END dictionary;
/