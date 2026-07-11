let
  admin = "craole";
  arch = "x86_64";
  os = "linux";
in {
  # ╔════════════════════════════════════════════════╗
  # ╠ IMPORTS                                        ╣
  # ╚════════════════════════════════════════════════╝
  imports = [./hardware-configuration.nix];
  disabledModules = [];

  # ╔════════════════════════════════════════════════╗
  # ╠ IDENTITY                                       ╣
  # ╚════════════════════════════════════════════════╝
  name = "Preci";
  id = "cfd69003";
  description = "Dell Precision M2800";
  type = "laptop";
  class = "nixos";
  inherit arch os;
  system = "${arch}-${os}";
  stateVersion = "25.11";
  paths.src = "/home/${admin}/.dots";

  # ╔════════════════════════════════════════════════╗
  # ╠ LOCALIZATION                                   ╣
  # ╚════════════════════════════════════════════════╝
  localization = {
    latitude = 18.015;
    longitude = -77.49;
    city = "Mandeville, Jamaica";
    locator = "geoclue2";
    timeZone = "America/Jamaica";
    defaultLocale = "en_US.UTF-8";
  };

  # ╔════════════════════════════════════════════════╗
  # ╠ USERS                                          ╣
  # ╚════════════════════════════════════════════════╝
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
      role = "administrator";
    }
  ];

  # ╔════════════════════════════════════════════════╗
  # ╠ HARDWARE SPECS                                 ╣
  # ╚════════════════════════════════════════════════╝
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

    display = [
      {
        monitor = "ktc-27";
        position = "right";
      }

      {
        monitor = "dell-19";
        position = "left";
      }
    ];
  };

  # ╔════════════════════════════════════════════════╗
  # ╠ INTERFACE                                      ╣
  # ╚════════════════════════════════════════════════╝
  interface = {
    boot = {
      loader = "systemd-boot";
      timeout = 1;
    };
    greeter = "dank-material-shell";
    backends = {
      hyprland = {
        preferred = true;
        enable = true;
        frontend = "dank-material-shell";
      };
      niri = {
        enable = true;
        preferred = false;
        frontend = "caelestia-shell";
        # needsXwaylandSatellite = true;
        # fallbackConfig = "config/niri/config.kdl";
      };
    };
    keyboard = {
      modifier = "SUPER";
      swapCapsEscape = false;
    };
  };

  # ╔════════════════════════════════════════════════╗
  # ╠ PACKAGES & SERVICES                            ╣
  # ╚════════════════════════════════════════════════╝
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
    aliases = {};
  };

  functionalities = [
    "ai"
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
    "streaming"
    "touchpad"
    "tpm"
    "vcs"
    "video"
    "virtualization"
    "vpn"
    "webcam"
    "wired"
    "wireless"
  ];

  applications = {
    ai = {
      claude = {
        enable = true;
        package = ["llm-agents" "claude-code"];
      };
      codex = {
        enable = true;
        package = ["llm-agents" "codex"];
      };
      hermes-agent = {
        enable = true;
        package = ["llm-agents" "hermes-agent"];
      };
      hermes-desktop = {
        enable = true;
        package = ["llm-agents" "hermes-desktop"];
      };
      hermes-hud = {
        enable = true;
        package = ["llm-agents" "hermes-hud"];
      };
      hermes = {
        enable = true;
        package = ["llm-agents" "hermes-agent"];
      };
    };
    connectivity = {
      tailscale = {
        enable = true;
        openFirewall = true;
        authKeySecret.enable = true;
      };
    };
    editors = {
      helix = {
        enable = true;
        package = "helix";
      };
      vscode = {
        enable = true;
        package = "vscode-fhs";
      };
      zed = {
        enable = true;
        package = "zed-editor-fhs";
      };
    };
    terminals = {
      alacritty = {
        enable = true;
        package = "alacritty";
      };
      foot = {
        enable = true;
        package = "foot";
      };
      kitty = {
        enable = true;
        package = "kitty";
      };
      tmux = {
        enable = true;
        package = "tmux";
      };
    };
    vcs = {
      git = {
        enable = true;
        package = "gitFull";
      };
      lfs = {
        enable = true;
        package = "git-lfs";
      };
      gh = {
        enable = true;
        package = "gh";
      };
      jj = {
        enable = true;
        package = "jujutsu";
      };
      gitui = {
        enable = true;
        package = "gitui";
      };
      delta = {
        enable = true;
        package = "delta";
      };
    };
  };
}
