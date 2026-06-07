{flake ? {}, ...}: let
  names = {
    src = "dots";
    top = "dots";
    lib = "lix";
  };

  paths = {
    src = ./.;
    api = ./configuration/api;
    dbg = ./debug;
    documentation = ./documentation;
    configurations = ./configuration/modules;
    templates = ./templates;
    devShells = ./utilities/shells;
    utilities = ./utilities;
    secrets = ./configuration/secrets;
    libraries = ./libraries;
  };

  defaults =
    {
      host = {
        name = "nixos";
        id = null;
        description = null;
        type = null;
        class = "nixos";
        system = "x86_64-linux";
        stateVersion = null; # ? Must be the same as when the OS was installed
        paths.src = "/etc/nixos";

        localization = {
          latitude = 18.015;
          longitude = -77.49;
          locator = "manual";
          city = "Mandeville/Jamaica";
          timezone = "America/Jamaica";
          locale = "en_US.UTF-8";
        };
      };

      excludes = [
        "archive"
        "backup"
        "review"
        "temp"
      ];

      tags = [
        "core"
        "home"
      ];
    }
    // (flake.defaults or {});

  libraries = import paths.libraries {
    inherit defaults paths names;
    inherit (flake) inputs root;
  };
in
  libraries.orEmptyAttrs libraries.flake
  // {
    dots = toString paths.src;
    # inputs = flake.inputs or {};
    inherit defaults libraries names paths;
    "${names.lib}" = libraries;
  }
