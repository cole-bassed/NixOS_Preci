{
  api,
  lix,
  top,
  ...
} @ args: let
  inherit (lix.api.applications) categories namesOf selectionOf;
  inherit (lix.ingestion) mkModules;
in
  mkModules (
    args
    // {
      base = ./.;
      # path = args.path or ["applications"];
      recurse = true;
      declareRegistry = true;
      extraArgs = {
        inherit top;
        registry = api.applications.modules or {};
        selection = selectionOf;
        selected = namesOf;
        catalog = categories;
      };
    }
  )
