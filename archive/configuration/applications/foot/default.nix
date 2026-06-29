{
  lix,
  top,
  lib,
  dom,
  mod,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix) mkModuleArgs;

  mk = scope: {
    config,
    pkgs,
    ...
  }: let
    _ = mkModuleArgs {inherit config top dom mod scope pkgs;};
    inherit (_) opt package programs enable;
  in {
    options = opt {enable = config.${top}.interface.protocol.wayland;};
    config = mkIf enable (
      if scope == "core"
      then {environment.systemPackages = [package];}
      else {inherit programs;}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
