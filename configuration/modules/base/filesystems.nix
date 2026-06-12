{
  lix,
  top,
  host,
  dom,
  mod,
  pkgs,
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
      udisks2 = mkOption {
        type = bool;
        default = true;
        description = "Enable udisks2 for removable media management.";
      };
      udevil = mkOption {
        type = bool;
        default = true;
        description = "Enable udevil for user-mountable devices.";
      };
    };

    config = mkIf enable (
      if scope == "core"
      then {
        environment.systemPackages = with pkgs; [
          eza
          lsd
        ];

        environment.shellAliases = {
          l = "lsd --git";
          ll = "l --long --almost-all";
          lt = "l --tree";
          lr = "l --recursive";
        };

        programs.udevil.enable = cfg.udevil;
        programs.yazi.enable = true;

        services.udisks2 = {
          enable = cfg.udisks2;
          mountOnMedia = true;
        };
      }
      else {
        programs.yazi.enable = true;
      }
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
