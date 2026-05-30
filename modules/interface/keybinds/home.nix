{
  config,
  lib,
  pkgs,
  top,
  ...
}: let
  inherit (lib) attrValues concatMap filterAttrs mkDefault mkEnableOption mkIf mkOption optionalAttrs;
  inherit (lib.types) bool nullOr str submodule;

  dom = "interface";
  mod = "keybinds";

  cfg = config.${top}.${dom}.${mod};

  helpScript = pkgs.writeShellScriptBin "dots-common-keybinds" ''
    ${lib.getExe pkgs.libnotify} "Common desktop keybinds" "$(cat <<'HELP'
    Win: primary launcher (Hyprland)
    Win+Space: secondary launcher
    Win+Ctrl+/: show keybind help
    Win+Enter: terminal
    Win+`: scratchpad terminal
    Win+B: primary browser
    Win+Alt+B: secondary browser
    Win+V: visual tools launcher
    Win+F: file manager
    Win+E: editor
    Alt+Enter / Win+Ctrl+F: fullscreen
    Win+Q: close focused window
    Win+Ctrl+L: lock session
    Win+Ctrl+Q: logout/exit session
    Print: screenshot
    HELP
    )"
  '';

  mkActionOption = description: defaults:
    mkOption {
      type = submodule {
        options = {
          command = mkOption {
            type = nullOr str;
            default = defaults.command or null;
            description = "Shell command used when the ${description} action is command-backed.";
          };

          description = mkOption {
            type = str;
            default = defaults.description or description;
            description = "Human readable description for the ${description} action.";
          };
        };
      };
      default = {};
      description = "Shared semantic interface action for ${description}.";
    };

  enabledActions = filterAttrs (_: action: action.command != null) cfg.actions;
  commandAction = action: action.command != null;
  spawnAction = command: {
    action.spawn = ["sh" "-lc" command];
  };

  hyprBind = key: dispatch: "${cfg.mod}, ${key}, ${dispatch}";
  hyprAltBind = key: dispatch: "ALT, ${key}, ${dispatch}";
  hyprCtrlBind = key: dispatch: "${cfg.mod} CTRL, ${key}, ${dispatch}";
  hyprExecBind = key: action: hyprBind key "exec, ${action.command}";
  hyprCtrlExecBind = key: action: hyprCtrlBind key "exec, ${action.command}";
  hyprAltExecBind = key: action: hyprAltBind key "exec, ${action.command}";

  bindIf = condition: value:
    if condition
    then [value]
    else [];

  niriSpawnBind = key: action: {
    ${key} = spawnAction action.command;
  };

  niriSpawnTitleBind = key: title: action: {
    ${key} = (spawnAction action.command) // {hotkey-overlay.title = title;};
  };
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "shared interface/session keybind profile";

    mod = mkOption {
      type = str;
      default = "SUPER";
      description = ''
        Primary compositor modifier. Hyprland uses this value directly; Niri
        maps it to its compositor-agnostic Mod alias in the translator.
      '';
    };

    hyprland.enable = mkOption {
      type = bool;
      default = true;
      description = "Whether to translate shared interface actions to Hyprland syntax.";
    };

    niri.enable = mkOption {
      type = bool;
      default = true;
      description = "Whether to translate shared interface actions to Niri syntax.";
    };

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
        command = "chromium";
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

  config = mkIf cfg.enable {
    home.packages = [
      helpScript
      pkgs.grim
      pkgs.libnotify
      pkgs.slurp
      pkgs.wl-clipboard
    ];

    wayland.windowManager.hyprland = mkIf cfg.hyprland.enable {
      settings = {
        "$mod" = mkDefault cfg.mod;

        bindr = bindIf (enabledActions ? primaryLauncher) "${cfg.mod}, Super_L, exec, ${enabledActions.primaryLauncher.command}";

        bind =
          bindIf (enabledActions ? secondaryLauncher) (hyprExecBind "Space" enabledActions.secondaryLauncher)
          ++ bindIf (enabledActions ? showKeybinds) (hyprCtrlExecBind "slash" enabledActions.showKeybinds)
          ++ bindIf (enabledActions ? terminal) (hyprExecBind "Return" enabledActions.terminal)
          ++ bindIf (enabledActions ? scratchpadTerminal) (hyprExecBind "grave" enabledActions.scratchpadTerminal)
          ++ bindIf (enabledActions ? primaryBrowser) (hyprExecBind "B" enabledActions.primaryBrowser)
          ++ bindIf (enabledActions ? secondaryBrowser) (hyprAltExecBind "B" enabledActions.secondaryBrowser)
          ++ bindIf (enabledActions ? visualTools) (hyprExecBind "V" enabledActions.visualTools)
          ++ bindIf (enabledActions ? fileManager) (hyprExecBind "F" enabledActions.fileManager)
          ++ bindIf (enabledActions ? editor) (hyprExecBind "E" enabledActions.editor)
          ++ bindIf (cfg.actions.fullscreen.description != null) (hyprAltBind "Return" "fullscreen, 0")
          ++ bindIf (cfg.actions.fullscreen.description != null) (hyprCtrlBind "F" "fullscreen, 0")
          ++ bindIf (cfg.actions.logout.description != null) (hyprCtrlBind "Q" "exit")
          ++ bindIf (cfg.actions.closeWindow.description != null) (hyprBind "Q" "killactive")
          ++ bindIf (cfg.actions.reloadConfig.description != null) (hyprCtrlBind "R" "exec, hyprctl reload")
          ++ bindIf (enabledActions ? lock) (hyprCtrlExecBind "L" enabledActions.lock)
          ++ bindIf (enabledActions ? screenshot) (hyprBind "Print" "exec, ${enabledActions.screenshot.command}");
      };
    };

    programs.niri.settings = mkIf cfg.niri.enable {
      binds =
        optionalAttrs (enabledActions ? secondaryLauncher) (niriSpawnTitleBind "Mod+Space" "Open Fuzzel" enabledActions.secondaryLauncher)
        # Niri does not safely support a bare Mod key bind through niri-flake,
        # so Win alone is only translated for Hyprland. Win+Space remains the
        # shared secondary launcher and recovery path.
        // optionalAttrs (cfg.actions.showKeybinds.description != null) {
          "Mod+Ctrl+Slash" = {
            action.show-hotkey-overlay = [];
            hotkey-overlay.title = "Show common keybinds";
          };
        }
        // optionalAttrs (enabledActions ? terminal) (niriSpawnTitleBind "Mod+Return" "Open terminal" enabledActions.terminal)
        // optionalAttrs (enabledActions ? scratchpadTerminal) (niriSpawnTitleBind "Mod+Grave" "Open scratchpad terminal" enabledActions.scratchpadTerminal)
        // optionalAttrs (enabledActions ? primaryBrowser) (niriSpawnTitleBind "Mod+B" "Open primary browser" enabledActions.primaryBrowser)
        // optionalAttrs (enabledActions ? secondaryBrowser) (niriSpawnTitleBind "Mod+Alt+B" "Open secondary browser" enabledActions.secondaryBrowser)
        // optionalAttrs (enabledActions ? visualTools) (niriSpawnTitleBind "Mod+V" "Open visual tools" enabledActions.visualTools)
        // optionalAttrs (enabledActions ? fileManager) (niriSpawnTitleBind "Mod+F" "Open file manager" enabledActions.fileManager)
        // optionalAttrs (enabledActions ? editor) (niriSpawnTitleBind "Mod+E" "Open editor" enabledActions.editor)
        // optionalAttrs (cfg.actions.fullscreen.description != null) {
          "Alt+Return" = {
            action.fullscreen-window = [];
            hotkey-overlay.title = "Toggle fullscreen";
          };
          "Mod+Ctrl+F" = {
            action.fullscreen-window = [];
            hotkey-overlay.title = "Toggle fullscreen";
          };
        }
        // optionalAttrs (cfg.actions.logout.description != null) {
          "Mod+Ctrl+Q" = {
            action.quit.skip-confirmation = true;
            hotkey-overlay.title = "Exit niri";
          };
        }
        // optionalAttrs (cfg.actions.closeWindow.description != null) {
          "Mod+Q" = {
            action.close-window = [];
            hotkey-overlay.title = "Close focused window";
          };
        }
        // optionalAttrs (enabledActions ? lock) (niriSpawnTitleBind "Mod+Ctrl+L" "Lock session" enabledActions.lock)
        // optionalAttrs (enabledActions ? screenshot) {
          "Mod+Print" = {
            action.screenshot-screen = [];
            hotkey-overlay.title = "Screenshot focused screen";
          };
        };

      # Niri reloads config changes automatically and does not expose a stable
      # reload-config bind action in niri-flake's action list, so reloadConfig
      # is intentionally only translated for Hyprland.
    };
  };
}
