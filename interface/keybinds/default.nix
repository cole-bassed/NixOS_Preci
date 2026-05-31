{
  config,
  lib,
  pkgs,
  top,
  ...
}: let
  dom = "interface";
  mod = "keybinds";
  cfg = config.${top}.${dom}.${mod};

  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
in {
  home-manager.sharedModules = mkIf cfg.enable [
    {
      imports = [
        ./options.nix
        ./hyprland.nix
        ./niri.nix
      ];

      home.packages = with pkgs; [
        (
          writeShellScriptBin "dots-common-keybinds" ''
            ${getExe libnotify} "Common desktop keybinds" "$(cat <<'HELP'
            Win: primary launcher (Hyprland)
            Win+Space: secondary launcher
            Win+Ctrl+/: show keybind help
            Win+Enter: terminal
            Win+`: scratchpad terminal
            Win+B: primary browser
            Win+Alt+B: secondary browser
            Win+V: visual tools launcher
            Win+F: file manager
            Win+E: editor
            Alt+Enter / Win+Ctrl+F: fullscreen
            Win+Q: close focused window
            Win+Ctrl+L: lock session
            Win+Ctrl+Q: logout/exit session
            Print: screenshot
            HELP
            )"
          ''
        )
        brightnessctl
        grim
        libnotify
        slurp
        wl-clipboard
      ];
    }
  ];
}
