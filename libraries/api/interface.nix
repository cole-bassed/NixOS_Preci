{...} @ args: let
  registry = (import ./collections.nix args).scoped.interface;
in {
  scoped = {
    inherit registry;
  };

  global = {
    interfaceAPI = registry;
  };
}
