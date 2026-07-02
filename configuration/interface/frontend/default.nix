{
  lix,
  top,
  host,
  ...
}: let
  inherit (lix.attrsets) attrNames;
  inherit (lix.lists) elem elemAt isList;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) enum nullOr;

  args = config: scope:
    mkModuleArgs {
      inherit config top scope;
      path = ["interface"];
    };

  hostInterface = host.interface or {};
  backend = host.interface.backends or [];
  primaryBackend = firstBackend backend;

  # Get first backend name
  firstBackend = raw:
    if isList raw
    then
      if raw == []
      then null
      else elemAt raw 0
    else if raw != {}
    then elemAt (attrNames raw) 0
    else null;

  compositors = ["hyprland" "niri" "sway"];
in {
  core = {config, ...}: let
    inherit ((args config "core")) cfg opt;
  in {
    options = opt {
      frontend = mkOption {
        type = nullOr (enum ["dms" "noctalia" "caelestia" "gnome" "plasma" "cosmic"]);
        default = hostInterface.frontend or null;
        description = "Graphical frontend layer for the selected desktop session backend.";
      };
    };

    config = {
      assertions = [
        {
          assertion = cfg.frontend == null || primaryBackend != null;
          message = "interface.frontend requires an active interface.backend.";
        }
        {
          assertion = !(elem cfg.frontend ["dms" "noctalia" "caelestia"]) || config.${top}.interface.protocol.wayland;
          message = "The selected interface.frontend requires a Wayland session.";
        }
        {
          assertion = cfg.frontend != "dms" || (primaryBackend != null && elem primaryBackend compositors);
          message = "The dms frontend requires a supported compositor (hyprland, niri, or sway).";
        }
        {
          assertion = cfg.frontend != "gnome" || primaryBackend == "gnome";
          message = "interface.frontend = \"gnome\" requires interface.backend to include \"gnome\".";
        }
        {
          assertion = cfg.frontend != "plasma" || primaryBackend == "plasma";
          message = "interface.frontend = \"plasma\" requires interface.backend to include \"plasma\".";
        }
        {
          assertion = cfg.frontend != "cosmic" || primaryBackend == "cosmic";
          message = "interface.frontend = \"cosmic\" requires the active backend to be cosmic.";
        }
      ];

      programs.dms-shell = {
        enable = {enable = cfg.frontend == "dms";};
      };
    };
  };

  home = {config, ...}: let
    inherit ((args config "home")) cfg opt;
    hasNiri = config.programs.niri.enable or false;
  in {
    options = opt {
      frontend = mkOption {
        type = nullOr (enum ["dms" "noctalia" "caelestia" "gnome" "plasma" "cosmic"]);
        default = hostInterface.frontend or null;
        description = "Graphical frontend layer for the selected desktop session backend.";
      };
    };

    config = {
      programs.dank-material-shell = {
        enable = {enable = cfg.frontend == "dms";};
        niri = {
          enableKeybinds = hasNiri;
          enableSpawn = hasNiri;
        };
      };
    };
  };
}
