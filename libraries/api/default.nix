{
  args,
  attrsets,
  filesystem,
  ingestion,
  paths,
  types,
  ...
}: let
  inherit (attrsets) listToAttrs mapAttrs recursiveUpdate;
  inherit (filesystem) mkPaths';
  inherit (ingestion) collectNamedSpecs;
  inherit (types) isList;

  domains = {
    hosts.includeFiles = false;
    users.includeFiles = false;
    displays.includeFiles = true;
    interface.includeFiles = true;
    applications.includeFiles = true;
  };

  specs = let
    base = paths.store.api or paths.store.data or {};
    src = base.src or ../../data;
    derived =
      mapAttrs
      (name: _: base.${name} or (src + "/${name}"))
      domains;
    resolved =
      recursiveUpdate paths
      {store.api = derived // {inherit src;};};
  in
    (mkPaths' {inherit (resolved) store local;}).store.api;

  extra = {
    normalize = raw:
      if isList raw
      then
        listToAttrs (map (name: {
            inherit name;
            value = {};
          })
          raw)
      else raw;
  };
in
  mapAttrs (name: domain:
    collectNamedSpecs {
      inherit (domain) includeFiles;
      args = args // extra;
      base = specs.${name};
      rekey = true;
    })
  domains
