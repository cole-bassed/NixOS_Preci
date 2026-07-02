{
  lix,
  top,
  host,
  path,
  ...
}: let
  inherit (lix.attrsets) attrNames;
  inherit (lix.lists) elem elemAt isList length;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) enum nullOr;

  args = config: scope: mkModuleArgs {inherit config top path scope;};

  hostInterface = host.interface or {};

  # Get primary backend name from host
  primaryBackend = host: let
    raw = (host.interface or {}).backends or [];
  in
    if isList raw
    then
      (
        if length raw > 0
        then elemAt raw 0
        else null
      )
    else if raw != {}
    then elemAt (attrNames raw) 0
    else null;

  compositors = ["hyprland" "niri" "sway"];

  mk = scope: {config, ...}: let
    inherit ((args config scope)) cfg opt;
    frontend = hostInterface.frontend or null;
    backend = primaryBackend host;
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
            message = "interface.frontend requires an active interface.backend.";
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
            message = "interface.frontend = \"gnome\" requires interface.backend to include \"gnome\".";
          }
          {
            assertion = cfg.frontend != "plasma" || backend == "plasma";
            message = "interface.frontend = \"plasma\" requires interface.backend to include \"plasma\".";
          }
          {
            assertion = cfg.frontend != "cosmic" || backend == "cosmic";
            message = "interface.frontend = \"cosmic\" requires the active backend to be cosmic.";
          }
        ];

        programs.dms-shell = {
          enable = {enable = cfg.frontend == "dms";};
        };
      }
      else {
        programs.dank-material-shell = {
          enable = {enable = cfg.frontend == "dms";};
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
