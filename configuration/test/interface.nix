{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.options) mkModuleArgs mkEnableOption;
  inherit (lix.lists) elem;

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt;
    # inherit (cfg) enable;
    wm = cfg.windowManagement or {};
    de = cfg.desktopEnvironment or {};
  in {
    options = opt {
      desktopEnvironment = {};
      windowManagement = {
        hyprland = {
          enable =
            mkEnableOption null
            // {
              description = ''
                Hyprland, the dynamic tiling Wayland compositor that doesn't sacrifice on its looks.
                You can manually launch Hyprland by executing {command}`start-hyprland` on a TTY.
                A configuration file will be generated in {file}`~/.config/hypr/hyprland.conf`.
                See <https://wiki.hyprland.org> for more information
              '';
              default = elem "hyprland" (host.interface.environment.managers or []);
            };
          withUWSM =
            mkEnableOption null
            // {
              description = ''
                Launch Hyprland with the UWSM (Universal Wayland Session Manager) session manager.
                This has improved systemd support and is recommended for most users.
                This automatically starts appropriate targets like `graphical-session.target`,
                and `wayland-session@Hyprland.target`.

                ::: {.note}
                Some changes may need to be made to Hyprland configs depending on your setup, see
                [Hyprland wiki](https://wiki.hyprland.org/Useful-Utilities/Systemd-start/#uwsm).
                :::
              '';
              default = true;
            };
        };
        niri = {
          enable =
            mkEnableOption "Niri, a scrollable-tiling Wayland compositor"
            // {default = elem "niri" (host.interface.environment.managers or [])};
        };
      };
    };

    config =
      if scope == "core"
      then {
        programs = {
          hyprland = {inherit (wm.hyprland) enable withUWSM;};
          niri = {inherit (wm.niri) enable;};
        };
      }
      else {
        wayland.windowManager.hyprland = {inherit (wm.hyprland) enable;};
        programs.niri = {inherit (wm.niri) enable;};
      };
  };
in {
  core = mk "core";
  home = mk "home";
}
