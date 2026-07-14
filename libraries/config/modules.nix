{
  ingestion,
  modules,
  options,
  types,
  ...
}: let
  exports = {
    scoped = {
      mkModules = importModules;
      inherit importModules mkModuleArgs mkCfgIf mkIf';
    };
    global = {inherit mkCfgIf mkIf';};
  };
  inherit (ingestion) importModules;
  inherit (modules) mkIf mkMerge;
  inherit (options) mkModuleArgs;
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

  mkIf' = cfg: condition: args:
    mkCfgIf {inherit cfg condition;} args;
in
  exports
