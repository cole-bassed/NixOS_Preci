{
  api,
  lix,
  top,
  ...
} @ args: let
  inherit (lix.ingestion) mkModules;
  inherit (lix.registry) selectionOf;
  backendRegistry = api.interface.registry or api.interface or {};
  selection = spec:
    selectionOf {
      inherit top spec;
      registry = backendRegistry;
    };
in
  mkModules (
    args
    // {
      base = ./.;
      path = args.path or ["interface"];
      recurse = true;
      declareRegistry = true;
      extraArgs = {inherit backendRegistry selection;};
    }
  )
