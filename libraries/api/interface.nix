{
  api,
  assembly,
  attrsets,
  lists,
  types,
  ...
}: let
  _names = {
    mod = "interface";
    app = "applications";
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
      "${_names.mod}Primary" = primaryOf;
      "${_names.mod}Registry" = registry;
      "${_names.mod}Secondary" = secondaryOf;
      "${_names.mod}Tertiary" = tertiaryOf;
      "mk${_names.mod}Environment" = mkEnvironments;
      "mk${_names.mod}Inferred" = inferredOf;
      "mk${_names.mod}Modules" = selectedModules;
      "mk${_names.mod}Registry" = mkRegistry;
      "mk${_names.mod}Selection" = selectionOf;
    };
  };

  inherit (assembly) mkApi mkRegistrySlice normalizeFieldName;
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

  # ╔════════════════════════════════════════════════╗
  # ╠ REGISTRY                                       ╣
  # ╚════════════════════════════════════════════════╝
  applications = mkApi {name = "applications";};
  backends = mkRegistrySlice {
    registry = applications;
    category = "backend";
  }; # TODO: This is now essentially interface.nix's registry
  registry = applications; # TODO: Shouldn't interface have it's own registry though?

  # Optional: convenience function for other slices
  mkRegistry = {
    category ? null,
    raw ? null,
    extra ? {},
    overrides ? {},
  }:
    mkApi {
      name = _names.app;
      inherit raw category extra overrides;
    };

  selectionOf = spec: spec.applications or {};
  normalizeName = name:
    normalizeFieldName {
      inherit name;
      registry = applications;
    };

  mkEnvironmentsRaw = spec: let
    api = spec.${_names.mod} or {};
  in
    asList (
      api.environment or (api.environments or (api.backend or (api.backends or [])))
    );

  mkEnvironments = spec:
    unique (map normalizeName (concatMap valuesOf (valuesOf (selectionOf spec))));

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
      (
        foldl'
        (acc: entry: let
          name = entryName entry;
        in
          if elem name acc.seen
          then acc
          else {
            seen = acc.seen ++ (asList name);
            entries = acc.entries ++ (asList entry);
          })
        {
          seen = [];
          entries = [];
        }
        valid
      )
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
