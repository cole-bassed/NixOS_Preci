{
  lix,
  top,
  host,
  config,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs;
  inherit (lix.modules) mkDefault;
  inherit (lix.lists) elem;
  inherit (lix.options) mkOption mkEnableOption;
  inherit (lix.types) str nullOr listOf attrsOf enum int float submodule;

  #? Raw host data is consulted ONLY as option defaults below. Nothing
  #  in `config` reads `host.*` directly -- all real wiring comes from
  #  `cfg = config.${top}.system`, so a field set directly on
  #  `${top}.system.*` (with no `host.nix` entry at all) behaves
  #  identically to one sourced from the host file.
  interfaceSrc = host.interface or {};
  devicesSrc = host.devices or {};
  specsSrc = host.specs or {};

  #? Schema S8: devices.file mounts.
  fsEntrySubmodule = submodule {
    options = {
      device = mkOption {
        type = str;
        description = "Source block device, addressed by UUID or path.";
      };
      fsType = mkOption {
        type = nullOr (enum ["ext4" "vfat" "btrfs" "xfs" "zfs"]);
        default = null;
        description = "Filesystem type for this mount.";
      };
      options = mkOption {
        type = listOf str;
        default = [];
        description = "Mount option flags.";
      };
    };
  };

  #? Schema S8: devices.boot (LUKS mappings) only ever need `.device`.
  luksEntrySubmodule = submodule {
    options = {
      device = mkOption {
        type = str;
        description = "Underlying block device, addressed by UUID.";
      };
    };
  };

  #? Schema S8: devices.swap entries.
  swapEntrySubmodule = submodule {
    options = {
      device = mkOption {
        type = str;
        description = "Swap device, addressed by UUID.";
      };
    };
  };

  #? Schema S8: devices.display entries.
  displayEntrySubmodule = submodule {
    options = {
      brand = mkOption {
        type = nullOr str;
        default = null;
        description = "Display/panel manufacturer.";
      };
      resolution = mkOption {
        type = nullOr str;
        default = null;
        description = "Native resolution, format \"WxH\".";
      };
      refreshRate = mkOption {
        type = nullOr float;
        default = null;
        description = "Refresh rate in Hz.";
      };
      scale = mkOption {
        type = float;
        default = 1.0;
        description = "Display scale factor.";
      };
      position = mkOption {
        type = nullOr str;
        default = null;
        description = "Position in the virtual layout, format \"XxY\".";
      };
      size = mkOption {
        type = nullOr float;
        default = null;
        description = "Physical panel size, diagonal inches.";
      };
      priority = mkOption {
        type = int;
        default = 0;
        description = "Display ordering priority; 0 is primary.";
      };
    };
  };

  #? `system.nix` only ever acted at `core` scope (NixOS itself --
  #  boot, filesystems, networking, the boot loader). There is no
  #  home-manager-side behavior to mirror, so `home` below is a
  #  deliberate no-op kept solely for caller compatibility with the
  #  existing `{ core = ...; home = ...; }` import convention.
  core = {
    options.${top}.system = {
      #? S2 SYSTEM IDENTITY
      name = mkOption {
        type = str;
        default = host.name or "nixos";
        description = "Human-readable hostname.";
      };

      id = mkOption {
        type = nullOr str;
        default = host.id or null;
        description = "8-character hex machine identifier.";
      };

      description = mkOption {
        type = nullOr str;
        default = host.description or null;
        description = "Free-form host description.";
      };

      type = mkOption {
        type = nullOr (enum ["laptop" "desktop" "server" "vm" "container"]);
        default = host.type or null;
        description = "Physical form factor.";
      };

      class = mkOption {
        type = enum ["nixos" "darwin"];
        default = host.class or "nixos";
        description = "Operating-system family.";
      };

      platform = mkOption {
        type = str;
        default = host.system or "${host.arch}-${host.os}";
        description = "Nix system double, e.g. \"x86_64-linux\".";
      };

      #? Schema S2 marks this `required = true`. No fallback default
      #  is provided here -- if neither `host.stateVersion` nor a
      #  direct `${top}.system.stateVersion` assignment exists
      #  anywhere, the module system itself raises "value is required
      #  but not set", which is the correct failure mode for a
      #  required field.
      stateVersion = mkOption (
        {
          type = str;
          description = "NixOS release baseline. Required -- must match hardware-configuration.nix at install time.";
        }
        // optionalAttrs (host.stateVersion or null != null) {
          default = host.stateVersion;
        }
      );

      #? S11 functionalities -- resolved/stored ONLY. Enablement of
      #  the underlying daemons is delegated to a separate consumer
      #  module; this module stays scoped to core specs and
      #  deployment metadata.
      functionalities = mkOption {
        type = listOf (enum [
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
        ]);
        default = host.functionalities or [];
        description = "Capability tags resolved for this host. Consumed by a separate module for actual enablement.";
      };

      #? S6 HARDWARE PROFILE
      specs = {
        machine = mkOption {
          type = nullOr (enum ["laptop" "desktop" "server" "vm" "container"]);
          default = specsSrc.machine or null;
          description = "Alias for top-level `type` at the specs scope.";
        };

        cpu = {
          arch = mkOption {
            type = nullOr str;
            default = (specsSrc.cpu or {}).arch or host.arch or null;
            description = "CPU architecture.";
          };
          brand = mkOption {
            type = nullOr (enum ["amd" "intel" "apple"]);
            default = (specsSrc.cpu or {}).brand or null;
            description = "CPU vendor.";
          };
          powerMode = mkOption {
            type = enum ["performance" "balanced" "powersave"];
            default = (specsSrc.cpu or {}).powerMode or "balanced";
            description = "Default CPU power profile.";
          };
          cores = mkOption {
            type = nullOr int;
            default = (specsSrc.cpu or {}).cores or null;
            description = "Physical core count.";
          };
        };

        gpu = {
          primary = {
            brand = mkOption {
              type = nullOr (enum ["amd" "intel" "nvidia"]);
              default = ((specsSrc.gpu or {}).primary or {}).brand or null;
              description = "Primary GPU vendor.";
            };
            busId = mkOption {
              type = nullOr str;
              default = ((specsSrc.gpu or {}).primary or {}).busId or null;
              description = "PCI bus ID, format \"PCI:D:B:F\".";
            };
            model = mkOption {
              type = nullOr str;
              default = ((specsSrc.gpu or {}).primary or {}).model or null;
              description = "Primary GPU model name.";
            };
          };
          secondary = {
            brand = mkOption {
              type = nullOr (enum ["amd" "intel" "nvidia"]);
              default = ((specsSrc.gpu or {}).secondary or {}).brand or null;
              description = "Secondary GPU vendor, if present.";
            };
            busId = mkOption {
              type = nullOr str;
              default = ((specsSrc.gpu or {}).secondary or {}).busId or null;
              description = "PCI bus ID, format \"PCI:D:B:F\".";
            };
            model = mkOption {
              type = nullOr str;
              default = ((specsSrc.gpu or {}).secondary or {}).model or null;
              description = "Secondary GPU model name.";
            };
          };
          mode = mkOption {
            type = enum ["integrated" "discrete" "hybrid" "off"];
            default = (specsSrc.gpu or {}).mode or "integrated";
            description = "Multi-GPU switching strategy.";
          };
        };
      };

      #? S7 KERNEL MODULES
      modules = mkOption {
        type = listOf str;
        default = host.modules or [];
        description = "Kernel module names passed to boot.initrd.availableKernelModules.";
      };

      #? S10 INTERFACE / BOOT
      interface = {
        bootLoader = mkOption {
          type = enum ["systemd-boot" "grub" "grub-efi"];
          default = interfaceSrc.bootLoader or "systemd-boot";
          description = "Boot loader backend.";
        };

        bootLoaderTimeout = mkOption {
          type = nullOr int;
          default = interfaceSrc.bootLoaderTimeout or null;
          description = "Seconds to show the boot menu. 0 = immediate, -1 = infinite.";
        };

        grubDevice = mkOption {
          type = str;
          default = interfaceSrc.grubDevice or "nodev";
          description = "Target device for GRUB install. Effectively required when bootLoader is \"grub\" or \"grub-efi\".";
        };

        osProber = mkEnableOption "GRUB os-prober detection of other installed operating systems";

        displayManager = mkOption {
          type = nullOr (enum ["gdm" "sddm" "regreet" "lightdm"]);
          default = interfaceSrc.displayManager or null;
          description = "Greeter / login manager.";
        };

        desktopEnvironment = mkOption {
          type = nullOr (enum ["plasma" "gnome" "xfce" "cinnamon"]);
          default = interfaceSrc.desktopEnvironment or null;
          description = "Full desktop environment, if used in place of a bare WM.";
        };

        windowManager = mkOption {
          type = nullOr (enum ["hyprland" "sway" "river" "dwm" "i3"]);
          default = interfaceSrc.windowManager or null;
          description = "Standalone window manager / compositor.";
        };

        displayProtocol = mkOption {
          type = nullOr (enum ["wayland" "x11"]);
          default = interfaceSrc.displayProtocol or null;
          description = "Display server protocol. Inferred from WM/DE if unset.";
        };

        keyboard = {
          modifier = mkOption {
            type = enum ["SUPER" "ALT" "CTRL"];
            default = (interfaceSrc.keyboard or {}).modifier or "SUPER";
            description = "Primary window-manager modifier key.";
          };
          swapCapsEscape = mkEnableOption "swapping Caps Lock and Escape";
        };
      };

      #? S8 DEVICES
      devices = {
        boot = mkOption {
          type = attrsOf luksEntrySubmodule;
          default = devicesSrc.boot or {};
          description = "LUKS/boot-time device mappings, keyed by mapper name.";
        };

        file = mkOption {
          type = attrsOf fsEntrySubmodule;
          default = devicesSrc.file or {};
          description = "Filesystem mounts, keyed by mount point.";
        };

        swap = mkOption {
          type = listOf swapEntrySubmodule;
          default = devicesSrc.swap or [];
          description = "Swap devices or files.";
        };

        network = mkOption {
          type = listOf str;
          default = devicesSrc.network or [];
          description = "Network interface names to bring up or configure.";
        };

        display = mkOption {
          type = attrsOf displayEntrySubmodule;
          default = devicesSrc.display or {};
          description = "Output/display layout, keyed by connector name.";
        };
      };
    };

    config = let
      #? Everything downstream reads the RESOLVED option tree, not raw
      #  `host.*`. This is what makes a field settable purely via
      #  `${top}.system.<path> = ...;` in some other module, with no
      #  `host.nix` entry at all.
      cfg = config.${top}.system;

      bootLoaderConfig =
        if cfg.interface.bootLoader == "systemd-boot"
        then {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        }
        else if cfg.interface.bootLoader == "grub"
        then {
          grub = {
            enable = true;
            device = cfg.interface.grubDevice;
            efiSupport = false;
            useOSProber = cfg.interface.osProber;
          };
        }
        else if cfg.interface.bootLoader == "grub-efi"
        then {
          grub = {
            enable = true;
            device = cfg.interface.grubDevice;
            efiSupport = true;
            useOSProber = cfg.interface.osProber;
          };
          efi.canTouchEfiVariables = true;
        }
        else {}; #TODO: Allow other bootloders

      hasFsConfig =
        (cfg.devices.file != {})
        || cfg.devices.swap != []
        || cfg.modules != []
        || cfg.devices.boot != {};
    in {
      assertions = [
        {
          assertion = elem cfg.interface.bootLoader ["systemd-boot" "grub" "grub-efi"];
          message = "${top}.system.interface.bootLoader must be one of \"systemd-boot\", \"grub\", \"grub-efi\"; got \"${cfg.interface.bootLoader}\" for host \"${cfg.name}\".";
        }
      ];

      networking.hostName = mkDefault cfg.name;
      system.stateVersion = mkDefault cfg.stateVersion;
      nixpkgs.hostPlatform = mkDefault cfg.platform;

      boot.loader =
        bootLoaderConfig
        // optionalAttrs (cfg.interface.bootLoaderTimeout != null) {
          timeout = cfg.interface.bootLoaderTimeout;
        };

      boot.initrd = optionalAttrs hasFsConfig {
        availableKernelModules = cfg.modules;
        luks.devices = cfg.devices.boot;
      };

      fileSystems = cfg.devices.file;
      swapDevices = cfg.devices.swap;
    };
  };

  home = {};
in {inherit core home;}
