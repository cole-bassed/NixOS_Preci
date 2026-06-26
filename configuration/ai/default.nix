{
  lix,
  inputs,
  ...
} @ args:
lix.importModules (args
  // {
    inherit inputs;
    base = ./.;
    includeFiles = true;
  })
