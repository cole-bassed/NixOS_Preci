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
    scoped = {inherit mkConfiguration mkFlake mkPaths mkSrc;};
    global = {inherit mkFlake mkConfiguration mkSrc;};
  };

  # Fallback for non-registry setups.  Returns a no-op if neither path works so
  # we get a clear failure at build time rather than a cryptic null-call error.
  mkFlakeModules = flake.modules.mkFlakeModules or flake.modules.mkFlake or (_: []);

  inherit (attrsets) attrNames filterAttrs genAttrs mapAttrs mapAttrsToList mergeAttrsList optionalAttrs recursiveUpdate;
  inherit (api) hosts getHostScopes;
  inherit (debug) withContext expect;
  inherit (environment) mkSrc;
  inherit (filesystem) mkPaths;
  inherit (lists) elem foldl' groupBy;
  inherit (types) isAttrs isBool isEnabled typeOf;
  inherit (strings) concat;
  inherit (systems) getClassification getBuilder systemOf;
  inherit (flake.registry.aggregated) overlays packages;

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
    in
      mergeAttrsList (
        mapAttrsToList
        (
          name: args:
            import paths'.${name}
            (base // {args = normalize args;})
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
                modules = {
                  core = [resolved.paths.store.configuration];
                  home = [];
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
        mapAttrs (_: host: let
          class = host.class or hosts.default.class;

          # ── Per-host scope-based module selection ─────────────────────────
          #
          # 1. Derive which topic scopes this host needs (e.g. a VPS gets
          #    ["core" "infrastructure" "secrets" "deployment"] while a desktop
          #    also gets ["desktop" "ui" "window-manager" ...]).
          #
          # 2. registry.aggregated.modules.${class}.select filters the registry
          #    entries whose `scopes` field intersects the wanted set, returning
          #    only the module values they contribute.
          #
          # 3. Always inject {nixpkgs.config.allowUnfree} since that is not
          #    sourced from any external input — it is generated inline.
          #
          # 4. Fall back to mkFlakeModules (which returns all modules) when no
          #    registry is available, preserving the original behaviour for
          #    non-registry flake setups.
          # ────────────────────────────────────────────────────────────────────
          hostScopes = getHostScopes host;

          scopedModsFor = type: let
            reg = flake.registry or {};
            agg = reg.aggregated or {};
            mods = (agg.modules or {}).${type} or null;
          in
            if mods != null
            then
              # nixpkgs.config is synthesised; it comes from no input entry
              [{nixpkgs.config = {allowUnfree = (flake.defaults or {}).allowUnfree or false;};}]
              ++ mods.select hostScopes
            else
              # Fallback: all modules + mkCore (includes nixpkgs config)
              mkFlakeModules type;

          src = mkSrc {
            inherit host extraArgs;
            libraries = base.libraries or (args.libraries or null);
          };
          specialArgs =
            {
              inherit host args;
              top = src.name or (src.names.top or (names.top or names.src));
              inherit (src) paths;
              mkPkgs = pkgs: pkgs // (packages.${systemOf pkgs} or {});
            }
            // (removeAttrs src ["lib" "name"]);
        in {
          inherit class specialArgs;
          modules =
            (scopedModsFor class)
            ++ (args.modules.core or [])
            ++ [
              {
                environment.pathsToLink = [
                  "/share/applications"
                  "/share/xdg-desktop-portal"
                ];

                nixpkgs.overlays = overlays.select hostScopes;

                home-manager = {
                  extraSpecialArgs = specialArgs;
                  backupFileExtension = concat {
                    delim = "-";
                    parts = [src.name "backup"];
                  };
                  sharedModules =
                    (scopedModsFor "home")
                    ++ (args.modules.home or []);
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
in
  exports
