CREATE OR REPLACE EDITIONABLE PACKAGE "WORKSPACE_MANAGER_BL"
IS
   gc_ws_live       CONSTANT VARCHAR2(8 CHAR) := 'LIVE';
   gc_ws_live_color CONSTANT VARCHAR2(8 CHAR) := 'red';

   PROCEDURE ws_create(p_ws_app_user IN meta_workspaces.ws_app_user%TYPE
                     , p_ws_name     IN meta_workspaces.ws_name%TYPE
                     , p_ws_color    IN meta_workspaces.ws_color%TYPE
                     , p_ws_app_id   IN meta_workspaces.ws_app_id%TYPE);

   FUNCTION ws_of_user(p_ws_app_user IN meta_workspaces_user.wsu_app_user%TYPE
                     , p_ws_app_id   IN meta_workspaces_user.wsu_app_id%TYPE)
      RETURN meta_workspaces_user.wsu_name%TYPE;

   PROCEDURE ws_remove(p_ws_name   IN meta_workspaces.ws_name%TYPE
                     , p_ws_app_id IN meta_workspaces.ws_app_id%TYPE);

   PROCEDURE ws_remove_all(p_ws_app_id IN meta_workspaces.ws_app_id%TYPE);

   PROCEDURE ws_goto(p_ws_app_user IN meta_workspaces.ws_app_user%TYPE
                   , p_ws_name     IN meta_workspaces.ws_name%TYPE
                   , p_ws_app_id   IN meta_workspaces.ws_app_id%TYPE);
END "WORKSPACE_MANAGER_BL";
/