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
  libraries
# libraries.mkSrc {}
# libaries.mkSrc {host=libraries.api.hosts.${libraries.defaults.host}}
