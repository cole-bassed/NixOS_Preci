{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.api) getAdminUsers;
  inherit (lix.attrsets) attrValues;
  inherit (lix.lists) elem elemAt length;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkEnableOption mkOption;
  inherit (lix.types) enum nullOr str;

  args = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};

  hostLogin = (host.interface or {}).login or {};

  primary = host.users.primary.value or null;

  admins = attrValues (getAdminUsers host);

  fallbackAdmin =
    if primary != null && (primary.role or "") == "administrator"
    then primary
    else if length admins > 0
    then elemAt admins 0
    else primary;

  fallbackUser =
    if fallbackAdmin != null
    then fallbackAdmin.name
    else null;

  autoLoginUser =
    hostLogin.autoLogin.user or fallbackUser;

  autoLoginEnable =
    hostLogin.autoLogin.enable or false;

  has = value: list:
    elem value list;

  getSession = spec:
    (spec.interface or {}).session
    or (spec.interface or {}).environment
    or {};

  hostSession =
    (host.interface or {}).session
    or (host.interface or {}).environment
    or {};

  userByName = name:
    if name == null
    then null
    else (host.users.values.${name} or null);

  orderedSessions = user: let
    userSession =
      if user == null
      then {}
      else getSession user;
  in
    (userSession.managers or [])
    ++ (userSession.desktops or [])
    ++ (hostSession.managers or [])
    ++ (hostSession.desktops or []);

  firstOrNull = list:
    if length list > 0
    then elemAt list 0
    else null;

  sessionFiles =
    hostLogin.sessions or {};

  toSessionName = name:
    if name == null
    then null
    else sessionFiles.${name} or name;

  defaultSessionFor = user:
    toSessionName (firstOrNull (orderedSessions user));

  opts = manager: defaultSession: {
    manager = mkOption {
      type = enum [
        "none"
        "gdm"
        "sddm"
        "greetd"
        "regreet"
        "lightdm"
      ];
      default = manager;
      description = "Display manager or greeter used to start graphical sessions.";
    };

    defaultSession = mkOption {
      type = nullOr str;
      default = defaultSession;
      description = "Default graphical session selected by the display manager.";
    };

    autoLogin = {
      enable =
        mkEnableOption "automatic login"
        // {default = autoLoginEnable;};

      user = mkOption {
        type = nullOr str;
        default = autoLoginUser;
        description = "User to automatically log in when autologin is enabled.";
      };
    };
  };
in {
  core = {config, ...}: let
    inherit ((args config "core")) cfg opt;

    session = config.${top}.${dom}.session;
    loginUser = userByName autoLoginUser;

    manager =
      hostLogin.manager
      or host.interface.displayManager
      or (
        if has "gnome" session.desktops
        then "gdm"
        else if has "plasma" session.desktops
        then "sddm"
        else if session.managers != []
        then "regreet"
        else "none"
      );

    defaultSession = hostLogin.defaultSession
      or defaultSessionFor loginUser;
  in {
    options = opt (opts manager defaultSession);

    config = {
      services = {
        displayManager = mkIf (cfg.manager != "none") {
          gdm.enable = cfg.manager == "gdm";
          sddm.enable = cfg.manager == "sddm";

          defaultSession = mkIf (cfg.defaultSession != null) cfg.defaultSession;

          autoLogin = mkIf cfg.autoLogin.enable {
            enable = true;
            user = cfg.autoLogin.user;
          };
        };

        xserver.displayManager.lightdm.enable = cfg.manager == "lightdm";

        greetd = mkIf (cfg.manager == "greetd" || cfg.manager == "regreet") {
          enable = true;
        };
      };

      programs.regreet.enable = cfg.manager == "regreet";
    };
  };

  home = {config, ...}: let
    inherit ((args config "home")) opt;
  in {
    options = opt {};
    config = {};
  };
}
