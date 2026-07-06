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
    options,
    pkgs,
    ...
  }: let
    scope = "core";
    inherit (mkArgs {inherit config options path pkgs scope;}) opt cfg;
  in {
    options = opt (mkEnable {inherit name prettyName config pkgs scope;});
    config = mkCfgIf {inherit cfg;} {
      environment.systemPackages = [pkgs.${name} or []];
    };
  };

  home = {
    config,
    pkgs,
    ...
  }: let
    scope = "home";
    inherit (mkArgs {inherit config path pkgs scope;}) opt cfg;
  in {
    options = opt (mkEnable {inherit name prettyName config pkgs scope;});
    config = mkCfgIf {inherit cfg;} {
      # User-level Mango dotfiles or environment hooks go here
    };
  };
}
