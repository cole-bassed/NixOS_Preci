{
  attrsets ? {},
  trivial ? {},
  filesystem ? {},
  names ? {},
  ...
}: let
  exports = {
    scoped = {
      mkLibs = mkLibrary;
      mkLix = mkLibraryFlat;
      inherit mkLibraryFlat;
    };
    global = {inherit mkLibrary mkLibraryFlat;};
  };

  bootstrap = import ./.;
  inherit (builtins) attrValues foldl' mapAttrs;

  recursiveUpdate = attrsets.recursiveUpdate or bootstrap.recursiveUpdate;
  recursiveSelf = trivial.recursiveSelf or bootstrap.recursiveSelf;
  getSpecs = filesystem.getSpecs or bootstrap.getSpecs;

  mkLibraryFlat = library:
    recursiveUpdate
    library
    {${names.lib or "lix"} = library.charged;};

  mkLibrary = {
    base,
    excludes ? seed.excludes.paths or ["default"], #TODO: This needs to see folders to skip as will, not just files and if the extension (nix) is present it doesn't skip?
    seed ? {},
    extra ? {},
  }: let
    clean = set:
      removeAttrs set [
        "flat"
        "global"
        "scoped"
        "value"
        "raw"
      ];

    normalize = spec: let
      global = spec.global or {};
      scoped =
        spec.scoped or (
          if spec ? global
          then {}
          else spec
        );
      value = recursiveUpdate global scoped;
      raw = spec;
    in {inherit global scoped raw value;};

    modules = recursiveSelf (self: let
      scope =
        recursiveUpdate
        seed
        (clean (mapAttrs (_: lib: lib.value) self));
    in
      foldl'
      recursiveUpdate
      {}
      (
        map
        (spec: {${spec.name} = normalize (import spec.input scope);})
        (getSpecs {inherit base excludes;})
      ));

    domains = mapAttrs (_: mod: mod.value) modules;
    aliases =
      foldl'
      (acc: mod: recursiveUpdate acc mod.global)
      {}
      (attrValues modules);
    merged = recursiveUpdate domains aliases;
    charged = recursiveUpdate (recursiveUpdate seed extra) merged;
  in {
    inherit aliases charged domains;
    # ${names.lib or "lix"} = charged;
    excluded = excludes;
  };
in
  exports
