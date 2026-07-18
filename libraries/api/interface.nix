{
  api,
  assembly,
  attrsets,
  lists,
  types,
  ...
}: let
  name = "interface";

  exports = {
    scoped = {
      inherit
        inferredOf
        mkEnvironments
        mkRegistry
        primaryOf
        registry
        secondaryOf
        selectedModules
        selectionOf
        tertiaryOf
        ;
    };
    global = {
      "${name}Primary" = primaryOf;
      "${name}Registry" = registry;
      "${name}Secondary" = secondaryOf;
      "${name}Tertiary" = tertiaryOf;
      "mk${name}Environment" = mkEnvironments;
      "mk${name}Inferred" = inferredOf;
      "mk${name}Modules" = selectedModules;
      "mk${name}Registry" = mkRegistry;
      "mk${name}Selection" = selectionOf;
    };
  };

  inherit (assembly) mkApi normalizeFieldName;
  inherit
    (attrsets)
    asAttrs
    asAttrsIf
    filterAttrs
    parseOrderedAttrs
    valuesOf
    ;
  inherit (lists) asList concatMap elem filter foldl' unique;
  inherit (types) isAttrs isString;

  applicationsRegistry = mkApi {
    api = api.applications;
    name = "applications";
  };

  registry =
    filterAttrs
    (_: entry: elem "backend" (entry.category or []))
    applicationsRegistry;

  mkRegistry = {
    api ? api.applications,
    extra ? null,
    overrides ? null,
  }:
    filterAttrs
    (_: entry: elem "backend" (entry.category or []))
    (mkApi {
      inherit api extra overrides;
      name = "applications";
    });

  selectionOf = spec: spec.applications or {};
  normalizeName = name: (normalizeFieldName {inherit registry name;});

  mkEnvironmentsRaw = spec: let
    api = spec.${name} or {};
  in
    asList (
      api.environment or (
        api.environments or (
          api.backend or (api.backends or [])
        )
      )
    );

  mkEnvironments = spec:
    unique (
      map
      normalizeName
      (concatMap valuesOf (valuesOf (selectionOf spec)))
    );
  inferredOf = spec: asAttrs (mkEnvironmentsRaw spec);

  selectedModules = spec: let
    names = mkEnvironments spec;
  in
    filterAttrs (name: _: elem name names) registry;

  entryName = entry:
    if isString entry
    then entry
    else entry.name or (entry.session or null);

  entryEnabled = entry:
    isString entry || (entry.enable or true);

  entryOverride = entry:
    asAttrsIf (isAttrs entry) (
      removeAttrs entry ["name" "session" "enable"]
    );

  resolveTiers = {
    user ? {},
    host ? {},
  }: let
    rawOf = spec:
      if spec == null
      then []
      else mkEnvironmentsRaw spec;

    combined = (rawOf user) ++ (rawOf host);

    valid =
      filter
      (entry:
        entryEnabled entry
        && entryName entry != null
        && registry ? ${entryName entry})
      combined;

    deduped =
      (foldl'
        (acc: entry: let
          name = entryName entry;
        in
          if elem name acc.seen
          then acc
          else {
            seen = acc.seen ++ [name];
            entries = acc.entries ++ [entry];
          })
        {
          seen = [];
          entries = [];
        }
        valid)
      .entries;

    resolved =
      map
      (entry: let
        name = entryName entry;
      in
        registry.${name}
        // (entryOverride entry)
        // {inherit name;})
      deduped;
  in
    parseOrderedAttrs resolved;

  primaryOf = args: (resolveTiers args).primary or null;
  secondaryOf = args: (resolveTiers args).secondary or null;
  tertiaryOf = args: (resolveTiers args).tertiary or null;
in
  exports
