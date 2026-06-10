{flake ? {}, ...}: let
  names = {
    src = "dots";
    top = "dots";
    lib = "lix";
  };

  paths = {
    store = {
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
    local.src = "/etc/nixos";
  };

  libraries =
    import paths.store.libraries
    {inherit flake names paths;};
in
  libraries.${names.src}
