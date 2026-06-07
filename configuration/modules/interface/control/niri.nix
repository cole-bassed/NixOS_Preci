# modules/interface/keybinds/niri.nix
{
  config,
  lib,
  top,
  ...
}: let
  dom = "interface";
  mod = "control";
  cfg = config.${top}.${dom}.${mod};

  inherit (lib.attrsets) filterAttrs optionalAttrs;
  inherit (lib.modules) mkIf;

  inherit (cfg) actions;
  enabled = filterAttrs (_: a: a.command != null) actions;

  spawn = command: {action.spawn = ["sh" "-lc" command];};

  withTitle = key: title: action: {
    ${key} =
      (spawn action.command)
      // {hotkey-overlay.title = title;};
  };

  # ---------------------------------------------------------------------------
  # Upstream default binds — restored explicitly because programs.niri.settings.binds
  # is a plain attrset that replaces rather than merges with niri's built-ins.
  # Derived from niri-wm/niri resources/default-config.kdl (main branch).
  # ---------------------------------------------------------------------------
  defaults = {
    # Hotkey overlay
    "Mod+Shift+Slash" = {action.show-hotkey-overlay = [];};

    # Focus
    "Mod+Left" = {action.focus-column-left = [];};
    "Mod+Right" = {action.focus-column-right = [];};
    "Mod+Up" = {action.focus-window-up = [];};
    "Mod+Down" = {action.focus-window-down = [];};
    "Mod+H" = {action.focus-column-left = [];};
    "Mod+L" = {action.focus-column-right = [];};
    "Mod+K" = {action.focus-window-up = [];};
    "Mod+J" = {action.focus-window-down = [];};

    # Focus monitor
    "Mod+Ctrl+Left" = {action.focus-monitor-left = [];};
    "Mod+Ctrl+Right" = {action.focus-monitor-right = [];};
    "Mod+Ctrl+Up" = {action.focus-monitor-up = [];};
    "Mod+Ctrl+Down" = {action.focus-monitor-down = [];};
    "Mod+Ctrl+H" = {action.focus-monitor-left = [];};
    "Mod+Ctrl+L" = {action.focus-monitor-right = [];};
    "Mod+Ctrl+K" = {action.focus-monitor-up = [];};
    "Mod+Ctrl+J" = {action.focus-monitor-down = [];};

    # Move windows
    "Mod+Shift+Left" = {action.move-column-left = [];};
    "Mod+Shift+Right" = {action.move-column-right = [];};
    "Mod+Shift+Up" = {action.move-window-up = [];};
    "Mod+Shift+Down" = {action.move-window-down = [];};
    "Mod+Shift+H" = {action.move-column-left = [];};
    "Mod+Shift+L" = {action.move-column-right = [];};
    "Mod+Shift+K" = {action.move-window-up = [];};
    "Mod+Shift+J" = {action.move-window-down = [];};

    # Move to monitor
    "Mod+Ctrl+Shift+Left" = {action.move-column-to-monitor-left = [];};
    "Mod+Ctrl+Shift+Right" = {action.move-column-to-monitor-right = [];};
    "Mod+Ctrl+Shift+Up" = {action.move-column-to-monitor-up = [];};
    "Mod+Ctrl+Shift+Down" = {action.move-column-to-monitor-down = [];};
    "Mod+Ctrl+Shift+H" = {action.move-column-to-monitor-left = [];};
    "Mod+Ctrl+Shift+L" = {action.move-column-to-monitor-right = [];};
    "Mod+Ctrl+Shift+K" = {action.move-column-to-monitor-up = [];};
    "Mod+Ctrl+Shift+J" = {action.move-column-to-monitor-down = [];};

    # Column / window sizing
    "Mod+R" = {action.switch-preset-column-width = [];};
    "Mod+Shift+R" = {action.switch-preset-window-height = [];};
    "Mod+Ctrl+R" = {action.reset-window-height = [];};
    "Mod+Minus" = {action.set-column-width = "-10%";};
    "Mod+Equal" = {action.set-column-width = "+10%";};
    "Mod+Shift+Minus" = {action.set-window-height = "-10%";};
    "Mod+Shift+Equal" = {action.set-window-height = "+10%";};
    "Mod+I" = {action.expand-column-to-available-width = [];};

    # Fullscreen / centering
    "Mod+Shift+F" = {action.fullscreen-window = [];};
    "Mod+Shift+C" = {action.center-column = [];};

    # Stacking / column manipulation
    "Mod+Comma" = {action.consume-window-into-column = [];};
    "Mod+Period" = {action.expel-window-from-column = [];};
    "Mod+BracketLeft" = {action.consume-or-expel-window-left = [];};
    "Mod+BracketRight" = {action.consume-or-expel-window-right = [];};

    # Overview
    "Mod+Tab" = {action.toggle-overview = [];};

    # Workspaces
    "Mod+Page_Down" = {action.focus-workspace-down = [];};
    "Mod+Page_Up" = {action.focus-workspace-up = [];};
    "Mod+U" = {action.focus-workspace-down = [];};
    # Mod+I is taken above by expand-column-to-available-width
    "Mod+Shift+Page_Down" = {action.move-column-to-workspace-down = [];};
    "Mod+Shift+Page_Up" = {action.move-column-to-workspace-up = [];};
    "Mod+Shift+U" = {action.move-column-to-workspace-down = [];};
    "Mod+Shift+I" = {action.move-column-to-workspace-up = [];};

    "Mod+1" = {action.focus-workspace = 1;};
    "Mod+2" = {action.focus-workspace = 2;};
    "Mod+3" = {action.focus-workspace = 3;};
    "Mod+4" = {action.focus-workspace = 4;};
    "Mod+5" = {action.focus-workspace = 5;};
    "Mod+6" = {action.focus-workspace = 6;};
    "Mod+7" = {action.focus-workspace = 7;};
    "Mod+8" = {action.focus-workspace = 8;};
    "Mod+9" = {action.focus-workspace = 9;};

    "Mod+Shift+1" = {action.move-column-to-workspace = 1;};
    "Mod+Shift+2" = {action.move-column-to-workspace = 2;};
    "Mod+Shift+3" = {action.move-column-to-workspace = 3;};
    "Mod+Shift+4" = {action.move-column-to-workspace = 4;};
    "Mod+Shift+5" = {action.move-column-to-workspace = 5;};
    "Mod+Shift+6" = {action.move-column-to-workspace = 6;};
    "Mod+Shift+7" = {action.move-column-to-workspace = 7;};
    "Mod+Shift+8" = {action.move-column-to-workspace = 8;};
    "Mod+Shift+9" = {action.move-column-to-workspace = 9;};

    # Scroll navigation
    "Mod+WheelScrollDown" = {
      action.focus-workspace-down = [];
      cooldown-ms = 150;
    };
    "Mod+WheelScrollUp" = {
      action.focus-workspace-up = [];
      cooldown-ms = 150;
    };
    "Mod+WheelScrollRight" = {action.focus-column-right = [];};
    "Mod+WheelScrollLeft" = {action.focus-column-left = [];};
    "Mod+Shift+WheelScrollDown" = {
      action.focus-column-right = [];
      cooldown-ms = 150;
    };
    "Mod+Shift+WheelScrollUp" = {
      action.focus-column-left = [];
      cooldown-ms = 150;
    };

    # Screenshots (native niri actions; grim+slurp variant added below)
    "Print" = {action.screenshot = [];};
    "Ctrl+Print" = {action.screenshot-screen = [];};
    "Alt+Print" = {action.screenshot-window = [];};

    # Media / system keys
    "XF86AudioRaiseVolume" = {
      action.spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"];
      allow-when-locked = true;
    };
    "XF86AudioLowerVolume" = {
      action.spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"];
      allow-when-locked = true;
    };
    "XF86AudioMute" = {
      action.spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
      allow-when-locked = true;
    };
    "XF86AudioMicMute" = {
      action.spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];
      allow-when-locked = true;
    };
    "XF86MonBrightnessUp" = {action.spawn = ["brightnessctl" "set" "10%+"];};
    "XF86MonBrightnessDown" = {action.spawn = ["brightnessctl" "set" "10%-"];};

    # Inhibit shortcut passthrough (useful in VMs / remote desktop)
    "Mod+Escape" = {action.toggle-keyboard-shortcuts-inhibit = [];};
  };
