{
  lix,
  top,
  stagedServices,
  ...
}: let
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) anything attrsOf submodule;

  stagedAi = stagedServices.ai or {};
  staged = stagedAi.ollama or {};

  mk = scope: {config, ...}: let
    mod = mkModuleArgs {
      inherit config top scope;
      path = ["services"];
    };
    opt = mod.set.options.module;
  in {
    options = opt {
      ai.ollama = mkOption {
        type = submodule {
          freeformType = attrsOf anything;
          options.enable = mkEnable {
            name = "ollama";
            inherit scope;
            default = staged.enable or false;
          };
        };
        default = {};
      };
    };

    config = {};
  };
in {
  core = mk "core";
  home = mk "home";
}
