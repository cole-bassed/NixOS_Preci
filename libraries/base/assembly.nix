{
  attrsets,
  trivial,
  filesystem,
  ...
}: let
  exports = {
    scoped = {
      mkLibs = mkLibrary;
      inherit (filesystem) mkPaths;
    };
    global = {inherit mkLibrary;};
  };

  inherit (builtins) attrValues foldl' mapAttrs;
  inherit (attrsets) recursiveAttrs;
  inherit (filesystem) getSpecs;
  inherit (trivial) fix;

  mkLibrary = {
    base,
    excludes ? ["default"], #TODO: This needs to see folders to skip as will, not just files and if the extension (nix) is present it doesn't skip?
    seed ? {},
    extra ? {},
  }: let
    clean = attrs:
      removeAttrs attrs [
        "flat"
        "global"
        "scoped"
        "value"
        "raw"
      ];

    normalize = spec: let
      global = spec.global or {};
      scoped =
        if spec ? scoped
        then spec.scoped
        else if spec ? global
        then {}
        else spec;
      value = recursiveAttrs global scoped;
    in {
      inherit global scoped value;
      raw = spec;
    };

    modules = fix (self: let
      scope =
        recursiveAttrs
        seed
        (clean (mapAttrs (_: lib: lib.value) self));
    in
      foldl'
      recursiveAttrs
      {}
      (
        map
        (spec: {
          ${spec.name} = normalize (import spec.input scope);
        })
        (getSpecs {inherit base excludes;})
      ));

    scoped = mapAttrs (_: mod: mod.value) modules;

    global =
      foldl'
      (acc: mod: recursiveAttrs acc mod.global)
      {}
      (attrValues modules);

    merged = recursiveAttrs global scoped;
    seeded = recursiveAttrs (recursiveAttrs seed extra) merged;
  in {
    # inherit global scoped merged seeded;
    domains = scoped;
    aliases = global;
    charged = seeded;
  };
in
  exports
