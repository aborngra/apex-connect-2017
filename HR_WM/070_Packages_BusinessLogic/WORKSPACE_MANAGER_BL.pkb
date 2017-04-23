CREATE OR REPLACE EDITIONABLE PACKAGE BODY "WORKSPACE_MANAGER_BL"
IS
   PROCEDURE ws_after_login(p_ws_app_user IN meta_workspaces.ws_app_user%TYPE
                          , p_ws_app_id   IN meta_workspaces.ws_app_id%TYPE)
   IS
   BEGIN
      NULL;
   END ws_after_login;

   PROCEDURE ws_create(
      p_ws_app_user_session IN meta_workspaces.ws_app_user_session%TYPE
    , p_ws_app_user         IN meta_workspaces.ws_app_user%TYPE
    , p_ws_name             IN meta_workspaces.ws_name%TYPE
    , p_ws_color            IN meta_workspaces.ws_color%TYPE
    , p_ws_app_id           IN meta_workspaces.ws_app_id%TYPE)
   IS
      v_ws_id wmsys.all_workspaces.workspace_id%TYPE;
   BEGIN
      --------------------------------------------------------------------------
      -- check params
      --------------------------------------------------------------------------
      IF (p_ws_app_user_session IS NOT NULL
      AND p_ws_app_user IS NOT NULL
      AND p_ws_name IS NOT NULL
      AND p_ws_app_id IS NOT NULL)
      THEN
         -----------------------------------------------------------------------
         -- create workspace manager workspace
         -----------------------------------------------------------------------
         DBMS_WM.createworkspace(workspace => p_ws_name);

         -----------------------------------------------------------------------
         -- read workspace_id for metadata record
         -----------------------------------------------------------------------
         SELECT workspace_id
           INTO v_ws_id
           FROM all_workspaces
          WHERE all_workspaces.workspace = p_ws_name;

         -----------------------------------------------------------------------
         -- create additional record in own metadata table for
         -- better ws handling
         -----------------------------------------------------------------------
         meta_workspaces_api.create_row(
            p_ws_id               => v_ws_id
          , p_ws_app_user_session => p_ws_app_user_session
          , p_ws_app_user         => p_ws_app_user
          , p_ws_name             => p_ws_name
          , p_ws_color            => p_ws_color
          , p_ws_app_id           => p_ws_app_id);
      END IF;
   END ws_create;

   PROCEDURE ws_delete(p_ws_name   IN meta_workspaces.ws_name%TYPE
                     , p_ws_app_id IN meta_workspaces.ws_app_id%TYPE)
   IS
      v_ws_id wmsys.all_workspaces.workspace_id%TYPE;
   BEGIN
      --------------------------------------------------------------------------
      -- check params
      --------------------------------------------------------------------------
      IF (p_ws_name IS NOT NULL AND p_ws_app_id IS NOT NULL)
      THEN
         -----------------------------------------------------------------------
         -- remove workspace manager workspace, but ensures that no workspaces
         -- from other applications are removed and no LIVE workspace is removed
         -- (LIVE workspace has always empty ws_app_id)
         -----------------------------------------------------------------------
         FOR i
            IN (SELECT *
                  FROM all_workspaces ws
                       LEFT OUTER JOIN meta_workspaces meta
                          ON ws.workspace_id = meta.ws_id
                 WHERE owner IN (USER, 'APEX_PUBLIC_USER')
                   AND ws_app_id = p_ws_app_id
                   AND ws_name = p_ws_name)
         LOOP
            DBMS_WM.removeworkspace(workspace => i.workspace);
         END LOOP;

         -----------------------------------------------------------------------
         -- remove record from own metadata table
         -----------------------------------------------------------------------
         v_ws_id      :=
            meta_workspaces_api.get_pk_by_unique_cols(p_ws_name => p_ws_name);

         meta_workspaces_api.delete_row(p_ws_id => v_ws_id);
      END IF;
   END ws_delete;

   PROCEDURE ws_delete_all(p_ws_app_id IN meta_workspaces.ws_app_id%TYPE)
   IS
   BEGIN
      --------------------------------------------------------------------------
      -- check params
      --------------------------------------------------------------------------
      IF (p_ws_app_id IS NOT NULL)
      THEN
         -----------------------------------------------------------------------
         -- ensures that no workspaces from other applications are removed and
         -- no LIVE workspace is removed (LIVE workspace has always
         -- empty ws_app_id)
         -----------------------------------------------------------------------
         FOR i
            IN (SELECT *
                  FROM all_workspaces ws
                       LEFT OUTER JOIN meta_workspaces meta
                          ON ws.workspace_id = meta.ws_id
                 WHERE owner IN (USER, 'APEX_PUBLIC_USER')
                   AND ws_app_id = p_ws_app_id)
         LOOP
            ws_delete(p_ws_name => i.workspace, p_ws_app_id => p_ws_app_id);
         END LOOP;
      END IF;
   END ws_delete_all;
END "WORKSPACE_MANAGER_BL";
/