{
  lix,
  top,
  host,
  path,
  mkUWSM,
  backendsOf,
  ...
}: let
  name = "hyprland";
  prettyName = "Hyprland";
  bin = prettyName;

  inherit (lix.lists) elem;
  inherit (lix.assembly) mkCfgIf;
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) enum;

  mk = {
    scope,
    config,
  }:
    mkModuleArgs {inherit top path config scope;};
in {
  core = {config, ...}: let
    scope = "core";
    inherit (mk {inherit config scope;}) cfg opt;
  in {
    options = opt {
      enable =
        (mkEnable {
          name = prettyName;
          default = elem name (backendsOf host);
        }).default;

      withUWSM =
        (mkEnable {
          description = "launching ${prettyName} through UWSM";
          default = cfg.enable;
        }).default;
    };

    config = mkCfgIf {inherit cfg;} {
      programs = {
        ${name} = {inherit (cfg) enable withUWSM;};
        uwsm.waylandCompositors = {
          ${name} = mkUWSM {inherit name prettyName bin;};
        };
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
      enable =
        (mkEnable {
          inherit scope;
          name = prettyName;
          default = elem name (backendsOf user);
        }).default;

      configType = mkOption {
        type = enum ["hyprlang" "lua"];
        default = "hyprlang";
        description = "Home Manager Hyprland configuration format.";
      };
    };
    config.wayland.windowManager = mkCfgIf {inherit cfg;} {
      ${name} = {inherit (cfg) enable configType;};
    };
  };
}
