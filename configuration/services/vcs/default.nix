{
  lix,
  top,
  dom,
  mod,
  ...
} @ args: let
  inherit (lix.ingestion) mkModules;
  inherit (lix.options) mkEnable mkModuleArgs;

  registry = {
    git = {package = "gitFull";};
    lfs = {package = "git-lfs";};
    gh = {package = "gh";};
    jj = {package = "jujutsu";};
    gitui = {package = "gitui";};
    delta = {package = "delta";};
  };

  getPkg = {
    name,
    pkgs,
  }:
    pkgs.${name};

  mkArgs = {
    config,
    scope,
  }: let
    module = mkModuleArgs {inherit config top dom mod scope;};
    mkEnableMod =
      (mkEnable {
        name = mod;
        inherit scope;
      })
      // {__functor = self: overrides: mkEnable ({inherit scope;} // overrides);};
  in
    module
    // {
      cfg = module.get.config.module;
      opt = module.set.options.module;
      inherit mkEnableMod;
    };

  inner = mkModules (args
    // {
      base = ./.;
      declareRegistry = true;
      extraArgs = {inherit registry getPkg mkArgs;};
    });
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
