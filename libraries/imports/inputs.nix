{bootstrap, ...}: let
  exports = {
    scoped = {
      inherit (bootstrap.inputs) classified normalized;
      enable = isFlake;
    };
    # global = {flakes = {inherit (bootstrap) inputs;};};
  };
  inherit (bootstrap) inputs;
  isFlake = bootstrap.isFlakeLike inputs;
in
  exports
