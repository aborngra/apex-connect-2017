CREATE OR REPLACE EDITIONABLE PACKAGE BODY "SVN_BL"
IS
   PROCEDURE create_svn_objects
   IS
   BEGIN
      tools.svn.create_svn_objects(
         p_user => SYS_CONTEXT('userenv', 'current_schema'));
   END create_svn_objects;

   PROCEDURE download_svn_sequences
   IS
   BEGIN
      tools.zip.apex_download_ziped_clobs(
         p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
       , p_source_filename_rule    => 'upper(SVN_NAME) || ''.sql'''
       , p_source_clob_column_name => 'SVN_SCRIPT'
       , p_source_sql_criteria     =>    'SVN_OBJECT=''SEQUENCE'' AND SVN_SCHEMA='''
                                      || SYS_CONTEXT('userenv'
                                                   , 'current_schema')
                                      || ''' '
       , p_target_zip_file_name    => 'Sequences.zip');
   END download_svn_sequences;

   PROCEDURE download_svn_tables
   IS
   BEGIN
      tools.zip.apex_download_ziped_clobs(
         p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
       , p_source_filename_rule    => 'upper(SVN_NAME) || ''.sql'''
       , p_source_clob_column_name => 'SVN_SCRIPT'
       , p_source_sql_criteria     =>    'SVN_OBJECT=''TABLE'' AND SVN_SCHEMA='''
                                      || SYS_CONTEXT('userenv'
                                                   , 'current_schema')
                                      || ''' '
       , p_target_zip_file_name    => 'Tables.zip');
   END download_svn_tables;

   PROCEDURE download_svn_indexes
   IS
   BEGIN
      tools.zip.apex_download_ziped_clobs(
         p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
       , p_source_filename_rule    => 'upper(SVN_NAME) || ''.sql'''
       , p_source_clob_column_name => 'SVN_SCRIPT'
       , p_source_sql_criteria     =>    'SVN_OBJECT=''INDEX'' AND SVN_SCHEMA='''
                                      || SYS_CONTEXT('userenv'
                                                   , 'current_schema')
                                      -- table constraints are generated inline within SVN scripts for tables,
                                      -- so indexes are here only manually created indexes can be downloaded
                                      || ''' AND SVN_NAME NOT IN (SELECT CONSTRAINT_NAME FROM USER_CONSTRAINTS)'
       , p_target_zip_file_name    => 'Indexes.zip');
   END download_svn_indexes;

   PROCEDURE download_svn_synonyms
   IS
   BEGIN
      tools.zip.apex_download_ziped_clobs(
         p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
       , p_source_filename_rule    => 'upper(SVN_NAME) || ''.sql'''
       , p_source_clob_column_name => 'SVN_SCRIPT'
       , p_source_sql_criteria     =>    'SVN_OBJECT=''SYNONYM'' AND SVN_SCHEMA='''
                                      || SYS_CONTEXT('userenv'
                                                   , 'current_schema')
                                      || ''' '
       , p_target_zip_file_name    => 'Synonyms.zip');
   END download_svn_synonyms;

   PROCEDURE download_svn_packages_api
   IS
   BEGIN
      tools.zip.apex_download_ziped_clobs(
         p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
       , p_source_filename_rule    => 'upper(SVN_NAME) || CASE WHEN SVN_OBJECT = ''PACKAGE'' THEN ''.pks'' ELSE ''.pkb'' END '
       , p_source_clob_column_name => 'SVN_SCRIPT'
       , p_source_sql_criteria     =>    'SVN_OBJECT IN (''PACKAGE'',''PACKAGE BODY'') AND SVN_SCHEMA='''
                                      || SYS_CONTEXT('userenv'
                                                   , 'current_schema')
                                      || ''' AND upper(SVN_NAME) LIKE ''%\_API'' ESCAPE ''\'''
                                      -- com_staging_api makes problems during download
                                      || ' AND upper(SVN_NAME) <> ''COM_STAGING_API'''
       , p_target_zip_file_name    => 'Packages_API.zip');
   END download_svn_packages_api;

   PROCEDURE download_svn_packages_bl
   IS
   BEGIN
      tools.zip.apex_download_ziped_clobs(
         p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
       , p_source_filename_rule    => 'upper(SVN_NAME) || CASE WHEN SVN_OBJECT = ''PACKAGE'' THEN ''.pks'' ELSE ''.pkb'' END '
       , p_source_clob_column_name => 'SVN_SCRIPT'
       , p_source_sql_criteria     =>    'SVN_OBJECT IN (''PACKAGE'',''PACKAGE BODY'') AND SVN_SCHEMA='''
                                      || SYS_CONTEXT('userenv'
                                                   , 'current_schema')
                                      || ''' AND upper(SVN_NAME) NOT LIKE ''%\_API'' ESCAPE ''\'''
       , p_target_zip_file_name    => 'Packages_BL.zip');
   END download_svn_packages_bl;

   PROCEDURE download_svn_functions
   IS
   BEGIN
      tools.zip.apex_download_ziped_clobs(
         p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
       , p_source_filename_rule    => 'upper(SVN_NAME) || ''.sql'''
       , p_source_clob_column_name => 'SVN_SCRIPT'
       , p_source_sql_criteria     =>    'SVN_OBJECT=''FUNCTION'' AND SVN_SCHEMA='''
                                      || SYS_CONTEXT('userenv'
                                                   , 'current_schema')
                                      || ''' '
       , p_target_zip_file_name    => 'Functions.zip');
   END download_svn_functions;

   PROCEDURE download_svn_procedures
   IS
   BEGIN
      tools.zip.apex_download_ziped_clobs(
         p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
       , p_source_filename_rule    => 'upper(SVN_NAME) || ''.sql'''
       , p_source_clob_column_name => 'SVN_SCRIPT'
       , p_source_sql_criteria     =>    'SVN_OBJECT=''PROCEDURE'' AND SVN_SCHEMA='''
                                      || SYS_CONTEXT('userenv'
                                                   , 'current_schema')
                                      || ''' '
       , p_target_zip_file_name    => 'Procedures.zip');
   END download_svn_procedures;

   PROCEDURE download_svn_triggers
   IS
   BEGIN
      tools.zip.apex_download_ziped_clobs(
         p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
       , p_source_filename_rule    => 'upper(SVN_NAME) || ''.sql'''
       , p_source_clob_column_name => 'SVN_SCRIPT'
       , p_source_sql_criteria     =>    'SVN_OBJECT=''TRIGGER'' AND SVN_SCHEMA='''
                                      || SYS_CONTEXT('userenv'
                                                   , 'current_schema')
                                      || ''' '
       , p_target_zip_file_name    => 'Triggers.zip');
   END download_svn_triggers;

   PROCEDURE download_svn_types
   IS
   BEGIN
      tools.zip.apex_download_ziped_clobs(
         p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
       , p_source_filename_rule    => 'upper(SVN_NAME) || ''.tps'''
       , p_source_clob_column_name => 'SVN_SCRIPT'
       , p_source_sql_criteria     =>    'SVN_OBJECT=''TYPE'' AND SVN_SCHEMA='''
                                      || SYS_CONTEXT('userenv'
                                                   , 'current_schema')
                                      || ''' '
       , p_target_zip_file_name    => 'Types.zip');
   END download_svn_types;

   PROCEDURE download_svn_views
   IS
   BEGIN
      tools.zip.apex_download_ziped_clobs(
         p_source_table_name       => 'TOOLS.CTLG_SVN_OBJECTS'
       , p_source_filename_rule    => 'upper(SVN_NAME) || ''.sql'''
       , p_source_clob_column_name => 'SVN_SCRIPT'
       , p_source_sql_criteria     =>    'SVN_OBJECT=''VIEW'' AND SVN_SCHEMA='''
                                      || SYS_CONTEXT('userenv'
                                                   , 'current_schema')
                                      || ''' '
       , p_target_zip_file_name    => 'Views.zip');
   END download_svn_views;

   FUNCTION get_svn_last_created_at(
      p_svn_schema  tools.ctlg_svn_objects.svn_schema%TYPE)
      RETURN tools.ctlg_svn_objects.svn_created_at%TYPE
   IS
      v_ret tools.ctlg_svn_objects.svn_created_at%TYPE;

      CURSOR v_cur
      IS
         SELECT MAX(svn_created_at)
           FROM tools.ctlg_svn_objects
          WHERE svn_schema = p_svn_schema;
   BEGIN
      OPEN v_cur;

      FETCH v_cur INTO v_ret;

      CLOSE v_cur;

      RETURN v_ret;
   END get_svn_last_created_at;
END "SVN_BL";