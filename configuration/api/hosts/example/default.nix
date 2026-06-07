{
  # ---------------------------------------------------------
  # SYSTEM IDENTITY
  # ---------------------------------------------------------
  name = "ExampleHost";
  id = "deadbeef"; # Valid 8-character hexadecimal ID template
  type = "laptop"; # Alternatives: desktop, server
  class = "nixos";
  system = "x86_64-linux"; # Alternatives: aarch64-linux, x86_64-darwin
  stateVersion = "26.05";
  paths.src = "/home/username/.dots";

  # ---------------------------------------------------------
  # LOCALIZATION
  # ---------------------------------------------------------
  localization = {
    city = "London, United Kingdom";
    timezone = "Europe/London";
    locale = "en_GB.UTF-8";
    locator = "geoclue2";
    latitude = 51.5074;
    longitude = -0.1278;
  };

  # ---------------------------------------------------------
  # USER ACCOUNTS
  # ---------------------------------------------------------
  users = {
    username = {
      role = "administrator";
      primary = true;
      autoLogin = true;
    };
    # guest = { role = "user"; enabled = false; };
  };

  # ---------------------------------------------------------
  # PACKAGES & CACHES
  # ---------------------------------------------------------
  packages = {
    unstable = true;
    allowUnfree = true;
    kernel = "linuxPackages_latest";
    caches = {
      example-cache = {
        sub = "https://nixos.org";
        key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
      };
    };
  };

  # ---------------------------------------------------------
  # DISPLAY ENVIRONMENT
  # ---------------------------------------------------------
  # Dual monitor example (Stacked arrangement setup)
  displays = {
    DP-1 = {
      brand = "Generic-Brand";
      size = 27.0;
      priority = 0; # Main screen
      resolution = "3840x2160";
      refreshRate = 144;
      scale = 1;
      position = "0x0";
    };
    HDMI-A-1 = {
      brand = "Generic-Brand";
      size = 24.0;
      priority = 1; # Secondary screen
      resolution = "1920x1080";
      refreshRate = 60;
      scale = 1;
      position = "960x2160";
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
    "nvme"
    "secureboot"
    "storage"
    "touchpad"
    "tpm"
    "video"
    "virtualization"
    "webcam"
    "wireless"
  ];

  services = ["ssh" "firewall"];
}
