# configuration/applications/hyprland/bindings.nix
#
# Replaces the old settings/bindings.nix + settings/rules/* pair. Those
# referenced raw `keyboard`/`apps` module args that no longer exist --
# leftover from before data/interface/default.nix + the mkBindings
# compiler existed. This file is the hyprland-native counterpart to
# niri/bindings.nix, consuming the SAME compiled entries so both
# backends read one source of truth (data/interface/default.nix's
# `common`/`wayland` blocks, resolved through mkBindings in
# libraries/config/assembly.nix) instead of hand-rolling their own.
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

  cfg = config.${top}.interface.backends.hyprland;
  hasHyprlandProgram = options.wayland.windowManager ? hyprland;

  enable = cfg.enable or false;
  semanticKeybinds = cfg.semanticKeybinds or false;
  actions = cfg.actions or {};

  # Same registry-driven applications/bindings that niri reads, resolved
  # via the shared compiler -- not a second copy of the launcher/terminal
  # list. `dots.interface.primary.{applications,bindings}` is populated by
  # configuration/interface/default.nix from data/interface/default.nix.
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
