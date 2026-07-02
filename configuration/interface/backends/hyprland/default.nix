{
  lix,
  path,
  mkArgs,
  mkEnable,
  ...
}: let
  name = "hyprland";
  prettyName = "Hyprland";

  inherit (lix.modules) mkCfgIf;
  inherit (lix.options) mkOption;
  inherit (lix.types) enum;
in {
  core = {config, ...}: let
    scope = "core";
    inherit (mkArgs {inherit config path scope;}) opt cfg;
  in {
    options = opt (mkEnable {inherit name prettyName config scope;});
    config = mkCfgIf {inherit cfg;} {
      programs.${name} = {inherit (cfg) enable withUWSM;};
    };
  };

  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config path scope;}) opt cfg;
  in {
    options = opt (
      (mkEnable {inherit name prettyName config scope;})
      // {
        configType = mkOption {
          type = enum ["hyprlang" "lua"];
          default = "hyprlang";
          description = "Home Manager Hyprland configuration format.";
        };
      }
    );
    config.wayland.windowManager = mkCfgIf {inherit cfg;} {
      ${name} = {inherit (cfg) enable configType;};
    };
  };
}
