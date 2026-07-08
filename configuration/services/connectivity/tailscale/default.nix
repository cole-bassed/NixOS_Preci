{
  lix,
  top,
  stagedServices,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) anything attrsOf bool listOf nullOr str submodule;

  staged = stagedServices.tailscale or {};
  stagedSecret = staged.authKeySecret or {};
  stagedNetwork = staged.network or {};

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
            authKeySecret = mkOption {
              type = submodule {
                freeformType = attrsOf anything;
                options = {
                  enable = mkEnable {
                    name = "tailscale auth key secret";
                    inherit scope;
                    default = stagedSecret.enable or false;
                  };
                  name = mkOption {
                    type = str;
                    default = stagedSecret.name or "services/tailscale/authKey";
                    description = "Logical sops secret name that stores the Tailscale auth key for this host.";
                  };
                  path = mkOption {
                    type = nullOr str;
                    default = null;
                    description = "Resolved filesystem path for the decrypted Tailscale auth key, materialized by the secrets layer.";
                  };
                };
              };
              default = stagedSecret;
              description = "Staged sops-backed auth key metadata for Tailscale before native secrets wiring.";
            };
            network = mkOption {
              type = submodule {
                freeformType = attrsOf anything;
                options = {
                  exitNode = mkOption {
                    type = nullOr str;
                    default = stagedNetwork.exitNode or null;
                    description = "Preferred exit node IP or stable name, staged under dots.services before any tailscale up automation consumes it.";
                  };
                  acceptRoutes = mkOption {
                    type = bool;
                    default = stagedNetwork.acceptRoutes or false;
                    description = "Whether this host should accept routes advertised by other Tailscale nodes.";
                  };
                  extraUpFlags = mkOption {
                    type = listOf str;
                    default = stagedNetwork.extraUpFlags or [];
                    description = "Additional `tailscale up` flags kept in staging for future activation or provisioning workflows.";
                  };
                };
              };
              default = stagedNetwork;
              description = "Staged network intent for Tailscale that may later feed activation or bootstrap tooling.";
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
