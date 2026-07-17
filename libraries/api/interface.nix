{
  api,
  assembly,
  attrsets,
  lists,
  # paths,
  types,
  ...
}: let
  name = "interface";
  defaults = {
    host = api.hosts.default;
    user = defaults.host.users.primary.value or {};
    api = api.${name};
  };
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

  mkRegistry = {
    api ? defaults.api,
    extra ? null,
    overrides ? null,
  }:
    mkApi {inherit api name extra overrides;};
  registry = mkRegistry {};

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

  # Ordered, filtered, resolved list of active environments: entries
  # without a resolvable name are dropped, entries with `enable = false`
  # are dropped, user's own ordering is ranked above host's, duplicate
  # names (by whichever source ranked first) are collapsed. Each returned
  # entry is the fully-resolved registry entry with that source's
  # overrides applied on top.
  resolveTiers = {
    user ? defaults.user,
    host ? defaults.host,
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
