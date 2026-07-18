let
  common = {
    applications = let
      editors = {
        tty = [
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
        gui = [
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
    in {
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
      editor = editors.tty;
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
      visual = editors.gui;
    };

    bindings = {
      browser = "B";
      editor = "C";
      explorer = "E";
      launcher = "SUPER_L";
      modifier = "SUPER";
      swapCapsEscape = false;
      terminal = "Grave";
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
    };
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
    };
  };
in {inherit common wayland x11;}
