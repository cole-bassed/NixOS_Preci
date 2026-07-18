{
  category = ["backend"];
  protocol = "wayland";
  scopes = ["core" "home"];
  aliases = ["niri-wm"];
  needsXwaylandSatellite = true;
  package = "niri-unstable";
  configType = "kdl";
  greeter = "dank-material-shell";
  frontend = "dank-material-shell";
}
