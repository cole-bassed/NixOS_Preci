{
  lib,
  pkgs,
  top,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool enum listOf package str;

  dom = "applications";
  mod = "zen-browser";
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "Zen Browser Home Manager profile";

    channel = mkOption {
      type = enum ["beta" "twilight" "twilight-official"];
      default = "twilight";
      description = "Zen Browser release channel/package to use.";
    };

    setAsDefaultBrowser = mkOption {
      type = bool;
      default = true;
      description = "Whether Zen should be set as the default browser by the upstream module.";
    };

    nativeMessagingHosts = mkOption {
      type = listOf package;
      default = [pkgs.firefoxpwa];
      description = "Native messaging host packages exposed to Zen.";
    };

    profile.name = mkOption {
      type = str;
      default = "default";
      description = "Zen profile name to configure.";
    };
  };
}
