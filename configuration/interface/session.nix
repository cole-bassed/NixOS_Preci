{
  lix,
  top,
  host,
  api,
  path,
  ...
} @ args: let
  inherit (lix.api) getAdminUsers;
  inherit (lix.attrsets) attrValues;
  inherit (lix.lists) elem elemAt length;
  inherit (lix.modules) mkIf mkModuleArgs;
  inherit (lix.options) mkEnableOption mkOption;
  inherit (lix.types) attrs enum listOf nullOr str;

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

  sessions = api.interface.mkSessions {
    user = fallback.admin;
    inherit host;
  };
  default = api.interface.mkDefaultSession {
    user = fallback.admin;
    inherit host;
  };

  defaultSessionName =
    if (default ? name && default.name != null)
    then
      (
        let
          inherit (default) name;
        in
          login.sessions.${name} or (default.session or name)
      )
    else null;

  displayManager = host.interface.greeter or (default.greeter or "regreet");
  greeterValues = map (env: env.greeter or "none") (attrValues api.interfaceRegistry);
  managerEnumValues = ["none" "dms" "regreet"] ++ greeterValues;
  dmsCompositors = ["hyprland" "niri" "sway"];

  mk = scope: {config, ...}: let
    mod = mkModuleArgs (args // {inherit config scope;});
    inherit (mod) get set;
    cfg = get.config.module;
    greeter = cfg.manager;
    compositor =
      if default != null && elem (default.name or "") dmsCompositors
      then default.name
      else null;
  in {
    options = set.opt {
      active = mkOption {
        type = listOf attrs;
        default = sessions;
        description = "All active interface sessions (environments) for this host/user, in priority order.";
      };

      autoLogin = {
        enable = mkEnableOption "automatic login" // {default = auto.enable;};
        user = mkOption {
          type = nullOr str;
          default = auto.user;
          description = "User to automatically log in when autologin is enabled.";
        };
      };

      default = mkOption {
        type = nullOr attrs;
        default = default;
        description = "The default/preselected session -- the top entry in `sessions`.";
      };

      defaultSession = mkOption {
        type = nullOr str;
        default = defaultSessionName;
        description = "Default graphical session selected by the display manager.";
      };

      manager = mkOption {
        type = enum managerEnumValues;
        default = displayManager;
        description = "Display manager or greeter used to start graphical sessions.";
      };
    };

    config =
      if scope == "core"
      then {
        assertions = [
          {
            assertion = (greeter != "dms") || compositor != null;
            message = "DMS greeter requires a supported compositor (hyprland, niri, or sway) as the default interface session.";
          }
        ];
        programs.regreet.enable = greeter == "regreet";
        services = {
          displayManager = mkIf (greeter != "none") {
            gdm.enable = greeter == "gdm";
            sddm.enable = greeter == "sddm";
            dms-greeter = mkIf (greeter == "dms") {
              enable = true;
              compositor.name = compositor;
            };
            autoLogin = mkIf cfg.autoLogin.enable {
              enable = true;
              user = cfg.autoLogin.user;
            };
          };
          xserver.displayManager.lightdm.enable = greeter == "lightdm";
          greetd = mkIf (elem greeter ["dms" "greetd" "regreet"]) {enable = true;};
        };
      }
      else {};
  };
in {
  core = mk "core";
  home = mk "home";
}
