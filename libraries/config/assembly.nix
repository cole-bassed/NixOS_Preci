{
  api,
  attrsets,
  debug,
  environment,
  filesystem,
  flake,
  lists,
  names,
  paths,
  strings,
  systems,
  types,
  ...
}: let
  exports = {
    scoped = {inherit mkConfiguration mkConfiguration' mkFlake mkFlake' mkFlakeModules mkPaths mkSrc;};
    global = {inherit mkFlake mkFlake' mkFlakeModules mkConfiguration mkConfiguration' mkSrc;};
  };

  inherit (api) hosts getHostScopes;
  inherit
    (attrsets)
    attrNames
    filterAttrs
    genAttrs
    hasAttr
    mapAttrs
    mapAttrsToList
    mergeAttrsList
    mkNamespaced
    optionalAttrs
    recursiveUpdate
    removeAttrs
    ;
  inherit (debug) withContext expect;
  inherit (environment) mkSrc;
  inherit (filesystem) mkPaths;
  inherit (lists) elem filter foldl' groupBy;
  inherit (types) isAttrs isBool isEnabled typeOf;
  inherit (strings) concat;
  inherit (systems) getClassification getBuilder systemOf;
  inherit (flake.registry.aggregated) overlays packages;

  mkFlakeModules = flake.modules.mkFlakeModules or (flake.modules.mkFlake or (_: []));

  # ╔════════════════════════════════════════════════╗
  # ╠ FLAKE ASSEMBLY                                 ╣
  # ╚════════════════════════════════════════════════╝
  mkFlake = {
    base,
    mods,
  }: let
    ctx = "mkFlake";
    normalize = value:
      assert withContext {
        name = ctx;
        assertion = isBool value || isAttrs value;
        message = "expected a bool or attrset, got ${typeOf value}";
        context = "normalising path spec in assemble";
      };
        optionalAttrs (isAttrs value) (removeAttrs value ["enable"]);

    resolved = {
      paths = mkPaths {
        store = base.paths.store or (base.paths or (paths.store or null));
        local = base.paths.local or (paths.local or null);
      };
    };
    paths' = removeAttrs resolved.paths.store ["api"];

    enabled =
      filterAttrs (
        name: value:
          assert withContext {
            inherit name;
            assertion = paths' ? ${name};
            message = "'${name}' is not a known path in paths.store. Known paths are [${concat {
              delim = ", ";
              parts = attrNames paths';
            }}]";
            context = "resolving path for '${name}' in assemble";
          };
            (name != "configuration") && (isEnabled value)
      )
      mods;

    outputs = {
      flake = let
        imported =
          mapAttrsToList
          (name: args: import paths'.${name} (base // {args = normalize args;}))
          enabled;
      in
        mergeAttrsList imported;

      configuration =
        optionalAttrs
        (isEnabled (mods.configuration or false))
        (
          mkConfiguration' base {
            modules = {
              core = [resolved.paths.store.configuration];
              home = [];
            };
          }
        );
    };
  in
    outputs.flake // outputs.configuration;

  mkFlake' = base: mods: mkFlake {inherit base mods;};

  # ╔════════════════════════════════════════════════╗
  # ╠ Getters & Setters                              ╣
  # ╚════════════════════════════════════════════════╝

  inherit
    (mkNamespaced {inherit get set;})
    getClass
    getNixpkgs
    getPkgs
    getScopes
    getSystem
    setPkgAliases
    ;

  set = {
    pkgAliases = host: final: prev: let
      updated =
        recursiveUpdate
        ((flake.defaults or {}).pkgAliases or {})
        host.packages.aliases;
      active =
        filter
        (shortcut: hasAttr updated.${shortcut} prev)
        (attrNames updated);
    in
      genAttrs active (shortcut: final.${updated.${shortcut}});
  };

  get = {
    class = host: host.class or hosts.default.class;

    scopes = host: getHostScopes host;

    nixpkgs = host: let
      name =
        if host.packages.stable or false
        then "nixpkgs-stable"
        else "nixpkgs";
    in
      if hasAttr name (flake.registry or {})
      then flake.registry.${name}
      else flake.registry.nixpkgs;

    system = host: host.system or (host.platform or hosts.default.system);

    pkgs = host: let
      system = getSystem host;
      nixpkgs = getNixpkgs host;
      scopes = getScopes host;
    in
      import nixpkgs.source.outPath {
        inherit system;
        config = {
          allowUnfree =
            host.packages.allowUnfree or (
              (flake.defaults or {}).allowUnfree or false
            );
          allowBroken =
            host.packages.allowBroken or (
              (flake.defaults or {}).allowBroken or false
            );
        };
        overlays =
          overlays.select scopes
          ++ [(final: prev: (packages.${system} or {})) (setPkgAliases host)];
      };
  };

  mkHost = {
    base,
    args,
    host,
  }: let
    ctx = "mkHost";

    class = getClass host;
    scopes = getScopes host;
    pkgs = getPkgs host;

    src = mkSrc {
      inherit host;
      extraArgs =
        recursiveUpdate (expect {
          name = ctx;
          type = "attrs";
          value = base;
          context = "validating base in systems";
        }) (
          optionalAttrs (args != null) (expect {
            name = ctx;
            type = "attrs";
            value = args;
            context = "validating args type in systems";
          })
        );
      libraries = base.libraries or (args.libraries or null);
    };
    top = src.name or (src.names.top or (names.top or names.src));

    specialArgs =
      {
        inherit args host top;
        inherit (src) paths;
        mkPkgs = pkgs: pkgs // (packages.${systemOf pkgs} or {});
      }
      // (removeAttrs src ["lib" "name"]);

    modules = let
      modulesFor = class: let
        aggregated = flake.registry.aggregated or {};
        registry = (aggregated.modules or {}).${class} or null;
      in
        if registry != null
        then registry.select scopes
        else mkFlakeModules class;
      core = (modulesFor class) ++ (args.modules.core or []);
      home = {
        environment = {
          pathsToLink = ["/share/applications" "/share/xdg-desktop-portal"];
        };

        home-manager = {
          extraSpecialArgs = specialArgs;
          backupFileExtension = concat {
            delim = "-";
            parts = [top "backup"];
          };
          sharedModules = (modulesFor "home") ++ (args.modules.home or []);
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };
    in
      core ++ [home];
  in {inherit class pkgs specialArgs modules;};

  # ╔════════════════════════════════════════════════╗
  # ╠ CONFIGURATION ASSEMBLY                         ╣
  # ╚════════════════════════════════════════════════╝
  mkConfiguration = {
    base,
    args ? {},
  }: let
    ctx = "mkConfiguration";

    resolved = mapAttrs (_: host: mkHost {inherit base args host;}) hosts;

    hostsByClass =
      groupBy
      (name: resolved.${name}.class)
      (attrNames resolved);

    build = class: names: let
      classification = getClassification class;
      builder = getBuilder class;
      classes = ["nixos" "darwin"];
    in
      assert withContext {
        name = ctx;
        assertion = elem class classes;
        message = "unknown class '${class}' in host specs, expected one of [${concat {
          delim = ", ";
          parts = classes;
        }}]";
        context = "grouping hosts by class";
      }; {
        ${classification} = genAttrs names (
          name:
            builder
            {inherit (resolved.${name}) modules pkgs specialArgs;}
        );
      };
  in
    foldl' recursiveUpdate {} (mapAttrsToList build hostsByClass);

  mkConfiguration' = base: args: mkConfiguration {inherit base args;};
in
  exports
