_: let
  exports = {
    scoped = {};
    global = {
      inherit
        (builtins)
        add
        sub
        mul
        div
        bitAnd
        bitOr
        bitXor
        ceil
        floor
        lessThan
        compareVersions
        parseDrvName
        splitVersion
        ;
    };
  };
in
  exports
