_: let
  exports = {
    scoped = {
      inherit makeHybrid readHybrid id setFunctionArgs getFunctionArgs;
      fix = makeFixedPoint;
    };
    global = {
      inherit makeFixedPoint;
      recursiveSelf = makeFixedPoint;
      makeHybridFn = makeHybrid;
      readHybridFn = readHybrid;
    };
  };

  inherit
    (builtins)
    all
    attrNames
    elem
    functionArgs
    groupBy
    hasAttr
    head
    isAttrs
    tail
    unsafeGetAttrPos
    ;
  unique = list: attrNames (groupBy id list);

  # setFunctionArgs = fn: args: {
  #   __functionArgs = args;
  #   __functor = self: supplied:
  #   #? If a positional value is passed, bypass validation and forward directly to the lambda
  #     if !isAttrs supplied
  #     then fn supplied
  #     else if !all (name: args.${name} || hasAttr name supplied) (attrNames args)
  #     then throw "setFunctionArgs: required argument missing"
  #     else if !all (name: hasAttr name args) (attrNames supplied)
  #     then throw "setFunctionArgs: unexpected argument"
  #     else fn supplied;
  # };
  setFunctionArgs = f: args: {
    __functor = self: f;
    __functionArgs = args;
  };
  getFunctionArgs = fn:
    if fn ? __functor
    then fn.__functionArgs or (functionArgs (fn.__functor fn))
    else functionArgs fn;

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
  # The Builder: Constructs the curried + attribute-set interface
  makeHybrid = {
    positional,
    primary ? head positional,
    fallback ? _: false,
  }: let
    _name = "makeHybrid";
  in
    assert positional != [];
      exec: let
        accumulate = collected: remaining: arg:
          if remaining == []
          then throw "${_name}: Too many positional arguments supplied"
          else let
            current = head remaining;
            rest = tail remaining;
            payload = collected // {"${current}" = arg;};
          in
            if rest == []
            then exec payload
            else accumulate payload rest;

        wrapper = payload:
          if isAttrs payload && payload ? ${primary}
          then exec payload
          else if fallback payload
          then exec {"${primary}" = payload;}
          else accumulate {} positional payload;
      in
        wrapper;

  # TODO: Create the proper doc
  /**
  The Reader: Explodes, validates, and applies defaults/fallbacks
  */
  readHybrid = {
    payload,
    required ? [],
    defaults ? {},
    allowed ? required ++ (attrNames defaults),
    legacy_key ? head required,
  }: let
    #> Define validation configuration and state
    rules = {
      allowed = unique allowed;
      keys = attrNames payload;
    };

    #> Perform determinant logic
    check = let
      hasRequired = all (req: hasAttr req payload) required;
      hasAllowed = all (key: elem key rules.allowed) rules.keys;
    in
      hasRequired && hasAllowed;

    #> Normalize the data structure based on the check result
    normalized =
      if check
      then payload
      else {"${legacy_key}" = payload;};
  in
    defaults // normalized;
in
  exports
