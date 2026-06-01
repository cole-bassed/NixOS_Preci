{lix}: let
  exports = let
    internal = {
      inherit asList nthOr orNull orDefault orEmpty;

      isEmpty = isEmpty';
      isNotEmpty = isNotEmpty';
      atOr = nthOr;
    };
    external = {
      isEmptyList = isEmpty';
      isNotEmptyList = isNotEmpty';
      orDefaultList = orDefault;
      orNullList = orNull;
      toList' = asList;
      valueInList = nthOr;
    };
  in {inherit internal external;};

  inherit (lix.attrsets) isAttrs;
  inherit (lix.debug) assertWithContext;
  inherit (lix.lists) elemAt isList length optionals toList;
  inherit (lix.types) typeOf isEmpty;

  isEmpty' = value: value == [];
  isNotEmpty' = value: !isEmpty' value;

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
