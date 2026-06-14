{attrsets, lists, ...}: let
exports={
  global = {inherit  mkLib mkLibs;};
  scoped = {inherit stem nest mkLib mkLibs;};
};
  inherit (attrsets) gets merge ;
  inherit (lists) head foldl' match asList tail;

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
in exports
