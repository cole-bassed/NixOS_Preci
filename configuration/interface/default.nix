{lix, ...} @ args: let
  inherit (lix.modules) mkModules mkModuleArgs;
  moduleArgs = {
    inherit extraArgs;
    base = ./.;
    excludes = [
      "backend"
      "frontend"
      "protocol"
      "session"
    ];
  };
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
in
  mkModules (args // moduleArgs)
