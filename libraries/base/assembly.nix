{
  debug ? {},
  attrsets ? {},
  trivial ? {},
  # lists ? {},
  filesystem ? {},
  names ? {},
  ...
}: let
  exports = {
    scoped = {
      mkFn = mkFunction;
      mkLibs = mkLibrary;
      mkLix = mkLibraryFlat;
      inherit mkFunction mkLibraryFlat;
    };
    global = {inherit mkLibrary mkLibraryFlat;};
  };

  bootstrap = import ./.;

  optionalAttrs = attrsets.optionalAttrs or bootstrap.optionalAttrs;
  recursiveUpdate = attrsets.recursiveUpdate or bootstrap.recursiveUpdate;
  recursiveSelf = trivial.recursiveSelf or bootstrap.recursiveSelf;
  getSpecs = filesystem.getSpecs or bootstrap.getSpecs;

  inherit
    (builtins)
    all
    attrNames
    attrValues
    elem
    elemAt
    filter
    foldl'
    hasAttr
    head
    isAttrs
    isList
    isString
    length
    listToAttrs
    mapAttrs
    split
    stringLength
    substring
    tail
    toJSON
    ;
  inherit (debug) assertWith traceWith tryWith warnWith;

  mkLibraryFlat = library:
    recursiveUpdate
    library
    {${names.lib or "lix"} = library.charged;};

  mkLibrary = {
    base,
    excludes ? seed.excludes.paths or ["default"], #TODO: This needs to see folders to skip as will, not just files and if the extension (nix) is present it doesn't skip?
    seed ? {},
    extra ? {},
    args ? null,
  }: let
    clean = set:
      removeAttrs set [
        "flat"
        "global"
        "scoped"
        "value"
        "raw"
      ];

    normalize = spec: let
      global = spec.global or {};
      scoped =
        spec.scoped or (
          if spec ? global
          then {}
          else spec
        );
      value = recursiveUpdate global scoped;
      raw = spec;
    in {inherit global scoped raw value;};

    modules = recursiveSelf (self: let
      scope =
        (optionalAttrs (args != null) {inherit args;})
        // (
          recursiveUpdate
          seed
          (clean (mapAttrs (_: lib: lib.value) self))
        );
    in
      foldl'
      recursiveUpdate
      {}
      (
        map
        (spec: {${spec.name} = normalize (import spec.input scope);})
        (getSpecs {inherit base excludes;})
      ));

    domains = mapAttrs (_: mod: mod.value) modules;
    aliases =
      foldl'
      (acc: mod: recursiveUpdate acc mod.global)
      {}
      (attrValues modules);
    merged = recursiveUpdate domains aliases;
    charged = recursiveUpdate (recursiveUpdate seed extra) merged;
  in {
    inherit aliases charged domains;
    ${names.lib or "lix"} = charged;
    lib = charged.lib or merged;
    excluded = excludes;
  };

  /**
  Build a standardized Nix function with hybrid invocation, validation, inline
  simulation, and debugging metadata.

  The generated function accepts either an explicit attribute set or curried
  positional arguments. Defaults are resolved before validation, and an isolated
  debug view is exposed alongside the callable function.

  # Type
  ```nix
  mkFunction :: AttrSet -> AttrSet
  ```

  # Dependencies
  - builtins.all
  - builtins.attrNames
  - builtins.elem
  - builtins.elemAt
  - builtins.filter
  - builtins.foldl'
  - builtins.hasAttr
  - builtins.head
  - builtins.isAttrs
  - builtins.isList
  - builtins.isString
  - builtins.length
  - builtins.listToAttrs
  - builtins.split
  - builtins.stringLength
  - builtins.substring
  - builtins.tail
  - builtins.toJSON
  - debug.assertWith
  - debug.traceWith
  - debug.tryWith
  - debug.warnWith

  # Arguments
  name
  : The fully qualified function name, typically dotted, such as
  `"strings.greet"`. The final segment becomes the key in the returned attribute
  set.

  positional
  : The argument names, in order, used for curried positional application.

  required
  : The argument names that must be resolved before execution.

  validation
  : An attribute set mapping argument names to validator functions or metadata
  attribute sets containing `validate` and optional descriptive fields.

  execution
  : A function receiving the resolved and validated arguments attribute set.

  defaults
  : Optional default values. Defaults to `{}`.

  fallback
  : Optional predicate that permits a raw input to be assigned to `primary`.
  Defaults to rejecting all inputs.

  legacyKey
  : Optional key used when normalizing a raw input. Defaults to `primary`.

  optional
  : Optional argument names. Defaults to the keys of `defaults`.

  primary
  : The argument receiving a single scalar value. Defaults to the first required
  argument. Must be supplied explicitly if `required` is empty.

  trace
  : Whether to trace each partial-application step. Defaults to `false`.

  simulation
  : Inline test cases containing `args` and either `desired` or `throws = true`.
  Defaults to `[]`.

  # Returns
  An attribute set of the shape `{ ${leaf} = callable; __debug.${leaf} = debugView; }`,
  where `leaf` is the last dot-segment of `name`. This is **not** self-referential
  under the binding you assign it to — consume it with `inherit`, not by nesting.

  # Examples
  - __Building a Function__

    > _greet = mkFunction {
        name = "strings.greet";
        positional = [ "name" "punctuation" ];
        required = [ "name" ];
        defaults.punctuation = "!";
        validation.name = builtins.toString;
        execution = args: "Hello, ${args.name}${args.punctuation}";
        simulation = [
          { args = "World"; desired = "Hello, World!"; }
          { args = [ "Alice" "." ]; desired = "Hello, Alice."; }
        ];
      };
    > inherit (_greet) greet;
    > inherit (_greet) __debug; # merge with other fns' __debug sets via recursiveUpdate

  ---
  - __Curried Positional Invocation__

    > greet "Nix" "?"
  ```sh
    "Hello, Nix?"
  ```
  ---
  - __Explicit Attribute Set Configuration__

    > greet { name = "Builder"; punctuation = "..."; }
  ```sh
    "Hello, Builder..."
  ```

  # Notes
  - Positional-curry mode and attrset-merge mode do not mix mid-chain: once a
    partial application has begun via positional args, passing an attrset next
    is treated as the raw value for the next positional field, not a merge.
    Attrset-merging via `__functor` (`explicit // nextRaw`) only applies to
    calls made directly against a fully-resolved (`__final`) result.
  - An explicit attrset call that uses only recognized field names but omits a
    required one throws immediately, rather than being silently reinterpreted
    as a legacy/raw value.
  */
  mkFunction = {
    #~@ Dependencies
    name,
    positional,
    required,
    validation,
    execution,
    #~@ Optionals
    defaults ? {},
    fallback ? _: false,
    legacyKey ? primary,
    optional ? attrNames defaults,
    primary ? head required,
    trace ? false, #> when true, emit a live trace line at each accumulation step
    #> Caller-authored worked examples, e.g.:
    #>   [ {args = "  hello  ";} {args = ["  hello  " "l" ""];} {args = {value = "  hello  ";};} ]
    #> Each entry's `args` is invoked against the built function itself
    #> (self), and the outcome is surfaced under __tests.
    simulation ? [],
  }: let
    _name = name;

    #> Distinguishes two shapes of incoming `arguments`:
    #>  1. named-args attrset using only recognized keys -> use as-is, complete or not
    #>     (completeness is `exec`'s job via `complete`, not normalize's)
    #>  2. anything else (unrecognized keys present) -> treat as a raw legacy value
    #>     and wrap it under `legacyKey`
    normalize = arguments: let
      args = required ++ positional ++ optional ++ (attrNames defaults);
      keys = attrNames arguments;
      hasAllowed = all (key: elem key args) keys;
    in
      if hasAllowed
      then arguments
      else {"${legacyKey}" = arguments;};

    #> A validation entry may be a plain function (input -> validatedValue),
    #> or an attrset { validate :: input -> validatedValue; options ? [...]; type ? "..."; }
    #> that also documents what's valid for that field. Normalize either
    #> shape to a callable, and separately expose whatever metadata was given.
    validator = {
      fn = field: let
        entry = validation.${field} or (v: v);
      in
        if isAttrs entry
        then entry.validate
        else entry;

      meta = field: let
        entry = validation.${field} or null;
      in
        if isAttrs entry
        then removeAttrs entry ["validate"]
        else {};
    };

    resolve = arguments: let
      fields = required ++ optional;
      merged = defaults // arguments;
      validateField = field: (validator.fn field) merged.${field};
    in
      listToAttrs (map (field: {
          name = field;
          value = validateField field;
        })
        fields);

    #> Invoke `self` (the fully-built wrapper) with a simulation entry's `args`,
    #> however they're shaped: a single positional value, a list of positional
    #> values applied one at a time, or an attrset applied directly.
    invoke = self: args:
      if isList args
      then
        # fold left: self arg1 arg2 arg3 ...
        foldl' (acc: a: acc a) self args
      else self args;

    #> Run every simulation entry against self and report expected vs actual.
    #> A `throws = true;` entry expects invocation to fail (tryWith.success == false).
    #> An entry that throws when it wasn't supposed to is reported via
    #> warnWith (non-fatal) rather than crashing evaluation of __tests.
    simulate = self: let
      runOne = entry: let
        expectThrow = entry.throws or false;
        attempt = tryWith (invoke self entry.args).result;
      in
        if expectThrow
        then {
          outcome =
            if !attempt.success
            then "<threw as expected>"
            else attempt.value;
          passed = !attempt.success;
          command = entry.args;
        }
        else let
          desired = entry.desired or null;
          unexpectedFailure = !attempt.success;
          outcome =
            warnWith {
              inherit name;
              assertion = !unexpectedFailure;
              message = "simulation entry threw unexpectedly for args: ${toJSON entry.args}";
              context = "simulate";
            } (
              if unexpectedFailure
              then "<threw unexpectedly>"
              else attempt.value
            );
        in {
          inherit outcome;
          passed = !unexpectedFailure && desired == outcome;
          command = entry.args;
        };
    in
      map runOne simulation;

    exec = history: arguments: let
      explicit = arguments;
      missing = filter (req: !(hasAttr req explicit)) required;
      #> Only required fields (not the full positional list) gate completeness.
      #> This lets functions like `has`/`trim` finalize early once required
      #> fields are met, while still accepting further optional positional
      #> args (mode, etc.) via the accumulate-overridden __functor below.
      complete = missing == [];
      normalized = normalize arguments;
      implicit = resolve normalized;
    in {
      __meta = {
        inherit
          defaults
          execution
          fallback
          legacyKey
          name
          optional
          positional
          primary
          required
          validation
          ;
        arity = length (attrNames explicit);
        validationInfo = listToAttrs (map (field: {
            name = field;
            value = validator.meta field;
          })
          (required ++ optional));
      };
      __args = {inherit explicit implicit;};
      __trace = history;
      __final = complete;
      __functor = self: nextRaw:
        if isAttrs nextRaw
        then exec history (explicit // nextRaw)
        else throw "${_name}: too many positional arguments";
      __tests =
        if complete
        then simulate wrapper
        else [];
      result =
        if complete
        then execution implicit
        else throw "${_name}: missing required argument(s): ${toJSON missing} — supply the rest, e.g. via attrset merge or the next curried argument";
    };

    #> Positional accumulation: collected so far -> remaining field names -> next value.
    #> Every step is fully resolvable (defaults backfill unset optional fields), and
    #> every step remains callable for the next positional arg via __functor.
    accumulate = collected: remaining: history: arg:
      if remaining == []
      then throw "${_name}: too many positional arguments"
      else let
        current = head remaining;
        rest = tail remaining;
        payload = collected // {${current} = arg;};
        arity = length (attrNames payload);
        record = {
          field = current;
          value = arg;
          inherit arity;
        };
        message = "set '${current}' (arity ${toString arity})";
        traced =
          if trace
          then
            traceWith {
              inherit name message;
              context = "accumulate";
            }
            record
          else record;
        nextHistory = history ++ [traced];
        result = exec nextHistory payload;
      in
        if rest == []
        then result
        else result // {__functor = self: accumulate payload rest nextHistory;};

    wrapper = payload:
      if isAttrs payload && (payload ? ${primary} || primary == null)
      then exec [] payload
      else if fallback payload
      then exec [] {${primary} = payload;}
      else accumulate {} positional [] payload;

    view = accessor: let
      project = out:
        if out ? __final
        then accessor out
        else out // {__functor = self: nextRaw: project (out.__functor self nextRaw);};
    in {__functor = self: raw: project (wrapper raw);};

    #? `name` is likely dotted, e.g. "strings.hasPrefix" -> leaf key is "hasPrefix"
    leaf = let
      parts = filter isString (split "\\." name);
    in
      elemAt parts (length parts - 1);

    callable = view (out: out.result);
    debugView = view (out: removeAttrs out ["result" "__functor"]);

    #> `primary` may default from `head required`, which throws on `[]`.
    #> `tryWith` converts that raw list-index throw into a legible assertion
    #> instead of a first-call surprise.
    primaryProbe = tryWith primary;

    assertions = {
      argsPositionalNeedsPrimary = assertWith {
        inherit name;
        assertion = positional != [] -> primary != null;
        message = "positional is non-empty but primary could not be resolved (check required)";
        context = "buildFunction setup";
      };
      primaryIsResolvable = assertWith {
        inherit name;
        assertion = primaryProbe.success;
        message = "primary could not be resolved (required is empty) - pass `primary` explicitly";
        context = "mkFunction setup";
      };
      legacyKeyIsString = assertWith {
        inherit name;
        assertion = isString legacyKey;
        message = "legacyKey (or primary) must resolve to a non-null string, got: ${toJSON legacyKey}";
        context = "mkFunction setup";
      };
      leafNeedsName = assertWith {
        inherit name;
        assertion = isString name && name != "" && substring (stringLength name - 1) 1 name != ".";
        message = "name must be a non-empty, non-dot-terminated string to derive a leaf key";
        context = "mkFunction leaf derivation";
      };
    };
  in
    assert assertions.primaryIsResolvable;
    assert assertions.argsPositionalNeedsPrimary;
    assert assertions.legacyKeyIsString;
    assert assertions.leafNeedsName;
      callable
      // {
        ${leaf} = callable;
        __debug.${leaf} = debugView;
      };
in
  exports
