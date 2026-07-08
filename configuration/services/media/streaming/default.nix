{
  lix,
  top,
  stagedServices,
  ...
}: let
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) anything attrsOf submodule;

  staged = stagedServices.streaming or {};

  mk = scope: {config, ...}: let
    mod = mkModuleArgs {
      inherit config top scope;
      path = ["services"];
    };
    opt = mod.set.options.module;
  in {
    options = opt {
      streaming = mkOption {
        type = submodule {
          freeformType = attrsOf anything;
          options.enable = mkEnable {
            name = "streaming";
            inherit scope;
            default = staged.enable or false;
          };
        };
        default = staged;
        description = "Staged streaming service configuration under dots.services before native wiring.";
      };
    };

    config = {};
  };
in {
  core = mk "core";
  home = mk "home";
}
