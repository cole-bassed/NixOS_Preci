{
  attrsets,
  debug,
  lists,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit asList nthOr orNull orDefault orEmpty;

      atOr = nthOr;
      has = has';
      hasAny = hasAny';
      isEmpty = isEmpty';
      isNotEmpty = isNotEmpty';
    };
    global = {
      isEmptyList = isEmpty';
      isNotEmptyList = isNotEmpty';
      orDefaultList = orDefault;
      orNullList = orNull;
      toList' = asList;
      valueInList = nthOr;

      # Added to global exports
      inList = has';
      anyInList = hasAny';
    };
  };

  inherit (attrsets) isAttrs;
  inherit (debug) assertWithContext;
  inherit (lists) elemAt isList length optionals toList any elem; # Inherited 'any' and 'elem'
  inherit (types) typeOf isEmpty;

  isEmpty' = value: value == [];
  isNotEmpty' = value: !isEmpty' value;

  # --- Membership Checks ---

  has' = item: list:
    assert assertWithContext {
      name = "lists.has";
      assertion = isList list;
      message = "expected a list to search within, got ${typeOf list}";
      context = "evaluating lists.has";
    };
      elem item list;

  hasAny' = candidates: list:
    assert assertWithContext {
      name = "lists.hasAny";
      assertion = isList list;
      message = "expected a target list to search within, got ${typeOf list}";
      context = "evaluating lists.hasAny";
    };
      any (candidate: elem candidate list) (asList candidates);

  # --- Existing Methods ---

  orNull = value:
    assert assertWithContext {
      name = "lists.orNull";
      assertion = isEmpty value || isList value;
      message = "expected a list, got ${typeOf value}";
      context = "evaluating lists.orNull";
    };
      if isEmpty value || !(isList value)
      then null
      else value;

  orDefault = default: value:
    assert assertWithContext {
      name = "lists.orDefault";
      assertion = isList default && isList value;
      message = "expected lists, got default=${typeOf default} value=${typeOf value}";
      context = "evaluating lists.orDefault";
    };
      if isNotEmpty' value
      then value
      else default;

  orEmpty = value:
    assert assertWithContext {
      name = "lists.orEmpty";
      assertion = value == null || isList value;
      message = "expected a list or null, got ${typeOf value}";
      context = "evaluating lists.orEmpty";
    };
      optionals (isNotEmpty' value) value;

  asList = val: optionals (val != null) (toList val);

  nthOr = input: let
    fromArgs = {
      position,
      value,
      default ? null,
    }:
      if isList value
      then
        if length value > position
        then elemAt value position
        else default
      else if position == 0
      then value
      else default;
  in
    if isAttrs input
    then fromArgs input
    else
      position:
        fromArgs {
          value = input;
          inherit position;
        };
in
  exports
