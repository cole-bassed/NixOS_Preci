{lix, ...} @ base:
lix.importModules (base
  // {
    base = ./.;
    recurse = false;
    excludes = [
      "applications"
      "services"
      "displays"
      "test"
    ];
  })
