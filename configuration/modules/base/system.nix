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
  inherit (lix.types) str;

  mk = scope: {config, ...}: let
    _ = mkModuleArgs {inherit config top dom mod scope;};
    inherit (_) cfg opt mkEnableMod;
    inherit (cfg) enable;
  in {
    options = opt {
      enable = mkEnableMod.true;
      stateVersion = mkOption {
        type = str;
        default = host.stateVersion or "25.11";
        description = "The NixOS state version for this host.";
      };
      hostName = mkOption {
        type = str;
        default = host.name or "nixos";
        description = "The hostname for this host.";
      };
      platform = mkOption {
        type = str;
        default = host.system or "x86_64-linux";
        description = "The host platform string.";
      };
    };

    config = mkIf enable (
      if scope == "core"
      then {
        system.stateVersion = mkDefault cfg.stateVersion;
        networking.hostName = mkDefault cfg.hostName;
        nixpkgs.hostPlatform = mkDefault cfg.platform;
      }
      else {}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
