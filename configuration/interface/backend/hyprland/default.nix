{
  lix,
  top,
  path,
  mkUWSM,
  ...
}: let
  name = "hyprland";
  prettyName = "Hyprland";
  bin = prettyName;

  inherit (lix.lists) elem;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) enum;

  mk = {
    scope,
    config,
  }:
    mkModuleArgs {inherit top path config scope;};
in {
  core = {
    config,
    host,
    ...
  }: let
    scope = "core";
    inherit (mk {inherit config scope;}) cfg opt;
  in {
    options = opt {
      enable = mkEnable {
        name = prettyName;
        default = elem name ((host.interface or {}).managers or []);
      };
      withUWSM = mkEnable {
        description = "launching ${prettyName} through UWSM";
        default = cfg.enable;
      };
    };

    config = {
      programs = {
        ${name} = {inherit (cfg) enable withUWSM;};
        uwsm.waylandCompositors = mkIf cfg.enable {${name} = mkUWSM {inherit name prettyName bin;};};
      };
    };
  };

  home = {
    config,
    user,
    ...
  }: let
    scope = "home";
    inherit (mk {inherit config scope;}) cfg opt;
  in {
    options = opt {
      enable = mkEnable {
        inherit scope;
        name = prettyName;
        default = elem name ((user.interface or {}).managers or []);
      };
      configType = mkOption {
        type = enum ["hyprlang" "lua"];
        default = "hyprlang";
        description = "Home Manager Hyprland configuration format.";
      };
    };
    config.wayland.windowManager.${name} = {
      inherit (cfg) enable configType;
    };
  };
}
