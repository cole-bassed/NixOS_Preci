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
  description = "Oracle Cloud Free Tier Ampere Instance";
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
    boot = {
      device = "/dev/disk/by-label/NIXBOOT"; # Standard target for systemd-boot installers
      fsType = "vfat";
    };
    file = {
      "/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };
    };
    swap = [];
    network = ["enp0s3"]; # Crucial for Oracle Cloud's virtual network card
    display = {};
  };

  firewall = {
    enable = true;
    tcp = {
      ranges = [];
      ports = [
        22 # SSH / Colmena deployments
        80 # Caddy HTTP
        443 # Caddy HTTPS / SSL handshakes
      ];
    };
    udp = {
      ranges = [];
      ports = [
        41641 # Default Tailscale port for direct peer connections
      ];
    };
  };

  nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  vpn = {
    tailscale = {
      enable = true;
      autoconnect = true;
    };
  };

  specs = {
    machine = "server";
    cpu = {
      inherit arch;
      cores = 2; # Matches your safe always-free slider layout
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
