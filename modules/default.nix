{
  lix,
  pkgs,
  ...
} @ args:
lix.importModules (args
  // {
    inherit pkgs;
    base = ./.;
    includeFiles = true;
  })
