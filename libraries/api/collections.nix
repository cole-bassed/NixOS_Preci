{
  args,
  attrsets,
  filesystem,
  ingestion,
  paths,
  ...
}: let
  inherit (attrsets) recursiveUpdate;
  inherit (filesystem) mkPaths';
  inherit (ingestion) collectNamedSpecs;

  exports = {
    scoped = {
      paths = paths';
      inherit hosts users displays interface;
    };
    global = {
      inherit hosts users displays interface;
      paths = paths';
    };
  };

  paths' = let
    src = paths.store.api.src or ../../configuration/api;
    hosts = paths.store.api.hosts or (src + "/hosts");
    users = paths.store.api.users or (src + "/users");
    displays = paths.store.api.displays or (src + "/displays");
    interface = paths.store.api.interface or (src + "/interface");
    expanded = recursiveUpdate paths {
      store.api = {
        inherit src hosts users displays interface;
      };
    };
    resolved = mkPaths' {inherit (expanded) store local;};
  in
    resolved;

  collect = {
    base,
    includeFiles ? true,
  }:
    collectNamedSpecs {
      inherit base includeFiles args;
      rekey = true;
    };

  hosts = collect {
    base = paths'.store.api.hosts;
    includeFiles = false;
  };

  users = collect {
    base = paths'.store.api.users;
    includeFiles = false;
  };

  displays = collect {
    base = paths'.store.api.displays;
    includeFiles = true;
  };

  interface = collect {
    base = paths'.store.api.interface;
    includeFiles = true;
  };
in
  exports
