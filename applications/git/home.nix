{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool;

  dom = "applications";
  mod = "git";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "Git profile";

    delta.enable = mkOption {
      type = bool;
      default = true;
      description = "Whether to enable Delta as the default Git diff viewer.";
    };

    gitui.enable = mkOption {
      type = bool;
      default = true;
      description = "Whether to install and enable GitUI.";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      git = {
        enable = mkDefault true;

        lfs = {
          enable = mkDefault true;
        };

        settings = {
          init = {
            defaultBranch = mkDefault "main";
          };

          pull = {
            rebase = mkDefault true;
          };

          rebase = {
            autoStash = mkDefault true;
          };

          push = {
            autoSetupRemote = mkDefault true;
          };

          core = {
            editor = mkDefault "hx";
          };

          merge = {
            conflictStyle = mkDefault "zdiff3";
          };
        };
      };

      delta = mkIf cfg.delta.enable {
        enable = mkDefault true;
        enableGitIntegration = mkDefault true;

        options = {
          navigate = mkDefault true;
          side-by-side = mkDefault true;
        };
      };

      gitui = mkIf cfg.gitui.enable {
        enable = mkDefault true;
      };
    };
  };
}
