{
  lix,
  pkgs,
  ...
} @ args:
lix.importModules (args
  // {
    base = ./.;
    includeFiles = true;
  })
