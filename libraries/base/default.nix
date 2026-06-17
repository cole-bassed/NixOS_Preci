{paths ? {src = ../../../.;}, ...}: (import ./bootstrap.nix {
  inherit paths;
  home = ./.;
  excludes = ["default" "bootstrap"];
  extra = builtins;
  enableExtras = false;
  enableAliases = false;
})
