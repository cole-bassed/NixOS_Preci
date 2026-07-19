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
      chord = ["Mod" "B"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+B { spawn \"zen-twilight\"; }"];
        };
      };
    };
    openBrowser2 = {
      scope = "home-manager";
      command = "chromium";
      description = "Launch the secondary browser (Chromium)";
      chord = ["Mod" "Shift" "B"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+B { spawn \"chromium\"; }"];
        };
      };
    };
    openBrowser3 = {
      scope = "home-manager";
      command = "firefox";
      description = "Launch the tertiary browser (Firefox)";
      chord = ["Mod" "Alt" "B"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Alt+B { spawn \"firefox\"; }"];
        };
      };
    };
    openZenBrowser = {
      scope = "home-manager";
      command = "zen-twilight";
      description = "Launch Zen Browser";
      chord = ["Mod" "Shift" "Alt" "B"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Alt+B { spawn \"zen-twilight\"; }"];
        };
      };
    };
    openChromium = {
      scope = "home-manager";
      command = "chromium";
      description = "Launch Chromium";
      chord = ["Mod" "Shift" "Alt" "C"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Alt+C { spawn \"chromium\"; }"];
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
      chord = ["Mod" "C"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+C { spawn \"foot\" \"-e\" \"hx\"; }"];
        };
      };
    };
    openEditor2 = {
      scope = "home-manager";
      command = "foot -e nvim";
      description = "Launch the secondary tty editor (NeoVim)";
      chord = ["Mod" "Shift" "C"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+C { spawn \"foot\" \"-e\" \"nvim\"; }"];
        };
      };
    };
    openEditor3 = {
      scope = "home-manager";
      command = "foot -e nano";
      description = "Launch the tertiary tty editor (GNU Nano)";
      chord = ["Mod" "Alt" "C"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Alt+C { spawn \"foot\" \"-e\" \"nano\"; }"];
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
      chord = ["Mod" "V"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+V { spawn \"code\"; }"];
        };
      };
    };
    openVisual2 = {
      scope = "home-manager";
      command = "zeditor";
      description = "Launch the secondary gui editor (Zed Editor)";
      chord = ["Mod" "Shift" "V"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+V { spawn \"zeditor\"; }"];
        };
      };
    };
    openVisual3 = {
      scope = "home-manager";
      command = "antigravity";
      description = "Launch the tertiary gui editor (Antigravity IDE)";
      chord = ["Mod" "Alt" "V"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Alt+V { spawn \"antigravity\"; }"];
        };
      };
    };
    openVscode = {
      scope = "home-manager";
      command = "code";
      description = "Launch Visual Studio Code";
      chord = ["Mod" "Shift" "Alt" "V"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Alt+V { spawn \"code\"; }"];
        };
      };
    };
    openZed = {
      scope = "home-manager";
      command = "zeditor";
      description = "Launch Zed Editor";
      chord = ["Mod" "Shift" "Alt" "Z"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Alt+Z { spawn \"zeditor\"; }"];
        };
      };
    };
    openAntigravity = {
      scope = "home-manager";
      command = "antigravity";
      description = "Launch Antigravity IDE";
      chord = ["Mod" "Shift" "Alt" "A"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Alt+A { spawn \"antigravity\"; }"];
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
      chord = ["Mod" "E"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+E { spawn \"doublecmd\"; }"];
        };
      };
    };
    openExplorer2 = {
      scope = "home-manager";
      command = "thunar";
      description = "Launch the secondary explorer (Thunar)";
      chord = ["Mod" "Shift" "E"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+E { spawn \"thunar\"; }"];
        };
      };
    };
    openExplorer3 = {
      scope = "home-manager";
      command = "";
      description = "Launch the tertiary explorer (None)";
      chord = ["Mod" "Alt" "E"];
      directive = {
        "programs.niri.settings" = {
          binds = [];
        };
      };
    };
    openDoublecmd = {
      scope = "home-manager";
      command = "doublecmd";
      description = "Launch Double Commander File Manager";
      chord = ["Mod" "Shift" "Alt" "D"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Alt+D { spawn \"doublecmd\"; }"];
        };
      };
    };
    openThunar = {
      scope = "home-manager";
      command = "thunar";
      description = "Launch Thunar File Manager";
      chord = ["Mod" "Shift" "Alt" "T"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Alt+T { spawn \"thunar\"; }"];
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
      chord = ["Mod" "Space"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Space { spawn \"dank-launcher\"; }"];
        };
      };
    };
    openLauncher2 = {
      scope = "home-manager";
      command = "vicinae open";
      description = "Launch the secondary launcher (Vicinae)";
      chord = ["Mod" "Shift" "Space"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Space { spawn \"vicinae\" \"open\"; }"];
        };
      };
    };
    openLauncher3 = {
      scope = "home-manager";
      command = "fuzzel";
      description = "Launch the tertiary launcher (Fuzzel)";
      chord = ["Mod" "Alt" "Space"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Alt+Space { spawn \"fuzzel\"; }"];
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
      chord = ["Mod" "Return"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Return { spawn \"foot\"; }"];
        };
      };
    };
    openTerminal2 = {
      scope = "home-manager";
      command = "kitty";
      description = "Launch the secondary terminal (Kitty)";
      chord = ["Mod" "Shift" "Return"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Return { spawn \"kitty\"; }"];
        };
      };
    };
    openTerminal3 = {
      scope = "home-manager";
      command = "ghostty";
      description = "Launch the tertiary terminal (Ghostty)";
      chord = ["Mod" "Alt" "Return"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Alt+Return { spawn \"ghostty\"; }"];
        };
      };
    };
    openFoot = {
      scope = "home-manager";
      command = "foot";
      description = "Launch Foot Terminal";
      chord = ["Mod" "Shift" "Alt" "F"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Alt+F { spawn \"foot\"; }"];
        };
      };
    };
    openKitty = {
      scope = "home-manager";
      command = "kitty";
      description = "Launch Kitty Terminal";
      chord = ["Mod" "Shift" "Alt" "K"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Alt+K { spawn \"kitty\"; }"];
        };
      };
    };
    openGhostty = {
      scope = "home-manager";
      command = "ghostty";
      description = "Launch Ghostty Terminal";
      chord = ["Mod" "Shift" "Alt" "G"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Alt+G { spawn \"ghostty\"; }"];
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
      chord = ["Mod" "Shift" "W"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+W { close-window; }"];
        };
      };
    };
    toggleFloating = {
      scope = "home-manager";
      command = null;
      description = "Toggle Window Floating State";
      chord = ["Mod" "H"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+H { toggle-window-floating; }"];
        };
      };
    };
    toggleFullscreen = {
      scope = "home-manager";
      command = null;
      description = "Toggle Active Window Fullscreen State";
      chord = ["Mod" "F"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+F { maximize-column; }"];
        };
      };
    };
    togglePip = {
      scope = "home-manager";
      command = null;
      description = "Toggle Picture-in-Picture mode (Floating status tracking)";
      chord = ["Mod" "P"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+P { toggle-window-floating; }"];
        };
      };
    };
    moveFocusUp = {
      scope = "home-manager";
      command = null;
      description = "Move focus to the window above";
      chord = ["Mod" "K"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+K { focus-window-up; }"];
        };
      };
    };
    moveFocusDown = {
      scope = "home-manager";
      command = null;
      description = "Move focus to the window below";
      chord = ["Mod" "J"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+J { focus-window-down; }"];
        };
      };
    };
    moveFocusLeft = {
      scope = "home-manager";
      command = null;
      description = "Move focus to the column on the left";
      chord = ["Mod" "H"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+H { focus-column-left; }"];
        };
      };
    };
    moveFocusRight = {
      scope = "home-manager";
      command = null;
      description = "Move focus to the column on the right";
      chord = ["Mod" "L"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+L { focus-column-right; }"];
        };
      };
    };
    moveWindowUp = {
      scope = "home-manager";
      command = null;
      description = "Move window position upward";
      chord = ["Mod" "Shift" "K"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+K { move-window-up; }"];
        };
      };
    };
    moveWindowDown = {
      scope = "home-manager";
      command = null;
      description = "Move window position downward";
      chord = ["Mod" "Shift" "J"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+J { move-window-down; }"];
        };
      };
    };
    moveWindowLeft = {
      scope = "home-manager";
      command = null;
      description = "Move column position leftward";
      chord = ["Mod" "Shift" "H"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+H { move-column-left; }"];
        };
      };
    };
    moveWindowRight = {
      scope = "home-manager";
      command = null;
      description = "Move column position rightward";
      chord = ["Mod" "Shift" "L"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+L { move-column-right; }"];
        };
      };
    };
    focusNextMonitor = {
      scope = "home-manager";
      command = null;
      description = "Shift tracking view context to next monitor";
      chord = ["Mod" "Tab"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Tab { focus-monitor-next; }"];
        };
      };
    };
    focusPrevMonitor = {
      scope = "home-manager";
      command = null;
      description = "Shift tracking view context to previous monitor";
      chord = ["Mod" "Tab"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Tab { focus-monitor-previous; }"];
        };
      };
    };
    moveMonitorNext = {
      scope = "home-manager";
      command = null;
      description = "Send active column to next monitor";
      chord = ["Mod" "Shift" "Tab"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Tab { move-column-to-monitor-next; }"];
        };
      };
    };
    moveMonitorPrev = {
      scope = "home-manager";
      command = null;
      description = "Send active column to previous monitor";
      chord = ["Mod" "Shift" "Tab"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Tab { move-column-to-monitor-previous; }"];
        };
      };
    };
    focusNextWorkspace = {
      scope = "home-manager";
      command = null;
      description = "Cycle display viewport forward by index";
      chord = ["Mod" "Right"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Right { focus-workspace-down; }"];
        };
      };
    };
    focusPrevWorkspace = {
      scope = "home-manager";
      command = null;
      description = "Cycle display viewport backward by index";
      chord = ["Mod" "Left"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Left { focus-workspace-up; }"];
        };
      };
    };
    moveWorkspaceNext = {
      scope = "home-manager";
      command = null;
      description = "Send active column to next workspace index";
      chord = ["Mod" "Shift" "Right"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Right { move-column-to-workspace-down; }"];
        };
      };
    };
    moveWorkspacePrev = {
      scope = "home-manager";
      command = null;
      description = "Send active column to previous workspace index";
      chord = ["Mod" "Shift" "Left"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Left { move-column-to-workspace-up; }"];
        };
      };
    };
    logout = {
      scope = "home-manager";
      command = null;
      description = "Exit current window manager session securely";
      chord = ["Mod" "Shift" "Q"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Q { quit; }"];
        };
      };
    };
    suspend = {
      scope = "home-manager";
      command = null;
      description = "Suspend machine state";
      chord = ["Mod" "Shift" "U"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+U { spawn \"systemctl\" \"suspend\"; }"];
        };
      };
    };
    screenshotWindow = {
      scope = "home-manager";
      command = "niri msg action screenshot-window";
      description = "Grab image screenshot of targeted active window";
      chord = ["Mod" "Alt" "Print"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Alt+Print { screenshot-window; }"];
        };
      };
    };
    screenshotSelect = {
      scope = "home-manager";
      command = "grim -g \"$(slurp)\" - | wl-copy";
      description = "Grab image screenshot of interactively selected region";
      chord = ["Mod" "Alt" "S"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Alt+S { spawn-sh \"grim -g \\\"$(slurp)\\\" - | wl-copy\"; }"];
        };
      };
    };
    captureWindow = {
      scope = "home-manager";
      command = "wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4";
      description = "Begin screen recording of targeted context";
      chord = ["Mod" "Ctrl" "Alt" "R"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Ctrl+Alt+R { spawn-sh \"wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4\"; }"];
        };
      };
    };
    captureSelect = {
      scope = "home-manager";
      command = "wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4 -g \"$(slurp)\"";
      description = "Begin screen recording of interactively selected region";
      chord = ["Mod" "Ctrl" "Alt" "S"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Ctrl+Alt+S { spawn-sh \"wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4 -g \\\"$(slurp)\\\"\"; }"];
        };
      };
    };
    screenshotScreen = {
      scope = "home-manager";
      command = "niri msg action screenshot";
      description = "Grab image screenshot of all available display outputs";
      chord = ["Mod" "Alt" "A"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Alt+A { screenshot; }"];
        };
      };
    };
    captureScreen = {
      scope = "home-manager";
      command = "wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4";
      description = "Begin screen recording of all available display outputs";
      chord = ["Mod" "Ctrl" "Alt" "A"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Ctrl+Alt+A { spawn-sh \"wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4\"; }"];
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
        "programs.niri.settings" = {
          binds = ["XF86AudioRaiseVolume allow-inhibiting=false { spawn \"wpctl\" \"set-volume\" \"@DEFAULT_AUDIO_SINK@\" \"5%+\"; }"];
        };
      };
    };
    lowerVolume = {
      scope = "home-manager";
      command = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      description = "Lower Volume";
      chord = ["XF86AudioLowerVolume"];
      directive = {
        "programs.niri.settings" = {
          binds = ["XF86AudioLowerVolume allow-inhibiting=false { spawn \"wpctl\" \"set-volume\" \"@DEFAULT_AUDIO_SINK@\" \"5%-\"; }"];
        };
      };
    };
    raiseBrightness = {
      scope = "home-manager";
      command = "brightnessctl set +5%";
      description = "Raise Brightness";
      chord = ["XF86MonBrightnessUp"];
      directive = {
        "programs.niri.settings" = {
          binds = ["XF86MonBrightnessUp allow-inhibiting=false { spawn \"brightnessctl\" \"set\" \"+5%\"; }"];
        };
      };
    };
    lowerBrightness = {
      scope = "home-manager";
      command = "brightnessctl set 5%-";
      description = "Lower Brightness";
      chord = ["XF86MonBrightnessDown"];
      directive = {
        "programs.niri.settings" = {
          binds = ["XF86MonBrightnessDown allow-inhibiting=false { spawn \"brightnessctl\" \"set\" \"5%-\"; }"];
        };
      };
    };
    toggleMute = {
      scope = "home-manager";
      command = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      description = "Toggle Audio Mute";
      chord = ["Mod" "XF86AudioMute"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+XF86AudioMute allow-inhibiting=false { spawn \"wpctl\" \"set-mute\" \"@DEFAULT_AUDIO_SINK@\" \"toggle\"; }"];
        };
      };
    };
    lockSession = {
      scope = "home-manager";
      command = "hyprlock";
      description = "Lock current window manager session";
      chord = ["Mod" "L"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+L { spawn \"hyprlock\"; }"];
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
      chord = ["Mod" "Grave"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Grave { toggle-window-flag \"scratchpad\"; }"];
          window-rules = ["{ matches { app-id \"scratch-term\"; } open-floating true; open-on-output \"primary\"; }"];
        };
      };
    }
    {
      scope = "home-manager";
      name = "media";
      description = "Media Scratchpad (MPV)";
      command = "mpv --class scratch-media";
      chord = ["Mod" "Shift" "Grave"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Shift+Grave { toggle-window-flag \"scratchpad\"; }"];
          window-rules = ["{ matches { app-id \"scratch-media\"; } open-floating true; open-on-output \"primary\"; }"];
        };
      };
    }
    {
      scope = "home-manager";
      name = "explorer";
      description = "Explorer Scratchpad";
      command = "thunar --class scratch-explorer";
      chord = ["Mod" "Alt" "Grave"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Alt+Grave { toggle-window-flag \"scratchpad\"; }"];
          window-rules = ["{ matches { app-id \"scratch-explorer\"; } open-floating true; open-on-output \"primary\"; }"];
        };
      };
    }
    {
      scope = "home-manager";
      name = "browser";
      description = "Browser Scratchpad";
      command = "zen-twilight --class scratch-browser";
      chord = ["Mod" "Ctrl" "Alt" "Grave"];
      directive = {
        "programs.niri.settings" = {
          binds = ["Mod+Ctrl+Alt+Grave { toggle-window-flag \"scratchpad\"; }"];
          window-rules = ["{ matches { app-id \"scratch-browser\"; } open-floating true; open-on-output \"primary\"; }"];
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
