{
  lix,
  top,
  dom,
  mod,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) bool;

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;
  in {
    options = opt {
      enable = mkEnableMod.true;
      ssh = mkOption {
        type = bool;
        default = true;
        description = "Enable OpenSSH server.";
      };
      tailscale = mkOption {
        type = bool;
        default = true;
        description = "Enable Tailscale VPN.";
      };
    };

    config = mkIf enable (
      if scope == "core"
      then {
        services.openssh = mkIf cfg.ssh {
          enable = true;
          openFirewall = true;
        };

        services.tailscale = mkIf cfg.tailscale {
          enable = true;
          openFirewall = true;
        };
      }
      else {}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
