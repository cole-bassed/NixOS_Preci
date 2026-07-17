{
  lix,
  top,
  path,
  ...
}: let
  inherit (lix.modules) mkDefault mkForce mkIf;
  inherit (lix.options) mkOption mkEnable mkModuleArgs;
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
    inherit (mod) cfg;
  in {
    options = mod.mkOpt {
      command = mkOption {
        type = str;
        default = "noctalia-shell";
        description = "Command used by compositor-specific startup hooks.";
      };
      onHyprland = (mkEnable {name = "Noctalia on Hyprland";}).true;
      onNiri = (mkEnable {name = "Noctalia on Niri";}).true;
    };

    config = mod.mkCfg {
      programs = {
        noctalia = {
          enable = mkDefault true;
          package = mkForce cfg.package;
          systemd.enable = mkDefault false;
        };
        niri.settings.spawn-at-startup = mkIf cfg.onNiri [{argv = [cfg.command];}];
      };
      wayland.windowManager.hyprland.settings.exec-once = mkIf cfg.onHyprland [cfg.command];
    };
  };
}
