{
  api,
  attrsets,
  lists,
  ...
}: let
  inherit (attrsets) filterAttrs;
  inherit (builtins) removeAttrs;
  inherit (lists) concatMap unique;

  registry = removeAttrs (api.applications.modules or {}) ["name" "tags"];
  categories = removeAttrs (api.applications.categories or {}) ["name" "tags"];
  aliases = removeAttrs (api.applications.aliases or {}) ["name" "tags"];

  selectionOf = spec: spec.applications or {};

  valuesOf = value:
    if builtins.isList value
    then value
    else if builtins.isAttrs value
    then builtins.attrValues value
    else if builtins.isString value
    then [value]
    else [];

  normalizeName = name: aliases.${name} or name;

  namesOf = spec:
    unique (map normalizeName (
      concatMap valuesOf (builtins.attrValues (selectionOf spec))
    ));

  selectedModules = spec: let
    names = namesOf spec;
  in
    filterAttrs (name: _: builtins.elem name names) registry;

  exports = {
    scoped = {
      inherit registry categories aliases selectionOf namesOf selectedModules;
    };

    global = {
      applicationAPI = registry;
      applicationCategories = categories;
      applicationAliases = aliases;
      inherit selectionOf namesOf selectedModules;
    };
  };
in
  exports
