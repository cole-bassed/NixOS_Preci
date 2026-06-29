{lix, ...} @ base:
lix.importModules (base
  // {
    base = ./.;
    recurse = false;
    excludes = [
      "libraries"
      "ai"
      "api"
      "applications"
      "test"
      # "secrets"
    ];
  })
