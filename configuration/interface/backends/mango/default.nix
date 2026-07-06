{
  path,
  mkArgs,
  ...
}: let
  mk = args: mkArgs ({inherit path;} // args);
in {
  core = {
    config,
    options,
    pkgs,
    ...
  }:
    (mk {inherit config options pkgs;}).evaluated;

  home = {
    config,
    options,
    pkgs,
    ...
  }: let
    scope = "home";
  in
    (mk {inherit config options pkgs scope;}).evaluated;
}
