{lix, ...} @ base:
lix.modules.ingest (base
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
