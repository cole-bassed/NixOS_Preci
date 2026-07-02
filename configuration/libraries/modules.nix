{ingestion, ...}: let
  exports = {
    scoped = {
      mkModules = importModules;
      inherit importModules;
    };
    global = {};
  };
  inherit (ingestion) importModules;
in
  exports
