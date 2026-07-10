{
  lix,
  top,
  dom,
  mod,
  ...
} @ args: let
  inherit (lix.ingestion) mkModules;
  inherit (lix.options) mkEnable mkModuleArgs;

  getPackages = pkgs:
    with pkgs; {
      inherit delta gitui gh jujutsu;
      lfs = git-lfs;
      git = gitFull;
    };

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
      declareRegistry = false;
      extraArgs = {inherit getPackages mkArgs;};
    });
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
