{
  api,
  attrsets,
  defaults,
  modules,
  names,
  paths,
  strings,
  ...
}: let
  exports = {
    scoped = {inherit mkConfigurations;};
    global = {inherit mkConfigurations;};
  };

  inherit (attrsets) mapAttrs recursiveUpdate;
  inherit (modules) nixosSystem darwinSystem;
  inherit (strings) hasPrefix;
  inherit (api) hosts;

  mkConfigurations = {
    args ? {inherit defaults paths names;},
    class ? "nixos",
  } @ params: let
    # TODO: Validate clas is one of ["nixos" "darwin"]
    args = recursiveUpdate params (params.extraArgs or {});
    # hosts = args.api.hosts or (import paths.api {inherit defaults;});
    type =
      if class == "nixos"
      then "nixosConfigurations"
      else if class == "darwin"
      then "darwinConfigurations"
      else (throw ''mkConfigurations.class: Expected one of ["nixos" "darwin"], got ${class}'');
    builder =
      if hasPrefix "nixos" class
      then nixosSystem
      else if hasPrefix "darwin"
      then darwinSystem
      else throw "mkConfigurations.builder: Unknown type";
  in {
    ${type} = mapAttrs (_: api: let
      host = recursiveUpdate defaults.host api;
      flake =
        recursiveUpdate
        (
          recursiveUpdate
          (defaults.flake or {})
          {inputs = args.inputs or (args.extraArgs.inputs or {});}
        ) (
          recursiveUpdate
          (host.flake or {})
          {home = host.path or (host.home or (host.dots or null));}
        );
    in
      builder {
        inherit (host) system;
        modules =
          (args.modules or [])
          ++ (args.extraArgs.modules or [])
          ++ (host.modules or [])
          ++ (host.imports or []);
        specialArgs =
          {
            inherit host flake;
            inherit (flake) inputs top;
            ${names.lib} = args.${names.lib};
            inherit (args) lix; # TODO: How can this not be hardcoded, i want to inherit args.${names.lib}
          }
          // args;
      })
    hosts;
  };
in
  exports
