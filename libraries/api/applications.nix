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

  selectionOf = spec: spec.applications or {};

  valuesOf = value:
    if builtins.isList value
    then value
    else if builtins.isString value
    then [value]
    else [];

  namesOf = spec:
    unique (
      concatMap valuesOf (builtins.attrValues (selectionOf spec))
    );

  selectedModules = spec:
    let names = namesOf spec;
    in filterAttrs (name: _: builtins.elem name names) registry;

  exports = {
    scoped = {
      inherit registry categories selectionOf namesOf selectedModules;
    };

    global = {
      applicationAPI = registry;
      applicationCategories = categories;
      inherit selectionOf namesOf selectedModules;
    };
  };
in
  exports
