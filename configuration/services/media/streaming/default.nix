{
  lix,
  top,
  stagedServices,
  ...
}: let
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) anything attrsOf nullOr str submodule;

  staged = stagedServices.streaming or {};
  stagedIngress = staged.ingress or {};

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
          options = {
            enable = mkEnable {
              name = "streaming";
              inherit scope;
              default = staged.enable or false;
            };
            provider = mkOption {
              type = nullOr str;
              default = staged.provider or null;
              description = "Primary staged streaming stack/provider name for this host.";
            };
            endpoint = mkOption {
              type = nullOr str;
              default = staged.endpoint or null;
              description = "Primary external endpoint or URL for the staged streaming service.";
            };
            ingress = mkOption {
              type = submodule {
                freeformType = attrsOf anything;
                options = {
                  domain = mkOption {
                    type = nullOr str;
                    default = stagedIngress.domain or null;
                    description = "Canonical domain intended to front the streaming service.";
                  };
                  proxy = mkOption {
                    type = nullOr str;
                    default = stagedIngress.proxy or null;
                    description = "Reverse proxy or ingress implementation expected to expose the streaming stack.";
                  };
                };
              };
              default = stagedIngress;
              description = "Staged ingress metadata for future streaming native wiring.";
            };
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
