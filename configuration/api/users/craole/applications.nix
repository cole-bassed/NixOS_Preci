{
  config,
  top,
  ...
}: let
  profiles = {
    craole = "32288735+Craole@users.noreply.github.com";
    craole-cc = "134658831+craole-cc@users.noreply.github.com";
    cole-bassed = "75517056+cole-bassed@users.noreply.github.com";
  };
in {
  ${top}.applications = {
    git = {
      enable = true;
      inherit profiles;
      defaultProfile = "craole";
      extraRepositories = {"${config.home.homeDirectory}/.dots/" = "cole-bassed";};
    };
    zen-browser.enable = true;
  };
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "code";
  };
}
