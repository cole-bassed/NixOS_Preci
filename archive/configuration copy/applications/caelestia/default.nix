{
  lix,
  top,
  path,
  ...
}: let
  inherit (lix.attrsets) asAttrsIf;
  inherit (lix.modules) mkDefault mkForce mkIf mkModuleArgs;
  inherit (lix.options) mkOption mkEnable;
  inherit (lix.types) str;

  mk = scope: {
    config,
    pkgs,
    options,
    ...
  }: let
    moduleArgs = mkModuleArgs {inherit config top scope path pkgs options;};
    inherit (moduleArgs) cfg app opt;
  in
    moduleArgs
    // {
      hasNiri = config ? programs.niri;
      hasHypr =
        config ? programs.hyprland
        || config ? wayland.windowManager.hyprland;
      mkCfg = spec: mkIf cfg.enable spec;
      mkOpt = spec: opt (app // spec);
      eval = {
        config = mkIf cfg.enable {};
        options = opt app;
        imports = [];
      };
    };
in {
  core = {
    config,
    pkgs,
    options,
    ...
  }: let
    mod = mk "core" {inherit config options pkgs;};
  in {inherit (mod.eval) config options imports;};

  home = {
    config,
    pkgs,
    options,
    ...
  }: let
    mod = mk "home" {inherit config options pkgs;};
    inherit (mod) cfg hasHypr hasNiri;
  in {
    options = mod.mkOpt {
      command =
        mkOption {
          type = str;
          default = "caelestia-shell";
          description = "Command used by compositor-specific startup hooks.";
        }
        // asAttrsIf hasHypr {
          onHyprland = (mkEnable {name = "Caelestia on Hyprland";}).true;
        }
        // asAttrsIf hasNiri {
          onNiri = (mkEnable {name = "Caelestia on Niri";}).true;
        };
    };

    config = mod.mkCfg {
      programs =
        {
          caelestia = {
            enable = mkForce cfg.enable;
            package = mkForce cfg.package;
            systemd.enable = mkForce cfg.enable;
          };
        }
        // asAttrsIf hasNiri {
          niri.settings.spawn-at-startup = mkIf cfg.onNiri [{argv = [cfg.command];}];
        };
      wayland.windowManager = asAttrsIf hasHypr {
        hyprland.settings.exec-once = mkIf cfg.onHyprland [cfg.command];
      };
    };
  };
}
