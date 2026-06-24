{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkEnableOption mkOption;
  inherit (lix.types) enum nullOr str;

  args = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};

  primary = host.users.primary.value or null;

  hostLogin = (host.interface or {}).login or {};

  defaultManager =
    hostLogin.manager
    or host.interface.displayManager
    or "gdm";

  defaultAutoLoginUser =
    hostLogin.autoLogin.user
    or (
      if primary != null && primary.autoLogin or false
      then primary.name
      else null
    );

  defaultAutoLogin =
    hostLogin.autoLogin.enable
    or (defaultAutoLoginUser != null);

  opts = {
    manager = mkOption {
      type = enum [
        "none"
        "gdm"
        "sddm"
        "greetd"
        "regreet"
        "lightdm"
      ];
      default = defaultManager;
      description = "Display manager or greeter used to start graphical sessions.";
    };

    autoLogin = {
      enable =
        mkEnableOption "automatic login"
        // {default = defaultAutoLogin;};

      user = mkOption {
        type = nullOr str;
        default = defaultAutoLoginUser;
        description = "User to automatically log in.";
      };
    };
  };
in {
  core = {config, ...}: let
    inherit ((args config "core")) cfg opt;
  in {
    options = opt opts;

    config = {
      services = {
        displayManager = {
          gdm.enable = cfg.manager == "gdm";
          sddm.enable = cfg.manager == "sddm";

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
