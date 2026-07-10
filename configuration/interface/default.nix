{
  api,
  lix,
  top,
  ...
} @ args: let
  inherit (lix.ingestion) mkModules;
  inherit (lix.registry) selectionOf;
  registry = api.interface or {};
  selection = spec: selectionOf {inherit top registry spec;};
in
  mkModules (
    args
    // {
      base = ./.;
      path = args.path or ["interface"];
      recurse = true;
      declareRegistry = true;
      extraArgs = {inherit registry selection;};
    }
  )
