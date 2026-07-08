{
  lix,
  host,
  ...
} @ args: let
  inherit (lix.ingestion) importModules;
  inherit (lix.attrsets) normalize;

  inner = importModules (args
    // {
      base = ./.;
      extraArgs.shared = normalize (host.services or {});
    });
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
