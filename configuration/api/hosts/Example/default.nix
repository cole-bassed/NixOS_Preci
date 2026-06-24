/*
╔══════════════════════════════════════════════════════════════════════════╗
║                    HOST CONFIGURATION SCHEMA SPEC                         ║
║                    NixOS Machine Definition Standard                      ║
╚══════════════════════════════════════════════════════════════════════════╝

Overview
────────
This attrset defines a single machine's complete identity, hardware
profile, and operational parameters. It is consumed by the host
abstraction layer to generate `config.nixos` or `config.darwin`
expressions.

Every key is typed, constrained, and documented. Missing required keys
will abort evaluation with a clear trace. Optional keys default to
`null` or an empty structure.

──────────────────────────────────────────────────────────────────────────
LEGEND
──────────────────────────────────────────────────────────────────────────
  Type      →  Nix type: str, int, bool, path, listOf T, attrsOf T
  Required  →  `true`  = must be set; `false` = optional
  Default   →  Value used when key is absent
  Inherits  →  Parent namespace keys that flow into this scope
  Example   →  Representative value

──────────────────────────────────────────────────────────────────────────
TOP-LEVEL BINDINGS (prelude)
──────────────────────────────────────────────────────────────────────────
These `let` bindings are not part of the returned attrset, but they
are inherited into it and are available to all downstream expressions.

  ┌─────────┬────────┬──────────┬─────────────────────────────────────────┐
  │ Name    │ Type   │ Required │ Description                             │
  ├─────────┼────────┼──────────┼─────────────────────────────────────────┤
  │ arch    │ str    │ true     │ Target system architecture.               │
  │         │        │          │ Must match `nixpkgs.system` or cross-    │
  │         │        │          │ compilation will fail.                  │
  │         │        │          │ Valid: "x86_64" | "aarch64" | "i686"   │
  ├─────────┼────────┼──────────┼─────────────────────────────────────────┤
  │ os      │ str    │ true     │ Target operating system kernel.           │
  │         │        │          │ Valid: "linux" | "darwin"               │
  ├─────────┼────────┼──────────┼─────────────────────────────────────────┤
  │ admin   │ str    │ true     │ Primary administrative username.          │
  │         │        │          │ Used for home-directory paths, SSH       │
  │         │        │          │ authorized_keys, and sudo policies.     │
  └─────────┴────────┴──────────┴─────────────────────────────────────────┘

──────────────────────────────────────────────────────────────────────────
SECTION 1 — MACHINE IMPORTS
──────────────────────────────────────────────────────────────────────────
NixOS module composition. These paths are resolved relative to the
host file's directory and merged into the module system's `imports`
list.

  ┌────────────────┬─────────────────┬──────────┬────────────────────────┐
  │ Key            │ Type            │ Required │ Description            │
  ├────────────────┼─────────────────┼──────────┼────────────────────────┤
  │ imports        │ listOf path     │ false    │ Host-specific hardware │
  │                │                 │          │ configuration and any  │
  │                │                 │          │ additional modules.    │
  │                │                 │          │ The first entry should │
  │                │                 │          │ always be the machine- │
  │                │                 │          │ generated `hardware-   │
  │                │                 │          │ configuration.nix`.    │
  │                │                 │          │ Default: [ ]            │
  ├────────────────┼─────────────────┼──────────┼────────────────────────┤
  │ disabledModules│ listOf str      │ false    │ Module paths or names  │
  │                │                 │          │ to explicitly disable. │
  │                │                 │          │ Use sparingly—prefer   │
  │                │                 │          │ fixing conflicts over  │
  │                │                 │          │ disabling modules.     │
  │                │                 │          │ Default: [ ]            │
  └────────────────┴─────────────────┴──────────┴────────────────────────┘

──────────────────────────────────────────────────────────────────────────
SECTION 2 — SYSTEM IDENTITY
──────────────────────────────────────────────────────────────────────────
Human- and machine-readable identifiers. These values appear in
prompts, status bars, network discovery, and secret key derivation.

  ┌───────────────┬────────┬──────────┬─────────────────────────────────────┐
  │ Key           │ Type   │ Required │ Description                         │
  ├───────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ name          │ str    │ false    │ Human-readable hostname.            │
  │               │        │          │ Falls back to the directory name    │
  │               │        │          │ containing this file.               │
  │               │        │          │ Constraints: RFC 1123 compliant,    │
  │               │        │          │ max 63 chars, [a-z0-9-].            │
  │               │        │          │ Default: directory basename         │
  ├───────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ id            │ str    │ false    │ 8-character lowercase hex string.   │
  │               │        │          │ Used as a stable machine identifier │
  │               │        │          │ for secret derivation and state     │
  │               │        │          │ partitioning.                       │
  │               │        │          │ Derivation: `head -c8 /etc/         │
  │               │        │          │ machine-id` on the target host.     │
  │               │        │          │ Default: null                       │
  ├───────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ description   │ str    │ false    │ Free-form description. Displayed    │
  │               │        │          │ in inventory tools and dashboards.  │
  │               │        │          │ Default: null                       │
  ├───────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ type          │ enum   │ false    │ Physical form factor.               │
  │               │        │          │ Valid: "laptop" | "desktop" |       │
  │               │        │          │ "server" | "vm" | "container"       │
  │               │        │          │ Default: null                       │
  ├───────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ class         │ enum   │ false    │ Operating-system family.            │
  │               │        │          │ Valid: "nixos" | "darwin"           │
  │               │        │          │ Default: "nixos"                    │
  ├───────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ arch          │ str    │ true*    │ Inherited from prelude.             │
  │ os            │ str    │ true*    │ Inherited from prelude.             │
  │ system        │ str    │ false    │ Computed as "${arch}-${os}".        │
  │               │        │          │ Override only for cross-compilation │
  │               │        │          │ scenarios.                          │
  │               │        │          │ Default: "${arch}-${os}"            │
  ├───────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ stateVersion  │ str    │ true     │ NixOS release string. Must match    │
  │               │        │          │ the value in `hardware-             │
  │               │        │          │ configuration.nix` at install time. │
  │               │        │          │ Format: "YY.MM" (e.g. "26.05")      │
  │               │        │          │ NEVER change this on an existing    │
  │               │        │          │ installation; it gates stateful     │
  │               │        │          │ migration scripts.                  │
  ├───────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ paths         │ attrs  │ false    │ Repository and asset paths.         │
  │   .src        │ path   │ false    │ Absolute path to the dotfiles or    │
  │               │        │          │ NixOS configuration repository.     │
  │               │        │          │ Used by activation scripts and      │
  │               │        │          │ relative-path resolution.           │
  │               │        │          │ Default: "/home/${admin}/.dots"     │
  │   .wallpapers │ path   │ false    │ Optional: wallpaper asset directory.│
  │               │        │          │ Default: null                       │
  └───────────────┴────────┴──────────┴─────────────────────────────────────┘

──────────────────────────────────────────────────────────────────────────
SECTION 3 — LOCALIZATION
──────────────────────────────────────────────────────────────────────────
Geographic, temporal, and locale settings. These drive geoclue,
redshift/gammastep, timezone links, and locale generation.

  ┌───────────────┬────────┬──────────┬───────────────────────────────────┐
  │ Key           │ Type   │ Required │ Description                       │
  ├───────────────┼────────┼──────────┼───────────────────────────────────┤
  │ latitude      │ float  │ false    │ Decimal degrees, -90 to 90.       │
  │               │        │          │ Negative = South.                 │
  │               │        │          │ Default: null                     │
  ├───────────────┼────────┼──────────┼───────────────────────────────────┤
  │ longitude     │ float  │ false    │ Decimal degrees, -180 to 180.     │
  │               │        │          │ Negative = West.                  │
  │               │        │          │ Default: null                     │
  ├───────────────┼────────┼──────────┼───────────────────────────────────┤
  │ city          │ str    │ false    │ Human-readable location string.   │
  │               │        │          │ Used for display, not parsing.    │
  │               │        │          │ Default: null                     │
  ├───────────────┼────────┼──────────┼───────────────────────────────────┤
  │ locator       │ enum   │ false    │ Location provider backend.        │
  │               │        │          │ Valid: "geoclue2" | "manual" |    │
  │               │        │          │ "networkmanager"                  │
  │               │        │          │ Default: "geoclue2"               │
  ├───────────────┼────────┼──────────┼───────────────────────────────────┤
  │ timeZone      │ str    │ true     │ tzdata identifier.                │
  │               │        │          │ Example: "America/Jamaica"        │
  │               │        │          │ Run `timedatectl list-timezones`  │
  │               │        │          │ for the full list.                │
  ├───────────────┼────────┼──────────┼───────────────────────────────────┤
  │ defaultLocale │ str    │ true     │ glibc locale string.              │
  │               │        │          │ Format: "lang_COUNTRY.charset"    │
  │               │        │          │ Example: "en_US.UTF-8"            │
  └───────────────┴────────┴──────────┴───────────────────────────────────┘

──────────────────────────────────────────────────────────────────────────
SECTION 4 — USER ACCOUNTS
──────────────────────────────────────────────────────────────────────────
List of user definitions. Order is significant: the first entry is
treated as the primary/administrative account.

  Type: listOf (submodule)

  ┌─────────────┬────────┬──────────┬─────────────────────────────────────┐
  │ Key         │ Type   │ Required │ Description                         │
  ├─────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ name        │ str    │ true     │ Unix username.                      │
  │             │        │          │ Constraints: POSIX.1-2008, max 32   │
  │             │        │          │ chars, [a-z_][a-z0-9_-]*.           │
  ├─────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ enable      │ bool   │ true     │ Whether to create and manage this   │
  │             │        │          │ account. Set to false to keep the   │
  │             │        │          │ definition without activating it.   │
  ├─────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ autoLogin   │ bool   │ false    │ Skip the display-manager greeter    │
  │             │        │          │ for this user. Only one user may    │
  │             │        │          │ have autoLogin = true.              │
  │             │        │          │ Default: false                      │
  ├─────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ role        │ enum   │ false    │ Internal privilege classification.  │
  │             │        │          │ Valid: "administrator" | "standard" │
  │             │        │          │ | "service" | "guest"               │
  │             │        │          │ Default: "standard"                 │
  └─────────────┴────────┴──────────┴─────────────────────────────────────┘

──────────────────────────────────────────────────────────────────────────
SECTION 5 — PACKAGES & CACHES
──────────────────────────────────────────────────────────────────────────
Package policy, kernel selection, and binary-cache configuration.

  ┌─────────────┬────────┬──────────┬─────────────────────────────────────┐
  │ Key         │ Type   │ Required │ Description                         │
  ├─────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ unstable    │ bool   │ false    │ Overlay nixpkgs-unstable on top of  │
  │             │        │          │ the stable channel.                 │
  │             │        │          │ Default: false                      │
  ├─────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ allowUnfree │ bool   │ false    │ Permit packages with unfree licenses│
  │             │        │          │ to be installed.                    │
  │             │        │          │ Default: false                      │
  ├─────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ kernel      │ str    │ false    │ NixOS kernel package attribute.     │
  │             │        │          │ Example: "linuxPackages_latest"     │
  │             │        │          │ | "linuxPackages_zen"               │
  │             │        │          │ Default: null (nixpkgs default)     │
  ├─────────────┼────────┼──────────┼─────────────────────────────────────┤
  │ caches      │ attrsOf│ false    │ Named binary-cache definitions.     │
  │   .<name>   │ attrs  │          │ Each cache is an attrset:           │
  │     .sub    │ str    │ true     │ Cache URL (substituter).            │
  │     .key    │ str    │ true     │ Public signing key for verification.│
  └─────────────┴────────┴──────────┴─────────────────────────────────────┘

──────────────────────────────────────────────────────────────────────────
SECTION 6 — HARDWARE PROFILE (specs)
──────────────────────────────────────────────────────────────────────────
Logical hardware description. This is NOT the raw mount layout;
see `devices.file` for that.

  ┌───────────────┬────────┬──────────┬───────────────────────────────────┐
  │ Key           │ Type   │ Required │ Description                       │
  ├───────────────┼────────┼──────────┼───────────────────────────────────┤
  │ machine       │ enum   │ false    │ Alias for `type` at this scope.   │
  │               │        │          │ Valid: same as `type`             │
  ├───────────────┼────────┼──────────┼───────────────────────────────────┤
  │ cpu           │ attrs  │ false    │ Central processing unit profile.  │
  │   .arch       │ str    │ true*    │ Inherited from prelude.           │
  │   .brand      │ enum   │ false    │ "amd" | "intel" | "apple"         │
  │   .powerMode  │ enum   │ false    │ "performance" | "balanced" |      │
  │               │        │          │ "powersave"                       │
  │   .cores      │ int    │ false    │ Physical core count.              │
  ├───────────────┼────────┼──────────┼───────────────────────────────────┤
  │ gpu           │ attrs  │ false    │ Graphics subsystem profile.       │
  │   .primary    │ attrs  │ false    │ Integrated or sole GPU.           │
  │     .brand    │ enum   │ false    │ "amd" | "intel" | "nvidia"        │
  │     .busId    │ str    │ false    │ PCI bus ID: "PCI:D:B:F"           │
  │     .model    │ str    │ false    │ Human-readable model string.      │
  │   .secondary  │ attrs  │ false    │ Discrete GPU (if present).        │
  │     (same     │        │          │ Same keys as .primary             │
  │     shape)    │        │          │                                   │
  │   .mode       │ enum   │ false    │ Multi-GPU strategy.               │
  │               │        │          │ Valid: "integrated" | "discrete"  │
  │               │        │          │ | "hybrid" | "off"                │
  │               │        │          │ Default: "integrated"             │
  └───────────────┴────────┴──────────┴───────────────────────────────────┘

──────────────────────────────────────────────────────────────────────────
SECTION 7 — KERNEL MODULES
──────────────────────────────────────────────────────────────────────────
Hardware and filesystem modules to load at boot or on demand.

  ┌─────────────┬─────────────────┬──────────┬────────────────────────────┐
  │ Key         │ Type            │ Required │ Description                │
  ├─────────────┼─────────────────┼──────────┼────────────────────────────┤
  │ modules     │ listOf str      │ false    │ Kernel module names.       │
  │             │                 │          │ These are passed to        │
  │             │                 │          │ `boot.kernelModules`.      │
  │             │                 │          │ Default: [ ]               │
  └─────────────┴─────────────────┴──────────┴────────────────────────────┘

──────────────────────────────────────────────────────────────────────────
SECTION 8 — DEVICES
──────────────────────────────────────────────────────────────────────────
Attached machine resources: block devices, filesystems, swap,
network interfaces, and display outputs.

  ┌─────────────┬───────────────┬──────────┬──────────────────────────────┐
  │ Key         │ Type          │ Required │ Description                  │
  ├─────────────┼───────────────┼──────────┼──────────────────────────────┤
  │ boot        │ attrsOf attrs │ false    │ LUKS or boot-time device     │
  │             │               │          │ mappings. Each key is a      │
  │             │               │          │ mapping name; value is an    │
  │             │               │          │ attrset with:                │
  │             │               │          │   .device → path or UUID     │
  ├─────────────┼───────────────┼──────────┼──────────────────────────────┤
  │ file        │ attrsOf attrs │ false    │ Filesystem mounts.           │
  │             │               │          │ Keys are absolute mount      │
  │             │               │          │ points. Each value:          │
  │             │               │          │   .device  → str (path)      │
  │             │               │          │   .fsType  → str (ext4,      │
  │             │               │          │               btrfs, vfat)   │
  │             │               │          │   .options → listOf str      │
  ├─────────────┼───────────────┼──────────┼──────────────────────────────┤
  │ swap        │ listOf attrs  │ false    │ Swap devices or files.       │
  │             │               │          │ Each element:                │
  │             │               │          │   { device = "..."; }        │
  ├─────────────┼───────────────┼──────────┼──────────────────────────────┤
  │ network     │ listOf str    │ false    │ Network interface names      │
  │             │               │          │ to bring up or configure.    │
  │             │               │          │ Example: [ "eno1" "wlo1" ]   │
  ├─────────────┼───────────────┼──────────┼──────────────────────────────┤
  │ display     │ attrsOf attrs │ false    │ Output/display layout.       │
  │             │               │          │ Keys are DRM/Wayland         │
  │             │               │          │ output names. Each value:    │
  │             │               │          │   .brand       → str         │
  │             │               │          │   .resolution  → str         │
  │             │               │          │                  (WxH)       │
  │             │               │          │   .refreshRate → float       │
  │             │               │          │   .scale       → float       │
  │             │               │          │   .position    → str         │
  │             │               │          │                  (XxY)       │
  │             │               │          │   .size        → float       │
  │             │               │          │                  (diagonal)  │
  │             │               │          │   .priority    → int         │
  │             │               │          │                  (0=main)    │
  └─────────────┴───────────────┴──────────┴──────────────────────────────┘

──────────────────────────────────────────────────────────────────────────
SECTION 9 — ACCESS & REMOTE OPERATIONS
──────────────────────────────────────────────────────────────────────────
Network accessibility, firewall rules, and secrets infrastructure.

  ┌─────────────┬─────────────────┬──────────┬───────────────────────────┐
  │ Key         │ Type            │ Required │ Description               │
  ├─────────────┼─────────────────┼──────────┼───────────────────────────┤
  │ ssh         │ str             │ false    │ SSH public key for remote │
  │             │                 │          │ admin access.             │
  ├─────────────┼─────────────────┼──────────┼───────────────────────────┤
  │ age         │ str             │ false    │ Age public key for        │
  │             │                 │          │ sops-nix or agenix        │
  │             │                 │          │ secret encryption.        │
  ├─────────────┼─────────────────┼──────────┼───────────────────────────┤
  │ firewall    │ attrs           │ false    │ Firewall configuration.   │
  │   .enable   │ bool            │ false    │ Master switch.            │
  │             │                 │          │ Default: true             │
  │   .tcp      │ attrs           │ false    │ TCP rule set.             │
  │     .ranges │ listOf str      │ false    │ Port ranges (e.g.         │
  │             │                 │          │ "8000-8100").             │
  │     .ports  │ listOf int      │ false    │ Individual open ports.    │
  │   .udp      │ attrs           │ false    │ Same shape as .tcp        │
  ├─────────────┼─────────────────┼──────────┼───────────────────────────┤
  │ nameservers │ listOf str      │ false    │ DNS resolver addresses.   │
  │             │                 │          │ Default: [ ]              │
  ├─────────────┼─────────────────┼──────────┼───────────────────────────┤
  │ vpn         │ attrs           │ false    │ VPN tunnel configuration. │
  │   .configFile│ path           │ false    │ OpenVPN/WireGuard file.   │
  │   .apps     │ listOf str      │ false    │ Desktop app names to      │
  │             │                 │          │ route through the tunnel  │
  └─────────────┴─────────────────┴──────────┴───────────────────────────┘

──────────────────────────────────────────────────────────────────────────
SECTION 10 — INTERFACE
──────────────────────────────────────────────────────────────────────────
Boot, display, and input configuration.

  ┌──────────────────┬────────┬──────────┬───────────────────────────────────┐
  │ Key                │ Type   │ Required │ Description                     │
  ├────────────────────┼────────┼──────────┼─────────────────────────────────┤
  │ bootLoader         │ enum   │ true     │ Boot loader backend.            │
  │                    │        │          │ Valid: "systemd-boot" |         │
  │                    │        │          │ "grub" | "grub-efi"             │
  ├────────────────────┼────────┼──────────┼─────────────────────────────────┤
  │ bootLoaderTimeout  │ int    │ false    │ Seconds to show boot menu.      │
  │                    │        │          │ 0 = immediate, -1 = infinite.   │
  │                    │        │          │ Default: 5                      │
  ├────────────────────┼────────┼──────────┼─────────────────────────────────┤
  │ displayManager     │ enum   │ false    │ Greeter / login manager.        │
  │                    │        │          │ Valid: "gdm" | "sddm" |         │
  │                    │        │          │ "regreet" | "lightdm"           │
  ├────────────────────┼────────┼──────────┼─────────────────────────────────┤
  │ desktopEnvironment │ enum   │ false    │ Full DE to launch.              │
  │                    │        │          │ Valid: "plasma" | "gnome" |     │
  │                    │        │          │ "xfce" | "cinnamon"             │
  ├────────────────────┼────────┼──────────┼─────────────────────────────────┤
  │ windowManager      │ enum   │ false    │ Standalone compositor / WM.     │
  │                    │        │          │ Valid: "hyprland" | "sway" |    │
  │                    │        │          │ "river" | "dwm" | "i3"          │
  ├────────────────────┼────────┼──────────┼─────────────────────────────────┤
  │ displayProtocol    │ enum   │ false    │ Display server protocol.        │
  │                    │        │          │ Valid: "wayland" | "x11"        │
  │                    │        │          │ Inferred from WM/DE if absent.  │
  ├────────────────────┼────────┼──────────┼─────────────────────────────────┤
  │ keyboard           │ attrs  │ false    │ Input customization.            │
  │  .modifier         │ enum   │ false    │ Primary modifier key.           │
  │                    │        │          │ Valid: "SUPER" | "ALT" | "CTRL" │
  │  .swapCapsEscape   │ bool   │ false    │ Swap Caps Lock and Escape.      │
  │                    │        │          │ Default: false                  │
  └────────────────────┴────────┴──────────┴─────────────────────────────────┘

──────────────────────────────────────────────────────────────────────────
SECTION 11 — SYSTEM FUNCTIONALITIES & SERVICES
──────────────────────────────────────────────────────────────────────────
Toggleable capability tags and optional service integrations.

  ┌─────────────────┬─────────────┬──────────┬───────────────────────────────────┐
  │ Key             │ Type        │ Required │ Description                       │
  ├─────────────────┼─────────────┼──────────┼───────────────────────────────────┤
  │ functionalities │ listOf enum │ false    │ Capability tags that              │
  │                 │             │          │ declaratively enable              │
  │                 │             │          │ hardware support,                 │
  │                 │             │          │ daemons, and polkit               │
  │                 │             │          │ rules.                            │
  │                 │             │          │                                   │
  │                 │             │          │ Valid tags:                       │
  │                 │             │          │   "audio"        → pipewire/pulse │
  │                 │             │          │   "battery"      → tlp/upower     │
  │                 │             │          │   "bluetooth"    → bluez          │
  │                 │             │          │   "efi"          → boot.efi       │
  │                 │             │          │   "gpu"          → mesa/nvidia    │
  │                 │             │          │   "keyboard"     → keyd/intercept │
  │                 │             │          │   "network"      → NetworkManager │
  │                 │             │          │   "secureboot"   → lanzaboote/sb  │
  │                 │             │          │   "storage"      → udisks2        │
  │                 │             │          │   "video"        → vaapi/vdpau    │
  │                 │             │          │   "virtualization"→ libvirt/qemu  │
  │                 │             │          │   "wired"        → dhcpcd/iface   │
  │                 │             │          │   "wireless"     → wpa_supplicant │
  │                 │             │          │ Default: [ ]                      │
  ├─────────────────┼─────────────┼──────────┼───────────────────────────────────┤
  │ services        │ listOf str  │ false    │ Additional service                │
  │                 │             │          │ modules to import and enable.     │
  │                 │             │          │ Example: [ "tailscale" ]          │
  │                 │             │          │ Default: [ ]                      │
  └─────────────────┴─────────────┴──────────┴───────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════
EXAMPLE: Minimal Laptop Configuration
═══════════════════════════════════════════════════════════════════════════

  let
    arch  = "x86_64";
    os    = "linux";
    admin = "craole";
  in {
    imports = [ ./hardware-configuration.nix ];

    name        = "Paragon";
    id          = "a1b2c3d4";
    type        = "laptop";
    class       = "nixos";
    stateVersion = "26.05";
    inherit arch os;
    paths.src = "/home/${admin}/.dots";{}

    localization = {
      timeZone      = "America/Jamaica";
      defaultLocale = "en_US.UTF-8";
      latitude      = 18.015;
      longitude     = -77.49;
    };

    users = [{
      name      = admin;
      enable    = true;
      autoLogin = true;
      role      = "administrator";
    }];

    packages = {
      allowUnfree = true;
      kernel      = "linuxPackages_latest";
    };

    specs = {
      machine = "laptop";
      cpu = { inherit arch; brand = "intel"; cores = 8; };
      gpu = {
        primary = { brand = "intel"; model = "UHD 620"; };
        mode    = "integrated";
      };
    };

    devices = {
      network = [ "wlo1" ];
      display = {
        "eDP-1" = {
          resolution  = "1920x1080";
          refreshRate = 60;
          scale       = 1;
          position    = "0x0";
          priority    = 0;
        };
      };
    };

    interface = {
      bootLoader       = "systemd-boot";
      bootLoaderTimeout = 1;
      windowManager    = "hyprland";
      keyboard = {
        modifier       = "SUPER";
        swapCapsEscape = false;
      };
    };

    functionalities = [
      "audio"
      "battery"
      "bluetooth"
      "efi"
      "gpu"
      "network"
      "storage"
      "video"
      "wireless"
    ];
  }

═══════════════════════════════════════════════════════════════════════════
CHANGELOG
═══════════════════════════════════════════════════════════════════════════
  v1.0.0  —  Initial schema.  All sections stable.

──────────────────────────────────────────────────────────────────────────
SPDX-License-Identifier: MIT
Authors: craole <craole@example.com>
*/
let
  admin = "craole";
  arch = "x86_64";
  os = "linux";
