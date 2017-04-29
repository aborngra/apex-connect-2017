
  CREATE OR REPLACE FORCE EDITIONABLE VIEW "WORKSPACES_RELATIONS_V" ("WORKSPACE", "WORKSPACE_ID", "PARENT_WORKSPACE", "PARENT_WORKSPACE_ID") AS 
  WITH workspaces
        AS (SELECT aw1.workspace
                 , aw1.workspace_id
                 , aw1.parent_workspace
                 , aw2.workspace_id AS parent_workspace_id
              FROM all_workspaces aw1
                   LEFT JOIN all_workspaces aw2
                      ON aw1.parent_workspace = aw2.workspace)
      , parents
        AS (SELECT all_mp_parent_workspaces.mp_leaf_workspace AS workspace
                 , all_mp_parent_workspaces.parent_workspace
                 , all_workspaces.workspace_id AS parent_workspace_id
              FROM all_mp_parent_workspaces
                   JOIN all_workspaces
                      ON all_mp_parent_workspaces.parent_workspace =
                            all_workspaces.workspace)
   SELECT workspaces.workspace
        , workspaces.workspace_id
        , COALESCE(parents.parent_workspace, workspaces.parent_workspace)
             AS parent_workspace
        , COALESCE(parents.parent_workspace_id, workspaces.parent_workspace_id)
             AS parent_workspace_id
     FROM workspaces
          LEFT JOIN parents ON workspaces.workspace = parents.workspace