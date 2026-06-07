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
      kernelModules = [];
    };
    kernelModules = ["kvm-intel"];
    kernelPackages = pkgs.linuxPackages_latest;
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

  nixpkgs.hostPlatform = mkDefault "x86_64-linux";
  networking.networkmanager.enable = true;
  hardware.cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
}
