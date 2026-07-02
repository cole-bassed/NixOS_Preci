{
  lix,
  path,
  mkArgs,
  mkEnable,
  ...
}: let
  name = "mango";
  prettyName = "Mango";

  inherit (lix.modules) mkCfgIf;
in {
  core = {
    config,
    pkgs,
    ...
  }: let
    scope = "core";
    inherit (mkArgs {inherit config path scope;}) opt cfg;
  in {
    options = opt (mkEnable {inherit name prettyName config scope;}).default;
    config = mkCfgIf {inherit cfg;} {
      environment.systemPackages = [pkgs.${name} or []];
    };
  };

  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config path scope;}) opt cfg;
  in {
    options = opt (mkEnable {inherit name prettyName config scope;}).default;
    config = mkCfgIf {inherit cfg;} {
      # User-level Mango dotfiles or environment hooks go here
    };
  };
}
