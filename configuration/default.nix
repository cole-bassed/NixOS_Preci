{lix, ...} @ base:
lix.importModules (base
  // {
    base = ./.;
    recurse = false;
    excludes = [
      "libraries"
      "api"
      # "applications"
      "test"
    ];
  })
