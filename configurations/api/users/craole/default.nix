# api/users/craole/default.nix
# Pure user spec — no role, no primary, no autoLogin (those are host concerns).
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
    ./applications.nix
    ./paths.nix
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
    keyboard = {
      swapCapsEscape = false;
      vimKeybinds = false;
    };
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
