CREATE OR REPLACE EDITIONABLE PACKAGE "SVN_BL"
IS
   PROCEDURE create_svn_objects;

   PROCEDURE download_svn_sequences;

   PROCEDURE download_svn_tables;

   PROCEDURE download_svn_indexes;

   PROCEDURE download_svn_synonyms;

   PROCEDURE download_svn_packages_api;

   PROCEDURE download_svn_packages_bl;

   PROCEDURE download_svn_functions;

   PROCEDURE download_svn_procedures;

   PROCEDURE download_svn_triggers;

   PROCEDURE download_svn_types;

   PROCEDURE download_svn_views;

   FUNCTION get_svn_last_created_at(
      p_svn_schema  tools.ctlg_svn_objects.svn_schema%TYPE)
      RETURN tools.ctlg_svn_objects.svn_created_at%TYPE;
END "SVN_BL";