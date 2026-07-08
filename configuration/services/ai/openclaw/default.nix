{
  lix,
  top,
  shared,
  ...
}: let
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) anything attrsOf submodule;

  name = "openclaw";
  staged = shared.ai.${name} or {};

  mk = scope: {config, ...}: let
    mod = mkModuleArgs {
      inherit config top scope;
      path = ["services"];
    };
    opt = mod.set.options.module;
  in {
    options = opt {
      ai.${name} = mkOption {
        type = submodule {
          freeformType = attrsOf anything;
          options.enable = mkEnable {
            inherit name scope;
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
