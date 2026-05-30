{lib, ...}: let
  inherit (lib.attrsets) filterAttrs mapAttrsToList;
  inherit (lib.filesystem) pathIsRegularFile readDir;
  inherit (lib.lists) elem filter findFirst;

  base = ./.;
  ignore = [
    "archive"
    "backup"
    "review"
    "temp"
  ];

  getPath = app: path: base + "/${app}/${path}";
  isAllowedDir = name: type: type == "directory" && !(elem name ignore);
  apps = filterAttrs isAllowedDir (readDir base);

  findNix = root: stem:
    findFirst pathIsRegularFile null [
      (getPath root "${stem}.nix")
      (getPath root "${stem}/default.nix")
    ];

  mkModules = app: let
    default = getPath app "default.nix";
    core = findNix app "core";
    home = findNix app "home";
    flat =
      if core == null && home == null && pathIsRegularFile default
      then default
      else null;
  in {
    inherit core;
    home =
      if home != null
      then home
      else flat;
  };

  modulesFor = getModule:
    filter
    (module: module != null)
    (
      mapAttrsToList
      (app: _: getModule (mkModules app))
      apps
    );
in {
  imports = modulesFor (modules: modules.core);
  home-manager.sharedModules = modulesFor (modules: modules.home);
}
