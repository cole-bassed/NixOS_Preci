{lix, ...} @ base: let
  inherit (lix.config) importModules;
in
  importModules (base
    // {
      base = ./.;
      excludes = [
        "ai"
        "applications"
        "interface"
      ];
    })
