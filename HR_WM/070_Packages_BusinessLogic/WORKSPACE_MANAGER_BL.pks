CREATE OR REPLACE EDITIONABLE PACKAGE "WORKSPACE_MANAGER_BL"
IS
   PROCEDURE ws_create(
      p_ws_app_user_session IN meta_workspaces.ws_app_user_session%TYPE
    , p_ws_app_user         IN meta_workspaces.ws_app_user%TYPE
    , p_ws_name             IN meta_workspaces.ws_name%TYPE
    , p_ws_color            IN meta_workspaces.ws_color%TYPE
    , p_ws_app_id           IN meta_workspaces.ws_app_id%TYPE);

   PROCEDURE ws_after_login(p_ws_app_user IN meta_workspaces.ws_app_user%TYPE
                          , p_ws_app_id   IN meta_workspaces.ws_app_id%TYPE);

   PROCEDURE ws_delete(p_ws_name   IN meta_workspaces.ws_name%TYPE
                     , p_ws_app_id IN meta_workspaces.ws_app_id%TYPE);

   PROCEDURE ws_delete_all(p_ws_app_id IN meta_workspaces.ws_app_id%TYPE);
END "WORKSPACE_MANAGER_BL";
/