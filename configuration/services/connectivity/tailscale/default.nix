{
  lix,
  top,
  stagedServices,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) anything attrsOf bool submodule;

  staged = stagedServices.tailscale or {};

  mk = scope: {config, ...}: let
    mod = mkModuleArgs {
      inherit config top scope;
      path = ["services"];
    };
    opt = mod.set.options.module;
    cfg = config.${top}.services.tailscale;
  in {
    options = opt {
      tailscale = mkOption {
        type = submodule {
          freeformType = attrsOf anything;
          options = {
            enable = mkEnable {
              name = "tailscale";
              inherit scope;
              default = staged.enable or false;
            };
            openFirewall = mkOption {
              type = bool;
              default = staged.openFirewall or true;
              description = "Open the firewall for Tailscale-managed traffic.";
            };
          };
        };
        default = staged;
        description = "Staged Tailscale service configuration under dots.services before native wiring.";
      };
    };

    config =
      if scope == "core"
      then
        mkIf cfg.enable {
          services.tailscale = {
            enable = true;
            openFirewall = cfg.openFirewall;
          };
        }
      else {};
  };
in {
  core = mk "core";
  home = mk "home";
}
