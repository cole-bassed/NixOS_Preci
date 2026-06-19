{bootstrap, ...}: let
  exports = {
    scoped = {inherit (bootstrap.inputs) classified normalized excluded;};
    global = {flakes = {inherit (bootstrap) inputs;};};
  };
in
  exports