in {
  config = mkIf (cfg.enable && cfg.onNiri) {
    programs.niri.settings.binds =
      # All upstream defaults first — semantic layer overrides via // below.
      defaults
      # Niri doesn't safely support a bare Mod key bind through niri-flake,
      # so Win alone is Hyprland-only. Win+Space is the shared recovery path.
      // (
        optionalAttrs (enabled ? secondaryLauncher)
        (withTitle "Mod+Space" "Open Fuzzel" enabled.secondaryLauncher)
      )
      // (
        optionalAttrs (enabled ? terminal)
        (withTitle "Mod+Return" "Open terminal" enabled.terminal)
      )
      # Scratchpad overrides Mod+Grave (which defaults would map to toggle-overview
      # if we had put it there — we didn't, so this is additive).
      // (
        optionalAttrs (enabled ? scratchpadTerminal)
        (withTitle "Mod+Grave" "Open scratchpad terminal" enabled.scratchpadTerminal)
      )
      // (
        optionalAttrs (enabled ? primaryBrowser)
        (withTitle "Mod+B" "Open primary browser" enabled.primaryBrowser)
      )
      // (
        optionalAttrs (enabled ? secondaryBrowser)
        (withTitle "Mod+Alt+B" "Open secondary browser" enabled.secondaryBrowser)
      )
      // (
        optionalAttrs (enabled ? visualTools)
        (withTitle "Mod+V" "Open visual tools" enabled.visualTools)
      )
      // (
        optionalAttrs (enabled ? fileManager)
        (withTitle "Mod+F" "Open file manager" enabled.fileManager)
      )
      // (
        optionalAttrs (enabled ? editor)
        (withTitle "Mod+E" "Open editor" enabled.editor)
      )
      // (
        optionalAttrs (actions.fullscreen.description != null) {
          "Alt+Return" = {
            action.fullscreen-window = [];
            hotkey-overlay.title = "Toggle fullscreen";
          };
          "Mod+Ctrl+F" = {
            action.fullscreen-window = [];
            hotkey-overlay.title = "Toggle fullscreen";
          };
        }
      )
      // (
        optionalAttrs (actions.logout.description != null) {
          "Mod+Ctrl+Q" = {
            action.quit.skip-confirmation = true;
            hotkey-overlay.title = "Exit niri";
          };
        }
      )
      // (
        optionalAttrs (actions.closeWindow.description != null) {
          "Mod+Q" = {
            action.close-window = [];
            hotkey-overlay.title = "Close focused window";
          };
        }
      )
      // (
        optionalAttrs (enabled ? lock)
        (withTitle "Mod+Ctrl+L" "Lock session" enabled.lock)
      )
      // (
        optionalAttrs (actions.showKeybinds.description != null) {
          "Mod+Ctrl+Slash" = {
            action.show-hotkey-overlay = [];
            hotkey-overlay.title = "Show common keybinds";
          };
        }
      )
      # grim+slurp region screenshot on Mod+Print; native Print stays from defaults.
      // (
        optionalAttrs (enabled ? screenshot) {
          "Mod+Print" = {
            action.spawn = ["sh" "-lc" enabled.screenshot.command];
            hotkey-overlay.title = "Region screenshot → clipboard";
          };
        }
      );

    # reloadConfig is intentionally Hyprland-only: niri reloads automatically
    # and niri-flake doesn't expose a stable reload-config action.
  };
}
