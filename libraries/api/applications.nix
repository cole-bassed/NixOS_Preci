{
  api,
  attrsets,
  lists,
  ...
}: let
  exports = {
    scoped = {
      inherit
        aliases
        categories
        namesOf
        registry
        selectedModules
        selectionOf
        ;
    };

    global = {
      applicationRegistry = registry;
      applicationCategories = categories;
      applicationAliases = aliases;
      applicationSelection = selectionOf;
      applicationNames = namesOf;
      applicationModules = selectedModules;
    };
  };

  inherit (attrsets) valuesOf filterAttrs;
  inherit (lists) concatMap elem unique;

  registry = removeAttrs (api.applications.modules or {}) ["name" "tags"];
  categories = removeAttrs (api.applications.categories or {}) ["name" "tags"];
  aliases = removeAttrs (api.applications.aliases or {}) ["name" "tags"];

  selectionOf = spec: spec.applications or {};
  normalizeName = name: aliases.${name} or name;

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
