{
  api,
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
        defaultSession
        inferredOf
        mkDefaultSession
        mkEnvironments
        mkRegistry
        mkSessions
        registry
        selectedModules
        selectionOf
        sessions
        ;
    };
    global = {
      "${mod}Registry" = registry;
      "${mod}Sessions" = sessions;
      "${mod}DefaultSession" = defaultSession;
      "mk${mod}Registry" = mkRegistry;
      "mk${mod}Selection" = selectionOf;
      "mk${mod}Inferred" = inferredOf;
      "mk${mod}Environment" = mkEnvironments;
      "mk${mod}Modules" = selectedModules;
      "mk${mod}Session" = mkDefaultSession;
      "mk${mod}Sessions" = mkSessions;
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
      in
        (recursiveUpdate protocol env) // {inherit applications;}
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

  mkSessions = {
    user ? defaults.user,
    host ? defaults.host,
  }: let
    rawOf = spec:
      if spec == null
      then []
      else mkEnvironmentsRaw spec;

    #? user's raw list first (in order), host's appended (in order) --
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
    resolved;
  sessions = mkSessions {};

  mkDefaultSession = {
    user ? defaults.user,
    host ? defaults.host,
  }: let
    resolved = mkSessions {inherit user host;};
  in
    if resolved == []
    then null
    else (parseOrderedAttrs resolved).primary or null;
  defaultSession = mkDefaultSession {};
in
  exports
