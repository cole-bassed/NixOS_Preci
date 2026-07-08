{
  lix,
  shared,
  ...
} @ args: let
  inherit (lix.ingestion) importModules;

  inner = importModules (args
    // {
      base = ./.;
      extraArgs = {inherit shared;};
    });
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
