{
  osConfig,
  top,
  ...
}: {
  ${top} = {
    interface = {
      keybinds = {
        enable = true;
      };
    };

    applications = {
      browsers = {
        enable = true;
      };
      git = {
        enable = true;
      };
      noctalia = {
        enable = true;
      };
      starship = {
        enable = true;
      };
      vicinae = {
        enable = true;
      };
    };
  };

  home = {
    inherit (osConfig.system) stateVersion;

    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "code";
    };
  };

  imports = [
    ./git.nix
  ];
}
