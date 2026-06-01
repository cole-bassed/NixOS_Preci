{lib}: let
  exports = let
    functions = {inherit asList nthOr orNull orDefault;};
    aliases = {
      orNullList = orNull;
      orDefaultList = orDefault;
      valueInList = nthOr;
      toList' = asList;
    };
    internal =
      functions
      // aliases
      // {
        atOr = nthOr;
      };
    external = aliases;
  in {inherit functions aliases internal external;};

  inherit (lib.lists) elemAt isList length optionals toList;
  inherit (lib.attrsets) isAttrs;

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
