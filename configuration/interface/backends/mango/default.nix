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
  mk = config: scope: mkArgs {inherit config path scope;};
in {
  core = {
    config,
    pkgs,
    ...
  }: let
    scope = "core";
    inherit (mk config scope) opt cfg;
  in {
    options = opt (mkEnable {inherit name prettyName config scope;}).default;
    config = mkCfgIf {inherit cfg;} {
      environment.systemPackages = [pkgs.${name} or []];
    };
  };

  home = {config, ...}: let
    scope = "home";
    inherit (mk config scope) opt cfg;
  in {
    options = opt (mkEnable {inherit name prettyName config scope;}).default;
    config = mkCfgIf {inherit cfg;} {
      # User-level Mango dotfiles or environment hooks go here
    };
  };
}
