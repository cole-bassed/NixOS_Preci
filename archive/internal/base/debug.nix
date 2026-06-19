{
  attrsets,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit inspect;
      inherit (builtins) abort throw;
      verbose = builtins.traceVerbose;
      try = builtins.tryEval;
      inherit (builtins) seq;
      inherit (builtins) deepSeq;
    };

    global = {
      inspectAttrs = inspect;
      inherit
        (builtins)
        abort
        addErrorContext
        break
        deepSeq
        getEnv
        seq
        throw
        trace
        traceVerbose
        tryEval
        warn
        ;
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
