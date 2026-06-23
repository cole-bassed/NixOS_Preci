let
  admin = "craole";
  arch = "aarch64";
  os = "linux";
in {
  inherit os arch;

  imports = [];
  disabledModules = [];

  name = "TheOracle";
  id = "0a11ce42";
  description = "Oracle Cloud free-tier Ampere instance";
  type = "server";
  class = "nixos";
  stateVersion = "26.05";
  paths.src = "/home/${admin}/.dots";

  localization = {
    latitude = 18.015;
    longitude = -77.49;
    city = "Mandeville, Jamaica";
    locator = "manual";
    timeZone = "America/Jamaica";
    defaultLocale = "en_US.UTF-8";
  };

  users = [
    {
      name = admin;
      enable = true;
      autoLogin = false;
      role = "administrator";
    }
  ];

  packages = {
    unstable = true;
    allowUnfree = true;
    kernel = "linuxPackages_latest";
    caches = {};
  };

  interface = {
    bootLoader = "systemd-boot";
    bootLoaderTimeout = 1;
  };

  modules = [];

  devices = {
    boot = {};
    file = {};
    swap = [];
    network = [];
    display = {};
  };

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

  vpn = {};

  specs = {
    machine = "server";
    cpu = {
      inherit arch;
    };
    gpu = {
      mode = "off";
    };
  };

  functionalities = [
    "network"
    "storage"
    "wired"
  ];

  services = ["tailscale"];
}
