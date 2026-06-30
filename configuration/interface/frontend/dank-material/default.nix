{
  lix,
  top,
  host,
  dom,
  mod,
  packages,
  ...
}: let
  inherit (lix.lists) elem;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) enum nullOr;

  hostInterface = host.interface or {};

  args = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};

  compositors = [
    "hyprland"
    "niri"
    "sway"
  ];

  mk = scope: {
    config,
    pkgs,
    ...
  }: let
    inherit ((args config scope)) cfg opt;
    frontend = hostInterface.frontend or null;
    backend = hostInterface.windowManager or hostInterface.desktopEnvironment or null;

    enable = {enable = cfg.frontend == "dms";};
    hasNiri = config.programs.niri.enable or false;
  in {
    options = opt {
      frontend = mkOption {
        type = nullOr (enum ["dms" "noctalia" "caelestia" "gnome" "plasma" "cosmic"]);
        default = frontend;
        description = "Graphical frontend layer for the selected desktop session backend.";
      };
    };

    config =
      if scope == "core"
      then {
        assertions = [
          {
            assertion = cfg.frontend == null || backend != null;
            message = "interface.frontend requires an active interface.windowManager or interface.desktopEnvironment.";
          }
          {
            assertion = !(elem cfg.frontend ["dms" "noctalia" "caelestia"]) || config.${top}.interface.protocol.wayland;
            message = "The selected interface.frontend requires a Wayland session.";
          }
          {
            assertion = cfg.frontend != "dms" || (backend != null && elem backend compositors);
            message = "The dms frontend requires a supported compositor (hyprland, niri, or sway).";
          }
          {
            assertion = cfg.frontend != "gnome" || backend == "gnome";
            message = "interface.frontend = \"gnome\" requires interface.desktopEnvironment = \"gnome\".";
          }
          {
            assertion = cfg.frontend != "plasma" || backend == "plasma";
            message = "interface.frontend = \"plasma\" requires interface.desktopEnvironment = \"plasma\".";
          }
          {
            assertion = cfg.frontend != "cosmic" || backend == "cosmic";
            message = "interface.frontend = \"cosmic\" requires the active backend to be cosmic.";
          }
        ];

        programs.dms-shell = {
          inherit enable;
        };
      }
      else {
        programs.dms-shell = {
          inherit enable;
          dgop.package = packages.dgop pkgs;
          quickshell.package = packages.quickshell pkgs;
          niri = {
            enableKeybinds = hasNiri;
            enableSpawn = hasNiri;
          };
        };
      };
  };
in {
  core = mk "core";
  home = mk "home";
}
