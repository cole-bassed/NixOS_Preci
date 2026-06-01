{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  inherit (lib.modules) mkDefault;
in {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
        "sr_mod"
        "sdhci_pci"
      ];
      kernelModules = ["amdgpu"];
    };
    kernelModules = [
      "kvm-amd"
      # "kvm-intel"
    ];
    kernelPackages = mkDefault pkgs.linuxPackages_latest;
    kernelPatches = [
      {
        name = "Rust Support";
        patch = null;
        features.rust = true;
      }
    ];
    extraModulePackages = [];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };
  };

  fileSystems = {
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

  swapDevices = [
    {device = "/dev/disk/by-uuid/7cd5b10d-efe9-4279-833c-6482cb6c1474";}
  ];

  nixpkgs = {
    hostPlatform = mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  networking = {
    hostName = mkDefault "Preci";
    hostId = mkDefault "9ebb411d";
    networkmanager.enable = true;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };
  location = {
    latitude = 18.015;
    longitude = -77.49;
    provider = "manual";
  };
  time = {
    timeZone = "America/Jamaica";
  };

  hardware = {
    cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services = {
    kmscon.enable = true;
    getty = {
      autologinOnce = true;
      autologinUser = "craole";
    };
    xserver = {
      xkb = {
        layout = "us";
        variant = "";
      };
      videoDrivers = ["modsetting"];
    };
  };

  system.stateVersion = "25.11";
}
