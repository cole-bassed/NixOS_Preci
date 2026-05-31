{
  config,
  lib,
  top,
  ...
}: let
  dom = "interface";
  mod = "keyd";
  cfg = config.${top}.${dom}.${mod};

  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) listOf str;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "keyd keyboard remapping profile";

    ids = mkOption {
      type = listOf str;
      default = ["*"];
      description = ''
        keyd keyboard ids to target. The current default keeps the temporary
        global fallback active until the RK71-specific device id is known.
      '';
    };

    capsAsEsc =
      mkEnableOption ''
        Whether CapsLock maps to Escape.

        device id once it is known. The RK71 needs Caps Lock as Escape, but
        the CIDOO keyboard already handles that in hardware.
      ''
      // {default = true;};

    metaTap =
      mkEnableOption ''
        Whether Super+Z is registerd as Left Meta
        tap Super  → send Super+Z  (caught by niri as Mod+Z → vicinae open)
        hold Super → Super modifier (all other Mod+* binds unaffected)
      ''
      // {default = true;};
  };

  config = mkIf cfg.enable {
    services.keyd = {
      enable = mkDefault true;
      keyboards.default = {
        ids = mkDefault cfg.ids;
        settings.main = with cfg; {
          # TODO: Replace this temporary global fallback with an RK71-specific
          capslock = mkIf capsAsEsc (mkDefault "esc");
          leftmeta = mkIf metaTap "overload(meta, macro(leftmeta+z))";
        };
      };
    };
  };
}
