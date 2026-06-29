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
      paths = paths.resolved;
      inherit hosts users displays;
    };
    # global = {paths = paths';};
  };

  inherit (attrsets) recursiveUpdate;
  inherit (filesystem) mkPaths';
  inherit (ingestion) collectNamedSpecs;

  paths' = let
    base = ../.;
    hosts = base + "/hosts";
    users = base + "/users";
    displays = base + "/displays";
    expanded = recursiveUpdate paths {
      store.api = {inherit base hosts users displays;};
    };
    resolved = mkPaths' {inherit (expanded) store local;};
  in {inherit expanded resolved;};

  collect = base:
    collectNamedSpecs {
      inherit base;
      includeFiles = true;
      rekey = true;
      inherit args;
    };

  hosts = collect paths'.expanded.store.api.hosts;
  users = collect paths'.expanded.store.api.users;
  displays = collect paths'.expanded.store.api.displays;
in
  exports
