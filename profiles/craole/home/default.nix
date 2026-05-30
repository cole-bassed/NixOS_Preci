{osConfig, top, ...}: {
  ${top} = {
    applications = {
      git = {
        enable = true;
      };
      starship = {
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
