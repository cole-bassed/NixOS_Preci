{
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
      {
        name = "nautilus";
        description = "Nautilus File Manager";
        command = "nautilus";
        bindings = {launch = "N";};
      }
    ];
    launcher = [
      {
        name = "vicinae";
        description = "Vicinae Launcher";
        command = "vicinae open";
      }
      {
        name = "fuzzel";
        description = "Fuzzel Launcher";
        command = "fuzzel";
      }
      {
        name = "rofi";
        description = "Rofi Launcher";
        command = "rofi -show drun";
      }
    ];
    terminal = [
      {
        name = "foot";
        description = "Foot Terminal";
        command = "foot";
        bindings = {launch = "F";};
      }
      {
        name = "ghostty";
        description = "Ghostty Terminal";
        command = "ghostty";
        bindings = {launch = "G";};
      }
      {
        name = "kitty";
        description = "Kitty Terminal";
        command = "kitty";
        bindings = {launch = "K";};
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
}
