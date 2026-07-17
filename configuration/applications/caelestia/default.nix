{
  lix,
  api,
  top,
  path,
  ...
}: let
  inherit (lix.lists) last;
  inherit (lix.modules) mkIf mkModuleArgs;
  inherit (lix.options) mkOption;
  inherit (lix.types) package;

  name = last path;
  entry = api.applications.registry.${name} or {};

  mk = scope: {
    config,
    pkgs,
    ...
  }: let
    mod = mkModuleArgs {inherit config top scope path;};
    cfg = mod.get.config.module;
    opt = mod.set.options.module;
  in {
    options = opt {
      enable = mod.set.enable {default = false;};
      package = mkOption {
        type = package;
        default = pkgs.${name} or null;
        description = "Package for ${name}.";
      };
    };
    config = mkIf cfg.enable (
      if scope == "core"
      then {environment.systemPackages = [cfg.package];}
      else {
        programs.${name} = {
          enable = true;
          inherit (cfg) package;
        };
      }
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
