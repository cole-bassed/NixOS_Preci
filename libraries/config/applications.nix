{
  attrsets,
  lists,
  types,
  ...
}: let
  exports = {
    scoped = {inherit resolveApps resolveBinds;};
    global = {};
  };

  inherit
    (attrsets)
    coalesce
    extractArgs
    mapParsedOrdered
    mapAttrs
    mkNamespaced
    namesOf
    valuesOf
    ;
  inherit (lists) concatMap filter flatten;
  inherit (types) isString;

  resolveApps = payload: let
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

  resolveBinds = {
    applications,
    bindings,
    modifier ? bindings.modifier or "SUPER",
  }: let
    resolved = {
      #> Resolve tier-based category bindings (e.g., browser -> B)
      categories = let
        #> Only process keys in `bindings` that actually exist as categories in `applications`
        validCategories =
          filter
          (
            name:
              applications ? ${name}
              && isString bindings.${name}
          )
          (namesOf bindings);

        mkTiers = name: let
          key = bindings.${name};
          tiers = (resolveApps {sets = applications;}).${name};
        in [
          {
            inherit key;
            mod = [modifier];
            action = tiers."".command;
          }
          {
            inherit key;
            mod = [modifier "SHIFT"];
            action = tiers.secondary.command;
          }
          {
            inherit key;
            mod = [modifier "ALT"];
            action = tiers.tertiary.command;
          }
        ];
      in
        concatMap mkTiers validCategories;

      #> Resolve specific app bindings (e.g., launch = "Z" for Zed)
      applications = let
        #> Flatten all category lists into one giant list of apps
        allApps = flatten (valuesOf applications);

        #> Filter down to only the apps that actually define a launch binding
        appsWithBinds = filter (app: app ? bindings.launch && app.bindings.launch != null) allApps;
      in
        map (app: {
          key = app.bindings.launch;
          mod = [modifier "SHIFT" "ALT"];
          action = app.command;
        })
        appsWithBinds;
    };
  in
    resolved.categories ++ resolved.applications;
in
  exports
