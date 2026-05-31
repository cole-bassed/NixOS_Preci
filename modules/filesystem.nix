{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      eza
      lsd
    ];

    shellAliases = {
      l = "lsd --git";
      ll = "l --long --almost-all";
      lt = "l --tree";
      lr = "l --recursive";
    };
  };

  programs = {
    udevil = {
      enable = true;
    };
    yazi = {
      enable = true;
    };
  };

  services = {
    udisks2 = {
      enable = true;
      mountOnMedia = true;
    };
  };
}
