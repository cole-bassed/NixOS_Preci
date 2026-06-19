{paths ? {src = ../../../.;}}: let
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

  recursiveSelf = f: let self = f self; in self;
  recursiveAttrs = lhs: rhs:
    if isAttrs lhs && isAttrs rhs
    then
      listToAttrs (map
        (name: {
          inherit name;
          value =
            if lhs ? ${name} && rhs ? ${name}
            then recursiveAttrs lhs.${name} rhs.${name}
            else rhs.${name} or lhs.${name};
        })
        (attrNames (lhs // rhs)))
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

  # mkLibs = {
  #   home,
  #   excludes ? ["default"],
  #   extra ? {},
  # }: let
  #   normalizedExcludes = map normalizeNix excludes;

  #   modules =
  #     map
  #     (name: {input = home + "/${name}";})
  #     (
  #       filter
  #       (
  #         name:
  #           hasNixSuffix name
  #           && !(elem (normalizeNix name) normalizedExcludes)
  #       )
  #       (attrNames (readDir home))
  #     );

  #   clean = attrs: removeAttrs attrs ["__flat" "__globals"];

  #   libraries = recursiveSelf (self:
  #     listToAttrs (
  #       map
  #       (spec: let
  #         name = nameOf spec.input;
  #         imported = import spec.input (clean (mapAttrs (_: v: v.__value) self) // {inherit paths;});
  #         global = imported.global or {};
  #         local = imported.scoped or imported.global or imported;
  #       in {
  #         inherit name;
  #         value = {
  #           __global = global;
  #           __value = recursiveAttrs global local;
  #         };
  #       })
  #       modules
  #     ));

  #   scoped =
  #     mapAttrs
  #     (_: mod: mod.__value)
  #     libraries;

  #   global =
  #     foldl'
  #     (acc: mod: recursiveAttrs acc mod.__global)
  #     {}
  #     (attrValues libraries);
  # in
  #   recursiveAttrs extra (recursiveAttrs global scoped);
  mkLibs = {
    home,
    excludes ? ["default"],
    extra ? {},
  }: let
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
        then {
          input = home + "/${name}";
        }
        else {
          input = home + "/${name}/default.nix";
        })
      (filter
        (name:
          isIncluded name
          && (
            (entries.${name} == "regular" && hasNixSuffix name)
            || (entries.${name} == "directory" && pathExists (home + "/${name}/default.nix"))
          ))
        (attrNames entries));

    clean = attrs: removeAttrs attrs ["__flat" "__globals"];

    libraries = recursiveSelf (self: let
      scope = clean (mapAttrs (_: v: v.__value) self);
    in
      listToAttrs (map
        (spec: let
          name = nameOf spec.input;
          imported = import spec.input (scope // {inherit paths;});
          global = imported.global or {};
          local = imported.scoped or imported.global or imported;
        in {
          inherit name;
          value = {
            __global = global;
            __value = recursiveAttrs global local;
          };
        })
        specs));

    scoped = mapAttrs (_: mod: mod.__value) libraries;

    global =
      foldl'
      (acc: mod: recursiveAttrs acc mod.__global)
      {}
      (attrValues libraries);
  in
    recursiveAttrs extra (recursiveAttrs global scoped);
in
  {inherit mkLibs;}
  // mkLibs {
    home = ./.;
    excludes = ["default" "bootstrap"];
    extra = builtins;
  }
