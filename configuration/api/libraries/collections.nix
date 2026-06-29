{
  paths,
  filesystem,
  attrsets,
  ingestion,
  ...
}: let
  exports = {
    scoped = {
      paths = paths';
      inherit hosts users displays;
    };
    # global = {paths = paths';};
  };

  inherit (attrsets) recursiveUpdate;
  inherit (filesystem) mkPaths;
  inherit (ingestion) collectNamedSpecs;

  paths' = let
    base = ../.;
    hosts = base + "/hosts";
    users = base + "/users";
    displays = base + "/displays";
    expanded = recursiveUpdate paths {
      store.api = {inherit base hosts users displays;};
    };
    resolved = mkPaths {inherit (expanded) store local;};
  in
    resolved;

  collect = base:
    collectNamedSpecs {
      inherit base;
      includeFiles = true;
      rekey = true;
    };

  hosts = collect paths'.store.api.hosts;
  users = collect paths'.store.api.users;
  displays = collect paths'.store.api.displays;
in
  exports
