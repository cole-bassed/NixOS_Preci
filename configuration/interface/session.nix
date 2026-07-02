{
  lix,
  top,
  host,
  dom,
  mod,
  registry,
  resolveBackends,
  ...
}: let
  inherit (lix.api) getAdminUsers;
  inherit (lix.attrsets) attrValues;
  inherit (lix.lists) elem elemAt length;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkEnableOption mkOption;
  inherit (lix.types) enum nullOr str;

  args = config: scope: mkModuleArgs {inherit config top dom mod scope;};

  first = list:
    if length list > 0
    then elemAt list 0
    else null;

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

  userByName = name:
    if name == null
    then null
    else host.users.values.${name} or null;

  # Resolved backends for a spec
  resolved = spec:
    resolveBackends {
      inherit registry;
      spec = spec;
    };

  # Primary backend from resolved list
  primaryBackend = spec: first (resolved spec);

  sessionName = env:
    if env == null
    then null
    else login.sessions.${env.name} or env.session or env.name;

  defaultSession = spec: sessionName (primaryBackend spec);

  displayManagerFor = spec: let
    env = primaryBackend spec;
  in
    login.manager or host.interface.displayManager or (
      if env != null
      then env.greeter or "regreet"
      else "none"
    );

  opts = manager: session: {
    manager = mkOption {
      type = enum ["none" "dms" "gdm" "sddm" "greetd" "regreet" "lightdm"];
      default = manager;
      description = "Display manager or greeter used to start graphical sessions.";
    };
    defaultSession = mkOption {
      type = nullOr str;
      default = session;
      description = "Default graphical session selected by the display manager.";
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

  dmsCompositors = ["hyprland" "niri" "sway"];

  mk = scope: {config, ...}: let
    inherit ((args config scope)) cfg opt;
    user = userByName auto.user;
    session = login.defaultSession or (defaultSession host);
    greeter = cfg.manager;
    compositor = let
      pref = primaryBackend host;
    in
      if pref != null && elem pref.name dmsCompositors
      then pref.name
      else null;
  in {
    options = opt (opts (displayManagerFor host) session);

    config =
      if scope == "core"
      then {
        assertions = [
          {
            assertion = (greeter != "dms") || compositor != null;
            message = "DMS greeter requires a supported compositor (hyprland, niri, or sway) from the selected interface backend.";
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