in {
  # ---------------------------------------------------------
  # MACHINE IMPORTS
  # ---------------------------------------------------------
  imports = [
    # ./hardware-configuration.nix
  ];
  disabledModules = [];

  # ---------------------------------------------------------
  # SYSTEM IDENTITY
  # ---------------------------------------------------------
  name = "Preci";
  id = "cfd69003";
  description = "Dell Precision M2800";
  type = "laptop";
  class = "nixos";
  inherit arch os;
  system = "${arch}-${os}";
  stateVersion = "25.11";
  paths.src = "/home/${admin}/Projects/Cole-Bassed_Solutions/NixOS_Preci";

  # ---------------------------------------------------------
  # LOCALIZATION
  # ---------------------------------------------------------
  localization = {
    latitude = 18.015;
    longitude = -77.49;
    city = "Mandeville, Jamaica";
    locator = "geoclue2";
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
      enable = true;
      autoLogin = false;
      role = "administrator";
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

  # ---------------------------------------------------------
  # KERNEL MODULES
  # ---------------------------------------------------------
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

  # ---------------------------------------------------------
  # DEVICES
  # ---------------------------------------------------------
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
        output = "HDMI-A-3";
        monitor = "ktc-27";
        position = "right";
      }

      {
        output = "DP-3";
        monitor = "dell-19";
        position = "left";
      }
    ];
  };

  # ---------------------------------------------------------
  # BOOT & INTERFACE
  # ---------------------------------------------------------
  interface = {
    boot = {
      loader = "systemd-boot";
      timeout = 1;
    };
    bootLoader = "systemd-boot";
    bootLoaderTimeout = 1;
    environment = {
      managers = [];
      desktops = [];
    };
    keyboard = {
      modifier = "SUPER";
      swapCapsEscape = false;
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
    "secureboot"
    "storage"
    "video"
    "virtualization"
    "wired"
    "wireless"
    #TODO: Extend schema enum to cover these:
    # "dualboot-windows"
    # "nvme"
    # "remote"
    # "touchpad"
    # "tpm"
    # "vpn"
    # "webcam"
  ];

  services = [
    "tailscale"
    "streaming"
  ];
}
