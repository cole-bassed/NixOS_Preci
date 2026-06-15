# let
#   inherit
#     (builtins)
#     attrNames
#     filter
#     foldl'
#     head
#     isAttrs
#     listToAttrs
#     match
#     readDir
#     stringLength
#     substring
#     ;
#   home = ./.;
#   fix = f: let self = f self; in self;
#   merge = lhs: rhs:
#     if isAttrs lhs && isAttrs rhs
#     then
#       listToAttrs (map
#         (name: {
#           inherit name;
#           value =
#             if lhs ? ${name} && rhs ? ${name}
#             then merge lhs.${name} rhs.${name}
#             else if rhs ? ${name}
#             then rhs.${name}
#             else lhs.${name};
#         })
#         (attrNames (lhs // rhs)))
#     else rhs;
#   hasNixSuffix = name: let
#     suffix = ".nix";
#     nameLen = stringLength name;
#     suffixLen = stringLength suffix;
#   in
#     (nameLen >= suffixLen)
#     && substring (nameLen - suffixLen) suffixLen name == suffix;
#   dropNixSuffix = name: let
#     groups = match "^(.*)\\.nix$" name;
#   in
#     if groups == null
#     then name
#     else head groups;
#   nameOf = path:
#     dropNixSuffix (baseNameOf path);
#   isLibraryFile = name:
#     hasNixSuffix name
#     && name != "default.nix"
#     && name != "bootstrap.nix";
#   orEmptyAttrs = names:
#     listToAttrs (map (name: {
#         inherit name;
#         value = {};
#       })
#       names);
#   specs =
#     map
#     (name: {input = home + "/${name}";})
#     (filter isLibraryFile (attrNames (readDir home)));
#   mkDeps = state:
#     orEmptyAttrs (map (spec: nameOf spec.input) specs)
#     // removeAttrs state ["__internal"];
#   libraries = state: spec: let
#     name = nameOf spec.input;
#     imported = import spec.input (mkDeps state);
#     scoped = imported.scoped or imported.global or imported;
#     global = imported.global or {};
#     value = merge scoped global;
#   in
#     merge state (
#       {${name} = value;}
#       # // global
#       // {}
#     );
# in
#   # builtins
#   # // foldl' libraries {} specs
#   fix (_: (foldl' libraries {} specs))
let
  inherit
    (builtins)
    attrNames
    filter
    isAttrs
    listToAttrs
    head
    match
    readDir
    stringLength
    substring
    ;

  home = ./.;

  fix = f: let self = f self; in self;

  merge = lhs: rhs:
    if isAttrs lhs && isAttrs rhs
    then
      listToAttrs (map
        (name: {
          inherit name;
          value =
            if lhs ? ${name} && rhs ? ${name}
            then merge lhs.${name} rhs.${name}
            else if rhs ? ${name}
            then rhs.${name}
            else lhs.${name};
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

  nameOf = path: dropNixSuffix (baseNameOf path);

  isLibraryFile = name:
    hasNixSuffix name
    && name != "default.nix"
    && name != "bootstrap.nix";

  mkLibs = self:
    listToAttrs (
      map
      (
        spec: let
          name = nameOf spec.input;
          imported = import spec.input (removeAttrs self ["__internal"]);
          scoped = imported.scoped or imported.global or imported;
          global = imported.global or {};
          value = merge scoped global;
        in {inherit name value;}
      )
      (
        map
        (name: {input = home + "/${name}";})
        (filter isLibraryFile (attrNames (readDir home)))
      )
    );
in
  fix (self: mkLibs self)
