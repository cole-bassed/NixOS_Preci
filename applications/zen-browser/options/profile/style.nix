{
  lib,
  top,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) str;

  dom = "applications";
  mod = "zen-browser";
in {
  options.${top}.${dom}.${mod}.profile.userChrome = mkOption {
    type = str;
    default = ''
      #navigator-toolbox {
        background-color: #2b2b2b;
      }

      #TabsToolbar {
        min-height: 28px;
      }

      .tab-icon-image {
        width: 16px;
        height: 16px;
      }
    '';
    description = "Custom userChrome.css content for Zen UI customization.";
  };
}
