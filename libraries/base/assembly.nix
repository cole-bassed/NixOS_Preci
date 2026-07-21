{
  debug ? {},
  attrsets ? {},
  trivial ? {},
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
    foldl'
    groupBy
    hasAttr
    head
    isAttrs
    isList
    length
    listToAttrs
    mapAttrs
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

    normalize = arguments: let
      args = required ++ positional ++ optional ++ (attrNames defaults);
      keys = attrNames arguments;
      check = let
        hasRequired = all (req: hasAttr req arguments) required;
        hasAllowed = all (key: elem key (attrNames (groupBy (x: x) args))) keys;
      in
        hasRequired && hasAllowed;
    in
      if check
      then arguments
      else {"${legacyKey}" = arguments;};

    #> A validation entry may be a plain function (input -> validatedValue),
    #> or an attrset { validate :: input -> validatedValue; options ? [...]; type ? "..."; }
    #> that also documents what's valid for that field. Normalize either
    #> shape to a callable, and separately expose whatever metadata was given.
    validatorFn = field: let
      entry = validation.${field} or (v: v);
    in
      if isAttrs entry
      then entry.validate
      else entry;

    validatorMeta = field: let
      entry = validation.${field} or null;
    in
      if isAttrs entry
      then removeAttrs entry ["validate"]
      else {};

    resolve = arguments: let
      fields = required ++ optional;
      merged = defaults // arguments;
      validateField = field: (validatorFn field) merged.${field};
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
    runSimulation = self: let
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
              context = "runSimulation";
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
        #> Per-field validator metadata (e.g. options/type), where the
        #> validator declared any - see validatorMeta above.
        validationInfo = listToAttrs (map (field: {
            name = field;
            value = validatorMeta field;
          })
          (required ++ optional));
      };
      __args = {inherit explicit implicit;};
      __trace = history;
      __functor = self: nextRaw:
        if isAttrs nextRaw
        then exec history (explicit // nextRaw)
        else throw "${_name}: too many positional arguments";
      __tests = runSimulation wrapper;
      result = execution implicit;
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
    #> If positional args are declared, a primary field must be resolvable
    #> (either given explicitly or derivable as head required) - otherwise
    #> the bare-value fallback path in `wrapper` has no key to assign into.
    guard = assertWith {
      inherit name;
      assertion = positional != [] -> primary != null;
      message = "positional is non-empty but primary could not be resolved (check required)";
      context = "buildFunction setup";
    };
  in
    assert guard; wrapper;
in
  exports
