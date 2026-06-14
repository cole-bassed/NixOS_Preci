let
  exports = {
    inherit
      asList
      fix
      foldl'
      gets
      merge
      mkLib
      mkLibs
      nest
      stem
      ;
  };

  inherit
    (builtins)
    attrNames
    foldl'
    head
    isAttrs
    isList
    isString
    listToAttrs
    match
    tail
    typeOf
    ;

  fix = fn: let result = fn result; in result;

  asList = value: let
    type = typeOf value;
  in
    if isList value
    then value
    else if isString value
    then [value]
    else if isAttrs value
    then attrNames value
    else if type == "path"
    then [value]
    else throw "lists.as:= unsupported type: ${type}";

  gets = names: attrs:
    listToAttrs (
      map (name: {
        inherit name;
        value = attrs.${name} or {};
      })
      names
    );

  merge = lhs: rhs:
    if isAttrs lhs && isAttrs rhs
    then
      listToAttrs (
        map
        (key: {
          name = key;
          value =
            if lhs ? ${key} && rhs ? ${key}
            then merge lhs.${key} rhs.${key}
            else rhs.${key} or lhs.${key};
        })
        (attrNames (lhs // rhs))
      )
    else rhs;

  stem = path: let
    name = baseNameOf (toString path);
    groups = match "^(.*)\\.nix$" name;
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
    scoped = imported.scoped or imported.global or imported;
    global = imported.global or {};
    value = merge scoped global;
  in
    {
      __raw = imported;
      __scoped = scoped;
      __global = global;
      __value = value;
    }
    // (nest (asList output) value)
    // global;

  mkLibs = {
    libraries,
    specs,
    prefix ? [],
    base ? {},
  }: let
    mkOne = {
      input,
      dependencies ? [],
      output ? null,
    }: let
      finalOutput =
        if output == null
        then prefix ++ [(stem input)]
        else prefix ++ asList output;
    in
      mkLib {
        inherit input;
        args = gets dependencies libraries;
        output = finalOutput;
      };
  in
    foldl' merge base (map mkOne specs);
in
  exports
