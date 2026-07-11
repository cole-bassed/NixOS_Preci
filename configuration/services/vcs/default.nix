{
  lix,
  top,
  host,
  path,
  ...
} @ args: let
  inherit (lix.attrsets) attrByPath;
  inherit (lix.ingestion) importModules;
  inherit (lix.lists) elem;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) package;

  here = path;

  registry = {
    git.package = "gitFull";
    lfs.package = "git-lfs";
    gh.package = "gh";
    jj.package = "jujutsu";
    gitui.package = "gitui";
    delta.package = "delta";
  };

  mkArgs = {
    config,
    path,
    pkgs ? {},
    scope ? "core",
    user ? {},
  }: let
    module = mkModuleArgs {inherit config top scope path pkgs;};
    inherit (module) get set;
    inherit (get.names) name;

    domHost = attrByPath here {} host;
    domUser = attrByPath here {} user;
    modHost = attrByPath path {} host;
    modUser = attrByPath path {} user;
    modData = registry.${name} or {};
  in
    module
    // {
      options = {
        enable = set.enable {
          default =
            domUser.enable or (
              domHost.enable or (elem name (
                (host.applications or [])
                ++ (user.applications or [])
              ))
            );
        };
        package = let
          pkg =
            modUser.package or (
              modHost.package or (
                modData.package or name
              )
            );
        in
          mkOption {
            type = package;
            default = pkgs.${pkg} or null;
            description = "Package of '${pkg}' for ${scope}.";
          };
      };
    };

  inner = importModules (args
    // {
      base = ./.;
      declareRegistry = true;
      extraArgs = {inherit registry mkArgs;};
    });
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
