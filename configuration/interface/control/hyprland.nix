# modules/interface/keybinds/hyprland.nix
{
  config,
  lib,
  top,
  ...
}: let
  dom = "interface";
  mod = "control";
  cfg = config.${top}.${dom}.${mod};

  inherit (lib.attrsets) filterAttrs;
  inherit (lib.modules) mkDefault mkIf;

  inherit (cfg) actions modifier;
  enabled = filterAttrs (_: a: a.command != null) actions;

  bind = key: dispatch: "${modifier}, ${key}, ${dispatch}";
  bindAlt = key: dispatch: "ALT, ${key}, ${dispatch}";
  bindCtrl = key: dispatch: "${modifier} CTRL, ${key}, ${dispatch}";

  exec = key: action: bind key "exec, ${action.command}";
  execCtrl = key: action: bindCtrl key "exec, ${action.command}";
  execAlt = key: action: bindAlt key "exec, ${action.command}";

  when = cond: value:
    if cond
    then [value]
    else [];
in {
  config = mkIf (cfg.enable && cfg.onHyprland) {
    wayland.windowManager.hyprland.settings = {
      "$mod" = mkDefault modifier;

      bindr =
        when
        (enabled ? primaryLauncher)
        "${modifier}, Super_L, exec, ${enabled.primaryLauncher.command}";

      bind =
        (
          when
          (enabled ? secondaryLauncher)
          (exec "Space" enabled.secondaryLauncher)
        )
        ++ (
          when
          (enabled ? showKeybinds)
          (execCtrl "slash" enabled.showKeybinds)
        )
        ++ (
          when
          (enabled ? terminal)
          (exec "Return" enabled.terminal)
        )
        ++ (
          when
          (enabled ? scratchpadTerminal)
          (exec "grave" enabled.scratchpadTerminal)
        )
        ++ (
          when
          (enabled ? primaryBrowser)
          (exec "B" enabled.primaryBrowser)
        )
        ++ (
          when
          (enabled ? secondaryBrowser)
          (execAlt "B" enabled.secondaryBrowser)
        )
        ++ (
          when
          (enabled ? visualTools)
          (exec "V" enabled.visualTools)
        )
        ++ (
          when
          (enabled ? fileManager)
          (exec "F" enabled.fileManager)
        )
        ++ (
          when
          (enabled ? editor)
          (exec "E" enabled.editor)
        )
        ++ (
          when
          (actions.fullscreen.description != null)
          (bindAlt "Return" "fullscreen, 0")
        )
        ++ (
          when
          (actions.fullscreen.description != null)
          (bindCtrl "F" "fullscreen, 0")
        )
        ++ (
          when
          (actions.logout.description != null)
          (bindCtrl "Q" "exit")
        )
        ++ (
          when
          (actions.closeWindow.description != null)
          (bind "Q" "killactive")
        )
        ++ (
          when
          (actions.reloadConfig.description != null)
          (bindCtrl "R" "exec, hyprctl reload")
        )
        ++ (
          when
          (enabled ? lock)
          (execCtrl "L" enabled.lock)
        )
        ++ (
          when
          (enabled ? screenshot)
          (bind "Print" "exec, ${enabled.screenshot.command}")
        );
    };
  };
}
