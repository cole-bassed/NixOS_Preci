{flake ? {}, ...}: let
  names = {
    src = "dots";
    top = "_";
    lib = "lix";
  };

  paths = {
    store = {
      src = ./.;
      api = ./configuration/api;
      dbg = ./debug;
      documentation = ./documentation;
      configuration = ./configuration;
      templates = ./templates;
      devShells = ./utilities/shells;
      utilities = ./utilities;
      secrets = ./configuration/secrets;
      libraries = ./libraries;
    };
  };

  defaults.host = let
    inherit (builtins) isAttrs getEnv;
    env = {
      host = getEnv "HOSTNAME";
      name = getEnv "NAME";
    };
  in
    if isAttrs flake && (flake.currentHost or "") != ""
    then flake.currentHost
    else if env.host != ""
    then env.host
    else if env.name != ""
    then env.name
    else "ExampleHost";

  libraries =
    import paths.store.libraries
    {inherit defaults flake names paths;};
in
  # libraries
  libraries.charged.mkSrc {inherit libraries;}
