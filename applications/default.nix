{lib, ...}: let
  inherit (builtins) readDir;
  inherit (lib) filter mapAttrsToList pathExists;

  appRoot = ./.;

  inactiveDirs = [
    "archive"
    "backup"
    "review"
    "temp"
  ];

  isActiveAppDir = name: type:
    type == "directory" && !(builtins.elem name inactiveDirs);

  activeApps = lib.filterAttrs isActiveAppDir (readDir appRoot);

  firstExisting = paths:
    lib.findFirst pathExists null paths;

  appPath = app: path:
    appRoot + "/${app}/${path}";

  coreModule = app:
    firstExisting [
      (appPath app "core.nix")
      (appPath app "core/default.nix")
    ];

  splitHomeModule = app:
    firstExisting [
      (appPath app "home.nix")
      (appPath app "home/default.nix")
    ];

  homeModule = app: let
    core = coreModule app;
    home = splitHomeModule app;
    default = appPath app "default.nix";
  in
    if home != null
    then home
    else if core == null && pathExists default
    then default
    else null;

  modulesFor = moduleFor:
    filter (module: module != null) (mapAttrsToList (name: _: moduleFor name) activeApps);
in {
  imports = modulesFor coreModule;

  home-manager = {
    sharedModules = modulesFor homeModule;
  };
}
