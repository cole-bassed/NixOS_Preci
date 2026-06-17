{
  attrsets,
  filesystem,
  ...
}: let
  exports = {
    global = {
      inherit mkLibrary;
      mkFixedPoint = fix;
      recursiveSelf = fix;
    };
    scoped = {
      inherit fix mkLibrary;
      inherit (filesystem) mkPaths;
    };
  };

  inherit (builtins) attrValues foldl listToAttrs mapAttrs;
  inherit (attrsets) asAttrsIf recursiveAttrs;
  inherit (filesystem) getSpecs;

  fix = fn: let self = fn self; in self;

  mkLibrary = {
    base,
    excludes ? ["default"],
    extra ? {},
    enableExtras ? true,
    enableAliases ? true,
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
      scope = clean (mapAttrs (_: lib: lib.value) self);
    in
      listToAttrs (
        map
        (spec: {
          name = spec.name;
          value = normalize (spec.input scope);
        })
        (getSpecs {inherit base excludes;})
      ));

    scoped = mapAttrs (_: mod: mod.value) modules;

    global =
      foldl
      (acc: mod: recursiveAttrs acc mod.global)
      {}
      (attrValues modules);

    merged =
      recursiveAttrs
      (asAttrsIf enableAliases global)
      scoped;

    charged =
      recursiveAttrs
      (asAttrsIf enableExtras extra)
      merged;
  in
    charged;
in
  exports
