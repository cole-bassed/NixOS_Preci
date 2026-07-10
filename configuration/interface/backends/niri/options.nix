{
  lib,
  top,
  ...
}: let
  cfgPath = [top "interface" "backends" "niri"];

  inherit (lib.attrsets) setAttrByPath;
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
      description = "Shared semantic Niri action for ${description}.";
    };
in {
  options = setAttrByPath cfgPath {
    modifier = mkOption {
      type = str;
      default = "SUPER";
      description = ''
        Primary compositor modifier key. Niri binds use its compositor-agnostic
        `Mod` alias, but this keeps the chosen host intent visible in the live API.
      '';
    };

    semanticKeybinds =
      mkEnableOption "modular semantic keybind layer for Niri"
      // {default = true;};

    actions = {
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
