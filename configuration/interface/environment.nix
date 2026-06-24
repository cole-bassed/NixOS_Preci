{
  inputs,
  lix,
  pkgs,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (inputs.niri) nixosModules overlays;

  inherit (lix.lists) elem optionals;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkEnableOption mkOption;
  inherit (lix.types) listOf enum;
in {
  imports = [nixosModules.niri];

  core = {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod;};
    inherit (args) cfg opt;
    env = host.interface.environment or {};
  in {
    options = opt {
      managers = mkOption {
        type = listOf (enum ["hyprland" "niri"]);
        default = env.managers or [];
        description = "Enabled standalone Wayland compositors/window managers.";
      };

      desktops = mkOption {
        type = listOf (enum ["plasma" "gnome" "xfce" "cinnamon"]);
        default = env.desktops or [];
        description = "Enabled full desktop environments.";
      };

      hyprland = {
        enable =
          mkEnableOption "Hyprland compositor"
          // {default = elem "hyprland" cfg.managers;};

        withUWSM =
          mkEnableOption "launching Hyprland through UWSM"
          // {default = true;};
      };

      niri = {
        enable =
          mkEnableOption "Niri compositor"
          // {default = elem "niri" cfg.managers;};
      };

      wayland =
        mkEnableOption "Wayland protocol/session support"
        // {default = cfg.hyprland.enable || cfg.niri.enable;};
    };

    config = {
      nixpkgs.overlays = mkIf cfg.niri.enable [overlays.niri];

      programs = {
        hyprland = {inherit (cfg.hyprland) enable withUWSM;};

        niri = {
          enable = cfg.niri.enable;
          package = pkgs.niri-unstable;
        };

        uwsm = mkIf cfg.wayland {
          enable = true;

          waylandCompositors = mkIf cfg.niri.enable {
            niri = {
              prettyName = "Niri";
              comment = "Niri compositor managed by UWSM";
              binPath = "/run/current-system/sw/bin/niri-session";
            };
          };
        };
      };

      environment = mkIf cfg.wayland {
        sessionVariables.NIXOS_OZONE_WL = "1";

        systemPackages = with pkgs;
          [
            cage
            libsecret
            wayland-utils
            wl-clipboard-rs
          ]
          ++ (
            optionals
            cfg.niri.enable
            [xwayland-satellite-unstable]
          );
      };
    };
  };

  home = {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod;};
    inherit (args) cfg opt;
    env = host.interface.environment or {};
  in {
    options = opt {
      managers = mkOption {
        type = listOf (enum ["hyprland" "niri"]);
        default = env.managers or [];
        description = "Enabled standalone Wayland compositors/window managers.";
      };

      desktops = mkOption {
        type = listOf (enum ["plasma" "gnome" "xfce" "cinnamon"]);
        default = env.desktops or [];
        description = "Enabled full desktop environments.";
      };

      hyprland = {
        enable =
          mkEnableOption "Hyprland Home Manager session"
          // {default = elem "hyprland" cfg.managers;};
      };

      niri = {
        enable =
          mkEnableOption "Niri Home Manager session"
          // {default = elem "niri" cfg.managers;};
      };
    };

    config = {
      wayland.windowManager.hyprland.enable = cfg.hyprland.enable;
      programs.niri.enable = cfg.niri.enable;
    };
  };
}
