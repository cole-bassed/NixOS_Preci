{
  imports = [./hardware-configuration.nix];

  name = "Preci";
  id = "cfd69003";
  description = "Dell Precision M2800";
  type = "laptop";
  class = "nixos";
  system = "x86_64-linux";
  stateVersion = "25.11";

  # paths.flake.local = "/home/craole/.dots";

  # localization = {
  #   latitude = 18.015;
  #   longitude = -77.49;
  #   city = "Mandeville, Jamaica";
  #   locator = "geoclue2";
  #   timezone = "America/Jamaica";
  #   locale = "en_US.UTF-8";
  # };

  users = {
    craole = {
      role = "administrator";
      primary = true;
      autoLogin = true;
    };
    # cc = {
    #   role = "service";
    #   enabled = false;
    # };
    # john = {};
  };

  packages = {
    unstable = true;
    allowUnfree = true;
    kernel = "linuxPackages_cachyos-lto";
    caches = {
      nyx = {
        sub = "https://geo-mirror.chaotic.cx/";
        key = "nyx.chaotic.cx-1:CNZOSlPJO5F0utqsPzkZbHkkD7YzNDWHGG6PqS30wMc=";
      };
    };
  };

  displays = {
    "HDMI-A-3" = {
      brand = "KTC";
      resolution = "2560x1440";
      refreshRate = 100;
      scale = 1;
      # Centered below DP-3: (2560 - 1600) / 2 = 480 → x=480; y=900 (below 900px tall DP-3)
      position = "480x900";
      size = 27.0;
      priority = 0; # Primary
    };

    "DP-3" = {
      brand = "DELL";
      resolution = "1600x900";
      refreshRate = 60;
      scale = 1;
      # Centered above HDMI-A-3: (2560 - 1600) / 2 = 480
      position = "480x0";
      size = 19.4;
      priority = 1;
    };
  };

  functionalities = [
    "audio"
    "battery"
    "bluetooth"
    "dualboot-windows"
    "efi"
    "gpu"
    "keyboard"
    "network"
    "nvme"
    "remote"
    "secureboot"
    "storage"
    "touchpad"
    "tpm"
    "video"
    "virtualization"
    "vpn"
    "webcam"
    "wired"
    "wireless"
  ];

  services = [
    "tailscale"
    "streaming"
  ];
}
