{
  mkChild,
  path,
  ...
}: {
  core = mkChild {
    inherit path;
    targets = [
      ["programs" "noctalia"]
      ["programs" "noctalia-shell"]
    ];
  };

  home = mkChild {
    inherit path;
    scope = "home";
    targets = [
      ["programs" "noctalia"]
      ["programs" "noctalia-shell"]
    ];
  };
}
