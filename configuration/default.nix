{lix, ...} @ base: let
  inherit (lix.ingestion) importModules;
in
  importModules (base
    // {
      base = ./.;
      excludes = [
        "ai"
        "api"
        "applications"
        "interface"
        "secrets"
      ];
    })
