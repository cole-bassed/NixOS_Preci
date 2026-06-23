{flake ? {}, ...}: let
  names = {
    src = "dots";
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
      shells = ./development;
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
    # TODO: Does flake truly ever pass currentHost as an argument?
    if isAttrs flake && ((flake.currentHost or "") != "")
    then flake.currentHost
    else if (env.host != "")
    then env.host
    else if (env.name != "")
    then env.name
    else "TheExample";

  libraries =
    import paths.store.libraries
    {inherit defaults flake names paths;};
in
  # libraries
  libraries.merged.mkSrc {inherit libraries;}
