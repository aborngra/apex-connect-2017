--------------------------------------------------------------------------------
-- SPECIFICATION
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE svn
   AUTHID CURRENT_USER
IS
   -----------------------------------------------------------------------------
   -- specification of public procedures / functions
   -----------------------------------------------------------------------------
   PROCEDURE create_svn_objects (
      p_user   IN user_users.username%TYPE DEFAULT USER);
END svn;
/