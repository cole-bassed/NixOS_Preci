{
  api,
  assembly,
  defaults,
  attrsets,
  ingestion,
  lists,
  modules,
  options,
  strings,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit mkModules mkModuleArgs mkCfg mkCfgIf mkOpt mkIf';
      ingest = mkModules;
      configure = mkModuleArgs;
    };
    global = {inherit mkModules mkModuleArgs mkCfgIf mkIf';};
  };

  inherit
    (attrsets)
    asAttrs
    foldMerge
    genAttrs
    hasAttr
    namesOf
    mapAttrs
    mkNamespaced
    optionalAttrs
    recursiveUpdate
    setAttrByPath
    valuesOf
    attrByPath
    isNotEmptyAttr
    ;
  inherit (ingestion) collectSpecs;
  inherit (lists) asList asListIf elem head init last optionals;
  inherit (types) attrs;
  inherit (assembly) mkBindings mkRegistryVariables;
  inherit (modules) mkIf mkMerge;
  inherit (options) mkEnable mkOption;
  inherit (strings) concatStringsSep toSentenceCase;
  inherit (types) isList;

  mkModules = args @ {
    base,
    data ? (
      let
        domain =
          if path != []
          then (last path)
          else null;
      in
        args.extraArgs.registry or (
          optionalAttrs
          (domain != null && api ? ${domain}.registry)
          api.${domain}.registry
        )
    ),
    excludes ? null,
    extraArgs ? {},
    includeFiles ? true,
    includes ? [],
    path ? [],
    childPath ? path,
    recurse ? true,
    tags ? defaults.tags,
    top,
    declareRegistry ? isNotEmptyAttr data,
    ...
  }: let
    hasData = isNotEmptyAttr data && declareRegistry;

    specs = collectSpecs {
      inherit args base excludes includes tags includeFiles recurse;
      path = childPath;
      extraArgs =
        recursiveUpdate (args.extraArgs or {}) extraArgs
        // optionalAttrs hasData {registry = data;};
    };

    registryModule = {
      options = setAttrByPath ([top] ++ path ++ ["registry"]) (mkOption {
        type = attrs;
        default =
          mapAttrs
          (
            _: entry: let
              hasVars = entry ? variables;
              hasApps = entry ? applications;
              hasBinds = entry ? bindings;
              updates =
                optionalAttrs hasBinds {
                  bindings =
                    (mkBindings {
                      inherit (entry) bindings;
                      applications = entry.applications or {};
                    }).options;
                }
                // optionalAttrs hasApps {inherit (entry) applications;}
                // optionalAttrs hasVars {variables = mkRegistryVariables entry;};
            in
              entry // updates
          )
          data;
        readOnly = true;
      });
    };
    registryModules = asListIf hasData [registryModule];
  in {
    imports = (specs.core or []) ++ registryModules;
    home-manager.sharedModules = (specs.home or []) ++ registryModules;
  };

  mkModuleArgs = {
    api ? lib.api or (lix.api or {}),
    config ? {},
    host ? {},
    hostPath ? path,
    extraArgs ? {},
    lib ? {},
    lix ? {},
    options ? {},
    osConfig ? {},
    path,
    pkgs ? {},
    scope ? "core",
    selection ? null,
    top ? null,
    userPath ? path,
    users ? api.users.getInteractiveUsers host,
  }: let
    targets = ["main" "custom" "domain" "parent" "module"];
    # selection = spec: selectionOf {inherit top spec registry;};

    validate = {
      path = target:
        if elem target targets
        then paths.${target}
        else
          throw "Invalid target: '${target}'. Valid targets are: ${
            concatStringsSep ", " targets
          }";
    };

    names =
      genAttrs targets (
        target: let
          check = validate.path target;
        in
          if check != []
          then last check
          else "main"
      )
      // {
        user =
          get.config.main.home.username or (
            get.config.custom.users.primary.name or null
          );
        package = pkg.name or null;
      };

    # pkgName may be a flat string ("gitFull") or a nested path
    # (["llm-agents" "claude-code"]) — normalize to a list either way.
    pkg = let
      name' = get.apiOr "package";
      path' =
        if name' != null
        then asList name'
        else [get.name];
    in {
      path = path';
      name = last path';
      spec = attrByPath path' null pkgs;
    };

    base =
      if top != null
      then top
      else names.custom;

    paths = {
      validate = validate.path;
      main = [];
      custom = [base];
      module = paths.custom ++ path;
      parent = init paths.module;
      domain = paths.custom ++ [(head path)];
    };

    get = {
      inherit host scope names paths users;
      name = names.module;
      prettyName = set.name {pretty = true;};

      user = let
        name = names.user;
      in
        optionalAttrs
        (name != null)
        ((users.${name} or {}) // {inherit name;});

      top =
        if top != null
        then top
        else names.custom;

      config =
        genAttrs targets
        (target: set.config {inherit target;});
      cfg = get.config.module;
      cfgOr = key: let
        fromConfig = attrByPath (paths.module ++ [key]) null config;
      in
        if fromConfig != null
        then fromConfig
        else
          attrByPath
          (paths.module ++ [key]) (extraArgs.${key} or null)
          osConfig;

      options =
        genAttrs targets
        (target: attrByPath (paths.validate target) {} options);

      enabled = {
        criteria ? elem (host.type or "laptop") ["desktop" "laptop"],
        selectFrom ? set.selection,
      }: let
        materialize = selected:
          mapAttrs
          (_: extra: {enable = true;} // extra)
          (foldMerge selected);

        required = let
          byHost = [(selectFrom host)];
          byUser =
            optionals
            criteria
            (map selectFrom (valuesOf users));
        in {
          core = materialize (byHost ++ byUser);
          home =
            materialize
            (byHost ++ (optionals criteria [(selectFrom get.user)]));
        };
      in
        hasAttr get.name required.${scope};

      package = pkg.spec;
      pkgName = pkg.name;
      pkgPath = pkg.path;

      hostEntry = attrByPath hostPath {} host;
      userEntry = attrByPath userPath {} get.user;
      dataEntry = genAttrs targets (
        target: let
          #TODO This is not making use of our target and genAttrs style setup
          domain = head path;
          name = last path;
          registry =
            if target == "module"
            then api.${domain}.registry.${name} or {}
            else if target == "domain"
            then api.${domain}.registry or {}
            else if target == "custom"
            then api.custom.registry or {}
            else if target == "main"
            then api.main.registry or {}
            else {};
        in {
          inherit registry;
          names = namesOf registry;
          values = valuesOf registry;
          select = asAttrs; # TODO: This is not working at all
        }
      );
      apiOr = key:
        get.hostEntry.${key} or
            (get.userEntry.${key} or
              (get.dataEntry.module.registry.${key} or
                (get.dataEntry.parent.registry.${key} or
                  (get.dataEntry.domain.registry.${key} or
                    (get.dataEntry.custom.registry.${key} or
                      (get.dataEntry.main.registry.${key} or null))))));
    };

    set = {
      config = {
        target ? "module",
        extra ? {},
      }: let
        targetPath = paths.validate target;
      in
        attrByPath targetPath {} (
          recursiveUpdate config
          (setAttrByPath targetPath extra)
        );

      options =
        genAttrs
        targets (target: extra: setAttrByPath (paths.validate target) extra);
      opt = set.options.module;

      name = {
        name ? names.module,
        pretty ? true,
      }:
        if pretty
        then toSentenceCase name
        else name;
      enable = {default ? false}:
        mkEnable {
          inherit (get) scope name;
          inherit default;
        };
      package = mkOption {
        type = with types; nullOr package;
        default = get.package;
        description = "Package backing the ${get.prettyName} compositor component.";
      };

      selection = spec:
        if selection != null
        then selection spec
        else asAttrs spec;

      bin = {
        module ? names.module,
        package ? get.package,
      }: let
        name =
          if package != null
          then package.NIX_MAIN_PROGRAM or module
          else null;
        path =
          if package != null
          then "/run/current-system/sw/bin/${module}"
          else null;
      in {inherit package name path;};
    };
  in
    (mkNamespaced {inherit get set;})
    // get
    // {inherit get set;};

  mkCfg = {
    config,
    path,
  }:
    attrByPath (asList path) {} config;

  mkOpt = {
    options,
    path,
  }:
    setAttrByPath (asList path) options;

  mkCfgIf = {
    cfg,
    condition ? cfg.enable or false,
  }: args:
    mkIf condition (
      if isList args
      then mkMerge args
      else args
    );

  mkIf' = cfg: condition: args:
    mkCfgIf {inherit cfg condition;} args;
in
  exports
