_: let
  exports = {
    scoped = {
      inherit
        getFunctionArgs
        id
        makeHybrid
        readHybrid
        setFunctionArgs
        setFunctionArgs'
        ;
      fix = makeFixedPoint;
    };
    global = {
      inherit makeFixedPoint;
      makeHybridFn = makeHybrid;
      readHybridFn = readHybrid;
      recursiveSelf = makeFixedPoint;
    };
  };
  inherit
    (builtins)
    all
    attrNames
    elem
    functionArgs
    hasAttr
    head
    isAttrs
    isList
    tail
    groupBy
    ;

  # TODO: Create the proper doc
  /**
  Create recursive fixed point
  */
  makeFixedPoint = fn: let self = fn self; in self;
  id = x: x;

  # TODO: Create the proper doc
  /**
  The Builder: Constructs the curried + attribute-set interface
  */
  makeHybrid = {
    positional,
    # primary ? head positional,
    primary ? (
      if positional == []
      then null
      else head positional
    ),
    fallback ? _: false,
  }: let
    _name = "makeHybrid";
  in
    assert positional != [] -> primary != null;
      exec: let
        accumulate = collected: remaining: arg:
          if remaining == []
          then throw "${_name}: too many positional arguments"
          else let
            current = head remaining;
            rest = tail remaining;
            payload = collected // {${current} = arg;};
          in
            if rest == []
            then exec payload
            else accumulate payload rest;

        wrapper = payload:
          if isAttrs payload && (payload ? ${primary} || primary == null)
          then exec payload
          else if fallback payload
          then exec {${primary} = payload;}
          else accumulate {} positional payload;
      in
        wrapper;

  # TODO: Create the proper doc
  /**
  The Reader: Explodes, validates, and applies defaults/fallbacks
  */
  readHybrid = {
    payload,
    positional ? [],
    primary ? null,
    required ? [],
    defaults ? {},
    allowed ? [],
    optional ? [],
    legacyKey ? head required,
  }: let
    #> Define validation configuration and state
    required' =
      required
      ++ (
        if isList primary
        then primary
        else if isAttrs primary
        then attrNames primary
        else if primary != null && primary != ""
        then [primary]
        else []
      );
    args = required' ++ positional ++ allowed ++ optional ++ (attrNames defaults);
    keys = attrNames payload;

    #> Perform determinant logic
    check = let
      hasRequired =
        all
        (req: hasAttr req payload)
        required';
      hasAllowed =
        all
        (key: elem key (attrNames (groupBy id args)))
        keys;
    in
      hasRequired && hasAllowed;
    #> Normalize the data structure based on the check result
    normalized =
      if check
      then payload
      else {"${legacyKey}" = payload;};
  in
    defaults // normalized;

  getFunctionArgs = fn:
    if fn ? __functor
    then fn.__functionArgs or (functionArgs (fn.__functor fn))
    else functionArgs fn;
  setFunctionArgs' = fn: args: {
    __functionArgs = args;
    __functor = self: supplied:
    #? If a positional value is passed, bypass validation and forward directly to the lambda
      if !isAttrs supplied
      then fn supplied
      else if !all (name: args.${name} || hasAttr name supplied) (attrNames args)
      then throw "setFunctionArgs: required argument missing"
      else if !all (name: hasAttr name args) (attrNames supplied)
      then throw "setFunctionArgs: unexpected argument"
      else fn supplied;
  };
  setFunctionArgs = f: args: {
    __functor = self: f;
    __functionArgs = args;
  };
in
  exports
