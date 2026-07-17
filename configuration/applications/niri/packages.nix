{
  config,
  lib,
  pkgs,
  top,
  ...
}: let
  cfg = config.${top}.interface.backends.niri;

  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
in {
  config = mkIf (cfg.enable && (cfg.semanticKeybinds or false)) {
    home.packages = with pkgs; [
      (
        writeShellScriptBin "dots-common-keybinds" ''
          ${getExe libnotify} "Common desktop keybinds" "$(cat <<'HELP'
          Win+Space: secondary launcher
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
          Win+Ctrl+Q: exit Niri
          Print: screenshot
          Win+Print: region screenshot to clipboard
          Win+Shift+/: Niri hotkey overlay
          HELP
          )"
        ''
      )
      brightnessctl
      grim
      libnotify
      slurp
      wl-clipboard
      wireplumber
    ];
  };
}
