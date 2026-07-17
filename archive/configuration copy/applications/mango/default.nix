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
    (mk {
      inherit config options pkgs;
      scope = "core";
    }).evaluated;

  home = {
    config,
    options,
    pkgs,
    ...
  }:
    (mk {
      inherit config options pkgs;
      scope = "home";
    }).evaluated;
}
