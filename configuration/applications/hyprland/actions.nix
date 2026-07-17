{lix, ...}: let
  inherit (lix.options) mkOption;
  inherit (lix.types) nullOr str submodule;

  mkActionOption = description: overrides:
    mkOption {
      type = submodule {
        options = {
          command = mkOption {
            type = nullOr str;
            default = overrides.command or null;
            description = "Shell command for the ${description} action.";
          };
          description = mkOption {
            type = str;
            default = overrides.description or description;
            description = "Human-readable label for the ${description} action.";
          };
        };
      };
      default = {};
      description = "Shared semantic Hyprland action for ${description}.";
    };
in {
  mkActions = {
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
    fullscreen = mkActionOption "fullscreen" {description = "Toggle fullscreen";};
    logout = mkActionOption "logout/exit session" {description = "Exit compositor session";};
    closeWindow = mkActionOption "close window" {description = "Close focused window";};
    lock = mkActionOption "lock" {
      command = "loginctl lock-session";
      description = "Lock session";
    };
    screenshot = mkActionOption "screenshot" {
      command = ''grim -g "$(slurp)" - | wl-copy'';
      description = "Take a screenshot";
    };
  };
}
