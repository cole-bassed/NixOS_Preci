{
  category = ["backend"];
  protocol = "wayland";
  supported = [
    "dank-material-shell"
    "caelestia-shell"
    "noctalia-shell"
  ];
  scopes = ["core" "home"];
  aliases = ["niri-wm"];
  needsXwaylandSatellite = true;
  package = "niri-unstable";
  configType = "kdl";
}
