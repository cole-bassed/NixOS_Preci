{
  api,
  assembly,
  attrsets,
  lists,
  paths,
  types,
  ...
}: let
  mod = "interface";
  defaults = {
    host = api.hosts.default;
    user = defaults.host.users.primary.value or {};
    api = api.${mod};
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
      "${mod}Registry" = registry;
      "mk${mod}Registry" = mkRegistry;
      "mk${mod}Selection" = selectionOf;
      "mk${mod}Inferred" = inferredOf;
      "mk${mod}Environment" = mkEnvironments;
      "mk${mod}Modules" = selectedModules;
      "${mod}Primary" = primaryOf;
      "${mod}Secondary" = secondaryOf;
      "${mod}Tertiary" = tertiaryOf;
    };
  };

  inherit
    (attrsets)
    asAttrs
    asAttrsIf
    filterAttrs
    mapAttrs
    parseOrderedAttrs
    recursiveUpdate
    valuesOf
    ;
  inherit (lists) asList concatMap elem filter foldl' unique;
  inherit (types) isAttrs isString;

  shared = import (paths.store.api + "/${mod}");
  common = shared.common or {};

  # Each registry entry is fully resolved here -- bindings/variables/app
  # bindings compiled via assembly.mkRegistry -- so there is exactly one
  # resolved registry, not a library-layer unresolved copy plus a
  # NixOS-layer resolved copy.
  mkRegistry = {api ? defaults.api}:
    mapAttrs (
      _: env: let
        protocol = recursiveUpdate common (
          shared.${env.protocol or "common"} or {}
        );
        applications = let
          ofProtocol = protocol.applications or {};
          ofEnvironment = env.applications or {};
        in
          ofProtocol
          // mapAttrs (category: list:
            list ++ (ofProtocol.${category} or []))
          ofEnvironment;
        merged = (recursiveUpdate protocol env) // {inherit applications;};
      in
        merged // (assembly.mkRegistry merged)
    ) (removeAttrs api ["default"]);
  registry = mkRegistry {};

  selectionOf = spec: spec.applications or {};
  normalizeName = name: registry.${name} or name;

  mkEnvironmentsRaw = spec: let
    api = spec.${mod} or {};
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
