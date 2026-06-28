{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs recursiveUpdate;
  inherit (lix.lists) elem foldl';
  inherit (lix.modules) mkDefault;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) listOf str;

  data = host.services or [];

  opts = mkOption {
    type = listOf str;
    default = [];
    description = "Additional service modules to import and enable. See schema S11.";
  };

  mkArgs = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};

  merge = parts: foldl' recursiveUpdate {} parts;

  #? Tag -> subsystem enablement, per schema S11's mapping table.
  #  `system` is the resolved ${top}.system config (from system.nix),
  #  consulted here for hardware context (e.g. GPU brand) that some
  #  tags need to pick the right driver. Each branch is deep-merged
  #  via `merge`, since multiple tags (e.g. "gpu" and "video") can
  #  both touch nested keys under the same top-level attribute
  #  (`hardware.graphics.*`) -- a shallow `//` chain would silently
  #  clobber one tag's contribution with another's.
  mkFunctionalities = system: tags: let
    has = tag: elem tag tags;
    gpu = system.specs.gpu or {};
    primaryBrand = gpu.primary.brand or null;
    secondaryBrand = gpu.secondary.brand or null;
    isNvidia = brand: brand == "nvidia";
  in
    merge [
      (optionalAttrs (has "audio") {
        security.rtkit.enable = true;
        services.pulseaudio.enable = false;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          pulse.enable = true;
        };
      })
      (optionalAttrs (has "battery") {
        services = {
          tlp.enable = true;
          upower.enable = true;
        };
      })
      (optionalAttrs (has "bluetooth") {
        hardware.bluetooth.enable = true;
        services.blueman.enable = true;
      })
      (optionalAttrs (has "efi") {
        boot.loader.efi.canTouchEfiVariables = true;
      })
      (optionalAttrs (has "gpu") {
        hardware.graphics.enable = true;
        hardware.nvidia = optionalAttrs (isNvidia primaryBrand || isNvidia secondaryBrand) {
          modesetting.enable = true;
        };
      })
      (optionalAttrs (has "keyboard") {
        services.keyd.enable = true;
      })
      (optionalAttrs (has "network") {
        networking.networkmanager.enable = true;
      })
      (optionalAttrs (has "secureboot") {
        boot.lanzaboote.enable = true;
      })
      (optionalAttrs (has "storage") {
        services.udisks2.enable = true;
      })
      (optionalAttrs (has "video") {
        hardware.graphics.enable32Bit = true;
      })
      (optionalAttrs (has "virtualization") {
        virtualisation.libvirtd.enable = true;
      })
      (optionalAttrs (has "wired") {
        networking.useDHCP = mkDefault true;
      })
      (optionalAttrs (has "wireless") {
        networking.wireless.enable = false; #? defer to networkmanager
      })
    ];

  #? Per-service config is intentionally minimal for now -- this is a
  #  stub: each named service is consulted for an `.enable` toggle
  #  only. Service-specific wiring (e.g. tailscale authKeyFile from
  #  secrets) belongs in a dedicated module once that need is sharper.
  mkServices = services:
    merge [
      (optionalAttrs (elem "tailscale" services) {
        services.tailscale.enable = true;
      })
      (optionalAttrs (elem "streaming" services) {
        #TODO: define what "streaming" actually enables
      })
    ];
in {
  core = {config, ...}: let
    inherit ((mkArgs config "core")) cfg opt;
    system = config.${top}.${dom}.system;
  in {
    options = opt opts;
    config = merge [
      {${top}.${dom}.${mod} = data;}
      (mkFunctionalities system system.functionalities)
      (mkServices cfg)
    ];
  };

  home = {config, ...}: let
    inherit ((mkArgs config "home")) opt;
  in {
    options = opt opts;
    config = {
      ${top}.${dom}.${mod} = data;
    };
  };
}
