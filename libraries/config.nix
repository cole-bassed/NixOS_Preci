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
  ...
}: let
  exports = {
    scoped = {
      inherit
        assemble
        perSystem
        supportedSystems
        systemBuilder
        systems
        systemType
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
  inherit (attrsets) attrNames attrValues filterAttrs genAttrs mapAttrs mapAttrsToList mergeAttrsList optionalAttrs orEmpty recursiveUpdate;
  inherit (debug) withContext;
  inherit (lists) elem groupBy unique;
  inherit (modules) mkCdAliases mkEnvVars;
  inherit (types) isAttrs isBool isFunction isNotEmpty isNull typeOf;

  # ── systems ────────────────────────────────────────────────────────────────

  systems = {
    base,
    args ? null,
  }:
    assert withContext {
      name = "config.systems";
      assertion = isAttrs base;
      message = "expected base to be an attrset, got ${typeOf base}";
      context = "validating base in systems";
    };
    assert withContext {
      name = "config.systems";
      assertion = isNull args || isAttrs args;
      message = "args must be an attribute set or null, got ${typeOf args}";
      context = "validating args type in systems";
    };
      assemble.configurations base (orEmpty args);

  # ── system type/builder helpers ────────────────────────────────────────────

  systemType = class:
    assert withContext {
      name = "config.systemType";
      assertion = elem class ["nixos" "darwin"];
      message = ''expected one of ["nixos" "darwin"], got ${class}'';
      context = "parsing system type from class";
    };
      if class == "darwin"
      then "darwinConfigurations"
      else "nixosConfigurations";

  systemBuilder = class:
    assert withContext {
      name = "config.systemBuilder";
      assertion = elem class ["nixos" "darwin"];
      message = ''expected one of ["nixos" "darwin"], got ${class}'';
      context = "parsing system builder from class";
    };
    assert withContext {
      name = "config.systemBuilder";
      assertion =
        if class == "nixos"
        then flake ? libraries.nixpkgs.nixosSystem
        else flake ? libraries.nix-darwin.darwinSystem;
      message = ''
        The required compiler for class "${class}" was not found in your flake inputs.
        Make sure you have passed the correct downstream lib/builder mapping.
      '';
      context = "validating system builder presence in flake inputs";
    };
      if class == "nixos"
      then flake.libraries.nixpkgs.nixosSystem
      else flake.libraries.darwin.darwinSystem;

  # ── supported systems ──────────────────────────────────────────────────────

  supportedSystems = {extra ? []}:
    unique (
      extra
      ++ map (host: host.system or host.platform or defaults.host.system)
      (attrValues hosts)
    );

  # ── perSystem ──────────────────────────────────────────────────────────────

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

  # ── assemble ───────────────────────────────────────────────────────────────

  assemble = {
    flake = base: mods: let
      normalise = value:
        assert withContext {
          name = "config.assemble.flake";
          assertion = isBool value || isAttrs value;
          message = "expected a bool or attrset, got ${typeOf value}";
          context = "normalising path spec in assemble";
        };
          if isBool value
          then optionalAttrs value {}
          else optionalAttrs (isNotEmpty value) (removeAttrs value ["enable"]);

      resolved.paths = base.paths or paths;

      enabled =
        filterAttrs (
          name: value:
            assert withContext {
              name = "config.assemble.flake";
              assertion = resolved.paths ? ${name};
              message = "'${name}' is not a known path in resolved.paths";
              context = "resolving path for '${name}' in assemble";
            };
              (value.enable or value) != false
        )
        mods;
    in
      mergeAttrsList (
        mapAttrsToList (
          name: args:
            import resolved.paths.${name} (base // {args = normalise args;})
        )
        enabled
      );

    configurations = base: args: let
      extraArgs = base // args;
      inherit (extraArgs.names) top;

      resolved =
        mapAttrs (
          _: spec: let
            host = recursiveUpdate defaults.host spec;
            class = host.class or defaults.host.class;
            specialArgs =
              {inherit top host;}
              // (removeAttrs extraArgs ["lib" "modules" "packages"])
              // {paths = recursiveUpdate paths host.paths;};
          in {
            inherit class specialArgs;
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
                        imports =
                          [
                            {
                              home = {
                                inherit (osConfig.system) stateVersion;
                                sessionVariables = mkEnvVars "" (config.${top}.paths or {});
                                shellAliases = mkCdAliases (config.${top}.paths or {});
                              };
                              programs.home-manager.enable = true;
                            }
                          ]
                          ++ (user.modules or [])
                          ++ (user.imports or []);
                      })
                      (host.users.byStatus.enabled.values or {});
                  };
                }
              ];
          }
        )
        hosts;

      byClass = groupBy (name: resolved.${name}.class) (attrNames resolved);
    in
      mergeAttrsList (
        mapAttrsToList (
          class: names: let
            type = systemType class;
            builder = systemBuilder class;
          in
            assert withContext {
              name = "config.assemble.configurations";
              assertion = elem class ["nixos" "darwin"];
              message = "unknown class '${class}' in host specs, expected one of [nixos darwin]";
              context = "grouping hosts by class";
            }; {
              ${type} = genAttrs names (
                name: builder {inherit (resolved.${name}) specialArgs modules;}
              );
            }
        )
        byClass
      );
  };
in
  exports
