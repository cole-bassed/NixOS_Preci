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
  inherit (attrsets) gets merge;
  inherit (lists) concat head foldl' asList tail;
  inherit (strings) matchRegex;

  /**
  Compute the fixed point of a function.

  The function receives its own final result as input.
  This allows self-referential values and recursive scopes to be defined
  without using `rec`.

  # Type
  ```nix
  fix :: (a -> a) -> a
  ```

  # Aliases
  - `fixedPoint`
  - `recursiveSelf`

  # Dependencies
  None

  # Arguments
  fn
  : The function to evaluate against its own final result.

  # Examples
  ```nix
  fix (self: {
    a = 1;
    b = self.a + 1;
  })
  # => { a = 1; b = 2; }
  ```

  ```nix
  fixedPoint (self: {
    inherit (self) name;
    name = "lix";
  })
  # => { name = "lix"; }
  ```

  ```nix
  recursiveSelf (libraries:
    {
      core = "ok";
      derived = libraries.core;
    })
  # => { core = "ok"; derived = "ok"; }
  ```
  */
  fix = fn: let
    self = fn self;
  in
    self;

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
    // (nest (asList output) value);

  mkLibs = {
    specs,
    prefix ? [],
    base ? {},
    seed ? {},
  }: let
    mkOne = state: {
      input,
      dependencies ? [],
      output ? null,
      prefix ? [],
    }: let
      finalOutput =
        if output == null
        then prefix ++ [(stem input)]
        else prefix ++ asList output;

      args = gets dependencies state.nested;

      module = mkLib {
        inherit input;
        inherit args;
        output = finalOutput;
      };
    in {
      nested = merge state.nested module;
      globals = merge state.globals (module.__global or {});
    };

    flattenSpec = spec:
      if spec ? specs
      then
        concat (map
          (child:
            flattenSpec (
              child
              // {
                prefix = (spec.prefix or []) ++ (child.prefix or []);
              }
            ))
          (spec.specs or []))
      else [spec];

    flattenSpecs = specs: concat (map flattenSpec specs);
  in let
    prefixed = map (spec: spec // {prefix = prefix ++ (spec.prefix or []);}) (flattenSpecs specs);
    result =
      foldl' mkOne {
        nested = merge base seed;
        globals = {};
      }
      prefixed;
  in
    with result; merge nested globals;

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
in
  exports
