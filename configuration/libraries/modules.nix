{
  ingestion,
  modules,
  types,
  ...
}: let
  exports = {
    scoped = {
      mkModules = importModules;
      inherit importModules mkCfgIf;
    };
    global = {inherit mkCfgIf;};
  };
  inherit (ingestion) importModules;
  inherit (modules) mkIf mkMerge;
  inherit (types) isList;

  mkCfgIf = {
    cfg,
    condition ? cfg.enable or false,
  }: args:
    mkIf condition (
      if isList args
      then mkMerge args
      else args
    );
in
  exports
