{
  api,
  lix,
  top,
  ...
} @ args: let
  inherit (lix.api.applications) categories namesOf selectionOf;
  inherit (lix.ingestion) mkModules;

  registry = api.applications.modules or {};
  selection = selectionOf;
  selected = namesOf;
  catalog = categories;
in
  mkModules (
    args
    // {
      base = ./.;
      path = args.path or ["applications"];
      recurse = true;
      declareRegistry = true;
      extraArgs = {
        inherit registry selection selected catalog top;
      };
    }
  )
