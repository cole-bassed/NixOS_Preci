let
  exports = {
    inherit
      applications
      chords
      controls
      fallbacks
      frontend
      greeter
      packages
      scratchpads
      variables
      ;
  };

  frontend = {
    wayland = "dank-material-shell";
    x11 = null;
  };
  greeter = "dms-greeter";

  fallbacks = {
    screenlocker = {
      wayland = "swaylock-effects";
      x11 = "betterlockscreen";
    };
    notifications = {
      wayland = "mako";
      x11 = "dunst";
    };
    bar = {
      wayland = "waybar";
      x11 = "polybar";
    };
    idle = {
      wayland = "hypridle";
      x11 = "xss-lock";
    };
    wallpaper = {
      wayland = "swww";
      x11 = "feh";
    };
  };

  chords = {
    groups = {
      navigation = chords.modifiers.primary;
      movement = chords.modifiers.secondary;
      state = chords.modifiers.primary;
      termination = chords.modifiers.secondary;
      capture = chords.modifiers.tertiary;
      captureVideo = chords.modifiers.quaternary;
      adjustment = [];
    };
    modifiers = {
      primary = ["SUPER"];
      secondary = ["SUPER" "SHIFT"];
      tertiary = ["SUPER" "ALT"];
      quaternary = ["SUPER" "CTRL" "ALT"];
      standalone = ["SUPER" "SHIFT" "ALT"];
    };
    triggers = {
      browser = "B";
      editor = "C";
      explorer = "E";
      launcher = "Space";
      terminal = "Return";
      visual = "V";
      scratchpad = "Grave";
    };
  };

  applications = let
    common = {
      browser = [
        {
          name = "zen-browser";
          description = "Zen Browser";
          command = "zen-twilight";
          trigger = "B";
        }
        {
          name = "chromium";
          description = "Chromium";
          command = "chromium";
          trigger = "C";
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
          trigger = "D";
        }
        {
          name = "thunar";
          description = "Thunar File Manager";
          command = "thunar";
          trigger = "T";
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
          trigger = "K";
        }
        {
          name = "ghostty";
          description = "Ghostty Terminal";
          command = "ghostty";
          trigger = "G";
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
          trigger = "V";
        }
        {
          name = "zed";
          description = "Zed Editor";
          command = "zeditor";
          trigger = "Z";
        }
        {
          name = "antigravity";
          description = "Antigravity IDE";
          command = "antigravity";
          trigger = "A";
        }
      ];
    };
  in {
    wayland =
      common
      // {
        terminal =
          [
            {
              name = "foot";
              description = "Foot Terminal";
              command = "foot";
              trigger = "F";
            }
          ]
          ++ common.terminal;
        launcher =
          common.launcher
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
            trigger = "S";
          }
          {
            name = "hyprshot";
            description = "Window Screenshot (Hyprshot)";
            command = "hyprshot -m window";
          }
          {
            name = "wl-screenrec-region";
            description = "Hardware Accelerated Region Recording";
            command = "wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4 -g \"$(slurp)\"";
          }
          {
            name = "wl-screenrec-window";
            description = "Hardware Accelerated Window Recording";
            command = "wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4 -g \"$(hyprctl activewindow -j | jq -r '.at[0],.at[1],.size[0],.size[1]' | paste -sd ' ' - | awk '{print $1\",\"$2\" \"$3\"x\"$4}')\"";
          }
          {
            name = "wl-screenrec-full";
            description = "Hardware Accelerated Full Display Recording";
            command = "wl-screenrec --filename ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4";
          }
        ];
      };

    x11 =
      common
      // {
        terminal =
          common.terminal
          ++ [
            {
              name = "xterm";
              description = "XTerm";
              command = "xterm";
              trigger = "X";
            }
          ];
        launcher =
          common.launcher
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
            trigger = "S";
          }
          {
            name = "scrot";
            description = "Full Screen Screenshot (Scrot)";
            command = "scrot -b -d 1 '%Y-%m-%d-%H%M%S.png' -e 'xclip -selection clipboard -t image/png -i $f'";
          }
          {
            name = "ffmpeg-region";
            description = "X11 Region Video Recording";
            command = "ffmpeg -f x11grab -video_size $(xdotool search --onlyvisible --name .* getwindowgeometry | awk '/Geometry/ {print $2}') -i :0.0 ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4";
          }
          {
            name = "ffmpeg-full";
            description = "X11 Display Video Recording";
            command = "ffmpeg -f x11grab -video_size 1920x1080 -i :0.0 ~/Videos/Capture-$(date +%Y%m%d-%H%M%S).mp4";
          }
        ];
      };
  };

  controls = {
    window = {
      close = {
        description = "Close Active Window";
        group = "termination";
        trigger = "W";
      };
      toggleFloating = {
        description = "Toggle Window Floating State";
        group = "state";
        trigger = "H";
      };
      toggleFullscreen = {
        description = "Toggle Active Window Fullscreen State";
        group = "state";
        trigger = "F";
      };
      togglePip = {
        description = "Toggle Picture-in-Picture mode (Floating, Sticky, and Pins Window on Top)";
        group = "state";
        trigger = "P";
      };
      moveFocusUp = {
        description = "Move focus to the window above";
        group = "navigation";
        trigger = "K";
      };
      moveFocusDown = {
        description = "Move focus to the window below";
        group = "navigation";
        trigger = "J";
      };
      moveFocusLeft = {
        description = "Move focus to the window on the left";
        group = "navigation";
        trigger = "H";
      };
      moveFocusRight = {
        description = "Move focus to the window on the right";
        group = "navigation";
        trigger = "L";
      };
      moveWindowUp = {
        description = "Move window position upward";
        group = "movement";
        trigger = "K";
      };
      moveWindowDown = {
        description = "Move window position downward";
        group = "movement";
        trigger = "J";
      };
      moveWindowLeft = {
        description = "Move window position leftward";
        group = "movement";
        trigger = "H";
      };
      moveWindowRight = {
        description = "Move window position rightward";
        group = "movement";
        trigger = "L";
      };
      screenshotWindow = {
        description = "Grab image screenshot of targeted active window";
        group = "capture";
        trigger = "Print";
      };
      screenshotSelect = {
        description = "Grab image screenshot of interactively selected region";
        group = "capture";
        trigger = "S";
      };
      captureWindow = {
        description = "Begin screen recording of targeted active window";
        group = "captureVideo"; # Shifted to separate recording group to clean out bind issues
        trigger = "R";
      };
      captureSelect = {
        description = "Begin screen recording of interactively selected region";
        group = "captureVideo"; # Shifted to separate recording group to clean out bind issues
        trigger = "S"; # Updated trigger safely to S for consistent 'Selection' shortcuts
      };
    };

    screen = {
      focusNextMonitor = {
        description = "Shift tracking view context to next monitor";
        group = "navigation";
        trigger = "Tab";
      };
      focusPrevMonitor = {
        description = "Shift tracking view context to previous monitor";
        group = "navigation";
        trigger = "Tab";
      };
      moveMonitorNext = {
        description = "Send active window to next monitor";
        group = "movement";
        trigger = "Tab";
      };
      moveMonitorPrev = {
        description = "Send active window to previous monitor";
        group = "movement";
        trigger = "Tab";
      };
      screenshot = {
        description = "Grab image screenshot of all available display outputs";
        group = "capture";
        trigger = "A";
      };
      capture = {
        description = "Begin screen recording of all available display outputs";
        group = "captureVideo"; # Shifted from capture group to clear out 'SUPER+ALT+A' collision
        trigger = "A";
      };
    };

    workspace = {
      focusNextWorkspace = {
        description = "Cycle display viewport forward by index";
        group = "navigation";
        trigger = "Right";
      };
      focusPrevWorkspace = {
        description = "Cycle display viewport backward by index";
        group = "navigation";
        trigger = "Left";
      };
      moveWorkspaceNext = {
        description = "Send active window to next workspace index";
        group = "movement";
        trigger = "Right";
      };
      moveWorkspacePrev = {
        description = "Send active window to previous workspace index";
        group = "movement";
        trigger = "Left";
      };
    };

    session = {
      lock = {
        description = "Lock current window manager session";
        group = "state";
        trigger = "L";
      };
      logout = {
        description = "Exit current window manager session securely";
        group = "termination";
        trigger = "Q";
      };
      suspend = {
        description = "Suspend machine state";
        group = "termination";
        trigger = "U";
      };
    };

    hardware = {
      raiseVolume = {
        description = "Raise Volume";
        command = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        group = "adjustment";
        trigger = "XF86AudioRaiseVolume";
      };
      lowerVolume = {
        description = "Lower Volume";
        command = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        group = "adjustment";
        trigger = "XF86AudioLowerVolume";
      };
      toggleMute = {
        description = "Toggle Audio Mute";
        command = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        group = "state";
        trigger = "XF86AudioMute";
      };
      raiseBrightness = {
        description = "Raise Brightness";
        command = "brightnessctl set +5%";
        group = "adjustment";
        trigger = "XF86MonBrightnessUp";
      };
      lowerBrightness = {
        description = "Lower Brightness";
        command = "brightnessctl set 5%-";
        group = "adjustment";
        trigger = "XF86MonBrightnessDown";
      };
    };
  };

  scratchpads = let
    common = [
      {
        name = "media";
        description = "Media Scratchpad (MPV)";
        command = "mpv --class scratch-media";
      }
      {
        name = "explorer";
        description = "Explorer Scratchpad";
        command = "thunar --class scratch-explorer";
      }
      {
        name = "browser";
        description = "Browser Scratchpad";
        command = "zen-twilight --class scratch-browser";
      }
    ];
  in {
    wayland =
      [
        {
          name = "terminal";
          description = "Terminal Scratchpad";
          command = "foot --app-id scratch-term";
        }
      ]
      ++ common;

    x11 =
      [
        {
          name = "terminal";
          description = "Terminal Scratchpad";
          command = "kitty --class scratch-term";
        }
      ]
      ++ common;
  };

  variables = let
    common = {
      FOO = "foo";
      BAR = "bar";
    };
  in {
    wayland = common // {WAYLAND_DISPLAY = "wayland-1";};
    x11 = common // {DISPLAY = ":0";};
  };

  packages = let
    common = ["jq"];
  in {
    wayland = common ++ ["wl-clipboard"];
    x11 = common ++ ["xsel" "xdotool"];
  };
in
  exports
