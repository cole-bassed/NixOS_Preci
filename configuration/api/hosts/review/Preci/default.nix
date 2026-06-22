let
  admin = "craole";
  arch = "x86_64";
  os = "linux";
in {
  # ---------------------------------------------------------
  # MACHINE IMPORTS
  # ---------------------------------------------------------
  imports = [./hardware-configuration.nix];
  disabledModules = [];

  # ---------------------------------------------------------
  # SYSTEM IDENTITY
  # ---------------------------------------------------------
  name = "Preci";
  id = "cfd69003";
  description = "Dell Precision M2800";
  type = "laptop";
  class = "nixos";
  system = "x86_64-linux";
  stateVersion = "25.11";
  paths.src = "/home/${admin}/.dots";

  # ---------------------------------------------------------
  # LOCALIZATION
  # ---------------------------------------------------------
  localization = {
    latitude = 18.015;
    longitude = -77.49;
    city = "Mandeville, Jamaica";
    locator = "geoclue2";
    timeZone = "America/Jamaica";
    defaultLocale = "en_US.UTF-8";
  };

  # ---------------------------------------------------------
  # USER ACCOUNTS
  # ---------------------------------------------------------
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

  # ---------------------------------------------------------
  # PACKAGES & CACHES
  # ---------------------------------------------------------
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

  # ---------------------------------------------------------
  # DISPLAY ENVIRONMENT
  # ---------------------------------------------------------
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

  # ---------------------------------------------------------
  # BOOT & DEVICES
  # ---------------------------------------------------------
  interface = {
    bootLoader = "systemd-boot";
    bootLoaderTimeout = 1;
  };

  modules = [
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "sr_mod"
    "sdhci_pci"
  ];

  devices = {
    boot = {};

    file = {
      "/" = {
        device = "/dev/disk/by-uuid/05382bd2-cc99-4717-8343-0c6076d81441";
        fsType = "ext4";
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/1FC3-D0C5";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
    };

    swap = [
      {device = "/dev/disk/by-uuid/7cd5b10d-efe9-4279-833c-6482cb6c1474";}
    ];
  };

  # ---------------------------------------------------------
  # SYSTEM FUNCTIONALITIES & SERVICES
  # ---------------------------------------------------------
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
