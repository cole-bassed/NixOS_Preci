{
  lix,
  top,
  host,
  dom,
  mod,
  registry,
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

  getBackend = spec:
    (spec.interface or {}).backend or {};

  hostBackend = (host.interface or {}).backend or {};

  ordered = user: let
    backend =
      if user == null
      then {}
      else getBackend user;
  in
    (backend.managers or [])
    ++ (backend.desktops or [])
    ++ (hostBackend.managers or [])
    ++ (hostBackend.desktops or []);

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

  displayManagerFor = backend: let
    names = backend.managers ++ backend.desktops;
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
        "dms"
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
      enable = mkEnableOption "automatic login" // {default = auto.enable;};

      user = mkOption {
        type = nullOr str;
        default = auto.user;
        description = "User to automatically log in when autologin is enabled.";
      };
    };
  };
  dmsCompositors = [
    "hyprland"
    "niri"
    "sway"
  ];

  mk = scope: {
    config,
    ...
  }: let
    inherit ((args config scope)) cfg opt;
    backend = config.${top}.interface.backend;
    user = userByName auto.user;
    session = login.defaultSession or (defaultSession user);
    greeter = cfg.manager;
    compositor =
      let
        preferredSession = preferred user;
      in
        if elem preferredSession dmsCompositors
        then preferredSession
        else null;
  in {
    options = opt (opts (displayManagerFor backend) session);

    config =
      if (scope == "core")
      then {
        assertions = [
          {
            assertion = (greeter != "dms") || compositor != null;
            message = "DMS greeter requires a supported compositor (hyprland, niri, or sway) from the selected interface backend.";
          }
        ];

        programs = {
          regreet.enable = greeter == "regreet";
        };

        services = {
          displayManager = mkIf (greeter != "none") {
            gdm.enable = greeter == "gdm";
            sddm.enable = greeter == "sddm";
            dms-greeter = mkIf (greeter == "dms") {
              enable = true;
              compositor.name = compositor;
            };
            # defaultSession =
            #   mkIf
            #   (cfg.defaultSession != null)
            #   cfg.defaultSession;

            autoLogin = mkIf cfg.autoLogin.enable {
              enable = true;
              user = cfg.autoLogin.user;
            };
          };

          xserver = {
            displayManager.lightdm.enable = greeter == "lightdm";
          };

          greetd = mkIf (elem greeter ["dms" "greetd" "regreet"]) {
            enable = true;
          };
        };
      }
      else {};
  };
in {
  core = mk "core";
  home = mk "home";
}
