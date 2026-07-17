{
  mkChild,
  path,
  ...
}: let
  targets = [
    ["programs" "caelestia-shell"]
    ["programs" "caelestia"]
  ];
in {
  core = mkChild {
    inherit path targets;
  };

  home = mkChild {
    inherit path targets;
    scope = "home";
  };
}
