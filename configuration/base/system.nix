# configuration/base/system.nix
{
  lix,
  top,
  host,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs;
  inherit (lix.modules) mkDefault;
  inherit (lix.options) mkOption;
  inherit (lix.types) attrsOf anything;

  interface = host.interface or {};
  devices = host.devices or {};

  mk = scope: { ... }: let
    bootData = {
      loader = interface.bootLoader or "systemd-boot";
      timeout = interface.bootLoaderTimeout or null;
      luks = devices.boot or {};
      modules = host.modules or [];
    };

    data = {
      name = host.name or "nixos";
      id = host.id or null;
      description = host.description or null;
      type = host.type or null;
      class = host.class or "nixos";
      platform = host.system or "x86_64-linux";
      stateVersion = host.stateVersion or "25.11";
      displays = host.displays or devices.display or {};
      functionalities = host.functionalities or [];
      boot = bootData;
      filesystems = devices.file or {};
      swap = devices.swap or [];
    };

    loader =
      if data.boot.loader == "systemd-boot"
      then {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      }
      else if data.boot.loader == "grub"
      then {
        grub = {
          enable = true;
          device = interface.grubDevice or "nodev";
          efiSupport = true;
          useOSProber = interface.osProber or false;
        };
        efi.canTouchEfiVariables = true;
      }
      else {}; #TODO: support other boot loaders
  in {
    options.${top}.system = mkOption {
      type = attrsOf anything;
      default = {};
      description = "Resolved host system metadata: hostname, id, description, form factor, OS class, platform, state version, display layout, enabled functionalities, boot configuration, filesystems, and swap devices.";
    };

    config =
      {${top}.system = data;}
      // (
        optionalAttrs (scope == "core")
        {
          networking.hostName = mkDefault data.name;
          system.stateVersion = mkDefault data.stateVersion;
          nixpkgs.hostPlatform = mkDefault data.platform;
        }
        // (
          optionalAttrs (interface != {}) {
            boot.loader =
              loader
              // (
                optionalAttrs
                (data.boot.timeout != null)
                {timeout = data.boot.timeout;}
              );
          }
        )
        // (
          optionalAttrs (data.filesystems != {} || data.swap != [] || data.boot.modules != [] || data.boot.luks != {}) {
            boot.initrd = {
              availableKernelModules = data.boot.modules;
              luks.devices = data.boot.luks;
            };
            fileSystems = data.filesystems;
            swapDevices = data.swap;
          }
        )
      );
  };
in {
  core = mk "core";
  home = mk "home";
}
