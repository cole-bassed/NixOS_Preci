{
  core = {pkgs, ...}: {
    programs = {
      gamescope.enable = true;
    };

    environment = {
      systemPackages = [
        pkgs.mangohud
      ];
    };
  };
}
