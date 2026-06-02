{
  lib ? null,
  inputs ? null,
  names ? {
    lib = "lix";
  },
  paths ? {
    src = ./.;
    ai = ./ai;
    api = ./api;
    apps = ./applications;
    docs = ./documentation;
    env = ./secrets;
    interface = ./interface;
    lib = ./libraries;
    mods = ./modules;
  },
  defaults ? {
    host = rec {
      name = null;
      id = null;
      description = null;
      type = null;
      class = "nixos";
      system = "x86_64-linux";
      stateVersion = null; #? Must be the same as when the OS was installed
      paths = {
        flake = flake.home;
      };

      flake = {
        inherit inputs;
        name = "dots";
        home = "/etc/nixos";
        top = "_";
      };

      localization = {
        latitude = 18.015;
        longitude = -77.49;
        locator = "manual";
        city = "Mandeville/Jamaica";
        timezone = "America/Jamaica";
        language = "en_US.UTF-8";
      };
    };
    excludes = [
      "archive"
      "backup"
      "review"
      "temp"
    ];
    tags = ["core" "home"];
  },
  libraries ? (import ./libraries {
    lib =
      if lib != null
      then lib
      else if inputs ? nixpkgs.lib
      then inputs.nixpkgs.lib
      else (import <nixpkgs/lib>);
    inherit defaults names paths;
  }),
  modules ? (with paths; [
    mods
  ]),
  ...
}: {
  inherit defaults libraries modules;
  "${names.lib}" = libraries;
}
