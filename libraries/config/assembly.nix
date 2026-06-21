{
  api,
  attrsets,
  debug,
  defaults,
  environment,
  filesystem,
  flake,
  ingestion,
  lists,
  names,
  paths,
  strings,
  systems,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit
        mkPaths
        mkConfiguration
        mkFlake
        mkSrc
        mkHomeUser
        mkHomeUsers
        mkCoreUsers
        mkSudoRules
        ;
    };
    global = {
      inherit
        mkFlake
        mkConfiguration
        mkSrc
        mkHomeUser
        mkHomeUsers
        mkCoreUsers
        mkSudoRules
        ;
    };
  };

  mkFlakeModules = flake.modules.mkFlakeModules or null;
  inherit
    (attrsets)
    attrNames
    attrValues
    filterAttrs
    genAttrs
    listToAttrs
    mapAttrs
    mapAttrsToList
    mergeAttrsList
    optionalAttrs
    recursiveUpdate
    ;
  inherit (api) getUsers getAdminUsers getNormalUsers hosts;
  inherit (debug) withContext expect;
  inherit (environment) mkCdAliases mkVariables mkSrc;
  inherit (filesystem) mkPaths;
  inherit (ingestion) collectNamedSpecs;
  inherit (lists) asList concatLists elem foldl' groupBy;
  inherit (types) isAttrs isBool isEnabled typeOf;
  inherit (strings) concat;
  inherit (systems) getClassification getBuilder;

  defaultHost = api.hosts.${defaults.host};

  mkFlake = arg: let
    _name = "config.assembly.mkFlake";
    exec = base: mods: let
      normalize = value:
        assert withContext {
          name = _name;
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

      enabled =
        filterAttrs (
          name: value:
            assert withContext {
              inherit name;
              assertion = resolved.paths ? ${name};
              message = "'${name}' is not a known path in paths.store";
              context = "resolving path for '${name}' in assemble";
            };
              (name != "configuration") && (isEnabled value)
        )
        mods;
    in
      mergeAttrsList (
        mapAttrsToList (
          name: args:
            import resolved.paths.${name} (base // {args = normalize args;})
        )
        enabled
      )
      // (
        let
          configuration = mods.configuration or false;
        in
          optionalAttrs (isEnabled configuration) (
            mkConfiguration {
              inherit base;
              args = {
                modules = let
                  collected = import resolved.paths.store.configuration (
                    recursiveUpdate base {
                      top = base.names.top or (names.top or "dots");
                      args = normalize configuration;
                    }
                  );
                in {
                  core = collected.imports or [];
                  home = collected."home-manager".sharedModules or [];
                };
              };
            }
          )
      );
  in
    if isAttrs arg && arg ? base && arg ? mods
    then exec arg.base arg.mods
    else mods: exec arg mods;

  mkConfiguration = arg: let
    _name = "config.assembly.mkConfiguration";
    exec = base: args: let
      extraArgs =
        recursiveUpdate (expect {
          name = _name;
          type = "attrs";
          value = base;
          context = "validating base in systems";
        }) (
          optionalAttrs (args != null)
          (expect {
            name = _name;
            type = "attrs";
            value = args;
            context = "validating args type in systems";
          })
        );
      resolved =
        mapAttrs (_: spec: let
          host = recursiveUpdate defaultHost spec;
          class = host.class or defaultHost.class;
          src = mkSrc {
            inherit host;
            overrides = extraArgs;
          };
          specialArgs =
            {
              inherit host src args;
              top = src.names.top or names.top;
            }
            // (removeAttrs src ["lib" "modules" "packages"]);
        in {
          inherit class specialArgs;
          modules =
            (mkFlakeModules class)
            ++ (src.modules.core or [])
            ++ (host.imports or [])
            ++ [
              {
                home-manager = {
                  extraSpecialArgs = specialArgs;
                  backupFileExtension = concat {
                    delim = "-";
                    parts = [src.name "backup"];
                  };
                  sharedModules = (mkFlakeModules "home") ++ (src.modules.home or []);
                  useGlobalPkgs = true;
                  useUserPackages = true;
                };
              }
            ];
        })
        hosts;
    in
      foldl' recursiveUpdate {} (
        mapAttrsToList (
          class: hostNames: let
            classification = getClassification class;
            builder = getBuilder class;
            opts = ["nixos" "darwin"];
          in
            assert withContext {
              name = _name;
              assertion = elem class opts;
              message = "unknown class '${class}' in host specs, expected one of [${concat {
                delim = ", ";
                parts = opts;
              }}]";
              context = "grouping hosts by class";
            }; {
              ${classification} = genAttrs hostNames (
                name:
                  builder {inherit (resolved.${name}) specialArgs modules;}
              );
            }
        )
        (groupBy (name: resolved.${name}.class) (attrNames resolved))
      );
  in
    if isAttrs arg && arg ? base
    then exec arg.base (arg.args or {})
    else args: exec arg args;

  mkCoreUsers = host: let
    principals =
      (
        if host.users ? values
        then host.users
        else getUsers host.users
      ).values;
  in {
    users =
      mapAttrs (_: user: {
        inherit (user) description;
        group = user.group or user.name;
        isNormalUser = (user.role or "") != "service";
        isSystemUser = (user.role or "") == "service";
        extraGroups =
          if user.role == "administrator"
          then ["networkmanager" "wheel"]
          else if user.role == "service"
          then ["networkmanager"]
          else [];
      })
      principals;

    groups = mapAttrs (_: user: {}) principals;
  };

  /**
  Generate Home Manager targets for all interactive users tracked by the host.
  */
  mkHomeUsers = {
    lib,
    host,
    dom,
    mod,
  }: let
    byName = collectNamedSpecs {
      args = {inherit host lib dom mod;};
      base = mod;
    };
  in
    mapAttrs (
      name: user:
        mkHomeUser (byName.${name} or {})
    ) (getNormalUsers host);

  /**
  UNIFIED RULE: Generates a Home Manager configuration layout for an individual user profile.
  Automatically merges system-wide flake paths with user-specific custom paths.
  */
  mkHomeUser = spec: {
    config,
    osConfig,
    top,
    src,
    ...
  }: let
    paths = let
      flake = osConfig.${top}.paths.local or {};
      host = listToAttrs (map (name: {
        name = concatLists "_" [src.name name];
        value = flake.${name};
      }) (attrNames flake));
      user = optionalAttrs (spec ? paths) spec.paths;
    in {
      inherit host user;
      merged = host // user;
      resolved = config.${top}.paths.local;
    };
  in {
    imports =
      [
        {
          ${top}.paths.local = paths.merged;
          home = {
            sessionVariables = mkVariables paths.config;
            shellAliases = mkCdAliases paths.config;
          };
          programs.home-manager.enable = true;
        }
        (
          optionalAttrs
          (osConfig ? system.stateVersion)
          {home = {inherit (osConfig.system) stateVersion;};}
        )
      ]
      ++ asList (spec.home or null);
  };

  mkSudoRules = host:
    map (user: {
      users = [user.name];
      commands = [
        {
          command = "ALL";
          options = ["SETENV" "NOPASSWD"];
        }
      ];
    }) (attrValues (getAdminUsers host));
in
  exports
