{
  lix,
  lib,
  top,
  dom,
  mod,
  ...
}: let
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) listOf str;
  inherit (lix) mkModuleArgs;
in {
  core = {config, ...}: let
    inherit (mkModuleArgs {inherit config top dom mod;}) cfg opt mkEnableMod;
  in {
    options = opt {
      enable = mkEnableMod.false;

      ids = mkOption {
        type = listOf str;
        default = ["*"];
        description = ''
          keyd keyboard ids to target. The current default keeps the temporary
          global fallback active until the RK71-specific device id is known.
        '';
      };

      capsAsEsc =
        mkEnableMod.true
        // {
          description = ''
            Whether CapsLock maps to Escape.

            device id once it is known. The RK71 needs Caps Lock as Escape, but
            the CIDOO keyboard already handles that in hardware.
          '';
        };

      metaTap =
        mkEnableMod.true
        // {
          description = ''
            Whether Super+Z is registerd as Left Meta
            tap Super  → send Super+Z  (caught by niri as Mod+Z → vicinae open)
            hold Super → Super modifier (all other Mod+* binds unaffected)
          '';
        };
    };

    config = mkIf cfg.enable {
      services.keyd = {
        enable = mkDefault true;
        keyboards.default = {
          ids = mkDefault cfg.ids;
          settings.main = {
            # TODO: Replace this temporary global fallback with an RK71-specific
            capslock = mkIf cfg.capsAsEsc (mkDefault "esc");
            leftmeta = mkIf cfg.metaTap "overload(meta, macro(leftmeta+z))";
          };
        };
      };
    };
  };
}
