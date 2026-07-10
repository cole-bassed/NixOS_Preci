{
  args,
  attrsets,
  filesystem,
  ingestion,
  paths,
  ...
}: let
  inherit (attrsets) mapAttrs recursiveUpdate;
  inherit (filesystem) mkPaths';
  inherit (ingestion) collectNamedSpecs;

  domains = {
    hosts.includeFiles = false;
    users.includeFiles = false;
    displays.includeFiles = true;
    interface.includeFiles = true;
    applications.includeFiles = true;
  };

  api = let
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
in
  mapAttrs (name: domain:
    collectNamedSpecs {
      inherit args;
      inherit (domain) includeFiles;
      base = api.${name};
      rekey = true;
    })
  domains
