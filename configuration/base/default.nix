{lix, ...} @ base: let
  inherit (lix.modules) importModules;
in
  importModules (base
    // {
      base = ./.;
      excludes = [
        "review"
      ];
    })
