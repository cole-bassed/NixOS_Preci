{
  actions = {
    # ╔════════════════════════════════════════════════╗
    # ╠ APPLICATIONS                                   ╣
    # ╚════════════════════════════════════════════════╝
    # --------------------------------------------------
    # BROWSERS
    # --------------------------------------------------
    openBrowser1 = {
      scope = "home-manager";
      command = "zen-twilight";
      description = "Launch the primary browser (Zen Browser)";
      chord = ["SUPER" "B"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, B, exec, zen-twilight"];
        };
      };
    };
    openBrowser2 = {
      scope = "home-manager";
      command = "chromium";
      description = "Launch the secondary browser (Chromium)";
      chord = ["SUPER" "SHIFT" "B"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, B, exec, chromium"];
        };
      };
    };
    openBrowser3 = {
      scope = "home-manager";
      command = "firefox";
      description = "Launch the tertiary browser (Firefox)";
      chord = ["SUPER" "ALT" "B"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod ALT, B, exec, firefox"];
        };
      };
    };
    openZenBrowser = {
      scope = "home-manager";
      command = "zen-twilight";
      description = "Launch Zen Browser";
      chord = ["SUPER" "SHIFT" "ALT" "B"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT ALT, B, exec, zen-twilight"];
        };
      };
    };
    openChromium = {
      scope = "home-manager";
      command = "chromium";
      description = "Launch Chromium";
      chord = ["SUPER" "SHIFT" "ALT" "C"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT ALT, C, exec, chromium"];
        };
      };
    };
    # --------------------------------------------------
    # EDITORS (WRAPPED IN PRIMARY TERMINAL)
    # --------------------------------------------------
    openEditor1 = {
      scope = "home-manager";
      command = "foot -e hx";
      description = "Launch the primary tty editor (Helix Editor)";
      chord = ["SUPER" "C"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, C, exec, foot -e hx"];
        };
      };
    };
    openEditor2 = {
      scope = "home-manager";
      command = "foot -e nvim";
      description = "Launch the secondary tty editor (NeoVim)";
      chord = ["SUPER" "SHIFT" "C"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, C, exec, foot -e nvim"];
        };
      };
    };
    openEditor3 = {
      scope = "home-manager";
      command = "foot -e nano";
      description = "Launch the tertiary tty editor (GNU Nano)";
      chord = ["SUPER" "ALT" "C"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod ALT, C, exec, foot -e nano"];
        };
      };
    };
    # --------------------------------------------------
    # GUI EDITORS
    # --------------------------------------------------
    openVisual1 = {
      scope = "home-manager";
      command = "code";
      description = "Launch the primary gui editor (Visual Studio Code)";
      chord = ["SUPER" "V"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, V, exec, code"];
        };
      };
    };
    openVisual2 = {
      scope = "home-manager";
      command = "zeditor";
      description = "Launch the secondary gui editor (Zed Editor)";
      chord = ["SUPER" "SHIFT" "V"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, V, exec, zeditor"];
        };
      };
    };
    openVisual3 = {
      scope = "home-manager";
      command = "antigravity";
      description = "Launch the tertiary gui editor (Antigravity IDE)";
      chord = ["SUPER" "ALT" "V"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod ALT, V, exec, antigravity"];
        };
      };
    };
    openVscode = {
      scope = "home-manager";
      command = "code";
      description = "Launch Visual Studio Code";
      chord = ["SUPER" "SHIFT" "ALT" "V"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT ALT, V, exec, code"];
        };
      };
    };
    openZed = {
      scope = "home-manager";
      command = "zeditor";
      description = "Launch Zed Editor";
      chord = ["SUPER" "SHIFT" "ALT" "Z"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT ALT, Z, exec, zeditor"];
        };
      };
    };
    openAntigravity = {
      scope = "home-manager";
      command = "antigravity";
      description = "Launch Antigravity IDE";
      chord = ["SUPER" "SHIFT" "ALT" "A"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT ALT, A, exec, antigravity"];
        };
      };
    };
    # --------------------------------------------------
    # FILE EXPLORERS
    # --------------------------------------------------
    openExplorer1 = {
      scope = "home-manager";
      command = "doublecmd";
      description = "Launch the primary explorer (Double Commander)";
      chord = ["SUPER" "E"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, E, exec, doublecmd"];
        };
      };
    };
    openExplorer2 = {
      scope = "home-manager";
      command = "thunar";
      description = "Launch the secondary explorer (Thunar)";
      chord = ["SUPER" "SHIFT" "E"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, E, exec, thunar"];
        };
      };
    };
    openExplorer3 = {
      scope = "home-manager";
      command = "";
      description = "Launch the tertiary explorer (None)";
      chord = ["SUPER" "ALT" "E"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = [];
        };
      };
    };
    openDoublecmd = {
      scope = "home-manager";
      command = "doublecmd";
      description = "Launch Double Commander File Manager";
      chord = ["SUPER" "SHIFT" "ALT" "D"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT ALT, D, exec, doublecmd"];
        };
      };
    };
    openThunar = {
      scope = "home-manager";
      command = "thunar";
      description = "Launch Thunar File Manager";
      chord = ["SUPER" "SHIFT" "ALT" "T"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT ALT, T, exec, thunar"];
        };
      };
    };
    # --------------------------------------------------
    # LAUNCHERS
    # --------------------------------------------------
    openLauncher1 = {
      scope = "home-manager";
      command = "dank-launcher";
      description = "Launch the primary launcher (Dank Material Shell Launcher)";
      chord = ["SUPER" "Space"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, Space, exec, dank-launcher"];
        };
      };
    };
    openLauncher2 = {
      scope = "home-manager";
      command = "vicinae open";
      description = "Launch the secondary launcher (Vicinae)";
      chord = ["SUPER" "SHIFT" "Space"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, Space, exec, vicinae open"];
        };
      };
    };
    openLauncher3 = {
      scope = "home-manager";
      command = "fuzzel";
      description = "Launch the tertiary launcher (Fuzzel)";
      chord = ["SUPER" "ALT" "Space"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod ALT, Space, exec, fuzzel"];
        };
      };
    };
    # --------------------------------------------------
    # TERMINALS
    # --------------------------------------------------
    openTerminal1 = {
      scope = "home-manager";
      command = "foot";
      description = "Launch the primary terminal (Foot)";
      chord = ["SUPER" "Return"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, Return, exec, foot"];
        };
      };
    };
    openTerminal2 = {
      scope = "home-manager";
      command = "kitty";
      description = "Launch the secondary terminal (Kitty)";
      chord = ["SUPER" "SHIFT" "Return"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, Return, exec, kitty"];
        };
      };
    };
    openTerminal3 = {
      scope = "home-manager";
      command = "ghostty";
      description = "Launch the tertiary terminal (Ghostty)";
      chord = ["SUPER" "ALT" "Return"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod ALT, Return, exec, ghostty"];
        };
      };
    };
    openFoot = {
      scope = "home-manager";
      command = "foot";
      description = "Launch Foot Terminal";
      chord = ["SUPER" "SHIFT" "ALT" "F"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT ALT, F, exec, foot"];
        };
      };
    };
    openKitty = {
      scope = "home-manager";
      command = "kitty";
      description = "Launch Kitty Terminal";
      chord = ["SUPER" "SHIFT" "ALT" "K"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT ALT, K, exec, kitty"];
        };
      };
    };
    openGhostty = {
      scope = "home-manager";
      command = "ghostty";
      description = "Launch Ghostty Terminal";
      chord = ["SUPER" "SHIFT" "ALT" "G"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT ALT, G, exec, ghostty"];
        };
      };
    };

    # ╔════════════════════════════════════════════════╗
    # ╠ SYSTEM CONTROLS & CAPTURE                      ╣
    # ╚════════════════════════════════════════════════╝
    closeWindow = {
      scope = "home-manager";
      command = null;
      description = "Close Active Window";
      chord = ["SUPER" "SHIFT" "W"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, W, killactive,"];
        };
      };
    };
    toggleFloating = {
      scope = "home-manager";
      command = null;
      description = "Toggle Window Floating State";
      chord = ["SUPER" "H"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, H, togglefloating,"];
        };
      };
    };
    toggleFullscreen = {
      scope = "home-manager";
      command = null;
      description = "Toggle Active Window Fullscreen State";
      chord = ["SUPER" "F"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, F, fullscreen, 0"];
        };
      };
    };
    togglePip = {
      scope = "home-manager";
      command = null;
      description = "Toggle Picture-in-Picture mode (Floating, Sticky, Pins on Top)";
      chord = ["SUPER" "P"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, P, exec, hyprctl dispatch togglefloating && hyprctl dispatch pin"];
        };
      };
    };
    moveFocusUp = {
      scope = "home-manager";
      command = null;
      description = "Move focus to the window above";
      chord = ["SUPER" "K"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, K, movefocus, u"];
        };
      };
    };
    moveFocusDown = {
      scope = "home-manager";
      command = null;
      description = "Move focus to the window below";
      chord = ["SUPER" "J"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, J, movefocus, d"];
        };
      };
    };
    moveFocusLeft = {
      scope = "home-manager";
      command = null;
      description = "Move focus to the window on the left";
      chord = ["SUPER" "H"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, H, movefocus, l"];
        };
      };
    };
    moveFocusRight = {
      scope = "home-manager";
      command = null;
      description = "Move focus to the window on the right";
      chord = ["SUPER" "L"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, L, movefocus, r"];
        };
      };
    };
    moveWindowUp = {
      scope = "home-manager";
      command = null;
      description = "Move window position upward";
      chord = ["SUPER" "SHIFT" "K"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, K, movewindow, u"];
        };
      };
    };
    moveWindowDown = {
      scope = "home-manager";
      command = null;
      description = "Move window position downward";
      chord = ["SUPER" "SHIFT" "J"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, J, movewindow, d"];
        };
      };
    };
    moveWindowLeft = {
      scope = "home-manager";
      command = null;
      description = "Move window position leftward";
      chord = ["SUPER" "SHIFT" "H"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, H, movewindow, l"];
        };
      };
    };
    moveWindowRight = {
      scope = "home-manager";
      command = null;
      description = "Move window position rightward";
      chord = ["SUPER" "SHIFT" "L"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, L, movewindow, r"];
        };
      };
    };
    focusNextMonitor = {
      scope = "home-manager";
      command = null;
      description = "Shift tracking view context to next monitor";
      chord = ["SUPER" "Tab"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, Tab, focusmonitor, +1"];
        };
      };
    };
    focusPrevMonitor = {
      scope = "home-manager";
      command = null;
      description = "Shift tracking view context to previous monitor";
      chord = ["SUPER" "Tab"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, Tab, focusmonitor, -1"];
        };
      };
    };
    moveMonitorNext = {
      scope = "home-manager";
      command = null;
      description = "Send active window to next monitor";
      chord = ["SUPER" "SHIFT" "Tab"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, Tab, movewindow, mon:+1"];
        };
      };
    };
    moveMonitorPrev = {
      scope = "home-manager";
      command = null;
      description = "Send active window to previous monitor";
      chord = ["SUPER" "SHIFT" "Tab"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, Tab, movewindow, mon:-1"];
        };
      };
    };
    focusNextWorkspace = {
      scope = "home-manager";
      command = null;
      description = "Cycle display viewport forward by index";
      chord = ["SUPER" "Right"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, Right, workspace, e+1"];
        };
      };
    };
    focusPrevWorkspace = {
      scope = "home-manager";
      command = null;
      description = "Cycle display viewport backward by index";
      chord = ["SUPER" "Left"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, Left, workspace, e-1"];
        };
      };
    };
    moveWorkspaceNext = {
      scope = "home-manager";
      command = null;
      description = "Send active window to next workspace index";
      chord = ["SUPER" "SHIFT" "Right"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, Right, movetoworkspace, r+1"];
        };
      };
    };
    moveWorkspacePrev = {
      scope = "home-manager";
      command = null;
      description = "Send active window to previous workspace index";
      chord = ["SUPER" "SHIFT" "Left"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, Left, movetoworkspace, r-1"];
        };
      };
    };
    logout = {
      scope = "home-manager";
      command = null;
      description = "Exit current window manager session securely";
      chord = ["SUPER" "SHIFT" "Q"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, Q, exit,"];
        };
      };
    };
    suspend = {
      scope = "home-manager";
      command = null;
      description = "Suspend machine state";
      chord = ["SUPER" "SHIFT" "U"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, U, exec, systemctl suspend"];
        };
      };
    };
    screenshotWindow = {
      scope = "home-manager";
      command = "hyprshot -m window";
      description = "Grab image screenshot of targeted active window";
      chord = ["SUPER" "ALT" "Print"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod ALT, Print, exec, hyprshot -m window"];
        };
      };
    };
    screenshotSelect = {
      scope = "home-manager";
      command = "grim -g \"$(slurp)\" - | wl-copy";
      description = "Grab image screenshot of interactively selected region";
      chord = ["SUPER" "ALT" "S"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod ALT, S, exec, grim -g \"$(slurp)\" - | wl-copy"];
        };
      };
    };
    captureWindow = {
      scope = "home-manager";
      command = "wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4 -g \"$(hyprctl activewindow -j | jq -r '.at[0],.at[1],.size[0],.size[1]' | paste -sd ' ' - | awk '{print $1\",\"$2\" \"$3\"x\"$4}')\"";
      description = "Begin screen recording of targeted active window";
      chord = ["SUPER" "CTRL" "ALT" "R"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod CTRL ALT, R, exec, wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4 -g \"$(hyprctl activewindow -j | jq -r '.at[0],.at[1],.size[0],.size[1]' | paste -sd ' ' - | awk '{print $1\",\"$2\" \"$3\"x\"$4}')\""];
        };
      };
    };
    captureSelect = {
      scope = "home-manager";
      command = "wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4 -g \"$(slurp)\"";
      description = "Begin screen recording of interactively selected region";
      chord = ["SUPER" "CTRL" "ALT" "S"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod CTRL ALT, S, exec, wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4 -g \"$(slurp)\""];
        };
      };
    };
    screenshotScreen = {
      scope = "home-manager";
      command = "grim ~/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png && wl-copy < ~/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png";
      description = "Grab image screenshot of all available display outputs";
      chord = ["SUPER" "ALT" "A"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod ALT, A, exec, grim ~/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png && wl-copy < ~/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png"];
        };
      };
    };
    captureScreen = {
      scope = "home-manager";
      command = "wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4";
      description = "Begin screen recording of all available display outputs";
      chord = ["SUPER" "CTRL" "ALT" "A"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod CTRL ALT, A, exec, wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4"];
        };
      };
    };

    # ╔════════════════════════════════════════════════╗
    # ╠ HARDWARE TRIGGERS & STATE LOCKS                ╣
    # ╚════════════════════════════════════════════════╝
    raiseVolume = {
      scope = "home-manager";
      command = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
      description = "Raise Volume";
      chord = ["XF86AudioRaiseVolume"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          binde = [", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"];
        };
      };
    };
    lowerVolume = {
      scope = "home-manager";
      command = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      description = "Lower Volume";
      chord = ["XF86AudioLowerVolume"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          binde = [", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"];
        };
      };
    };
    raiseBrightness = {
      scope = "home-manager";
      command = "brightnessctl set +5%";
      description = "Raise Brightness";
      chord = ["XF86MonBrightnessUp"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          binde = [", XF86MonBrightnessUp, exec, brightnessctl set +5%"];
        };
      };
    };
    lowerBrightness = {
      scope = "home-manager";
      command = "brightnessctl set 5%-";
      description = "Lower Brightness";
      chord = ["XF86MonBrightnessDown"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          binde = [", XF86MonBrightnessDown, exec, brightnessctl set 5%-"];
        };
      };
    };
    toggleMute = {
      scope = "home-manager";
      command = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      description = "Toggle Audio Mute";
      chord = ["SUPER" "XF86AudioMute"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bindl = ["$mod, XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"];
        };
      };
    };
    lockSession = {
      scope = "home-manager";
      command = "hyprlock";
      description = "Lock current window manager session";
      chord = ["SUPER" "L"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bindl = ["$mod, L, exec, hyprlock"];
        };
      };
    };
  };

  # ╔════════════════════════════════════════════════╗
  # ╠ SCRATCHPADS                                    ╣
  # ╚════════════════════════════════════════════════╝
  scratchpads = [
    {
      scope = "home-manager";
      name = "terminal";
      description = "Terminal Scratchpad";
      command = "foot --app-id scratch-term";
      chord = ["SUPER" "Grave"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod, Grave, togglespecialworkspace, scratch-term"];
          windowrulev2 = [
            "workspace special:scratch-term,class:^(scratch-term)$"
            "float,class:^(scratch-term)$"
          ];
        };
      };
    }
    {
      scope = "home-manager";
      name = "browser";
      description = "Browser Scratchpad";
      command = "zen-twilight --class scratch-browser";
      chord = ["SUPER" "SHIFT" "Grave"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod SHIFT, Grave, togglespecialworkspace, scratch-browser"];
          windowrulev2 = [
            "workspace special:scratch-browser,class:^(scratch-browser)$"
            "float,class:^(scratch-browser)$"
          ];
        };
      };
    }
    {
      scope = "home-manager";
      name = "explorer";
      description = "Explorer Scratchpad";
      command = "thunar --class scratch-explorer";
      chord = ["SUPER" "ALT" "Grave"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod ALT, Grave, togglespecialworkspace, scratch-explorer"];
          windowrulev2 = [
            "workspace special:scratch-explorer,class:^(scratch-explorer)$"
            "float,class:^(scratch-explorer)$"
          ];
        };
      };
    }
    {
      scope = "home-manager";
      name = "media";
      description = "Media Scratchpad (MPV)";
      command = "mpv --class scratch-media";
      chord = ["SUPER" "CTRL" "ALT" "Grave"];
      directive = {
        "wayland.windowManager.hyprland.settings" = {
          bind = ["$mod CTRL ALT, Grave, togglespecialworkspace, scratch-media"];
          windowrulev2 = [
            "workspace special:scratch-media,class:^(scratch-media)$"
            "float,class:^(scratch-media)$"
          ];
        };
      };
    }
  ];

  packages = ["jq" "wl-clipboard"];

  variables = {
    BAR = "bar";
    FOO = "foo";
    WAYLAND_DISPLAY = "wayland-1";
  };
}
