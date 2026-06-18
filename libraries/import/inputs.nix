{
  attrsets,
  lists,
  types,
  defaults,
  inputs,
  flake,
  paths,
  name ? null,
  names ? {src = "dots";},
  path ? null,
  ...
}: let
  exports = {
    scoped = {inherit raw classified;} // args;
    global = {
      flakes.inputs = raw;
      flakeInputs = normalized;
    };
  };

  inherit (lists) elem;
  inherit (attrsets) recursiveAttrs filterAttrs firstOf;
  inherit (types) hasLib hasModules hasOverlays isHomeManagerLike isNixDarwinLike isNixpkgsInfrastructure isNixpkgsLike isNotEmpty isTreefmtLike isAttrs isString;
  inherit (builtins) getEnv;

  args = {
    defaults = recursiveAttrs defaults (
      recursiveAttrs {
        host = let
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

        excludes = {
          paths = [
            "archive"
            "backup"
            "review"
            "temp"

            "default.nix"
            "flake.nix"
          ];
        };

        tags = ["core" "home"];
      } (flake.defaults or {})
    );

    names = recursiveAttrs names (
      recursiveAttrs {
        src =
          if name != null
          then name
          else names.src;
      }
      (flake.names or {})
    );

    paths = recursiveAttrs paths (
      recursiveAttrs {
        store.src =
          if path != null
          then path
          else paths.src;
      } (flake.paths or{})
    );

    path = args.paths.store.src;
    name = args.names.src;
  };

  raw =
    filterAttrs
    (input: _: !(elem input ["self" name]))
    inputs;

  classified = {
    nixpkgs = filterAttrs (_: isNixpkgsLike) raw;
    nix-darwin = filterAttrs (_: isNixDarwinLike) raw;
    treefmt = filterAttrs (_: isTreefmtLike) raw;

    home-manager =
      filterAttrs
      (
        input: isHomeManagerLike
        # || input == "nixHM"
      )
      raw;

    modules =
      filterAttrs
      (
        input: value:
          hasModules value
          && !(isNixpkgsLike value)
        # && input != "nixHM"
      )
      raw;

    overlays = filterAttrs (_: hasOverlays) raw;

    packages =
      filterAttrs
      (_: value: value ? packages && !(isNixpkgsLike value))
      raw;

    libraries = filterAttrs (_: hasLib) raw;
    infrastructure = filterAttrs (_: isNixpkgsInfrastructure) raw;
  };

  normalized = recursiveAttrs classified {
    inherit raw;
    nixpkgs =
      if isString defaults.nixpkgs
      then inputs.${defaults.nixpkgs}
      else if isAttrs defaults.nixpkgs && isNotEmpty (defaults.nixpkgs or {})
      then defaults.nixpkgs
      else firstOf classified.nixpkgs;

    nix-darwin = firstOf classified.nix-darwin;
    home-manager = firstOf classified.home-manager;
    treefmt = firstOf classified.treefmt;
  };
in
  exports
