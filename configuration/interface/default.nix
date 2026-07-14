{
  api,
  lix,
  top,
  ...
} @ args: let
  inherit (args) path;
  inherit (lix.modules) mkModules mkModuleArgs;
in
  mkModules (
    args
    // {
      inherit path;
      base = ./.;
      excludes = ["session" "frontend" "protocol"];
      recurse = true;
      extraArgs = {
        mkArgs = {
          config,
          osConfig ? {},
          options ? {},
          path,
          scope ? "core",
          pkgs ? {},
        }:
          mkModuleArgs {
            inherit
              api
              config
              options
              osConfig
              path
              pkgs
              scope
              top
              ;
          };
      };
    }
  )
