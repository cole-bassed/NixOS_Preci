{
  paths,
  attrsets,
  ...
}: let
  inherit (attrsets) recursiveUpdate;
  base = paths.store.api or paths.api or ../.;
in {
  paths.store.api = {
    inherit base;
    hosts = base + "/hosts";
    users = base + "/users";
    displays = base + "/displays";
  };
}
