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
  inherit arch os;
  system = "${arch}-${os}";
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
  users = [
    {
      name = admin;
      enable = true;
      autoLogin = true;
      role = "administrator";
    }
    {
      name = "cc";
      enable = true;
      autoLogin = false;
      role = "administrator";
    }
  ];
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
  # HARDWARE PROFILE
  # ---------------------------------------------------------
  specs = {
    machine = "laptop";
    cpu = {
      inherit arch;
      brand = "intel";
      cores = 4; # i7-4810MQ
    };
    gpu = {
      primary = {
        brand = "intel";
        model = "HD Graphics 4600";
      };
      mode = "integrated";
    };
  };

  # ---------------------------------------------------------
  # KERNEL MODULES
  # ---------------------------------------------------------
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

  # ---------------------------------------------------------
  # DEVICES
  # ---------------------------------------------------------
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

    display = [
      {
        enable = true;
        output = "eDP-1";
        monitor = "dell-m2800";
        position = "center";
      }

      {
        enable = true;
        output = "HDMI-A-3";
        monitor = "ktc-27";
        position = "right";
      }

      {
        enable = true;
        output = "DP-3";
        monitor = "dell-19";
        position = "left";
      }

      {
        enable = false;
        output = "HDMI-A-3";
        monitor = "acer-24";
        position = "right";
      }
    ];
  };

  # ---------------------------------------------------------
  # BOOT & INTERFACE
  # ---------------------------------------------------------
  interface = {
    boot = {
      loader = "systemd-boot";
      timeout = 1;
    };
    bootLoader = "systemd-boot";
    bootLoaderTimeout = 1;
    environment = {
      managers = [];
      desktops = [];
    };
    keyboard = {
      modifier = "SUPER";
      swapCapsEscape = false;
    };
  };

  # ---------------------------------------------------------
  # SYSTEM FUNCTIONALITIES & SERVICES
  # ---------------------------------------------------------
  functionalities = [
    "audio"
    "battery"
    "bluetooth"
    "efi"
    "gpu"
    "keyboard"
    "network"
    "secureboot"
    "storage"
    "video"
    "virtualization"
    "wired"
    "wireless"
    #TODO: Extend schema enum to cover these:
    # "dualboot-windows"
    # "nvme"
    # "remote"
    # "touchpad"
    # "tpm"
    # "vpn"
    # "webcam"
  ];

  services = [
    "tailscale"
    "streaming"
  ];
}
