{
  config, # TODO: config is not to be here, this is the original nix way, not my dual-mode core/home way
  lix,
  options,
  top,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs;
  inherit (lix.assembly) mkBindings;
  # inherit (lix.backends) mkHyprlandBinds;
  inherit (lix.modules) mkIf;

  cfg = config.${top}.applications.hyprland; #TODO: This is too manual, we need to have known this from moduleArgs
  hasApp = options.wayland.windowManager ? hyprland; #TODO: This is too manual, we need to have known this from moduleArgs
  mkBinds = lix.backends.mkHyprlandBinds;

  enable = cfg.enable or false;
  semanticKeybinds = cfg.semanticKeybinds or false;
  actions = cfg.actions or {};

  resolvedInterface = config.${top}.interface.primary or {};

  compiled = mkBindings {
    bindings = resolvedInterface.bindings or actions;
    applications = resolvedInterface.applications or {};
  };

  entries = compiled.entries or [];
in {
  config = optionalAttrs hasApp (mkIf (enable && semanticKeybinds) {
    # wayland.windowManager.hyprland.settings.bind = mkBinds entries; #? this is too manual settings should import this file directly, so all we should need to define is binds
    bind = mkBinds entries;
  });
}
