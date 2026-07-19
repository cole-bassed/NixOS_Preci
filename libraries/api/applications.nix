{
  api,
  assembly,
  attrsets,
  lists,
  ...
}: let
  name = "applications";
  defaults = {
    api = api.${name};
  };

  exports = {
    scoped = {
      inherit
        aliases
        categories
        namesOf
        registry
        selectedModules
        selectionOf
        supportedOf
        ;
    };

    global = {
      applicationRegistry = registry;
      applicationCategories = categories;
      applicationAliases = aliases;
      applicationSelection = selectionOf;
      applicationNames = namesOf;
      applicationModules = selectedModules;
      applicationSupported = supportedOf;
    };
  };

  inherit (assembly) mkApi normalizeFieldName;
  inherit (attrsets) attrNames filterAttrs listToAttrs valuesOf;
  inherit (lists) asList concatMap elem foldl' unique;

  mkRegistry = {
    raw ? null,
    extra ? null,
    overrides ? null,
  }:
    mkApi {inherit raw name extra overrides;};
  registry = mkRegistry {};

  entryCategories = entry: asList (entry.category or []);
  entryAliases = entry: asList (entry.alias or (entry.aliases or []));

  categories = let
    pairs =
      concatMap
      (name: map (cat: {inherit cat name;}) (entryCategories registry.${name}))
      (attrNames registry);
  in
    foldl'
    (acc: p: acc // {${p.cat} = (acc.${p.cat} or []) ++ [p.name];})
    {}
    pairs;

  aliases = let
    pairs =
      concatMap
      (name:
        map (a: {
          inherit name;
          alias = a;
        }) (entryAliases registry.${name}))
      (attrNames registry);
  in
    listToAttrs (map (p: {
        name = p.alias;
        value = p.name;
      })
      pairs);

  selectionOf = spec: spec.applications or {};
  normalizeName = name: (normalizeFieldName {inherit registry name;});

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

  supportedOf = name:
    map normalizeName (asList (registry.${name}.supported or []));
in
  exports
