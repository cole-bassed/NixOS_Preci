args: let
  collections = args.collections or (import ./collections.nix args).scoped;
  registry = collections.interface;
in {
  scoped = {
    inherit registry;
  };

  global = {
    interfaceAPI = registry;
  };
}
