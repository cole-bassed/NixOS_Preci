{
  lib,
  top,
  ...
}: let
  dom = "interface";
  mod = "control";

  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) nullOr str submodule;

  mkActionOption = description: defaults:
    mkOption {
      type = submodule {
        options = {
          command = mkOption {
            type = nullOr str;
            default = defaults.command or null;
            description = "Shell command for the ${description} action.";
          };
          description = mkOption {
            type = str;
            default = defaults.description or description;
            description = "Human-readable label for the ${description} action.";
          };
        };
      };
      default = {};
      description = "Shared semantic interface action for ${description}.";
    };
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "shared interface/session keybind profile";

    modifier = mkOption {
      type = str;
      default = "SUPER";
      description = ''
        Primary compositor modifier key. Hyprland uses this directly; Niri
        maps it to its compositor-agnostic Mod alias.
      '';
    };

    onHyprland =
      mkEnableOption "translate shared keybind actions to Hyprland syntax"
      // {default = true;};

    onNiri =
      mkEnableOption "translate shared keybind actions to Niri syntax"
      // {default = true;};

    actions = {
      primaryLauncher = mkActionOption "primary launcher" {
        command = "vicinae open";
        description = "Open Vicinae";
      };
      secondaryLauncher = mkActionOption "secondary launcher" {
        command = "fuzzel";
        description = "Open Fuzzel";
      };
      showKeybinds = mkActionOption "show keybinds/help" {
        command = "dots-common-keybinds";
        description = "Show common keybinds";
      };
      terminal = mkActionOption "terminal" {
        command = "foot";
        description = "Open terminal";
      };
      scratchpadTerminal = mkActionOption "scratchpad/quake terminal" {
        command = "foot --app-id dots-scratchpad";
        description = "Open scratchpad terminal";
      };
      primaryBrowser = mkActionOption "primary browser" {
        command = "zen";
        description = "Open primary browser";
      };
      secondaryBrowser = mkActionOption "secondary browser" {
        command = "chromium";
        description = "Open secondary browser";
      };
      visualTools = mkActionOption "visual tools" {
        command = "vicinae open || fuzzel";
        description = "Open visual tools";
      };
      fileManager = mkActionOption "file manager" {
        command = "xdg-open $HOME";
        description = "Open file manager";
      };
      editor = mkActionOption "editor" {
        command = "code";
        description = "Open editor";
      };
      fullscreen = mkActionOption "fullscreen" {
        description = "Toggle fullscreen";
      };
      logout = mkActionOption "logout/exit session" {
        description = "Exit compositor session";
      };
      closeWindow = mkActionOption "close window" {
        description = "Close focused window";
      };
      reloadConfig = mkActionOption "reload config" {
        description = "Reload compositor config";
      };
      lock = mkActionOption "lock" {
        command = "loginctl lock-session";
        description = "Lock session";
      };
      screenshot = mkActionOption "screenshot" {
        command = ''grim -g "$(slurp)" - | wl-copy'';
        description = "Take a screenshot";
      };
    };
  };
}
