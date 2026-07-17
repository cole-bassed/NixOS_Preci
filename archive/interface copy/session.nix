{
  lix,
  top,
  host,
  api,
  path,
  ...
} @ args: let
  inherit (lix.api) getAdminUsers;
  inherit (lix.api.interface) mkSessions;
  inherit (lix.attrsets) attrValues parseOrdered;
  inherit (lix.lists) elem elemAt length map;
  inherit (lix.modules) mkIf mkModuleArgs;
  inherit (lix.options) mkEnableOption mkOption;
  inherit (lix.types) attrs enum nullOr str;

  login = (host.interface or {}).login or {};
  primary = host.users.primary.value or null;
  admins = attrValues (getAdminUsers host);

  fallback = {
    admin =
      if primary != null && (primary.role or "") == "administrator"
      then primary
      else if length admins > 0
      then elemAt admins 0
      else primary;
    user =
      if fallback.admin != null
      then fallback.admin.name
      else null;
  };

  auto = {
    enable = login.autoLogin.enable or false;
    user = login.autoLogin.user or fallback.user;
  };

  greeterValues = map (env: env.greeter or "none") (attrValues api.interfaceRegistry);
  managerEnumValues = ["none" "dms" "regreet"] ++ greeterValues;

  dmsCompositors = ["hyprland" "niri" "sway"];

  mk = scope: {config, ...}: let
    mod = mkModuleArgs (args // {inherit config scope;});
    inherit (mod) get set;
    inherit (get) cfg;

    registry = get.config.domain.registry or {};
    sessions = mkSessions {inherit host registry;};

    resolveEntry = entry: registry.${entry.name or ""} or entry;
    # active = map resolveEntry rawActive;
    # parsed = parseOrdered active;
    # default = parsed.primary or null;
    # compositor =
    #   if default != null && elem (default.name or "") dmsCompositors
    #   then default.name
    #   else null;
  in {
    options = set.opt {
      others = mkOption {
        type = attrs;
        default = removeAttrs sessions [
          "default"
          "fallback"
          "preferred"
          "1"
          "2"
          "3"
          "primary"
          "secondary"
          "tertiary"
        ];
        description = "All active interface sessions, tiered by priority (.primary/.secondary/.../.default/.preferred/.fallback).";
      };

      primary = mkOption {
        type = nullOr attrs;
        default = sessions.primary or null;
        description = "The default/preselected session -- `active.primary`.";
      };

      secondary = mkOption {
        type = nullOr attrs;
        default = sessions.secondary or null;
        description = "The default/preselected session -- `active.primary`.";
      };

      tertiary = mkOption {
        type = nullOr attrs;
        default = sessions.tertiary or null;
        description = "The default/preselected session -- `active.primary`.";
      };

      greeter = mkOption {
        type = nullOr (enum managerEnumValues);
        default = cfg.primary.greeter or null;
        description = "Display manager or greeter used to start graphical sessions.";
      };

      defaultSession = mkOption {
        type = nullOr str;
        default = cfg.primary.name or null;
        description = "Default graphical session name selected by the display manager.";
      };

      autoLogin = {
        enable = mkEnableOption "automatic login" // {default = auto.enable;};
        user = mkOption {
          type = nullOr str;
          default = auto.user;
          description = "User to automatically log in when autologin is enabled.";
        };
      };
    };

    config =
      if scope == "core"
      then {
        assertions = [
          {
            assertion = (cfg.manager != "dms") || compositor != null;
            message = "DMS greeter requires a supported compositor (hyprland, niri, or sway) as the default interface session.";
          }
        ];
        programs.regreet.enable = cfg.greeter == "regreet";
        services = {
          displayManager = mkIf (cfg.greeter != "none") {
            gdm.enable = cfg.greeter == "gdm";
            sddm.enable = cfg.greeter == "sddm";
            dms-greeter = mkIf (cfg.greeter == "dms") {
              enable = true;
              compositor.name = compositor;
            };
            autoLogin = mkIf cfg.autoLogin.enable {
              enable = true;
              user = cfg.autoLogin.user;
            };
          };
          xserver.displayManager.lightdm.enable = cfg.greeter == "lightdm";
          greetd = mkIf (elem cfg.greeter ["dms" "greetd" "regreet"]) {enable = true;};
        };
      }
      else {};
  };
in {
  core = mk "core";
  home = mk "home";
}
