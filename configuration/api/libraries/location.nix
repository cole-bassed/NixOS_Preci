{
  paths,
  filesystem,
  attrsets,
  ...
}: let
  exports = {
    scoped = expanded;
    # global = {paths = paths';};
  };
  inherit (filesystem) mkPaths;
  inherit (attrsets) recursiveUpdate;

  base = ../.;
  hosts = base + "/hosts";
  users = base + "/users";
  displays = base + "/displays";
  # expanded = recursiveUpdate paths {store.api = {inherit base hosts users displays;};};
  # paths' = mkPaths {store = (recursiveUpdate paths {store.api = expanded;};);

  # expanded = recursiveUpdate paths {
  #   store.api = {inherit base hosts users displays;};
  # };
  expanded = paths;
in
  exports
