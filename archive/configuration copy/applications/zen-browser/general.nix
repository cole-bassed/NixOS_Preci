{
  lib,
  packages,
  mkArgs,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) bool enum listOf package str;
in {
  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config scope;}) opt mkEnableMod;
  in {
    options = opt {
      enable = mkEnableMod.false;
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
        default = [packages.firefoxpwa];
        description = "Native messaging host packages exposed to Zen.";
      };
      profile.name = mkOption {
        type = str;
        default = "default";
        description = "Zen profile name to configure.";
      };
    };
  };
}
