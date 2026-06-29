{
  lib,
  mod,
  packages,
  mkArgs,
  ...
}: let
  name = mod;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) package;
in {
  core = {config, ...}: let
    scope = "core";
    inherit (mkArgs {inherit config scope;}) cfg opt mkEnableMod;
  in {
    options = opt {
      enable = mkEnableMod.false;
      package = mkOption {
        type = package;
        default = packages.${name};
        description = "Package of '${name}' to install system-wide.";
      };
    };
    config = mkIf cfg.enable {
      environment.systemPackages = [cfg.package];
    };
  };

  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config scope;}) cfg opt mkEnableMod;
  in {
    options = opt {
      enable = mkEnableMod.false;
      package = mkOption {
        type = package;
        default = packages.${name};
        description = "Package of '${name}' to enable for the user.";
      };
    };
    config = mkIf cfg.enable {
      programs.${name} = {
        enable = mkDefault true;
        package = mkDefault packages.${name};
        settings = {
          init.defaultBranch = mkDefault "main";
          pull.rebase = mkDefault true;
          rebase.autoStash = mkDefault true;
          push.autoSetupRemote = mkDefault true;
          core.editor = mkDefault "hx";
          merge.conflictStyle = mkDefault "zdiff3";
        };
      };
    };
  };
}
