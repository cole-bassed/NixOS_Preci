{
  attrsets,
  lists,
  types,
  ...
}: let
  exports = {
    scoped = {};
    global = {
      inherit
        mkRegistry
        mkRegistryVariables
        mkAppVariables
        mkAppBindings
        mkBindings
        ;
    };
  };

  inherit
    (attrsets)
    coalesce
    mapParsedOrdered
    extractArgs
    mapAttrs
    optionalAttrs
    namesOf
    mkNamespaced
    valuesOf
    ;
  inherit
    (lists)
    asList
    asListIf
    concatMap
    flatten
    filter
    init
    last
    ;
  inherit (types) isAttrs isBool isList isString;

  mkRegistry = registry:
    optionalAttrs (registry ? variables || registry ? applications)
    {variables = mkRegistryVariables registry;}
    // optionalAttrs (registry ? bindings)
    {
      bindings =
        (mkBindings {
          inherit (registry) bindings;
          applications = registry.applications or {};
        }).options;
    }
    // optionalAttrs (registry ? applications)
    {applications = mkAppBindings {inherit (registry) applications;};};

  mkRegistryVariables = registry: let
    commands = let
      sets =
        mapAttrs
        (_: apps: map (app: app.command) apps)
        (registry.applications or {});
    in
      optionalAttrs (sets != {}) (mkAppVariables {inherit sets;});

    bindings = optionalAttrs (registry ? bindings.modifier) {
      MOD = registry.bindings.modifier;
    };
  in
    bindings // commands // (registry.variables or {});

  mkAppVariables = payload: let
    args = extractArgs {
      args = payload;
      required = ["sets"];
      defaults = {transformation = "POSIX";};
    };
  in
    mkNamespaced {
      inherit (args) transformation;
      sets =
        mapAttrs
        (
          _: commands: let
            secondary = coalesce commands.secondary commands.primary;
            tertiary = coalesce commands.tertiary secondary;
          in {
            "" = commands.primary;
            inherit secondary tertiary;
          }
        )
        (mapParsedOrdered args.sets);
    };

  mkAppBindings = {
    applications,
    modifier ? "SUPER",
  }: let
    format = name: value:
      asList modifier
      ++ (asListIf (name == "launch") ["ALT"])
      ++ asList value;

    resolve = app:
      if app ? bindings && isAttrs app.bindings
      then app // {bindings = mapAttrs format app.bindings;}
      else app;
  in
    mapAttrs
    (
      _: value:
        if isList value
        then map resolve value
        else value
    )
    applications;

  mkBindings = {
    bindings,
    applications ? {},
    modifier ? bindings.modifier or "SUPER",
  }: let
    mod = asList modifier;

    assemble = name: key:
      if name == "modifier"
      then mod
      else if isBool key
      then key
      else if isString key
      then {inherit key mod;}
      else if isList key
      then {
        mod = mod ++ init key;
        key = last key;
      }
      else null;

    resolve = entry:
      if isBool entry || isList entry
      then entry
      else entry.mod ++ [entry.key];

    registry = mapAttrs assemble bindings;

    apps =
      map (app: {
        key = app.bindings.launch;
        mod = mod ++ ["SHIFT" "ALT"];
        action = app.command;
      })
      (
        filter
        (app: app ? bindings.launch && app.bindings.launch != null)
        (flatten (valuesOf applications))
      );

    groups = let
      validated =
        filter
        (name: applications ? ${name} && isString bindings.${name})
        (namesOf bindings);

      tiers = name: let
        apps = mkAppVariables {sets = applications;};
        mk = extraMod: field: {
          key = registry.${name}.key;
          mod = registry.${name}.mod ++ extraMod;
          action = apps.${name}.${field}.command;
        };
      in [
        (mk [] "")
        (mk ["SHIFT"] "secondary")
        (mk ["ALT"] "tertiary")
      ];
    in
      concatMap tiers validated;
  in {
    options = mapAttrs (_: resolve) registry;
    entries = apps ++ groups;
  };
in
  exports
