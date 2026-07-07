{
  lix,
  path,
  mkArgs,
  ...
}: let
  inherit (lix.modules) mkMerge;

  mk = args: mkArgs ({inherit path;} // args);
in {
  core = {
    config,
    options,
    pkgs,
    ...
  }: let
    inherit (mk {inherit config options pkgs;}) initiated evaluated;
    frontend = config.${initiated.top}.interface.frontend.selected or null;
  in {
    inherit (evaluated) options;
    config = mkMerge [
      evaluated.config
      {
        programs.dms-shell.enable = frontend == "dank-material";
      }
    ];
  };

  home = {
    config,
    options,
    pkgs,
    ...
  }: let
    scope = "home";
    inherit (mk {inherit config options pkgs scope;}) initiated evaluated;
    frontend = config.${initiated.top}.interface.frontend.selected or null;
    hasNiri = config.programs.niri.enable or false;
  in {
    inherit (evaluated) options;
    config = mkMerge [
      evaluated.config
      {
        programs.dank-material-shell = {
          enable = frontend == "dank-material";
          niri = {
            enableKeybinds = hasNiri;
            enableSpawn = hasNiri;
          };
        };
      }
    ];
  };
}
