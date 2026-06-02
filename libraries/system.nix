{
  api,
  debug,
  attrsets,
  defaults,
  lists,
  modules,
  types,
  fromFlake,
  ...
}: let
  exports = {
    scoped = {inherit build resolve systemBuilder systemType perSystem supportedSystems;};
    global = {
      inherit perSystem;
      resolveFlakeConfig = resolve;
      mkConfigurations = build;
    };
  };

  inherit (api) hosts;
  inherit (attrsets) mapAttrs genAttrs optionalAttrs recursiveUpdate;
  inherit (debug) withContext;
  inherit (lists) elem concatMap asList;
  inherit (modules) collectUserSpecs mkCdAliases mkEnvVars;
  inherit (types) isString typeOf isAttrs isNull;

  build = {
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
      hosts = resolve args;
    in {${type} = mapAttrs (_: host: builder host) hosts;};

  systemBuilder = class:
    assert withContext {
      name = "config.systemBuilder";
      assertion = elem class ["nixos" "darwin"];
      message = ''expected one of ["nixos" "darwin"], got ${class}'';
      context = "parsing builder type from class";
    };
    assert withContext {
      name = "config.systemBuilder";
      assertion =
        if class == "nixos"
        then fromFlake ? libraries.nixpkgs.nixosSystem
        else fromFlake ? libraries.nix-darwin.darwinSystem;
      message = ''
        The required compiler for class "${class}" was not found in your flake inputs.
        Make sure you have passed the correct downstream lib/builder mapping.
      '';
      context = "validating system builder presence in namespaced flake inputs";
    };
      if class == "nixos"
      then fromFlake.libraries.nixpkgs.nixosSystem
      else fromFlake.libraries.darwin.darwinSystem;

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

  resolve = value: let
    args =
      recursiveUpdate
      defaults
      (optionalAttrs (isAttrs value) value);
  in
    mapAttrs (_: spec: let
      host = recursiveUpdate defaults.host spec;
      flake =
        recursiveUpdate (defaults.flake or {}) (host.flake or {})
        // {
          inputs = args.inputs or (args.extraArgs.inputs or {});
          home = host.path or (host.home or (host.dots or null));
        };

      specialArgs =
        fromFlake
        // {
          "${fromFlake.names.top}_${fromFlake.name}" = "red";
          inherit host flake;
          "${fromFlake.names.lib}" = removeAttrs (args.libraries or {}) ["lib"];
        }
        // removeAttrs args ["modules"];
    in {
      inherit (host) system;
      inherit specialArgs;

      modules =
        (fromFlake.modules.core or [])
        ++ (args.modules.core or [])
        ++ (host.modules or [])
        ++ (host.imports or [])
        ++ [
          {
            home-manager = {
              backupFileExtension = "BaC";
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = (fromFlake.modules.home or []) ++ (args.modules.home or []);
              extraSpecialArgs = specialArgs;
              users =
                mapAttrs (_: user: {
                  config,
                  osConfig,
                  top,
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
                    ++ (user.imports or [])
                    ++ (
                      concatMap
                      (spec: asList (spec.home or null))
                      (collectUserSpecs user)
                    );
                })
                (host.users.byStatus.enabled.values or {});
            };
          }
        ];
    })
    hosts;

  supportedSystems = ["x86_64-linux" "aarch64-linux"]; # TODO: api.hosts should tell use all the needed systems
  perSystem = f:
    genAttrs supportedSystems (
      system: f fromFlake.packages.nixpkgs.${system}
    );
in
  exports
