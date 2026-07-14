{lix, ...} @ args: let
  inherit (lix.modules) mkModules mkModuleArgs;
in
  mkModules (
    args
    // {
      base = ./.;
      excludes = [
        # "backend"
        "frontend"
        "protocol"
        "session"
      ];
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
              config
              options
              osConfig
              path
              pkgs
              scope
              ;
          };
      };
    }
  )
