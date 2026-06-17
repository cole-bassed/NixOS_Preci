_: let
  exports = {
    scoped = {inherit fix;};
    global = {
      mkFixedPoint = fix;
      recursiveSelf = fix;
    };
  };

  fix = fn: let self = fn self; in self;
in
  exports
