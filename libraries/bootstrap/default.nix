let
  inherit
    (builtins)
    attrNames
    filter
    foldl'
    listToAttrs
    match
    readDir
    stringLength
    substring
    ;

  removeNix = name: substring 0 (stringLength name - 4) name;

  libraries =
    filter
    (name: name != "default.nix" && match ".*\\.nix" name != null)
    (attrNames (readDir ./.));

  normalize = library:
    (library.scoped or {})
    // (library.global or {})
    // library;

  scoped = listToAttrs (
    map
    (name: {
      name = removeNix name;
      value = normalize (import ./${name});
    })
    libraries
  );

  global =
    builtins
    // foldl'
    (
      acc: name: let
        library = scoped.${name};
      in
        if library ? global
        then acc // library.global
        else acc
    )
    {}
    (attrNames scoped);
in
  global // scoped // {inherit global scoped;}
