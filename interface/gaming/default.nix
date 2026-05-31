{pkgs, ...}: {
  programs = {
    gamescope.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      mangohud
    ];
  };
}
