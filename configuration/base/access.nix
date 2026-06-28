{
  lix,
  top,
  host,
  dom,
  mod,
  registry,
  ...
}: let
  inherit (lix.api) getInteractiveUsers;
  inherit (lix.attrsets) asAttrs namesOf valuesOf;
  inherit (lix.lists) elem concatMap;
  inherit (lix.options) mkModuleArgs mkEnableOption mkOption;
  inherit (lix.types) enum listOf;

  setOf = list: namesOf (asAttrs list);

  getUI = base: let
    ui = base.interface or {};
  in
    ui.session or ui.environment or {};

  collect = field: specs:
    setOf (concatMap (spec: spec.${field} or []) specs);

  merge = specs: {
    managers = collect "managers" specs;
    desktops = collect "desktops" specs;
  };

  spec = let
    host' = getUI host;
    users = map getUI (valuesOf (getInteractiveUsers host));
  in {
    all = {
      managers = with registry.managers; x11 ++ wayland;
      desktops = with registry.desktops; x11 ++ wayland;
      x11 = registry.managers.x11 ++ registry.desktops.x11;
      wayland = registry.managers.wayland ++ registry.desktops.wayland;
    };

    host = host';
    inherit users;

    core = merge ([host'] ++ users);

    home = user: let
      user' = getUI user;
    in
      merge [host' user'];
  };

  opts = preset: cfg: {
    managers = mkOption {
      type = listOf (enum spec.all.managers);
      default = preset.managers;
      description = "Enabled standalone compositors/window managers.";
    };

    i3 = {
      enable =
        mkEnableOption "i3 window manager"
        // {default = elem "i3" cfg.managers;};
    };
  };

  mkArgs = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};
in {
  core = {config, ...}: let
    inherit ((mkArgs config "core")) cfg opt;
  in {
    options = opt (opts spec.core cfg);
    config = {
    };
  };

  home = {
    config,
    user ? {},
    ...
  }: let
    inherit ((mkArgs config "home")) cfg opt;
  in {
    options = opt (opts (spec.home user) cfg);
    config = {
    };
  };
}
