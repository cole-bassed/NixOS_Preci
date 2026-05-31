{
  osConfig,
  top,
  config,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
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

  home = {
    #: TODO This has to be defined for every user, so we need to put it somewhere else
    inherit (osConfig.system) stateVersion;

    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "code";
    };
  };
}
