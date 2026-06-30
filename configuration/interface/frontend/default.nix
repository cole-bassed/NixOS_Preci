{lix, ...} @ args: let
  inherit (lix.ingestion) importModules;
  inherit (lix.flake) registry;
  inherit (lix.systems) systemOf;
in
  importModules (args
    // {
      base = ./.;
      extraArgs = {
        packages = pkgs: pkgs // (registry.aggregated.packages.${systemOf pkgs} or {});
      };
    })
