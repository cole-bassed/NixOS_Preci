/**
* Host Configuration Schema
* ==========================
*
* This file is a *specification*, not a working module. It documents every
* field of the per-host config used by this flake, expressed as a real
* `lib.types` shape so it can be dropped into an `options = { ... }` block
* (e.g. via `lib.mkOption`) almost verbatim.
*
* Read it top-to-bottom: each attribute is documented immediately above
* its definition, using block comments (slash-star-star ... star-slash).
* Where a field has constraints (enum values, units, formats) they are
* spelled out in the comment rather than left implicit.
*
* Conventions used throughout:
*   - `types.str`              free-form text
*   - `types.enum [ ... ]`     closed set of allowed string values
*   - `types.nullOr T`         the field may be `null` (i.e. "unset")
*   - `types.listOf T`         an ordered list of `T`
*   - `types.attrsOf T`        a key -> value map where every value is `T`
*   - `types.submodule { ... }` a nested record with its own fixed fields
*/
{
  options = {
    /**
    * -------------------------------------------------------------
    * SYSTEM IDENTITY
    * -------------------------------------------------------------
    * Top-level scalars that identify *this* machine, as opposed to
    * the class of machines it belongs to. These are read by other
    * modules to label outputs, tag backups, set hostnames, etc.
    */

    /**
      Human-readable machine name.
    *  type    : nullOr str
    *  default : null  -> falls back to the host directory name
    *  example : "TheExample"
    */
    name = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Human-readable machine name. Falls back to the host directory name when unset.";
      example = "TheExample";
    };

    /**
      Stable machine identifier.
    *  type    : nullOr str
    *  format  : 8-character lowercase hex
    *  default : null  -> no ID is set
    *  derive  : `head -c8 /etc/machine-id`
    *  example : "deadbeef"
    */
    id = mkOption {
      type = types.nullOr (types.strMatching "[0-9a-f]{8}");
      default = null;
      description = "8-character hex machine ID. Obtain with `head -c8 /etc/machine-id`.";
      example = "deadbeef";
    };

    /**
      Free-text description of the machine's purpose.
    *  type    : nullOr str
    *  default : null  -> no description is set
    */
    description = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Short human-readable description of the machine.";
      example = "Example machine for schema documentation";
    };

    /**
      Device form factor, for internal schema/tagging purposes only.
    *  type    : enum
    *  values  : "laptop" | "desktop" | "server"
    */
    type = mkOption {
      type = types.enum ["laptop" "desktop" "server"];
      description = "Device class label used for internal schema/tagging.";
      example = "laptop";
    };

    /**
      Operating system family.
    *  type    : enum
    *  values  : "nixos" | "darwin"
    *  default : "nixos" if unset (⚠ may be wrong — set explicitly)
    */
    class = mkOption {
      type = types.enum ["nixos" "darwin"];
      default = "nixos";
      description = ''
        OS class label. Defaults to "nixos" when unset, which may not be
        correct for every host — set explicitly rather than relying on
        the default.
      '';
      example = "nixos";
    };

    /**
      CPU instruction-set architecture.
    *  type    : enum
    *  values  : "x86_64" | "aarch64" | ...
    *  note    : also re-exported by `specs.cpu.arch` via `inherit arch`
    */
    arch = mkOption {
      type = types.enum ["x86_64" "aarch64" "armv7l" "i686"];
      description = "CPU architecture identifier.";
      example = "x86_64";
    };

    /**
      Kernel/OS family.
    *  type    : enum
    *  values  : "linux" | "darwin"
    */
    os = mkOption {
      type = types.enum ["linux" "darwin"];
      description = "Operating system family.";
      example = "linux";
    };

    /**
      Nix system double, derived from `arch` and `os`.
    *  type    : str   (computed, not hand-set)
    *  formula : "${arch}-${os}"
    *  note    : technically redundant given `arch`/`os`, kept for
    *            convenience when passing to `nixpkgs.system` etc.
    */
    system = mkOption {
      type = types.str;
      readOnly = true;
      description = "Computed Nix system double: \"\${arch}-\${os}\".";
      example = "x86_64-linux";
    };

    /**
      NixOS release baseline for this host.
    *  type    : str
    *  format  : "YY.MM" matching the release the host was *first*
    *            installed with — must match `hardware-configuration.nix`
    *  warning : never bump this retroactively; it controls stateful
    *            defaults, not the channel you currently track
    */
    stateVersion = mkOption {
      type = types.strMatching "[0-9]{2}\\.[0-9]{2}";
      description = ''
        NixOS state-version baseline. Must equal the value recorded in
        hardware-configuration.nix at first install. Do not change this
        when upgrading channels.
      '';
      example = "26.05";
    };

    /**
      Filesystem paths relevant to provisioning this host.
    *  type    : submodule
    */
    paths = mkOption {
      description = "Filesystem paths used when provisioning this host.";
      type = types.submodule {
        options = {
          /**
            Source checkout of the dotfiles/flake repo.
          *  type    : path-like str
          *  default : "/home/${admin}/.dots"
          */
          src = mkOption {
            type = types.str;
            description = "Absolute path to the dotfiles/flake checkout.";
            example = "/home/craole/.dots";
          };

          /**
            Optional path to a wallpaper asset directory.
          *  type    : nullOr str
          *  default : null
          */
          wallpapers = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Optional path to host-specific wallpaper assets.";
            example = "/home/craole/.dots/Assets/Images/wallpaper";
          };
        };
      };
    };

    /**
    * -------------------------------------------------------------
    * LOCALIZATION
    * -------------------------------------------------------------
    * Geographic and regional settings, grouped so downstream modules
    * (locale, timezone, redshift/gammastep, geoclue) read from one place.
    */
    localization = mkOption {
      description = "Geographic and regional settings.";
      type = types.submodule {
        options = {
          /**
            Latitude in decimal degrees.
          *  type   : float
          *  range  : -90.0 .. 90.0
          */
          latitude = mkOption {
            type = types.float;
            description = "Latitude in decimal degrees.";
            example = 18.015;
          };

          /**
            Longitude in decimal degrees.
          *  type   : float
          *  range  : -180.0 .. 180.0
          */
          longitude = mkOption {
            type = types.float;
            description = "Longitude in decimal degrees.";
            example = -77.49;
          };

          /**
            Human-readable location label.
          *  type   : str
          */
          city = mkOption {
            type = types.str;
            description = "Human-readable city/region label.";
            example = "Mandeville, Jamaica";
          };

          /**
            Geolocation backend used to refine position at runtime.
          *  type   : enum
          *  values : "geoclue2" | "manual" | "none"
          */
          locator = mkOption {
            type = types.enum ["geoclue2" "manual" "none"];
            default = "manual";
            description = "Geolocation backend for runtime position lookups.";
            example = "geoclue2";
          };

          /**
            IANA timezone identifier.
          *  type   : str  (validated against the tzdata set upstream)
          */
          timeZone = mkOption {
            type = types.str;
            description = "IANA timezone name.";
            example = "America/Jamaica";
          };

          /**
            Default system locale.
          *  type   : str
          *  format : "<lang>_<TERRITORY>.<encoding>"
          */
          defaultLocale = mkOption {
            type = types.str;
            description = "Default system locale string.";
            example = "en_US.UTF-8";
          };
        };
      };
    };

    /**
    * -------------------------------------------------------------
    * USER ACCOUNTS
    * -------------------------------------------------------------
    * Deliberately a *list*, not an attrset, so the primary/default
    * account can be guaranteed to sit at index 0 and be reordered
    * by position rather than by renaming keys.
    */
    users = mkOption {
      type = types.listOf (types.submodule {
        options = {
          /**
            Unix account name.
          *  type : str
          */
          name = mkOption {
            type = types.str;
            description = "Unix username.";
            example = "craole";
          };

          /**
            Whether this account is created on the system.
          *  type    : bool
          *  default : true
          */
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether the account is created on this host.";
          };

          /**
            Whether this account auto-logs-in to the display manager.
          *  type    : bool
          *  default : false
          */
          autoLogin = mkOption {
            type = types.bool;
            default = false;
            description = "Whether this account auto-logs-in at boot.";
          };

          /**
            Privilege tier for this account.
          *  type   : enum
          *  values : "administrator" | "service" | "guest"
          */
          role = mkOption {
            type = types.enum ["administrator" "service" "guest"];
            description = "Privilege/role tier assigned to this account.";
            example = "administrator";
          };
        };
      });
      default = [];
      description = ''
        Ordered list of accounts. List form (not attrsOf) is intentional:
        it lets the primary/default account stay first and be reordered
        by position.
      '';
    };

    /**
    * -------------------------------------------------------------
    * PACKAGES & CACHES
    * -------------------------------------------------------------
    */
    packages = mkOption {
      description = "Package policy: channel tracking, licensing, kernel choice, binary caches.";
      type = types.submodule {
        options = {
          /**
            Track nixos-unstable rather than the stable channel.
          *  type    : bool
          *  default : false
          */
          unstable = mkOption {
            type = types.bool;
            default = false;
            description = "Whether this host tracks nixos-unstable.";
          };

          /**
            Permit non-FOSS-licensed packages.
          *  type    : bool
          *  default : false
          */
          allowUnfree = mkOption {
            type = types.bool;
            default = false;
            description = "Whether unfree packages are permitted.";
          };

          /**
            Kernel package attribute to boot.
          *  type   : str  (must resolve under `pkgs.linuxKernel.packages`
          *           or be a top-level `linuxPackages*` attribute)
          */
          kernel = mkOption {
            type = types.str;
            default = "linuxPackages";
            description = "Kernel package set to boot.";
            example = "linuxPackages_latest";
          };

          /**
            Additional binary substituters, keyed by a short name.
          *  type : attrsOf submodule
          */
          caches = mkOption {
            type = types.attrsOf (types.submodule {
              options = {
                /**
                  Substituter URL.
                *  type : str (URL)
                */
                sub = mkOption {
                  type = types.str;
                  description = "Binary cache substituter URL.";
                  example = "https://geo-mirror.chaotic.cx/";
                };

                /**
                  Trusted public key for this substituter.
                *  type   : str
                *  format : "<name>:<base64-key>"
                */
                key = mkOption {
                  type = types.str;
                  description = "Trusted public key for this substituter.";
                  example = "nyx.chaotic.cx-1:EXAMPLEKEY...=";
                };
              };
            });
            default = {};
            description = "Map of cache-name -> { sub, key } for extra binary caches.";
          };
        };
      };
    };

    /**
    * -------------------------------------------------------------
    * HARDWARE PROFILE
    * -------------------------------------------------------------
    * Logical description of the machine's hardware — what kind of
    * device this is and what it's built from — as distinct from the
    * raw mount/device layout under `devices`.
    */
    specs = mkOption {
      description = "Logical hardware profile: machine class, CPU, GPU.";
      type = types.submodule {
        options = {
          /**
            Redundant-but-explicit machine class for this section.
          *  type   : enum
          *  values : "laptop" | "desktop" | "server"
          */
          machine = mkOption {
            type = types.enum ["laptop" "desktop" "server"];
            description = "Machine form factor (mirrors top-level `type`).";
            example = "laptop";
          };

          /**
          CPU details.
          */
          cpu = mkOption {
            description = "CPU details.";
            type = types.submodule {
              options = {
                /**
                Instruction-set architecture (mirrors top-level `arch`).
                */
                arch = mkOption {
                  type = types.enum ["x86_64" "aarch64" "armv7l" "i686"];
                  description = "CPU architecture (inherited from top-level `arch`).";
                };

                /**
                  Silicon vendor.
                *  type   : enum
                *  values : "amd" | "intel" | "arm"
                */
                brand = mkOption {
                  type = types.enum ["amd" "intel" "arm"];
                  description = "CPU vendor.";
                  example = "amd";
                };

                /**
                  Default CPU governor / power profile.
                *  type   : enum
                *  values : "performance" | "powersave" | "ondemand" | "schedutil"
                */
                powerMode = mkOption {
                  type = types.enum ["performance" "powersave" "ondemand" "schedutil"];
                  default = "schedutil";
                  description = "Default CPU frequency governor.";
                  example = "performance";
                };

                /**
                  Physical core count.
                *  type  : positive int
                */
                cores = mkOption {
                  type = types.ints.positive;
                  description = "Number of physical CPU cores.";
                  example = 8;
                };
              };
            };
          };

          /**
          GPU details — supports a hybrid dual-GPU layout.
          */
          gpu = mkOption {
            description = "GPU details, including optional hybrid dual-GPU layout.";
            type = types.submodule {
              options = {
                /**
                Primary (typically integrated) GPU.
                */
                primary = mkOption {
                  type = types.submodule {
                    options = {
                      /**
                      GPU vendor. enum: "amd" | "nvidia" | "intel"
                      */
                      brand = mkOption {
                        type = types.enum ["amd" "nvidia" "intel"];
                        description = "Primary GPU vendor.";
                      };
                      /**
                      PCI bus address. format: "PCI:bus:device:function"
                      */
                      busId = mkOption {
                        type = types.str;
                        description = "PCI bus ID, format \"PCI:bus:device:function\".";
                        example = "PCI:6:0:0";
                      };
                      /**
                      Human-readable model string.
                      */
                      model = mkOption {
                        type = types.str;
                        description = "GPU model name.";
                        example = "Example iGPU";
                      };
                    };
                  };
                };

                /**
                Secondary (typically discrete) GPU — optional.
                */
                secondary = mkOption {
                  type = types.nullOr (types.submodule {
                    options = {
                      brand = mkOption {
                        type = types.enum ["amd" "nvidia" "intel"];
                        description = "Secondary GPU vendor.";
                      };
                      busId = mkOption {
                        type = types.str;
                        description = "PCI bus ID, format \"PCI:bus:device:function\".";
                        example = "PCI:1:0:0";
                      };
                      model = mkOption {
                        type = types.str;
                        description = "GPU model name.";
                        example = "Example dGPU";
                      };
                    };
                  });
                  default = null;
                  description = "Secondary GPU, if this host has a hybrid graphics layout.";
                };

                /**
                  Graphics switching strategy when both GPUs are present.
                *  type   : enum
                *  values : "hybrid" | "integrated" | "discrete"
                */
                mode = mkOption {
                  type = types.enum ["hybrid" "integrated" "discrete"];
                  default = "integrated";
                  description = "Graphics-switching mode for dual-GPU hosts.";
                  example = "hybrid";
                };
              };
            };
          };
        };
      };
    };

    /**
    * -------------------------------------------------------------
    * KERNEL MODULES
    * -------------------------------------------------------------
    * Modules required at boot, typically for `boot.initrd.availableKernelModules`.
    *  type : listOf str
    */
    modules = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Kernel modules required by this host's hardware (e.g. for initrd).";
      example = ["nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod"];
    };

    /**
    * -------------------------------------------------------------
    * DEVICES
    * -------------------------------------------------------------
    * Raw device/mount/network/display layout — distinct from the
    * logical `specs` section above.
    */
    devices = mkOption {
      description = "Raw device layout: boot mappings, filesystems, swap, network, displays.";
      type = types.submodule {
        options = {
          /**
            LUKS (or other) boot-time device mappings, keyed by
          *  mapper name (e.g. "luks-root").
          *  type : attrsOf submodule
          */
          boot = mkOption {
            type = types.attrsOf (types.submodule {
              options = {
                /**
                Underlying block device, by stable UUID path.
                */
                device = mkOption {
                  type = types.str;
                  description = "Underlying block device, addressed by UUID.";
                  example = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
                };
              };
            });
            default = {};
            description = "Encrypted/boot-time device mappings keyed by mapper name.";
          };

          /**
            Filesystem mounts, keyed by mount point.
          *  type : attrsOf submodule
          */
          file = mkOption {
            type = types.attrsOf (types.submodule {
              options = {
                /**
                Source block device, by stable UUID path.
                */
                device = mkOption {
                  type = types.str;
                  description = "Source block device, addressed by UUID.";
                  example = "/dev/disk/by-uuid/0000-0000";
                };
                /**
                  Filesystem type.
                *  type   : enum
                *  values : "ext4" | "vfat" | "btrfs" | "xfs" | "zfs"
                */
                fsType = mkOption {
                  type = types.enum ["ext4" "vfat" "btrfs" "xfs" "zfs"];
                  description = "Filesystem type for this mount.";
                  example = "ext4";
                };
                /**
                Mount options, e.g. umask controls for FAT/EFI.
                */
                options = mkOption {
                  type = types.listOf types.str;
                  default = [];
                  description = "Mount option flags.";
                  example = ["fmask=0077" "dmask=0077"];
                };
              };
            });
            default = {};
            description = "Filesystem mounts keyed by mount point (e.g. \"/\", \"/boot\").";
          };

          /**
            Swap devices.
          *  type : listOf submodule
          */
          swap = mkOption {
            type = types.listOf (types.submodule {
              options = {
                device = mkOption {
                  type = types.str;
                  description = "Swap device, addressed by UUID.";
                  example = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
                };
              };
            });
            default = [];
            description = "Swap devices for this host.";
          };

          /**
            Network interface names attached to this host.
          *  type : listOf str
          */
          network = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Network interface names (e.g. ethernet, wifi).";
            example = ["eno1" "wlo1"];
          };

          /**
            Output/display layout, keyed by connector name
          *  (e.g. "eDP-1", "HDMI-A-1").
          *  type : attrsOf submodule
          */
          display = mkOption {
            type = types.attrsOf (types.submodule {
              options = {
                /**
                Panel manufacturer.
                */
                brand = mkOption {
                  type = types.str;
                  description = "Display/panel manufacturer.";
                  example = "AUO";
                };
                /**
                  Native resolution.
                *  format : "<width>x<height>"
                */
                resolution = mkOption {
                  type = types.strMatching "[0-9]+x[0-9]+";
                  description = "Native panel resolution.";
                  example = "1920x1080";
                };
                /**
                Refresh rate in Hz. May be fractional.
                */
                refreshRate = mkOption {
                  type = types.numbers.positive;
                  description = "Refresh rate in Hz.";
                  example = 144.15;
                };
                /**
                Compositor scale factor.
                */
                scale = mkOption {
                  type = types.numbers.positive;
                  default = 1;
                  description = "Display scale factor.";
                  example = 1;
                };
                /**
                Position in the virtual layout, "<x>x<y>".
                */
                position = mkOption {
                  type = types.strMatching "-?[0-9]+x-?[0-9]+";
                  description = "Position offset in the virtual display layout.";
                  example = "0x1080";
                };
                /**
                Physical panel size, diagonal inches.
                */
                size = mkOption {
                  type = types.numbers.positive;
                  description = "Physical panel size in diagonal inches.";
                  example = 15.6;
                };
                /**
                Ordering priority; lower = primary.
                */
                priority = mkOption {
                  type = types.ints.unsigned;
                  default = 0;
                  description = "Display ordering priority; 0 is primary.";
                  example = 0;
                };
              };
            });
            default = {};
            description = "Display outputs keyed by connector name.";
          };
        };
      };
    };

    /**
    * -------------------------------------------------------------
    * ACCESS & REMOTE OPERATIONS
    * -------------------------------------------------------------
    */
    access = mkOption {
      description = "Remote access: SSH/age identities, firewall, DNS, optional VPN.";
      type = types.submodule {
        options = {
          /**
            Public SSH key authorized for remote admin access.
          *  type    : nullOr str
          *  default : null
          */
          ssh = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Authorized SSH public key for remote administration.";
            example = "ssh-ed25519 AAAA...";
          };

          /**
            Age public identity for secrets decryption (e.g. agenix/sops).
          *  type    : nullOr str
          *  default : null
          */
          age = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Age public identity used for secrets handling.";
            example = "age1...";
          };

          /**
          Firewall policy.
          */
          firewall = mkOption {
            description = "Firewall enable flag and per-protocol port/range allow-lists.";
            type = types.submodule {
              options = {
                /**
                Master firewall switch.
                */
                enable = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Whether the firewall is enabled.";
                };

                /**
                TCP allow-list.
                */
                tcp = mkOption {
                  description = "Allowed TCP ports and port ranges.";
                  type = types.submodule {
                    options = {
                      ranges = mkOption {
                        type = types.listOf (types.submodule {
                          options = {
                            from = mkOption {
                              type = types.port;
                              description = "Range start (inclusive).";
                            };
                            to = mkOption {
                              type = types.port;
                              description = "Range end (inclusive).";
                            };
                          };
                        });
                        default = [];
                        description = "Allowed TCP port ranges.";
                      };
                      ports = mkOption {
                        type = types.listOf types.port;
                        default = [];
                        description = "Allowed individual TCP ports.";
                        example = [22 80 443];
                      };
                    };
                  };
                };

                /**
                UDP allow-list.
                */
                udp = mkOption {
                  description = "Allowed UDP ports and port ranges.";
                  type = types.submodule {
                    options = {
                      ranges = mkOption {
                        type = types.listOf (types.submodule {
                          options = {
                            from = mkOption {
                              type = types.port;
                              description = "Range start (inclusive).";
                            };
                            to = mkOption {
                              type = types.port;
                              description = "Range end (inclusive).";
                            };
                          };
                        });
                        default = [];
                        description = "Allowed UDP port ranges.";
                      };
                      ports = mkOption {
                        type = types.listOf types.port;
                        default = [];
                        description = "Allowed individual UDP ports.";
                      };
                    };
                  };
                };
              };
            };
          };

          /**
            DNS resolvers, in priority order.
          *  type : listOf str  (IPv4/IPv6 literals)
          */
          nameservers = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "DNS resolver addresses, in priority order.";
            example = ["1.1.1.1" "1.0.0.1"];
          };

          /**
          Optional VPN configuration.
          */
          vpn = mkOption {
            type = types.nullOr (types.submodule {
              options = {
                /**
                Path to the VPN client config file (e.g. .ovpn).
                */
                configFile = mkOption {
                  type = types.str;
                  description = "Path to the VPN client configuration file.";
                  example = "/etc/openvpn/protonvpn-us.ovpn";
                };
                /**
                Apps that should be routed/launched through the VPN.
                */
                apps = mkOption {
                  type = types.listOf types.str;
                  default = [];
                  description = "Applications associated with/routed through this VPN.";
                  example = ["freetube" "chromium"];
                };
              };
            });
            default = null;
            description = "Optional VPN configuration for this host.";
          };
        };
      };
    };

    /**
    * -------------------------------------------------------------
    * INTERFACE
    * -------------------------------------------------------------
    * Boot UI and desktop/session presentation settings.
    */
    interface = mkOption {
      description = "Boot loader and desktop/session presentation settings.";
      type = types.submodule {
        options = {
          /**
            Boot loader implementation.
          *  type   : enum
          *  values : "systemd-boot" | "grub" | "refind"
          */
          bootLoader = mkOption {
            type = types.enum ["systemd-boot" "grub" "refind"];
            description = "Boot loader implementation.";
            example = "systemd-boot";
          };

          /**
          Boot menu timeout, in seconds. 0 = skip menu entirely.
          */
          bootLoaderTimeout = mkOption {
            type = types.ints.unsigned;
            default = 5;
            description = "Boot loader menu timeout, in seconds.";
            example = 1;
          };

          /**
            Display manager / greeter.
          *  type    : nullOr enum
          *  values  : "regreet" | "sddm" | "gdm" | "lightdm" | null
          */
          displayManager = mkOption {
            type = types.nullOr (types.enum ["regreet" "sddm" "gdm" "lightdm"]);
            default = null;
            description = "Display manager / login greeter.";
            example = "regreet";
          };

          /**
            Desktop environment, if a full DE is used instead of a
          *  standalone window manager.
          *  type : nullOr str
          */
          desktopEnvironment = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Desktop environment, if used in place of a bare window manager.";
            example = "plasma";
          };

          /**
            Standalone window manager / compositor.
          *  type : nullOr str
          */
          windowManager = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Window manager or compositor.";
            example = "hyprland";
          };

          /**
            Display protocol in use.
          *  type   : nullOr enum
          *  values : "wayland" | "x11" | null
          */
          displayProtocol = mkOption {
            type = types.nullOr (types.enum ["wayland" "x11"]);
            default = null;
            description = "Display protocol in use.";
            example = "wayland";
          };

          /**
          Keyboard behavior.
          */
          keyboard = mkOption {
            description = "Keyboard modifier and key-remap settings.";
            type = types.submodule {
              options = {
                /**
                  Primary WM modifier key.
                *  type   : enum
                *  values : "SUPER" | "ALT" | "CTRL"
                */
                modifier = mkOption {
                  type = types.enum ["SUPER" "ALT" "CTRL"];
                  default = "SUPER";
                  description = "Primary window-manager modifier key.";
                  example = "SUPER";
                };
                /**
                Whether Caps Lock and Escape are swapped.
                */
                swapCapsEscape = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Whether Caps Lock and Escape are swapped.";
                };
              };
            };
          };
        };
      };
    };

    /**
    * -------------------------------------------------------------
    * SYSTEM FUNCTIONALITIES
    * -------------------------------------------------------------
    * Coarse-grained capability flags this host should support; other
    * modules gate on membership in this list rather than on hardware
    * detection alone.
    *  type : listOf enum
    */
    functionalities = mkOption {
      type = types.listOf (types.enum [
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
      default = [];
      description = "Coarse capability flags this host should support.";
      example = ["audio" "battery" "bluetooth" "network" "wireless"];
    };

    /**
    * -------------------------------------------------------------
    * SERVICES
    * -------------------------------------------------------------
    * Named opt-in services layered on top of `functionalities`.
    *  type : listOf str
    */
    services = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Named opt-in services enabled for this host.";
      example = ["tailscale"];
    };

    /**
    * -------------------------------------------------------------
    * MODULE IMPORT CONTROL
    * -------------------------------------------------------------
    */

    /**
      NixOS modules to import for this host. The machine-generated
    *  hardware-configuration.nix should always be first.
    *  type : listOf path
    */
    imports = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "Modules imported for this host. Hardware config should be listed first.";
      example = [./hardware-configuration.nix];
    };

    /**
      Modules to explicitly disable/exclude from evaluation.
    *  type    : listOf path
    *  default : [ ]
    */
    disabledModules = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "Modules explicitly excluded from evaluation for this host.";
    };

    /**
      Administrative username referenced by templated paths
    *  (e.g. `paths.src`). Not itself a user account entry — see `users`.
    *  type : str
    */
    admin = mkOption {
      type = types.str;
      description = "Admin username used to template default paths.";
      example = "craole";
    };
  };
}
