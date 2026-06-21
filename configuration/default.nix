{lix, ...} @ base:
lix.ingestion.importModules base {
  base = ./.;
  excludes = [
    "ai"
    "api"
    "applications"
    "interface"
    "secrets"
  ];
}
