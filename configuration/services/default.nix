{
  lix,
  host,
  ...
} @ args: let
  inherit (lix.ingestion) importModules;
  inherit (lix.attrsets) normalize;

  modules = {
    base = ./.;
    extraArgs.stagedServices = normalize (host.services or []);
  };

  inner = importModules (args // modules);
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
