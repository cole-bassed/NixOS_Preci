{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption;
  inherit (lib.types) bool listOf str;

  dom = "applications";
  mod = "keyd";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "keyd keyboard remapping profile";

    ids = mkOption {
      type = listOf str;
      default = [""];
      description = ''
        keyd keyboard ids to target. The current default preserves the previous
        temporary global fallback until the RK71-specific device id is known.
      '';
    };

    remapCapsLockToEscape = mkOption {
      type = bool;
      default = true;
      description = "Whether this profile maps Caps Lock to Escape.";
    };
  };

  config = mkIf cfg.enable {
    services = {
      keyd = {
        enable = mkDefault true;
        keyboards.default = {
          # TODO: Replace this temporary global fallback with an RK71-specific
          # device id once it is known. The RK71 needs Caps Lock as Escape, but
          # the CIDOO keyboard already handles that in hardware.
          ids = mkDefault cfg.ids;
          settings = mkIf cfg.remapCapsLockToEscape {
            main = {
              capslock = mkDefault "esc";
            };
          };
        };
      };
    };
  };
}
