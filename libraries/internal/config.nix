{
  api,
  debug,
  attrsets,
  lists,
  types,
  external,
  paths,
  names,
  defaults,
  ...
}: let
  exports = {
    scoped = {
      inherit
        assemble
        perSystem
        mkSrc
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

  inherit (attrsets) attrNames attrValues attrByPath filterAttrs genAttrs mapAttrs mapAttrsToList mergeAttrsList optionalAttrs orEmpty recursiveUpdate;
  inherit (debug) withContext;
  inherit (lists) elem groupBy unique;
  # inherit (modules) mkCdAliases mkEnvVars;
  inherit (types) isAttrs isBool isFunction isNotEmpty typeOf;
  inherit (api) hosts;
  defaultHost = api.hosts.${defaults.host};

  /**
  Build the basic `dots` path configuration for a host.

  # Type

  ```nix
  mkDots :: AttrSet -> AttrSet -> AttrSet
  ```

  # Dependencies

  None

  # Arguments

  paths
  : Project paths. Must include `src`.

  host
  : Host config. Must include `paths.src`.

  # Examples

  ```nix
  mkDots { src = ./.; } { paths.src = /home/me/dots; }
  # => { dots = { store = "..."; local = /home/me/dots; }; }
  ```
  */
  mkSrc = {
    host,
    args ? {},
  }: {
    ${external.flake.names.src or names.src} = recursiveUpdate args {
      paths = {
        local = let
          src =
            if host ? paths.src
            then host.paths.src
            else if host ? paths.dots
            then host.paths.dots
            else if host ? paths.home
            then host.paths.home
            else if host ? dots
            then host.dots
            else if host ? home
            then host.home
            else paths.local.src;
        in
          recursiveUpdate
          paths.local
          (recursiveUpdate {inherit src;} (host.paths or {}));
        store =
          recursiveUpdate
          (
            paths.store or {
              src = external.flake.paths.src or paths.src;
            }
          ) (args.paths or {});
      };
    };
  };

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
        then external ? libraries.normalized.nixpkgs.nixosSystem
        else external ? libraries.normalized.nix-darwin.darwinSystem;
      message = ''
        The required compiler for class "${class}" was not found in your flake inputs.
        Make sure you have passed the correct downstream lib/builder mapping.
      '';
      context = "validating system builder presence in flake inputs";
    };
      if class == "nixos"
      then external.libraries.normalized.nixpkgs.nixosSystem
      else external.libraries.normalized.darwin.darwinSystem;

  # ── supported systems ──────────────────────────────────────────────────────

  supportedSystems = {extra ? []}:
    unique (
      extra
      ++ map (host: host.system or host.platform or defaultHost.system)
      (attrValues hosts)
    );

  # ── perSystem ──────────────────────────────────────────────────────────────

  perSystem = arg: let
    opts =
      if isFunction arg
      then {fn = arg;}
      else arg;
    packages = opts.packages or external.packages.default;
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
      )
      // optionalAttrs (mods.configurations or false != false) (
        assemble.configurations base {}
      );

    configurations = base: args: let
      extraArgs = base // args;
      inherit (extraArgs.names) top;

      resolved =
        mapAttrs (
          _: spec: let
            host = recursiveUpdate defaultHost spec;
            class = host.class or defaultHost.class;
            specialArgs =
              {
                inherit top host libraries;
                src = mkSrc {inherit host args;};
              }
              // (removeAttrs extraArgs ["lib" "modules" "packages"])
              // {paths = recursiveUpdate paths host.paths;};
          in {
            inherit class specialArgs;
            modules =
              attrByPath ["modules" "classified" class] [] external
              ++ (spec.imports or [])
              ++ (host.modules or [])
              ++ (host.imports or [])
              # ++ (extraArgs.modules.core or [])
              # ++ (base.modules.core or [])
              # ++ (args.modules.core or [])
              ++ [
                (import ../../configuration/modules/localization.nix)
                #   ({host, ...}: {
                #     system.stateVersion = host.stateVersion or "22.11";
                #     # config.system.stateVersion = config.system.nixos.release;
                #   })
              ]
              ++ [
                {
                  home-manager = {
                    backupFileExtension = "backup";
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    sharedModules =
                      attrByPath ["modules" "classified" "home"] [] external
                      ++ extraArgs.modules.home or [];

                    #     extraSpecialArgs =
                    #       specialArgs
                    #       // {
                    #         flakeModules = flake.modules.home;
                    #       };
                    #     users =
                    #       mapAttrs
                    #       (_: user: {
                    #         config,
                    #         osConfig,
                    #         ...
                    #       }: {
                    #         imports =
                    #           [
                    #             {
                    #               home = {
                    #                 inherit (osConfig.system) stateVersion;
                    #                 sessionVariables = mkEnvVars "" (config.${top}.paths or {});
                    #                 shellAliases = mkCdAliases (config.${top}.paths or {});
                    #               };
                    #               programs.home-manager.enable = true;
                    #             }
                    #           ]
                    #           ++ [];
                    #       })
                    #       (host.users.byStatus.enabled.values or {});
                  };
                }
              ];

            # modules =
            #   (
            #     optionals
            #     (flake.modules ? mkCore)
            #     (flake.modules.mkCore class)
            #   )
            #   ++ (extraArgs.modules.core or [])
            #   ++ (host.modules or [])
            #   ++ (host.imports or [])
            #   ++ [spec]
            #   ++ [
            #     {
            #       home-manager = {
            #         backupFileExtension = "backup";
            #         useGlobalPkgs = true;
            #         useUserPackages = true;
            #         sharedModules = extraArgs.modules.home or [];

            #         extraSpecialArgs =
            #           specialArgs
            #           // {
            #             flakeModules = flake.modules.home;
            #           };
            #         # sharedModules =
            #         #   (flake.modules.home or [])
            #         #   ++ (extraArgs.modules.home or []);
            #         # extraSpecialArgs = specialArgs;
            #         users =
            #           mapAttrs
            #           (_: user: {
            #             config,
            #             osConfig,
            #             ...
            #           }: {
            #             imports =
            #               [
            #                 {
            #                   home = {
            #                     inherit (osConfig.system) stateVersion;
            #                     sessionVariables = mkEnvVars "" (config.${top}.paths or {});
            #                     shellAliases = mkCdAliases (config.${top}.paths or {});
            #                   };
            #                   programs.home-manager.enable = true;
            #                 }
            #               ]
            #               # ++ (user.modules or [])
            #               # ++ (user.imports or [])
            #               ++ [];
            #           })
            #           (host.users.byStatus.enabled.values or {});
            #       };
            #     }
            #   ];
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
