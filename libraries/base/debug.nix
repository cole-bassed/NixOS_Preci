let
  exports = {
    scoped = {
      inherit ((import ./attrsets.nix).global) inspectAttrs;
    };

    global = {
    };
  };
in
  exports
