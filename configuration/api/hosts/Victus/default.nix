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
  name = "Victus";
  id = "d2c1db8e";
  description = "HP Victus 15 Gaming Laptop";
  type = "laptop";
  class = "nixos";
  inherit arch os;
  system = "${arch}-${os}";
  stateVersion = "25.05";
  paths.src = "/home/${admin}/Downloads/public/dotDots";
  # paths.wallpapers = "/home/${admin}/.dots/Assets/Images/wallpaper";

  # ---------------------------------------------------------
  # LOCALIZATION
  # ---------------------------------------------------------
  localization = {
    latitude = 18.015;
    longitude = -77.49;
    city = "Mandeville, Jamaica";
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
      enable = false;
      autoLogin = false;
      role = "service";
    }
    {
      name = "qyatt";
      enable = false;
      autoLogin = false;
      role = "guest";
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
      brand = "amd";
      powerMode = "performance";
      cores = 12;
    };

    gpu = {
      primary = {
        brand = "amd";
        busId = "PCI:6:0:0";
        model = "Radeon 680M";
      };
      secondary = {
        brand = "nvidia";
        busId = "PCI:1:0:0";
        model = "RTX 2050";
      };
      mode = "hybrid";
    };
  };

  # ---------------------------------------------------------
  # KERNEL MODULES
  # ---------------------------------------------------------
  modules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];

  # ---------------------------------------------------------
  # DEVICES
  # ---------------------------------------------------------
  devices = {
    boot = {
      "luks-03a38b8f-5279-4c0f-9172-a7878fbcc92d" = {
        device = "/dev/disk/by-uuid/03a38b8f-5279-4c0f-9172-a7878fbcc92d";
      };
    };

    file = {
      "/" = {
        device = "/dev/disk/by-uuid/6494d9f3-9b6b-43ee-b0c9-6abeec96bf38";
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/3C12-4AC5";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
    };

    swap = [
      {device = "/dev/disk/by-uuid/d9e04286-b70c-4c8a-8691-a9a9cbcf57fe";}
    ];

    network = [
      "eno1"
      "wlo1"
    ];

    display = {
      "eDP-1" = {
        brand = "AUO";
        resolution = "1920x1080";
        refreshRate = 144.15;
        scale = 1;
        position = "0x0";
        size = 15.6;
        priority = 0;
      };

      "HDMI-A-1" = {
        brand = "ACER";
        resolution = "1920x1080";
        refreshRate = 100;
        scale = 1;
        position = "0x1080";
        # transform = 3;
        size = 24.5;
        priority = 2;
      };
    };
  };

  # ---------------------------------------------------------
  # ACCESS & REMOTE OPERATIONS
  # ---------------------------------------------------------
  access = {
    ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuAgYKymJKvky9sAhU0wjHPHbGt+Hg0KLOTIYjoZ9tw root@nixos";
    # age = "age1j5cug724x386nygk8dhc38tujhzhp9nyzyelzl0yaz3ndgtq3qwqxtkfpv";

    firewall = {
      # enable = true;
      tcp = {
        ranges = [
          {
            from = 49160;
            to = 65534;
          }
        ];
        ports = [22 80 443 1678 1876];
      };
      udp = {
        ranges = [
          {
            from = 49160;
            to = 65534;
          }
        ];
        ports = [];
      };
    };

    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];

    vpn = {
      configFile = "/etc/openvpn/protonvpn-us.ovpn";
      apps = [
        "freetube"
        "chromium"
      ];
    };
  };

  # ---------------------------------------------------------
  # BOOT & INTERFACE
  # ---------------------------------------------------------
  interface = {
    bootLoader = "systemd-boot";
    bootLoaderTimeout = 1;
    # desktopEnvironment = "plasma";
    windowManager = "hyprland";
    # displayProtocol = "wayland";
    # keyboard = {
    #   modifier = "SUPER";
    #   swapCapsEscape = true;
    # };
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
    # "tpm"
    # "vpn"
    # "webcam"
    # "touchpad"  # currently non-functional
  ];

  services = [];
}
