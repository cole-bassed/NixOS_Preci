let
  inherit
    (builtins)
    attrNames
    elem
    filter
    isAttrs
    listToAttrs
    pathExists
    readDir
    stringLength
    substring
    ;

  getSpecs = {
    base ? ./.,
    excludes ? ["default"],
    ...
  }: let
    hasNixSuffix = name: let
      suffix = ".nix";
      nameLen = stringLength name;
      suffixLen = stringLength suffix;
    in
      nameLen
      >= suffixLen
      && substring (nameLen - suffixLen) suffixLen name == suffix;

    dropNixSuffix = name:
      if hasNixSuffix name
      then substring 0 ((stringLength name) - 4) name
      else name;
    entries = readDir base;

    normalizedExcludes = map dropNixSuffix excludes;

    isIncluded = name:
      !(elem (dropNixSuffix name) normalizedExcludes);

    hasDefault = name:
      pathExists (base + "/${name}/default.nix");

    isModuleFile = name:
      entries.${name} == "regular" && hasNixSuffix name;

    isModuleDir = name:
      entries.${name} == "directory" && hasDefault name;

    mkSpec = name:
      if isModuleFile name
      then {
        name = dropNixSuffix name;
        input = base + "/${name}";
      }
      else {
        inherit name;
        input = base + "/${name}/default.nix";
      };
  in
    map mkSpec (
      filter
      (name:
        isIncluded name
        && (isModuleFile name || isModuleDir name))
      (attrNames entries)
    );

  recursiveSelf = f: let self = f self; in self;

  recursiveUpdate = lhs: rhs:
    if isAttrs lhs && isAttrs rhs
    then
      listToAttrs (
        map
        (name: {
          inherit name;
          value =
            if lhs ? ${name} && rhs ? ${name}
            then recursiveUpdate lhs.${name} rhs.${name}
            else rhs.${name} or lhs.${name};
        })
        (attrNames (lhs // rhs))
      )
    else rhs;

  optionalAttrs = condition: set:
    if condition
    then set
    else {};
in {inherit getSpecs recursiveUpdate recursiveSelf optionalAttrs;}
