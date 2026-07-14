{
  api,
  ingestion,
  modules,
  options,
  types,
  ...
}: let
  exports = {
    scoped = {inherit mkModules mkModuleArgs mkCfgIf mkIf';};
    global = {inherit mkCfgIf mkIf';};
  };

  inherit (modules) mkIf mkMerge;
  inherit (types) isList;

  mkModules = args: ingestion.importModules (args // {inherit api;});
  mkModuleArgs = args: options.mkModuleArgs (args // {inherit api;});

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
