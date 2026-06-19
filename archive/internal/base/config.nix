{
  attrsets,
  lists,
  strings,
  ...
}: let
  exports = {
    global = {
      inherit mkLib mkLibs;
      fixedPoint = fix;
      recursiveSelf = fix;
    };
    scoped = {inherit fix stem nest mkLib mkLibs;};
  };

  inherit
    (builtins)
    attrNames
    attrValues
    elem
    filter
    foldl'
    isAttrs
    listToAttrs
    mapAttrs
    pathExists
    readDir
    stringLength
    substring
    ;
  inherit (attrsets) merge;
  inherit (lists) head asList tail;
  inherit (strings) matchRegex;

  fix = fn: let
    self = fn self;
  in
    self;

  stem = path: let
    name = baseNameOf (toString path);
    groups = matchRegex "^(.*)\\.nix$" name;
  in
    if groups == null
    then name
    else head groups;

  nest = path: value:
    if path == []
    then value
    else {${head path} = nest (tail path) value;};

  mkLib = {
    input,
    output ? [(stem input)],
    args ? {},
  }: let
    imported = import input args;
    scoped =
      imported.scoped or (
        if imported ? global
        then {}
        else imported
      );
    global = imported.global or {};
    value = merge global scoped;
  in
    {
      __raw = imported;
      __scoped = scoped;
      __global = global;
      __value = value;
    }
    // (nest (asList output) value);

  mkLibs = {
    home,
    excludes ? ["default"],
    extra ? {},
  }: let
    recursiveAttrs = lhs: rhs:
      if isAttrs lhs && isAttrs rhs
      then
        listToAttrs (
          map
          (name: {
            inherit name;
            value =
              if lhs ? ${name} && rhs ? ${name}
              then recursiveAttrs lhs.${name} rhs.${name}
              else rhs.${name} or lhs.${name};
          })
          (attrNames (lhs // rhs))
        )
      else rhs;

    hasNixSuffix = name: let
      suffix = ".nix";
      nameLen = stringLength name;
      suffixLen = stringLength suffix;
    in
      nameLen
      >= suffixLen
      && substring (nameLen - suffixLen) suffixLen name == suffix;

    dropNixSuffix = name: let
      groups = matchRegex "^(.*)\\.nix$" name;
    in
      if groups == null
      then name
      else head groups;

    normalizeNix = name:
      if hasNixSuffix name
      then dropNixSuffix name
      else name;

    nameOf = path: dropNixSuffix (baseNameOf (toString path));

    normalizedExcludes = map normalizeNix excludes;
    entries = readDir home;

    isIncluded = name:
      !(elem (normalizeNix name) normalizedExcludes);

    specs =
      map
      (name: let
        kind = entries.${name};
      in
        if kind == "regular" && hasNixSuffix name
        then {input = home + "/${name}";}
        else {input = home + "/${name}/default.nix";})
      (
        filter
        (name:
          isIncluded name
          && (
            (entries.${name} == "regular" && hasNixSuffix name)
            || (entries.${name}
              == "directory"
              && pathExists (home + "/${name}/default.nix"))
          ))
        (attrNames entries)
      );

    clean = attrs:
      removeAttrs attrs [
        "__flat"
        "__globals"
        "__global"
        "__scoped"
        "__value"
        "__raw"
      ];

    libraries = fix (self: let
      scope = clean (mapAttrs (_: v: v.__value) self);
    in
      listToAttrs (
        map
        (spec: let
          name = nameOf spec.input;
          imported = import spec.input (extra // scope);
          global = imported.global or {};
          scoped =
            imported.scoped or (
              if imported ? global
              then {}
              else imported
            );
        in {
          inherit name;
          value = {
            __raw = imported;
            __global = global;
            __scoped = scoped;
            __value = recursiveAttrs global scoped;
          };
        })
        specs
      ));

    scoped =
      mapAttrs (_: mod: mod.__value) libraries;

    global =
      foldl'
      (acc: mod: recursiveAttrs acc mod.__global)
      {}
      (attrValues libraries);
  in
    recursiveAttrs extra (recursiveAttrs global scoped);
in
  exports
