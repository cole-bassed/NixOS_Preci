{
  top,
  lix,
  pkgs ? null,
  dom,
  mod,
  ...
} @ args: let
  inherit (lix.ingestion) mkModules;
  inherit (lix.options) mkEnable mkModuleArgs;

  packages =
    if pkgs == null
    then {}
    else {
      inherit (pkgs) firefoxpwa;
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
      // {
        __functor = _self: overrides: mkEnable ({inherit scope;} // overrides);
      };
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
      extraArgs = {inherit packages mkArgs;};
    });
in {
  core = [];
  home = inner.home-manager.sharedModules or [];
}
