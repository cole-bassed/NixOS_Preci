{lix, ...} @ base:
lix.importModules (base
  // {
    base = ./.;
    recurse = false;
    excludes = [
      "ai"
      "api"
      "applications"
      "test"
      # "secrets"
    ];
  })
