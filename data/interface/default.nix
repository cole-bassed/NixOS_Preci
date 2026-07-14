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
        }
        {
          name = "zed";
          description = "Zed Editor";
          command = "zeditor";
        }
        {
          name = "antigravity";
          description = "Antigravity IDE";
          command = "antigravity";
        }
      ];
    };
  in {
    browser = [
      {
        name = "zen-browser";
        description = "Zen Browser";
        command = "zen-twilight";
      }
      {
        name = "chromium";
        description = "Chromium";
        command = "chromium";
      }
      {
        name = "firefox";
        description = "Firefox";
        command = "firefox";
      }
    ];
    editor = editors.tty;
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
    ];
    terminal = [
      {
        name = "foot";
        description = "Foot Terminal";
        command = "foot";
      }
      {
        name = "ghostty";
        description = "Ghostty Terminal";
        command = "ghostty";
      }
      {
        name = "kitty";
        description = "Kitty Terminal";
        command = "kitty";
      }
    ];
    visual = editors.gui;
  };
  bindings = {
    modifier = "SUPER";
  };
}
