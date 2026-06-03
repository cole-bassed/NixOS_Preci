flake: let
  inherit (flake.libraries.modules) importModules;

  core =
    (flake.modules.core or [])
    ++ [
      (importModules {
        base = ./.;
        args = flake;
        excludes =
          flake.defaults.excludes
          ++ [
            "ai"
            "applications"
            "interface"
          ];
      })
    ];
in
  flake.libraries.mkConfigurations {
    class = "nixos";
    inherit flake;
    # flake = flake // {modules = flake.modules // {inherit core;};};
  }
