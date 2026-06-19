{bootstrap, ...}: let
  exports = {
    scoped =
      {
        inherit
          (inputs)
          raw
          classified
          normalized
          ;
        enable = types.isFlakeLike inputs;
      }
      // types;
    global = types;
  };
  inherit (bootstrap) inputs;
  types = {inherit (bootstrap) isFlakeLike isHomeManagerLike isNixDarwinLike isNixpkgsInfrastructure isNixpkgsLike isTreefmtLike;};
in
  exports
