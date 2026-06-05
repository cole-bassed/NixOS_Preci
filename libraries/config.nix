{
  api,
  debug,
  attrsets,
  lists,
  modules,
  types,
  flake,
  paths,
  defaults,
  # names,
  ...
}: let
  exports = {
    scoped = {
      inherit
        perSystem
        supportedSystems
        systemBuilder
        systems
        systemType
        assemble
        ;
    };
    global = {
      inherit assemble;
      assembleConfigurations = assemble.configurations;
      assembleFlake = assemble.flake;
      buildSystems = systems;
      forEachSystem = perSystem;
      mkConfigurations = systems;
    };
  };

  inherit (api) hosts;
  inherit (attrsets) attrValues filterAttrs genAttrs mapAttrs mapAttrsToList mergeAttrsList optionalAttrs recursiveUpdate;
  inherit (debug) withContext;
  inherit (lists) elem unique;
  inherit (modules) mkCdAliases mkEnvVars;
  inherit (types) isAttrs isBool isFunction isNotEmpty isString typeOf;

  systems = {
    args ? null,
    class ? "nixos",
  }:
    assert withContext {
      name = "config.build";
      assertion = isString class;
      message = "class must be a string, got ${typeOf class}";
      context = "validating class type in build";
    };
    assert withContext {
      name = "config.build";
      assertion = isNull args || isAttrs args;
      message = "args must be an attribute set or null, got ${typeOf args}";
      context = "validating args type in build";
    }; let
      type = systemType class;
      builder = systemBuilder class;
      hosts = assemble.flake args;
    in {${type} = mapAttrs (_: builder) hosts;};

  systemBuilder = class:
    assert withContext {
      name = "config.systemBuilder";
      assertion = elem class [
        "nixos"
        "darwin"
      ];
      message = ''expected one of ["nixos" "darwin"], got ${class}'';
      context = "parsing builder type from class";
    };
    assert withContext {
      name = "config.systemBuilder";
      assertion =
        if class == "nixos"
        then flake?libraries.nixpkgs.nixosSystem
        else flake?libraries.nix-darwin.darwinSystem;
      message = ''
        The required compiler for class "${class}" was not found in your flake inputs.
        Make sure you have passed the correct downstream lib/builder mapping.
      '';
      context = "validating system builder presence in namespaced flake inputs";
    };
      if class == "nixos"
      then flake.libraries.nixpkgs.nixosSystem
      else flake.libraries.darwin.darwinSystem;

  systemType = class:
    assert withContext {
      name = "config.systemType";
      assertion = elem class ["nixos" "darwin"];
      message = ''expected one of ["nixos" "darwin"], got ${class}'';
      context = "parsing type of config from class for config.mkConfigurations";
    };
      if class == "darwin"
      then "darwinConfigurations"
      else "nixosConfigurations";

  supportedSystems = {extra ? []}:
    unique (
      extra
      ++ map (host: host.system or host.platform or defaults.host.system)
      (attrValues hosts)
    );

  perSystem = arg: let
    opts =
      if isFunction arg
      then {fn = arg;}
      else arg;
    packages = opts.packages or flake.packages.nixpkgs;
    extra = opts.extra or [];
  in
    genAttrs
    (supportedSystems {inherit extra;})
    (system: opts.fn packages.${system});

  assemble = {
    flake = base: mods: let
      normalise = value:
        assert withContext {
          name = "config.assemble";
          assertion = isBool value || isAttrs value;
          message = "expected a bool or attrset, got ${typeOf value}";
          context = "normalising path spec in assemble";
        };
          if isBool value
          then optionalAttrs value {}
          else optionalAttrs (isNotEmpty value) (removeAttrs value ["enable"]);

      resolvedPaths = base.paths or paths;

      enabled =
        filterAttrs (
          name: value:
            assert withContext {
              name = "config.assemble";
              assertion = resolvedPaths ? ${name};
              message = "'${name}' is not a known path in resolvedPaths";
              context = "resolving path for '${name}' in assemble";
            };
              (value.enable or value) != false
        )
        mods;
    in
      mergeAttrsList (
        mapAttrsToList (
          name: args:
            import resolvedPaths.${name} (base // {args = normalise args;})
        )
        enabled
      );

    configurations = base: args: let
      extraArgs = base // args;
      inherit (extraArgs.names) top;
    in
      mapAttrs (
        _: spec: let
          host = recursiveUpdate defaults.host spec;
          specialArgs =
            {
              inherit top;
              paths = recursiveUpdate paths host.paths;
            }
            // (removeAttrs extraArgs [
              "lib"
              "modules"
              "packages"
            ]);
        in {
          inherit specialArgs;

          modules =
            (flake.modules.core or [])
            ++ (extraArgs.modules.core or [])
            ++ (host.modules or [])
            ++ (host.imports or [])
            ++ [
              {
                home-manager = {
                  backupFileExtension = "BaC";
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  sharedModules =
                    (flake.modules.home or [])
                    ++ (extraArgs.modules.home or []);
                  extraSpecialArgs = specialArgs;
                  users =
                    mapAttrs
                    (_: user: {
                      config,
                      osConfig,
                      ...
                    }: {
                      imports = [
                          {
                            home = {
                              inherit (osConfig.system) stateVersion;
                              sessionVariables = mkEnvVars "" (config.${top}.paths or {});
                              shellAliases = mkCdAliases (config.${top}.paths or {});
                            };
                            programs.home-manager.enable = true;
                          }
                        ]
                        ++ (user.modules or []);
                    })
                    (host.users.byStatus.enabled.values or {});
                };
              }
            ];
        }
      )
      hosts;
  };
in
  exports
