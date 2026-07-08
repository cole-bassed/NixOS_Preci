{
  mkChild,
  path,
  ...
}: {
  core = mkChild {
    inherit path;
    targets = [
      ["programs" "caelestia-shell"]
      ["programs" "caelestia"]
    ];
  };

  home = mkChild {
    inherit path;
    scope = "home";
    targets = [
      ["programs" "caelestia-shell"]
      ["programs" "caelestia"]
    ];
  };
}
