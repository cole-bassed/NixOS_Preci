let
  common = {
    applications = {
      browser = [
        {
          name = "zen-browser";
          description = "Zen Browser";
          command = "zen-twilight";
          bindings = {launch = "B";};
        }
        {
          name = "chromium";
          description = "Chromium";
          command = "chromium";
          bindings = {launch = "C";};
        }
        {
          name = "firefox";
          description = "Firefox";
          command = "firefox";
        }
      ];
      editor = [
        {
          name = "helix";
          description = "Helix Editor";
          command = "hx";
        }
        {
          name = "neovim";
          description = "NeoVim";
          command = "nvim";
        }
        {
          name = "nano";
          description = "GNU Nano";
          command = "nano";
        }
      ];
      explorer = [
        {
          name = "doublecmd";
          description = "Double Commander File Manager";
          command = "doublecmd";
          bindings = {launch = "D";};
        }
        {
          name = "thunar";
          description = "Thunar File Manager";
          command = "thunar";
          bindings = {launch = "T";};
        }
      ];
      player = [
        {
          name = "mpv";
          description = "MPV Media Player";
          command = "mpv";
        }
      ];
      terminal = [
        {
          name = "kitty";
          description = "Kitty Terminal";
          command = "kitty";
          bindings = {launch = "K";};
        }
        {
          name = "ghostty";
          description = "Ghostty Terminal";
          command = "ghostty";
          bindings = {launch = "G";};
        }
      ];
      launcher = [
        {
          name = "vicinae";
          description = "Vicinae Launcher";
          command = "vicinae open";
        }
      ];
      screenshot = [];
      visual = [
        {
          name = "vscode";
          description = "Visual Studio Code";
          command = "code";
          bindings = {launch = "V";};
        }
        {
          name = "zed";
          description = "Zed Editor";
          command = "zeditor";
          bindings = {launch = "Z";};
        }
        {
          name = "antigravity";
          description = "Antigravity IDE";
          command = "antigravity";
          bindings = {launch = "A";};
        }
      ];
    };

    scratchpads = [
      {
        name = "terminal";
        description = "Terminal Scratchpad";
        command = "kitty --class scratch-term";
        bindings = {launch = "Grave";};
      }
      {
        name = "browser";
        description = "Browser Scratchpad";
        command = "zen-twilight --class scratch-browser";
        bindings = {launch = "B";};
      }
      {
        name = "explorer";
        description = "Explorer Scratchpad";
        command = "thunar --class scratch-explorer";
        bindings = {launch = "E";};
      }
      {
        name = "media";
        description = "Media Scratchpad (MPV)";
        command = "mpv --class scratch-media";
        bindings = {launch = "M";};
      }
    ];

    controls = {
      window = {
        closeWindow = {
          description = "Close Active Window";
          action = "closeWindow";
          bindings = {launch = "W";};
        };
        toggleFloating = {
          description = "Toggle Window Floating State";
          action = "toggleFloating";
          bindings = {launch = "Space";};
        };
        toggleFullscreen = {
          description = "Toggle Active Window Fullscreen State";
          action = "toggleFullscreen";
          bindings = {launch = "F";};
        };
        moveFocusUp = {
          description = "Move focus to the window above";
          action = "focusUp";
          bindings = {launch = "K";};
        };
        moveFocusDown = {
          description = "Move focus to the window below";
          action = "focusDown";
          bindings = {launch = "J";};
        };
        moveFocusLeft = {
          description = "Move focus to the window on the left";
          action = "focusLeft";
          bindings = {launch = "H";};
        };
        moveFocusRight = {
          description = "Move focus to the window on the right";
          action = "focusRight";
          bindings = {launch = "L";};
        };
        moveWindowUp = {
          description = "Move window position upward";
          action = "moveWindowUp";
          bindings = {launch = "K";};
        };
        moveWindowDown = {
          description = "Move window position downward";
          action = "moveWindowDown";
          bindings = {launch = "J";};
        };
        moveWindowLeft = {
          description = "Move window position leftward";
          action = "moveWindowLeft";
          bindings = {launch = "H";};
        };
        moveWindowRight = {
          description = "Move window position rightward";
          action = "moveWindowRight";
          bindings = {launch = "L";};
        };
        # Static Image Screenshots
        screenshotWindow = {
          description = "Grab image screenshot of targeted active window";
          action = "screenshotWindow";
          bindings = {launch = "Print";};
        };
        screenshotSelect = {
          description = "Grab image screenshot of interactively selected region";
          action = "screenshotSelect";
          bindings = {launch = "S";};
        };
        # Dynamic Video Captures
        captureWindow = {
          description = "Begin screen recording of targeted active window";
          action = "captureWindow";
          bindings = {launch = "R";};
        };
        captureSelect = {
          description = "Begin screen recording of interactively selected region";
          action = "captureSelect";
          bindings = {launch = "SHIFT+R";}; # Downstream handles mask parsing
        };
      };

      screen = {
        focusNextMonitor = {
          description = "Shift tracking view context to next monitor";
          action = "focusNextMonitor";
          bindings = {launch = "Tab";};
        };
        focusPrevMonitor = {
          description = "Shift tracking view context to previous monitor";
          action = "focusPrevMonitor";
          bindings = {launch = "Tab";};
        };
        moveMonitorNext = {
          description = "Send active window to next monitor";
          action = "moveMonitorNext";
          bindings = {launch = "Tab";};
        };
        moveMonitorPrev = {
          description = "Send active window to previous monitor";
          action = "moveMonitorPrev";
          bindings = {launch = "Tab";};
        };
        screenshotFullscreen = {
          description = "Grab image screenshot of all available display outputs";
          action = "screenshotFullscreen";
          bindings = {launch = "A";};
        };
        captureFullscreen = {
          description = "Begin screen recording of all available display outputs";
          action = "captureFullscreen";
          bindings = {launch = "A";};
        };
      };

      workspace = {
        focusNextWorkspace = {
          description = "Cycle display viewport forward by index";
          action = "focusNextWorkspace";
          bindings = {launch = "Right";};
        };
        focusPrevWorkspace = {
          description = "Cycle display viewport backward by index";
          action = "focusPrevWorkspace";
          bindings = {launch = "Left";};
        };
        moveWorkspaceNext = {
          description = "Send active window to next workspace index";
          action = "moveWorkspaceNext";
          bindings = {launch = "Right";};
        };
        moveWorkspacePrev = {
          description = "Send active window to previous workspace index";
          action = "moveWorkspacePrev";
          bindings = {launch = "Left";};
        };
      };

      session = {
        lockSession = {
          description = "Lock current window manager session";
          action = "lockSession";
          bindings = {launch = "L";};
        };
        logoutSession = {
          description = "Exit current window manager session securely";
          action = "logoutSession";
          bindings = {launch = "Q";};
        };
        suspendSession = {
          description = "Suspend machine state";
          action = "suspendSession";
          bindings = {launch = "U";};
        };
      };

      hardware = {
        raiseVolume = {
          description = "Raise Volume";
          command = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          bindings = {launch = "XF86AudioRaiseVolume";};
        };
        lowerVolume = {
          description = "Lower Volume";
          command = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          bindings = {launch = "XF86AudioLowerVolume";};
        };
        toggleMute = {
          description = "Toggle Audio Mute";
          command = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          bindings = {launch = "XF86AudioMute";};
        };
        raiseBrightness = {
          description = "Raise Brightness";
          command = "brightnessctl set +5%";
          bindings = {launch = "XF86MonBrightnessUp";};
        };
        lowerBrightness = {
          description = "Lower Brightness";
          command = "brightnessctl set 5%-";
          bindings = {launch = "XF86MonBrightnessDown";};
        };
      };
    };

    bindings = {
      browser = "B";
      editor = "C";
      explorer = "E";
      launcher = "SUPER_L";
      modifier = "SUPER";
      swapCapsEscape = false;
      terminal = "Return";
      visual = "V";
    };

    variables = {
      FOO = "foo";
      BAR = "bar";
    };
  };

  wayland = {
    applications = {
      terminal =
        [
          {
            name = "foot";
            description = "Foot Terminal";
            command = "foot";
            bindings = {launch = "F";};
          }
        ]
        ++ common.applications.terminal;
      launcher =
        common.applications.launcher
        ++ [
          {
            name = "fuzzel";
            description = "Fuzzel Launcher";
            command = "fuzzel";
          }
        ];
      screenshot = [
        {
          name = "grimshot";
          description = "Region Screenshot (Grim/Slurp)";
          command = "grim -g \"$(slurp)\" - | wl-copy";
          bindings = {launch = "S";};
        }
        {
          name = "hyprshot";
          description = "Window Screenshot (Hyprshot)";
          command = "hyprshot -m window";
        }
      ];
    };
    scratchpads = [
      {
        name = "terminal";
        description = "Terminal Scratchpad";
        command = "foot --app-id scratch-term";
        bindings = {launch = "Grave";};
      }
    ];
  };

  x11 = {
    applications = {
      terminal =
        common.applications.terminal
        ++ [
          {
            name = "xterm";
            description = "XTerm";
            command = "xterm";
            bindings = {launch = "X";};
          }
        ];
      launcher =
        common.applications.launcher
        ++ [
          {
            name = "rofi";
            description = "Rofi Launcher";
            command = "rofi -show drun";
          }
        ];
      screenshot = [
        {
          name = "maim";
          description = "Region Screenshot (Maim)";
          command = "maim -s | xclip -selection clipboard -t image/png";
          bindings = {launch = "S";};
        }
        {
          name = "scrot";
          description = "Full Screen Screenshot (Scrot)";
          command = "scrot -b -d 1 '%Y-%m-%d-%H%M%S.png' -e 'xclip -selection clipboard -t image/png -i $f'";
        }
      ];
    };
    scratchpads = common.scratchpads;
  };
in {inherit common wayland x11;}
