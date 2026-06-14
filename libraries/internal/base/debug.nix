{
  attrsets,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit inspect;
    };

    global = {
      inspectAttrs = inspect;
    };
  };

  inherit (attrsets) maps;
  inherit (types) isFunction isPath isList isAttrs;

  inspect = level: let
    fn = depth: value:
      if depth <= 0
      then "..."
      else if isFunction value
      then "<function>"
      else if isPath value
      then "<path>"
      else if isList value
      then map (fn (depth - 1)) value
      else if isAttrs value
      then maps (_: fn (depth - 1)) value
      else value;
  in
    fn level;
in
  exports
