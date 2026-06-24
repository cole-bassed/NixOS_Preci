{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.api) getAdminUsers;
  inherit (lix.attrsets) attrValues optionalAttrs;
  inherit (lix.lists) elem elemAt length;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkEnableOption mkOption;
  inherit (lix.types) enum nullOr str;

  args = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};

  has = value: list:
    elem value list;

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

  getEnvironment = spec:
    (spec.interface or {}).environment
    or (spec.interface or {}).session
    or {};

  hostEnvironment =
    (host.interface or {}).environment
    or (host.interface or {}).session
    or {};

  ordered = user: let
    env =
      if user == null
      then {}
      else getEnvironment user;
  in
    (env.managers or [])
    ++ (env.desktops or [])
    ++ (hostEnvironment.managers or [])
    ++ (hostEnvironment.desktops or []);

  entry = name:
    registry.managers.${name}
    or registry.desktops.${name}
    or {};

  sessionName = name:
    if name == null
    then null
    else login.sessions.${name} or (entry name).session or name;

  preferred = user:
    first (ordered user);

  defaultSession = user:
    sessionName (preferred user);

  managerFor = environment: let
    names = environment.managers ++ environment.desktops;
    name = first names;
  in
    login.manager
    or host.interface.displayManager
    or (
      if name != null
      then (entry name).login or "regreet"
      else "none"
    );

  opts = manager: session: {
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
      default = session;
      description = "Default graphical session selected by the display manager.";
    };

    autoLogin = {
      enable =
        mkEnableOption "automatic login"
        // {default = auto.enable;};

      user = mkOption {
        type = nullOr str;
        default = auto.user;
        description = "User to automatically log in when autologin is enabled.";
      };
    };
  };

  mk = scope: {config, ...}: let
    inherit ((args config scope)) cfg opt;
    env = config.${top}.${dom}.environment;
    user = userByName auto.user;
    session = login.defaultSession or (defaultSession user);
  in {
    options = opt (opts (managerFor env) session);

    config = optionalAttrs (scope == "core") {
      services = {
        displayManager = mkIf (cfg.manager != "none") {
          gdm.enable = cfg.manager == "gdm";
          sddm.enable = cfg.manager == "sddm";

          defaultSession =
            mkIf
            (cfg.defaultSession != null)
            cfg.defaultSession;

          autoLogin = mkIf cfg.autoLogin.enable {
            enable = true;
            user = cfg.autoLogin.user;
          };
        };

        xserver = {
          displayManager.lightdm.enable = cfg.manager == "lightdm";
        };

        greetd = mkIf (cfg.manager == "greetd" || cfg.manager == "regreet") {
          enable = true;
        };
      };

      programs = {
        regreet.enable = cfg.manager == "regreet";
      };
    };
  };
in {
  core = mk "core";
  home = mk "home";
}
