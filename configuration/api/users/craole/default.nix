{attrsets, ...}: let
  inherit (attrsets) mapOrderedAttrs;

  applications = mapOrderedAttrs {
    browsers = ["zen-twilight" "chromium"];
    editors = ["helix" "neovim"];
    visuals = ["vscode" "zeditor"];
    terminals = ["foot" "warp-terminal" "ghostty"];
    launchers = ["vicinae" "fuzzel"];
    shells = ["bash" "nushell" "powershell"];
    bar = "quickshell";
    prompt = "starship";
  };
in {
  imports = [
    # ./applications.nix
    # ./paths.nix
  ];

  inherit applications;

  # host-agnostic user metadata
  description = "Craig 'Craole' Cole";
  capabilities = [
    "writing"
    "conferencing"
    "development"
    "creation"
    "analysis"
    "management"
    "gaming"
    "multimedia"
  ];

  ssh = "age1a2m7lypwqplsn8w8um9fzlrej84meee0zw9uljllqlayn46edpwq9mkfwg";

  interface = {
    environment = {
      managers = ["hyprland" "niri"];
      desktops = [];
    };
    keyboard = {
      swapCapsEscape = false;
      vimKeybinds = false;
    };
  };

  git = {
    craole = "32288735+Craole@users.noreply.github.com";
    craole-cc = "134658831+craole-cc@users.noreply.github.com";
    cole-bassed = "75517056+cole-bassed@users.noreply.github.com";
  };

  style = {
    autoSwitch = true;
    theme = {
      polarity = "dark";
      accent = "teal";
      dark = "Catppuccin Frappé";
      light = "Catppuccin Latte";
    };
    icons = {
      dark = "candy-icons";
      light = "candy-icons";
    };
    cursors = {
      accent = "mauve";
      dark = "material";
      light = "material";
    };
    fonts = {
      emoji = "Noto Color Emoji";
      monospace = "Maple Mono NF";
      sans = "Monaspace Radon Frozen";
      serif = "Noto Serif";
      material = "Material Symbols Sharp";
      clock = "Rubik";
    };
  };
}
