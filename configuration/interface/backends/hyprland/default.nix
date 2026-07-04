{
  lix,
  path,
  mkArgs,
  mkEnable,
  ...
}: let
  inherit (lix.modules) mkCfgIf;
  inherit (lix.options) mkOption;
  inherit (lix.types) enum;

  inherit (lix.lists) length elemAt;
  inherit (lix.strings) optionalString;
  getName = path: let
    len = length path;
    lastElem = elemAt path (len - 1);
  in
    optionalString (len > 0) lastElem;
  name = getName path;
in {
  core = {config, ...}: let
    scope = "core";
    inherit (mkArgs {inherit config path scope;}) opt cfg;
  in {
    options = opt (mkEnable {inherit path config scope;});
    config = mkCfgIf {inherit cfg;} {
      programs.${name} = {inherit (cfg) enable withUWSM;};
    };
  };

  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config path scope;}) opt cfg;
  in {
    options = opt (
      (mkEnable {inherit config scope;})
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
