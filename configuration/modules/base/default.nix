{
  lix,
  top,
  host,
  ...
} @ args:
lix.importModules (args
  // {
    base = ./.;
    includeFiles = true;
  })
