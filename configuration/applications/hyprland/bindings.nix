# configuration/applications/hyprland/bindings.nix
{
  config,
  lix,
  options,
  top,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs;
  inherit (lix.assembly) mkBindings;
  inherit (lix.backends) mkHyprlandBinds;
  inherit (lix.modules) mkIf;

  cfg = config.${top}.applications.hyprland;
  hasHyprlandProgram = options.wayland.windowManager ? hyprland;

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
  config = optionalAttrs hasHyprlandProgram (mkIf (enable && semanticKeybinds) {
    wayland.windowManager.hyprland.settings.bind = mkHyprlandBinds entries;
  });
}
