_: let
  exports = {
    scoped = {};
    global = {inherit readDir readFile readFileType;};
  };

  inherit (builtins) readDir readFile readFileType;
in
  exports
