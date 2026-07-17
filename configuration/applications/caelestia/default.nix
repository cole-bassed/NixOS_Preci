{
  lix,
  api,
  top,
  path,
  ...
}: let
  inherit (lix.lists) last init;
  inherit (lix.modules) mkIf mkModuleArgs;
  inherit (lix.options) mkApplicationOptions;

  rawName = last path;
  name = api.applications.aliases.${rawName} or rawName;

  mk = scope: {
    config,
    pkgs,
    ...
  }: let
    mod = mkModuleArgs {
      inherit config top scope;
      path = (init path) ++ [name];
    };
    cfg = mod.get.config.module;
    opt = mod.set.options.module;
  in {
    options = opt (mkApplicationOptions {
      get = mod.get;
      inherit name scope pkgs;
      packageCandidates = [name rawName];
    });
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
