CREATE OR REPLACE EDITIONABLE PACKAGE BODY "WORKSPACE_MANAGER_BL"
IS
   FUNCTION ws_of_user(p_ws_app_user IN meta_workspaces_user.wsu_app_user%TYPE
                     , p_ws_app_id   IN meta_workspaces_user.wsu_app_id%TYPE)
      RETURN meta_workspaces_user.wsu_name%TYPE
   IS
      v_ret    meta_workspaces_user.wsu_name%TYPE;
      v_wsu_id meta_workspaces_user.wsu_id%TYPE;
   BEGIN
      --------------------------------------------------------------------------
      -- check params
      --------------------------------------------------------------------------
      IF (p_ws_app_user IS NOT NULL AND p_ws_app_id IS NOT NULL)
      THEN
         -----------------------------------------------------------------------
         -- find out current workspace of the user
         -----------------------------------------------------------------------
         v_wsu_id      :=
            meta_workspaces_user_api.get_pk_by_unique_cols(
               p_wsu_app_user => p_ws_app_user
             , p_wsu_app_id   => p_ws_app_id);

         -----------------------------------------------------------------------
         -- and return the name
         -----------------------------------------------------------------------
         v_ret := meta_workspaces_user_api.get_name(p_wsu_id => v_wsu_id);
      END IF;

      --------------------------------------------------------------------------
      -- always return a workspace
      --------------------------------------------------------------------------
      RETURN COALESCE(v_ret, gc_ws_live);
   END ws_of_user;

   PROCEDURE ws_create(
      p_ws_app_user IN meta_workspaces.ws_app_user%TYPE
    , p_ws_name     IN meta_workspaces.ws_name%TYPE
    , p_ws_color    IN meta_workspaces.ws_color%TYPE
    , p_ws_app_id   IN meta_workspaces.ws_app_id%TYPE
    , p_ws_refresh  IN all_workspaces.continually_refreshed%TYPE DEFAULT 'N')
   IS
      v_ws_id wmsys.all_workspaces.workspace_id%TYPE;
   BEGIN
      --------------------------------------------------------------------------
      -- check params
      --------------------------------------------------------------------------
      IF (p_ws_app_user IS NOT NULL
      AND p_ws_name IS NOT NULL
      AND p_ws_app_id IS NOT NULL
      AND p_ws_refresh IN ('Y'
                         , 'N'
                         , 'YES'
                         , 'NO'))
      THEN
         -----------------------------------------------------------------------
         -- create workspace manager workspace
         -----------------------------------------------------------------------
         DBMS_WM.createworkspace(
            workspace   => p_ws_name
          , isrefreshed => CASE
                             WHEN p_ws_refresh IN ('Y', 'YES') THEN TRUE
                             ELSE FALSE
                          END);

         -----------------------------------------------------------------------
         -- read workspace_id for metadata record
         -----------------------------------------------------------------------
         SELECT workspace_id
           INTO v_ws_id
           FROM all_workspaces
          WHERE all_workspaces.workspace = p_ws_name;

         -----------------------------------------------------------------------
         -- create additional record in own metadata table for
         -- better workspace handling
         -----------------------------------------------------------------------
         meta_workspaces_api.create_row(p_ws_id       => v_ws_id
                                      , p_ws_app_user => p_ws_app_user
                                      , p_ws_name     => p_ws_name
                                      , p_ws_color    => p_ws_color
                                      , p_ws_app_id   => p_ws_app_id);
      END IF;
   END ws_create;

   PROCEDURE ws_remove(p_ws_name   IN meta_workspaces.ws_name%TYPE
                     , p_ws_app_id IN meta_workspaces.ws_app_id%TYPE)
   IS
      v_ws_id wmsys.all_workspaces.workspace_id%TYPE;
   BEGIN
      --------------------------------------------------------------------------
      -- check params
      --------------------------------------------------------------------------
      IF (p_ws_name IS NOT NULL
      AND p_ws_app_id IS NOT NULL
      AND p_ws_name <> gc_ws_live)
      THEN
         -----------------------------------------------------------------------
         -- remove workspace manager workspace, but ensures that no workspaces
         -- from other applications are removed and no LIVE workspace is removed
         -----------------------------------------------------------------------
         FOR i
            IN (SELECT *
                  FROM all_workspaces ws
                       JOIN meta_workspaces meta
                          ON ws.workspace_id = meta.ws_id
                 WHERE owner IN (USER, 'APEX_PUBLIC_USER')
                   AND ws_app_id = p_ws_app_id
                   AND ws_name = p_ws_name)
         LOOP
            DBMS_WM.removeworkspace(workspace => i.workspace);
         END LOOP;

         -----------------------------------------------------------------------
         -- remove record from own metadata table for workspaces
         -----------------------------------------------------------------------
         v_ws_id      :=
            meta_workspaces_api.get_pk_by_unique_cols(p_ws_name => p_ws_name);

         meta_workspaces_api.delete_row(p_ws_id => v_ws_id);

         -----------------------------------------------------------------------
         -- remove record from own metadata table for current workspaces of user
         -- API call not possible here, because many users can have same
         -- workspace as current workspace
         -----------------------------------------------------------------------
         DELETE FROM meta_workspaces_user
               WHERE wsu_name = p_ws_name;
      END IF;
   END ws_remove;

   PROCEDURE ws_remove_all(p_ws_app_id IN meta_workspaces.ws_app_id%TYPE)
   IS
   BEGIN
      --------------------------------------------------------------------------
      -- check params
      --------------------------------------------------------------------------
      IF (p_ws_app_id IS NOT NULL)
      THEN
         -----------------------------------------------------------------------
         -- ensures that no workspaces from other applications are removed and
         -- no LIVE workspace is removed (LIVE workspace has always empty
         -- ws_app_id)
         -----------------------------------------------------------------------
         FOR i
            IN (SELECT *
                  FROM all_workspaces ws
                       JOIN meta_workspaces meta
                          ON ws.workspace_id = meta.ws_id
                 WHERE owner IN (USER, 'APEX_PUBLIC_USER')
                   AND ws_app_id = p_ws_app_id)
         LOOP
            ws_remove(p_ws_name => i.workspace, p_ws_app_id => p_ws_app_id);
         END LOOP;
      END IF;
   END ws_remove_all;

   PROCEDURE ws_goto(p_ws_app_user IN meta_workspaces.ws_app_user%TYPE
                   , p_ws_name     IN meta_workspaces.ws_name%TYPE
                   , p_ws_app_id   IN meta_workspaces.ws_app_id%TYPE)
   IS
      v_wsu_id meta_workspaces_user.wsu_id%TYPE;
      v_ws_id  meta_workspaces.ws_id%TYPE;
   BEGIN
      --------------------------------------------------------------------------
      -- check params
      --------------------------------------------------------------------------
      IF (p_ws_app_user IS NOT NULL
      AND p_ws_name IS NOT NULL
      AND p_ws_app_id IS NOT NULL)
      THEN
         -----------------------------------------------------------------------
         -- ensures that no workspaces from other applications can be accessed
         -----------------------------------------------------------------------
         FOR i
            IN (SELECT *
                  FROM all_workspaces ws
                       JOIN meta_workspaces meta
                          ON ws.workspace_id = meta.ws_id
                 WHERE owner IN (USER, 'APEX_PUBLIC_USER')
                   AND ws_app_id = p_ws_app_id)
         LOOP
            DBMS_WM.gotoworkspace(workspace => p_ws_name);
         END LOOP;

         -----------------------------------------------------------------------
         -- create or update metadata entry for the current workspace of user
         -----------------------------------------------------------------------
         v_wsu_id      :=
            meta_workspaces_user_api.get_pk_by_unique_cols(
               p_wsu_app_user => p_ws_app_user
             , p_wsu_app_id   => p_ws_app_id);

         v_wsu_id      :=
            meta_workspaces_user_api.create_or_update_row(
               p_wsu_id       => v_wsu_id
             , p_wsu_app_user => p_ws_app_user
             , p_wsu_app_id   => p_ws_app_id
             , p_wsu_name     => p_ws_name);

         -----------------------------------------------------------------------
         -- set session state for application item: current workspace
         -----------------------------------------------------------------------
         APEX_UTIL.set_session_state(p_name  => 'AI_CURRENT_WM_WORKSPACE'
                                   , p_value => p_ws_name);

         -----------------------------------------------------------------------
         -- set session state for application item: current workspace color
         -----------------------------------------------------------------------
         v_ws_id      :=
            meta_workspaces_api.get_pk_by_unique_cols(p_ws_name => p_ws_name);

         APEX_UTIL.set_session_state(
            p_name  => 'AI_CURRENT_WM_WORKSPACE_COLOR'
          , p_value => CASE
                         WHEN p_ws_name = gc_ws_live THEN gc_ws_live_color
                         ELSE meta_workspaces_api.get_color(p_ws_id => v_ws_id)
                      END);
      END IF;
   END ws_goto;

   FUNCTION ws_get_parent(p_ws_name IN all_workspaces.workspace%TYPE)
      RETURN all_workspaces.parent_workspace%TYPE
   IS
      v_ret all_workspaces.parent_workspace%TYPE;

      CURSOR v_cur_parent
      IS
         SELECT parent_workspace
           FROM all_workspaces
          WHERE workspace = p_ws_name;
   BEGIN
      --------------------------------------------------------------------------
      -- check params
      --------------------------------------------------------------------------
      IF (p_ws_name IS NOT NULL)
      THEN
         IF (p_ws_name = 'LIVE')
         THEN
            v_ret := p_ws_name;
         ELSE
            --------------------------------------------------------------------
            -- find out parent
            --------------------------------------------------------------------
            OPEN v_cur_parent;

            FETCH v_cur_parent INTO v_ret;

            CLOSE v_cur_parent;
         END IF;
      END IF;

      RETURN v_ret;
   END ws_get_parent;

   PROCEDURE sp_rollbackto(
      p_ws_name IN all_workspace_savepoints.workspace%TYPE
    , p_sp_name IN all_workspace_savepoints.savepoint%TYPE)
   IS
      v_position all_workspace_savepoints.position%TYPE;

      CURSOR v_cur_position
      IS
         SELECT position
           FROM all_workspace_savepoints
          WHERE workspace = p_ws_name AND savepoint = p_sp_name;
   BEGIN
      --------------------------------------------------------------------------
      -- check params
      --------------------------------------------------------------------------
      IF (p_ws_name IS NOT NULL AND p_sp_name IS NOT NULL)
      THEN
         -----------------------------------------------------------------------
         -- find out position to delete overhead savepoints
         -----------------------------------------------------------------------
         OPEN v_cur_position;

         FETCH v_cur_position INTO v_position;

         CLOSE v_cur_position;

         -----------------------------------------------------------------------
         -- rollback to savepoint, that makes SP with higher position redundant
         -----------------------------------------------------------------------
         DBMS_WM.rollbacktosp(workspace      => p_ws_name
                            , savepoint_name => p_sp_name);

         -----------------------------------------------------------------------
         -- delete savepoints that are redundant
         -----------------------------------------------------------------------
         FOR i IN (SELECT *
                     FROM all_workspace_savepoints
                    WHERE workspace = p_ws_name AND position > v_position)
         LOOP
            DBMS_WM.deletesavepoint(workspace      => p_ws_name
                                  , savepoint_name => i.savepoint);
         END LOOP;
      END IF;
   END sp_rollbackto;
END "WORKSPACE_MANAGER_BL";
/