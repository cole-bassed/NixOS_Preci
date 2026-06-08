{
  defaults,
  external,
  name,
  names,
  paths,
  ...
}: let
  inherit
    (external)
    getAttrs
    inheritAttr
    mapAttrs
    recursiveUpdate
    ;

  scoped =
    mapAttrs
    (_: library: (library.scoped or {}) // (library.global or {}))
    libraries;

  global = scoped.attrsets.mergeUnique {
    owner = library: "${name}.${library}.global";
    what = "libraries";
    items = libraries;
    attrs = library:
      libraries.${library}.global or (libraries.${library} or {});
  };

  base = recursiveUpdate external {
    inherit names defaults paths;
  };

  all = external.classified;

  default = recursiveUpdate external (
    global
    // scoped
    // {
      lib = external;

      "${name}" = recursiveUpdate external (
        global
        // scoped
        // {
          inherit global scoped;
        }
      );
    }
  );

  mkLib = includes:
    recursiveUpdate base (
      {libraries = all;}
      // inheritAttr "flake" external
      // getAttrs includes scoped
    );

  libraries = {
    api = import paths.api (mkLib [
      "attrsets"
      "modules"
      "lists"
    ]);

    attrsets = import ./attrsets.nix (mkLib [
      "debug"
      "lists"
      "types"
    ]);

    config = import ./config.nix (mkLib [
      "api"
      "debug"
      "modules"
      "filesystem"
      "lists"
      "types"
    ]);

    debug = import ./debug.nix (mkLib [
      "lists"
      "types"
    ]);

    filesystem = import ./filesystem.nix (mkLib [
      "debug"
      "lists"
    ]);

    lists = import ./lists.nix (mkLib [
      "debug"
      "types"
    ]);

    modules = import ./modules.nix (mkLib [
      "debug"
      "filesystem"
      "lists"
      "types"
    ]);

    options = import ./options.nix (mkLib [
      "debug"
      "lists"
      "types"
    ]);

    strings = import ./strings.nix (mkLib [
      "debug"
      "lists"
      "types"
    ]);

    types = import ./types.nix (mkLib [
      "debug"
    ]);
  };
in
  default
