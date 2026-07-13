{
  api,
  attrsets,
  lists,
  ...
}: let
  exports = {
    scoped = {inherit registry inferredOf selectionOf selectedModules;};
    global = {
      interfaceRegistry = registry;
      interfaceSelection = selectionOf;
      interfaceInferred = inferredOf;
      interfaceNames = namesOf;
      interfaceModules = selectedModules;
    };
  };

  inherit (attrsets) as filterAttrs valuesOf;
  inherit (lists) concatMap elem filter unique;

  registry = api.interface;

  rawOf = spec: let
    interface = spec.interface or {};
  in
    interface.backends
    or (
      unique (
        filter (x: x != null && x != "") (
          (interface.backend.managers or [])
          ++ (interface.backend.desktops or [])
          ++ [
            (interface.windowManager or null)
            (interface.desktopEnvironment or null)
          ]
        )
      )
    );

  selectionOf = spec: spec.applications or {};
  inferredOf = spec: as (rawOf spec);
  normalizeName = name: registry.${name} or name;

  namesOf = spec:
    unique (
      map
      normalizeName
      (concatMap valuesOf (valuesOf (selectionOf spec)))
    );

  selectedModules = spec: let
    names = namesOf spec;
  in
    filterAttrs (name: _: elem name names) registry;
in
  exports
