# configuration/modules/base/identity.nix
{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.modules) mkIf mkDefault;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) nullOr str;

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;
  in {
    options = opt {
      enable = mkEnableMod.true;
      name = mkOption {
        type = str;
        default = host.name or "nixos";
        description = "The hostname for this host.";
      };
      id = mkOption {
        type = nullOr str;
        default = host.id or null;
        description = "A short unique identifier for this host.";
      };
      description = mkOption {
        type = nullOr str;
        default = host.description or null;
        description = "A human-readable description of this host.";
      };
      type = mkOption {
        type = nullOr str;
        default = host.type or null;
        description = "Form factor of this host (laptop, desktop, server, etc.).";
      };
      class = mkOption {
        type = str;
        default = host.class or "nixos";
        description = "OS class for this host (nixos or darwin).";
      };
      platform = mkOption {
        type = str;
        default = host.system or "x86_64-linux";
        description = "The host platform string.";
      };
      stateVersion = mkOption {
        type = str;
        default = host.stateVersion or "25.11";
        description = "The NixOS state version for this host.";
      };
    };

    config = mkIf enable (
      if scope == "core"
      then {
        networking.hostName = mkDefault cfg.name;
        system.stateVersion = mkDefault cfg.stateVersion;
        nixpkgs.hostPlatform = mkDefault cfg.platform;
      }
      else {}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
