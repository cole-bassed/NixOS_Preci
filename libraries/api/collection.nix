{
  args,
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
  inherit (filesystem) mkPaths';
  inherit (ingestion) collectNamedSpecs;

  paths' = let
    src = ../.;
    hosts = src + "/hosts";
    users = src + "/users";
    displays = src + "/displays";
    expanded = recursiveUpdate paths {
      store.api = {inherit src hosts users displays;};
    };
    resolved = mkPaths' {inherit (expanded) store local;};
  in
    resolved;

  collect = base:
    collectNamedSpecs {
      inherit base;
      includeFiles = true;
      rekey = true;
      inherit args;
    };

  hosts = collect paths'.store.api.hosts;
  users = collect paths'.store.api.users;
  displays = collect paths'.store.api.displays;
in
  exports
