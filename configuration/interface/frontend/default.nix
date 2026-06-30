{
  inputs ? {},
  lib,
  lix,
  top,
  host,
  dom,
  mod,
  registry,
  ...
}: let
  inherit (lix.lists) elem;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) enum nullOr;

  hostInterface = host.interface or {};

  waylandBackends = [
    "hyprland"
    "labwc"
    "mango"
    "niri"
    "river"
    "sway"
    "wayfire"
    "gnome"
    "plasma"
    "cosmic"
  ];

  args = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};

  dmsCompositors = [
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
    system = pkgs.stdenv.hostPlatform.system;
    quickshell =
      if registry ? quickshell.packages.${system}
      then {quickshell.package = registry.quickshell.packages.${system}.default;}
      else {};
    noctaliaPackage =
      if pkgs ? noctalia
      then pkgs.noctalia
      else if registry ? noctalia.packages.${system}
      then registry.noctalia.packages.${system}.default
      else inputs.noctalia.packages.${system}.default;
    caelestiaPackage =
      if registry ? "caelestia-shell".packages.${system}
      then registry."caelestia-shell".packages.${system}.default
      else inputs."caelestia-shell".packages.${system}.default;
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
            assertion = cfg.frontend != "dms" || (backend != null && elem backend dmsCompositors);
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

        programs.dms-shell = mkIf (cfg.frontend == "dms") ({enable = true;} // quickshell);
      }
      else lib.mkMerge [
        (mkIf (cfg.frontend == "dms") {
          programs.dank-material-shell = {enable = true;} // quickshell;
        })
        (mkIf (cfg.frontend == "noctalia") {
          programs.noctalia = {
            enable = true;
            package = noctaliaPackage;
            systemd.enable = true;
          };
        })
        (mkIf (cfg.frontend == "caelestia") {
          programs.caelestia = {
            enable = true;
            package = caelestiaPackage;
            systemd.enable = true;
          };
        })
      ];
  };
in {
  core = mk "core";
  home = mk "home";
}