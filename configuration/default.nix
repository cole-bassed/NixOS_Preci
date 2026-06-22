{lix, ...} @ base:
lix.importModules (base
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
