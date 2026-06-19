{bootstrap, ...}: let
  exports = {
    scoped = {inherit (bootstrap.inputs) classified normalized;};
    global = {flakes = {inherit (bootstrap) inputs;};};
  };
in
  exports
