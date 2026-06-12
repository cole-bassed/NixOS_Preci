{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) listOf str enum;
  inherit (lix.lists) hasAny;

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;

    funcs = host.functionalities or [];
    hasFunc = f: builtins.elem f funcs;
  in {
    options = opt {
      enable = mkEnableMod.true;
      items = mkOption {
        type = listOf str;
        default = funcs;
        description = "System functionalities to enable.";
      };
    };

    config = mkIf enable (
      if scope == "core"
      then {
        # Audio
        services.pipewire = mkIf (hasFunc "audio") {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };

        # Battery / Power
        services.power-profiles-daemon = mkIf (hasFunc "battery") {
          enable = true;
        };
        services.upower = mkIf (hasFunc "battery") {
          enable = true;
        };

        # Bluetooth
        hardware.bluetooth = mkIf (hasFunc "bluetooth") {
          enable = true;
          powerOnBoot = true;
        };
        services.blueman = mkIf (hasFunc "bluetooth") {
          enable = true;
        };

        # Dual-boot Windows
        time.hardwareClockInLocalTime = mkIf (hasFunc "dualboot-windows") true;

        # EFI
        boot.loader.efi.canTouchEfiVariables = mkIf (hasFunc "efi") true;

        # GPU
        hardware.graphics = mkIf (hasFunc "gpu") {
          enable = true;
          # Video (acceleration)
          enable32Bit = mkIf (hasFunc "video") true;
        };

        # Keyboard
        services.xserver.xkb = mkIf (hasFunc "keyboard") {
          layout = "us";
        };

        # Network
        networking.networkmanager = mkIf (hasFunc "network") {
          enable = true;
        };

        # NVMe
        services.fstrim = mkIf (hasFunc "nvme") {
          enable = true;
        };

        # Remote (SSH)
        services.openssh = mkIf (hasFunc "remote") {
          enable = true;
          openFirewall = true;
        };

        # Secure Boot
        # Requires lanzaboote or similar - placeholder
        # boot.lanzaboote = mkIf (hasFunc "secureboot") { enable = true; };

        # Storage (udisks2)
        services.udisks2 = mkIf (hasFunc "storage") {
          enable = true;
          mountOnMedia = true;
        };

        # Touchpad
        services.libinput = mkIf (hasFunc "touchpad") {
          enable = true;
        };

        # TPM
        security.tpm2 = mkIf (hasFunc "tpm") {
          enable = true;
        };

        # Virtualization
        virtualisation.libvirtd = mkIf (hasFunc "virtualization") {
          enable = true;
        };
        programs.virt-manager = mkIf (hasFunc "virtualization") {
          enable = true;
        };

        # VPN
        services.tailscale = mkIf (hasFunc "vpn") {
          enable = true;
          openFirewall = true;
        };

        # Webcam
        # Typically no explicit config needed, hardware auto-detected

        # Wired
        networking.useDHCP = mkIf (hasFunc "wired") true;

        # Wireless
        networking.wireless = mkIf (hasFunc "wireless") {
          enable = true;
        };
      }
      else {}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
