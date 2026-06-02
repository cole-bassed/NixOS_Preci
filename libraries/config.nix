{
  api,
  core,
  home,
  debug,
  attrsets,
  defaults,
  lists,
  modules,
  types,
  system,
  ...
}: let
  exports = {
    scoped = {inherit build resolve systemBuilder systemType;};
    global = {
      resolveFlakeConfig = resolve;
      mkConfigurations = build;
    };
  };

  inherit (api) hosts;
  inherit (attrsets) mapAttrs optionalAttrs recursiveUpdate;
  inherit (debug) withContext;
  inherit (lists) elem concatMap asList;
  inherit (modules) collectUserSpecs mkCdAliases mkEnvVars;
  inherit (system) nixosSystem darwinSystem;
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
      if class == "nixos"
      then nixosSystem
      else darwinSystem;

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
        {
          inherit host flake;
          inherit (flake) inputs top;
          lib = args.lib or args.libraries.lib or {};
          "${args.names.lib}" = removeAttrs (args.libraries or {}) ["lib"];
        }
        // removeAttrs args ["modules"];
    in {
      inherit (host) system;
      inherit specialArgs;

      modules =
        core
        ++ (args.modules.core or [])
        ++ (host.modules or [])
        ++ (host.imports or [])
        ++ [
          {
            home-manager = {
              backupFileExtension = "BaC";
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = home ++ (args.modules.home or []);
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
in
  exports
