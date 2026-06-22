let
  admin = "craole";
  arch = "aarch64";
  os = "linux";
in {
  # ---------------------------------------------------------
  # MACHINE IMPORTS
  # ---------------------------------------------------------
  imports = [];
  disabledModules = [];

  # ---------------------------------------------------------
  # SYSTEM IDENTITY
  # ---------------------------------------------------------
  name = "TheOracle";
  id = "0a11ce42";
  description = "Oracle Cloud free-tier Ampere instance";
  type = "server";
  class = "nixos";
  stateVersion = "26.05";
  paths.src = "/home/${admin}/Projects/Cole-Bassed_Solutions/NixOS_Preci";
  inherit arch os;
  system = "${arch}-${os}";

  # ---------------------------------------------------------
  # LOCALIZATION
  # ---------------------------------------------------------
  localization = {
    city = "Mandeville, Jamaica";
    timezone = "America/Jamaica";
    locale = "en_US.UTF-8";
  };

  # ---------------------------------------------------------
  # USER ACCOUNTS
  # ---------------------------------------------------------
  users = {
    ${admin} = {
      role = "administrator";
      primary = true;
      autoLogin = false;
    };
  };

  # ---------------------------------------------------------
  # PACKAGES & CACHES
  # ---------------------------------------------------------
  packages = {
    unstable = true;
    allowUnfree = true;
    kernel = "linuxPackages_latest";
    caches = {};
  };

  # ---------------------------------------------------------
  # BOOT & DEVICES
  # ---------------------------------------------------------
  interface = {
    bootLoader = "systemd-boot";
    bootLoaderTimeout = 1;
  };

  modules = [];

  devices = {
    boot = {};
    file = {};
    swap = [];
  };

  # ---------------------------------------------------------
  # ACCESS & REMOTE OPERATIONS
  # ---------------------------------------------------------
  access = {
    firewall = {
      enable = true;
      tcp = {
        ranges = [];
        ports = [
          22
          80
          443
        ];
      };
      udp = {
        ranges = [];
        ports = [];
      };
    };

    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };

  # ---------------------------------------------------------
  # SYSTEM FUNCTIONALITIES & SERVICES
  # ---------------------------------------------------------
  functionalities = [
    "efi"
    "remote"
    "vpn"
    "wired"
  ];

  services = ["tailscale"];
}
