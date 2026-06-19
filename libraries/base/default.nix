let
  base = ./.;
  excludes = ["default"];
  inherit
    (builtins)
    attrNames
    attrValues
    elem
    filter
    foldl'
    head
    isAttrs
    listToAttrs
    mapAttrs
    match
    pathExists
    readDir
    stringLength
    substring
    ;

  recursiveSelf = f: let
    self = f self;
  in
    self;

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
            else if rhs ? ${name}
            then rhs.${name}
            else lhs.${name};
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
    groups = match "^(.*)\\.nix$" name;
  in
    if groups == null
    then name
    else head groups;

  normalizeNix = name:
    if hasNixSuffix name
    then dropNixSuffix name
    else name;

  nameOf = path: dropNixSuffix (baseNameOf path);

  normalizedExcludes = map normalizeNix excludes;
  entries = readDir base;

  isIncluded = name:
    !(elem (normalizeNix name) normalizedExcludes);

  specs =
    map
    (name: let
      kind = entries.${name};
    in
      if kind == "regular" && hasNixSuffix name
      then {
        input = base + "/${name}";
      }
      else {
        input = base + "/${name}/default.nix";
      })
    (filter
      (name:
        isIncluded name
        && (
          (entries.${name} == "regular" && hasNixSuffix name)
          || (entries.${name} == "directory" && pathExists (base + "/${name}/default.nix"))
        ))
      (attrNames entries));

  clean = attrs: removeAttrs attrs ["__value" "__global" "__scoped"];

  collectGlobals = exported:
    if exported ? global
    then exported.global
    else if exported ? scoped
    then {}
    else if isAttrs exported
    then
      foldl'
      recursiveAttrs
      {}
      (map
        (name: let
          value = exported.${name};
        in
          if isAttrs value && value ? global
          then value.global
          else {})
        (attrNames exported))
    else {};

  collectScoped = exported:
    if exported ? scoped
    then exported.scoped
    else if exported ? global
    then exported.global
    else exported;

  libraries = recursiveSelf (self: let
    scope = clean (mapAttrs (_: v: v.__value) self);
  in
    listToAttrs (
      map
      (spec: let
        name = nameOf spec.input;
        imported = import spec.input scope;
        global = collectGlobals imported;
        scoped = collectScoped imported;
      in {
        inherit name;
        value = {
          __global = global;
          __scoped = scoped;
          __value = recursiveAttrs global scoped;
        };
      })
      specs
    ));

  scoped = mapAttrs (_: mod: mod.__value) libraries;

  global =
    foldl'
    (acc: mod: recursiveAttrs acc mod.__global)
    {}
    (attrValues libraries);
in
  scoped // global
