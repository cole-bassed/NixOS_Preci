{
  actions = {
    # ╔════════════════════════════════════════════════╗
    # ╠ APPLICATIONS                                   ╣
    # ╚════════════════════════════════════════════════╝
    # --------------------------------------------------
    # BROWSERS
    # --------------------------------------------------
    openBrowser1 = {
      scope = "nixos";
      command = "zen-twilight";
      description = "Launch the primary browser (Zen Browser)";
      chord = ["SUPER" "B"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,B,spawn,zen-twilight"];
        };
      };
    };
    openBrowser2 = {
      scope = "nixos";
      command = "chromium";
      description = "Launch the secondary browser (Chromium)";
      chord = ["SUPER" "SHIFT" "B"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,B,spawn,chromium"];
        };
      };
    };
    openBrowser3 = {
      scope = "nixos";
      command = "firefox";
      description = "Launch the tertiary browser (Firefox)";
      chord = ["SUPER" "ALT" "B"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+ALT,B,spawn,firefox"];
        };
      };
    };
    openZenBrowser = {
      scope = "nixos";
      command = "zen-twilight";
      description = "Launch Zen Browser";
      chord = ["SUPER" "SHIFT" "ALT" "B"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT+ALT,B,spawn,zen-twilight"];
        };
      };
    };
    openChromium = {
      scope = "nixos";
      command = "chromium";
      description = "Launch Chromium";
      chord = ["SUPER" "SHIFT" "ALT" "C"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT+ALT,C,spawn,chromium"];
        };
      };
    };
    # --------------------------------------------------
    # EDITORS (WRAPPED IN PRIMARY TERMINAL)
    # --------------------------------------------------
    openEditor1 = {
      scope = "nixos";
      command = "foot -e hx";
      description = "Launch the primary tty editor (Helix Editor)";
      chord = ["SUPER" "C"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,C,spawn,foot -e hx"];
        };
      };
    };
    openEditor2 = {
      scope = "nixos";
      command = "foot -e nvim";
      description = "Launch the secondary tty editor (NeoVim)";
      chord = ["SUPER" "SHIFT" "C"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,C,spawn,foot -e nvim"];
        };
      };
    };
    openEditor3 = {
      scope = "nixos";
      command = "foot -e nano";
      description = "Launch the tertiary tty editor (GNU Nano)";
      chord = ["SUPER" "ALT" "C"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+ALT,C,spawn,foot -e nano"];
        };
      };
    };
    # --------------------------------------------------
    # GUI EDITORS
    # --------------------------------------------------
    openVisual1 = {
      scope = "nixos";
      command = "code";
      description = "Launch the primary gui editor (Visual Studio Code)";
      chord = ["SUPER" "V"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,V,spawn,code"];
        };
      };
    };
    openVisual2 = {
      scope = "nixos";
      command = "zeditor";
      description = "Launch the secondary gui editor (Zed Editor)";
      chord = ["SUPER" "SHIFT" "V"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,V,spawn,zeditor"];
        };
      };
    };
    openVisual3 = {
      scope = "nixos";
      command = "antigravity";
      description = "Launch the tertiary gui editor (Antigravity IDE)";
      chord = ["SUPER" "ALT" "V"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+ALT,V,spawn,antigravity"];
        };
      };
    };
    openVscode = {
      scope = "nixos";
      command = "code";
      description = "Launch Visual Studio Code";
      chord = ["SUPER" "SHIFT" "ALT" "V"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT+ALT,V,spawn,code"];
        };
      };
    };
    openZed = {
      scope = "nixos";
      command = "zeditor";
      description = "Launch Zed Editor";
      chord = ["SUPER" "SHIFT" "ALT" "Z"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT+ALT,Z,spawn,zeditor"];
        };
      };
    };
    openAntigravity = {
      scope = "nixos";
      command = "antigravity";
      description = "Launch Antigravity IDE";
      chord = ["SUPER" "SHIFT" "ALT" "A"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT+ALT,A,spawn,antigravity"];
        };
      };
    };
    # --------------------------------------------------
    # FILE EXPLORERS
    # --------------------------------------------------
    openExplorer1 = {
      scope = "nixos";
      command = "doublecmd";
      description = "Launch the primary explorer (Double Commander)";
      chord = ["SUPER" "E"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,E,spawn,doublecmd"];
        };
      };
    };
    openExplorer2 = {
      scope = "nixos";
      command = "thunar";
      description = "Launch the secondary explorer (Thunar)";
      chord = ["SUPER" "SHIFT" "E"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,E,spawn,thunar"];
        };
      };
    };
    openExplorer3 = {
      scope = "nixos";
      command = "";
      description = "Launch the tertiary explorer (None)";
      chord = ["SUPER" "ALT" "E"];
      directive = {
        "programs.mangowm.settings" = {
          bind = [];
        };
      };
    };
    openDoublecmd = {
      scope = "nixos";
      command = "doublecmd";
      description = "Launch Double Commander File Manager";
      chord = ["SUPER" "SHIFT" "ALT" "D"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT+ALT,D,spawn,doublecmd"];
        };
      };
    };
    openThunar = {
      scope = "nixos";
      command = "thunar";
      description = "Launch Thunar File Manager";
      chord = ["SUPER" "SHIFT" "ALT" "T"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT+ALT,T,spawn,thunar"];
        };
      };
    };
    # --------------------------------------------------
    # LAUNCHERS
    # --------------------------------------------------
    openLauncher1 = {
      scope = "nixos";
      command = "dank-launcher";
      description = "Launch the primary launcher (Dank Material Shell Launcher)";
      chord = ["SUPER" "Space"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,Space,spawn,dank-launcher"];
        };
      };
    };
    openLauncher2 = {
      scope = "nixos";
      command = "vicinae open";
      description = "Launch the secondary launcher (Vicinae)";
      chord = ["SUPER" "SHIFT" "Space"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,Space,spawn,vicinae open"];
        };
      };
    };
    openLauncher3 = {
      scope = "nixos";
      command = "fuzzel";
      description = "Launch the tertiary launcher (Fuzzel)";
      chord = ["SUPER" "ALT" "Space"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+ALT,Space,spawn,fuzzel"];
        };
      };
    };
    # --------------------------------------------------
    # TERMINALS
    # --------------------------------------------------
    openTerminal1 = {
      scope = "nixos";
      command = "foot";
      description = "Launch the primary terminal (Foot)";
      chord = ["SUPER" "Return"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,Return,spawn,foot"];
        };
      };
    };
    openTerminal2 = {
      scope = "nixos";
      command = "kitty";
      description = "Launch the secondary terminal (Kitty)";
      chord = ["SUPER" "SHIFT" "Return"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,Return,spawn,kitty"];
        };
      };
    };
    openTerminal3 = {
      scope = "nixos";
      command = "ghostty";
      description = "Launch the tertiary terminal (Ghostty)";
      chord = ["SUPER" "ALT" "Return"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+ALT,Return,spawn,ghostty"];
        };
      };
    };
    openFoot = {
      scope = "nixos";
      command = "foot";
      description = "Launch Foot Terminal";
      chord = ["SUPER" "SHIFT" "ALT" "F"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT+ALT,F,spawn,foot"];
        };
      };
    };
    openKitty = {
      scope = "nixos";
      command = "kitty";
      description = "Launch Kitty Terminal";
      chord = ["SUPER" "SHIFT" "ALT" "K"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT+ALT,K,spawn,kitty"];
        };
      };
    };
    openGhostty = {
      scope = "nixos";
      command = "ghostty";
      description = "Launch Ghostty Terminal";
      chord = ["SUPER" "SHIFT" "ALT" "G"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT+ALT,G,spawn,ghostty"];
        };
      };
    };

    # ╔════════════════════════════════════════════════╗
    # ╠ SYSTEM CONTROLS & CAPTURE                      ╣
    # ╚════════════════════════════════════════════════╝
    closeWindow = {
      scope = "nixos";
      command = null;
      description = "Close Active Window";
      chord = ["SUPER" "SHIFT" "W"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,W,killclient"];
        };
      };
    };
    toggleFloating = {
      scope = "nixos";
      command = null;
      description = "Toggle Window Floating State";
      chord = ["SUPER" "H"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,H,togglefloating"];
        };
      };
    };
    toggleFullscreen = {
      scope = "nixos";
      command = null;
      description = "Toggle Active Window Fullscreen State";
      chord = ["SUPER" "F"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,F,togglefullscreen"];
        };
      };
    };
    togglePip = {
      scope = "nixos";
      command = null;
      description = "Toggle Picture-in-Picture mode (Floating, Sticky, Pins on Top)";
      chord = ["SUPER" "P"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,P,togglefloating"];
        };
      };
    };
    moveFocusUp = {
      scope = "nixos";
      command = null;
      description = "Move focus to the window above";
      chord = ["SUPER" "K"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,K,focusdir,up"];
        };
      };
    };
    moveFocusDown = {
      scope = "nixos";
      command = null;
      description = "Move focus to the window below";
      chord = ["SUPER" "J"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,J,focusdir,down"];
        };
      };
    };
    moveFocusLeft = {
      scope = "nixos";
      command = null;
      description = "Move focus to the window on the left";
      chord = ["SUPER" "H"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,H,focusdir,left"];
        };
      };
    };
    moveFocusRight = {
      scope = "nixos";
      command = null;
      description = "Move focus to the window on the right";
      chord = ["SUPER" "L"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,L,focusdir,right"];
        };
      };
    };
    moveWindowUp = {
      scope = "nixos";
      command = null;
      description = "Move window position upward";
      chord = ["SUPER" "SHIFT" "K"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,K,exchange_client,up"];
        };
      };
    };
    moveWindowDown = {
      scope = "nixos";
      command = null;
      description = "Move window position downward";
      chord = ["SUPER" "SHIFT" "J"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,J,exchange_client,down"];
        };
      };
    };
    moveWindowLeft = {
      scope = "nixos";
      command = null;
      description = "Move window position leftward";
      chord = ["SUPER" "SHIFT" "H"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,H,exchange_client,left"];
        };
      };
    };
    moveWindowRight = {
      scope = "nixos";
      command = null;
      description = "Move window position rightward";
      chord = ["SUPER" "SHIFT" "L"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,L,exchange_client,right"];
        };
      };
    };
    focusNextMonitor = {
      scope = "nixos";
      command = null;
      description = "Shift tracking view context to next monitor";
      chord = ["SUPER" "Tab"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,Tab,focusmon,right"];
        };
      };
    };
    focusPrevMonitor = {
      scope = "nixos";
      command = null;
      description = "Shift tracking view context to previous monitor";
      chord = ["SUPER" "Tab"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,Tab,focusmon,left"];
        };
      };
    };
    moveMonitorNext = {
      scope = "nixos";
      command = null;
      description = "Send active window to next monitor";
      chord = ["SUPER" "SHIFT" "Tab"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,Tab,tagmon,right,1"];
        };
      };
    };
    moveMonitorPrev = {
      scope = "nixos";
      command = null;
      description = "Send active window to previous monitor";
      chord = ["SUPER" "SHIFT" "Tab"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,Tab,tagmon,left,1"];
        };
      };
    };
    focusNextWorkspace = {
      scope = "nixos";
      command = null;
      description = "Cycle display viewport forward by index";
      chord = ["SUPER" "Right"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,Right,viewtoright"];
        };
      };
    };
    focusPrevWorkspace = {
      scope = "nixos";
      command = null;
      description = "Cycle display viewport backward by index";
      chord = ["SUPER" "Left"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,Left,viewtoleft"];
        };
      };
    };
    moveWorkspaceNext = {
      scope = "nixos";
      command = null;
      description = "Send active window to next workspace index";
      chord = ["SUPER" "SHIFT" "Right"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,Right,tagtoright"];
        };
      };
    };
    moveWorkspacePrev = {
      scope = "nixos";
      command = null;
      description = "Send active window to previous workspace index";
      chord = ["SUPER" "SHIFT" "Left"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,Left,tagtoleft"];
        };
      };
    };
    logout = {
      scope = "nixos";
      command = null;
      description = "Exit current window manager session securely";
      chord = ["SUPER" "SHIFT" "Q"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,Q,quit"];
        };
      };
    };
    suspend = {
      scope = "nixos";
      command = null;
      description = "Suspend machine state";
      chord = ["SUPER" "SHIFT" "U"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,U,spawn,systemctl suspend"];
        };
      };
    };
    screenshotWindow = {
      scope = "nixos";
      command = "hyprshot -m window";
      description = "Grab image screenshot of targeted active window";
      chord = ["SUPER" "ALT" "Print"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+ALT,Print,spawn,hyprshot -m window"];
        };
      };
    };
    screenshotSelect = {
      scope = "nixos";
      command = "grim -g \"$(slurp)\" - | wl-copy";
      description = "Grab image screenshot of interactively selected region";
      chord = ["SUPER" "ALT" "S"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+ALT,S,spawn_shell,grim -g \"$(slurp)\" - | wl-copy"];
        };
      };
    };
    captureWindow = {
      scope = "nixos";
      command = "wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4 -g \"$(hyprctl activewindow -j | jq -r '.at[0],.at[1],.size[0],.size[1]' | paste -sd ' ' - | awk '{print $1\",\"$2\" \"$3\"x\"$4}')\"";
      description = "Begin screen recording of targeted active window";
      chord = ["SUPER" "CTRL" "ALT" "R"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+CTRL+ALT,R,spawn_shell,wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4 -g \"$(hyprctl activewindow -j | jq -r '.at[0],.at[1],.size[0],.size[1]' | paste -sd ' ' - | awk '{print $1\",\"$2\" \"$3\"x\"$4}')\""];
        };
      };
    };
    captureSelect = {
      scope = "nixos";
      command = "wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4 -g \"$(slurp)\"";
      description = "Begin screen recording of interactively selected region";
      chord = ["SUPER" "CTRL" "ALT" "S"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+CTRL+ALT,S,spawn_shell,wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4 -g \"$(slurp)\""];
        };
      };
    };
    screenshotScreen = {
      scope = "nixos";
      command = "grim ~/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png && wl-copy < ~/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png";
      description = "Grab image screenshot of all available display outputs";
      chord = ["SUPER" "ALT" "A"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+ALT,A,spawn_shell,grim ~/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png && wl-copy < ~/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png"];
        };
      };
    };
    captureScreen = {
      scope = "nixos";
      command = "wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4";
      description = "Begin screen recording of all available display outputs";
      chord = ["SUPER" "CTRL" "ALT" "A"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+CTRL+ALT,A,spawn_shell,wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4"];
        };
      };
    };

    # ╔════════════════════════════════════════════════╗
    # ╠ HARDWARE TRIGGERS & STATE LOCKS                ╣
    # ╚════════════════════════════════════════════════╝
    raiseVolume = {
      scope = "nixos";
      command = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
      description = "Raise Volume";
      chord = ["XF86AudioRaiseVolume"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"];
        };
      };
    };
    lowerVolume = {
      scope = "nixos";
      command = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      description = "Lower Volume";
      chord = ["XF86AudioLowerVolume"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"];
        };
      };
    };
    raiseBrightness = {
      scope = "nixos";
      command = "brightnessctl set +5%";
      description = "Raise Brightness";
      chord = ["XF86MonBrightnessUp"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["NONE,XF86MonBrightnessUp,spawn,brightnessctl set +5%"];
        };
      };
    };
    lowerBrightness = {
      scope = "nixos";
      command = "brightnessctl set 5%-";
      description = "Lower Brightness";
      chord = ["XF86MonBrightnessDown"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["NONE,XF86MonBrightnessDown,spawn,brightnessctl set 5%-"];
        };
      };
    };
    toggleMute = {
      scope = "nixos";
      command = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      description = "Toggle Audio Mute";
      chord = ["SUPER" "XF86AudioMute"];
      directive = {
        "programs.mangowm.settings" = {
          bindl = ["SUPER,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"];
        };
      };
    };
    lockSession = {
      scope = "nixos";
      command = "hyprlock";
      description = "Lock current window manager session";
      chord = ["SUPER" "L"];
      directive = {
        "programs.mangowm.settings" = {
          bindl = ["SUPER,L,spawn,hyprlock"];
        };
      };
    };
  };

  # ╔════════════════════════════════════════════════╗
  # ╠ SCRATCHPADS                                    ╣
  # ╚════════════════════════════════════════════════╝
  scratchpads = [
    {
      scope = "nixos";
      name = "terminal";
      description = "Terminal Scratchpad";
      command = "foot --app-id scratch-term";
      chord = ["SUPER" "Grave"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER,Grave,toggle_named_scratchpad,scratch-term,none,foot --app-id scratch-term"];
          windowrule = ["isnamedscratchpad:1,appid:scratch-term"];
        };
      };
    }
    {
      scope = "nixos";
      name = "media";
      description = "Media Scratchpad (MPV)";
      command = "mpv --class scratch-media";
      chord = ["SUPER" "SHIFT" "Grave"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+SHIFT,Grave,toggle_named_scratchpad,scratch-media,none,mpv --class scratch-media"];
          windowrule = ["isnamedscratchpad:1,appid:scratch-media"];
        };
      };
    }
    {
      scope = "nixos";
      name = "explorer";
      description = "Explorer Scratchpad";
      command = "thunar --class scratch-explorer";
      chord = ["SUPER" "ALT" "Grave"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+ALT,Grave,toggle_named_scratchpad,scratch-explorer,none,thunar --class scratch-explorer"];
          windowrule = ["isnamedscratchpad:1,appid:scratch-explorer"];
        };
      };
    }
    {
      scope = "nixos";
      name = "browser";
      description = "Browser Scratchpad";
      command = "zen-twilight --class scratch-browser";
      chord = ["SUPER" "CTRL" "ALT" "Grave"];
      directive = {
        "programs.mangowm.settings" = {
          bind = ["SUPER+CTRL+ALT,Grave,toggle_named_scratchpad,scratch-browser,none,zen-twilight --class scratch-browser"];
          windowrule = ["isnamedscratchpad:1,appid:scratch-browser"];
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
