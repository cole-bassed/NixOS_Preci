{
  lix,
  top,
  lib,
  dom,
  mod,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix) mkModuleArgs;
in {
  core = {config, ...}: let
    scope = "core";
    inherit (mkModuleArgs {inherit config top dom mod scope;}) cfg opt mkEnable;
  in {
    options = opt {enable = mkEnable.true;};
    config = mkIf cfg.enable {
      ${top} = {
        applications.git.enable = true;
        interface.keyd.enable = true;
      };
    };
  };

  home = {config, ...}: let
    scope = "home";
    inherit (mkModuleArgs {inherit config top dom mod scope;}) cfg opt mkEnable;
    homeDir = config.home.homeDirectory;
  in {
    options = opt {enable = mkEnable.true;};
    config = mkIf cfg.enable {
      ${top} = {
        interface = {
          browsers.enable = true;
          control.enable = true;
        };

        applications = {
          zen-browser.enable = true;

          git = {
            enable = true;
            profiles = {
              craole = "32288735+Craole@users.noreply.github.com";
              craole-cc = "134658831+craole-cc@users.noreply.github.com";
              cole-bassed = "75517056+cole-bassed@users.noreply.github.com";
            };
            defaultProfile = "craole-cc";
            extraRepositories = {
              "${homeDir}/.dots/" = "cole-bassed";
            };
          };

          noctalia.enable = true;
          starship.enable = true;
          vicinae.enable = true;
        };
      };

      home.sessionVariables = {
        EDITOR = "hx";
        VISUAL = "code";
      };
    };
  };
}
