{types, ...}: let
  exports = {
    scoped = {
      from = {};
      to = {
        float = toFloat;
      };
    };

    global = {
      inherit toFloat;
    };
  };

  inherit (types) coercedTo fromJSON isFloat isInt str float int;

  toFloat = let
    fromInt = i: i * 1.0;
    fromStr = s: let
      parsed = fromJSON s;
    in
      if isFloat parsed || isInt parsed
      then parsed * 1.0
      else throw "toFloat: cannot convert string '${s}' to a number";
  in
    coercedTo int fromInt (coercedTo str fromStr float);
in
  exports
