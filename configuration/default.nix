{lix, ...} @ base:
lix.importModules (base
  // {
    base = ./.;
    recurse = false;
    excludes = [
      "applications"
      "services"
      "secrets"
      "displays"
      "test"
    ];
  })
