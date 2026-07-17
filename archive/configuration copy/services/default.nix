{
  lix,
  host,
  ...
} @ args: let
  inherit (lix.modules) mkModules;
  inherit (lix.attrsets) normalize;

  inner = mkModules (args
    // {
      base = ./.;
      extraArgs.shared = normalize (host.services or {});
    });
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
