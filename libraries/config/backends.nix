{
  attrsets,
  lists,
  modules,
  strings,
  options,
  types,
  ...
}: let
  exports = {
    scoped = {inherit mkHyprlandBinds mkNiriBinds mkBackendOptions;};
    global = {
      mkBackendHyprlandBinds = mkHyprlandBinds;
      mkBackendNiriBinds = mkNiriBinds;
      inherit mkBackendOptions;
    };
  };

  inherit (attrsets) filterAttrs hasAttrByPath optionalAttrs setAttrByPath;
  inherit (lists) filter;
  inherit (strings) concatStringsSep;
  inherit (lists) findFirst;
  inherit (modules) mkIf mkMerge;
  inherit (options) mkRegistryOptions mkEnableOption mkOption;
  inherit (types) enum nullOr nullPkg nullStr str submodule;

  # Hyprland's bind syntax: "MOD1 MOD2, KEY, exec, ACTION"
  mkHyprlandBinds = entries: let
    valid = filter (e: e.action != null && e.key != null) entries;
    format = e: "${concatStringsSep " " e.mod}, ${e.key}, exec, ${e.action}";
  in
    map format valid;

  # Niri's bind syntax: attrset keyed "Mod+Key" -> { action.spawn = [...]; }
  mkNiriBinds = entries: let
    valid = filter (e: e.action != null && e.key != null) entries;
    toBindKey = e: concatStringsSep "+" (e.mod ++ [e.key]);
    toSpawn = action: {action.spawn = ["sh" "-lc" action];};
  in
    filterAttrs (_: v: v != null) (
      builtins.listToAttrs (map (e: {
          name = toBindKey e;
          value = toSpawn e.action;
        })
        valid)
    );

  # libraries/config/backend-options.nix
  #
  # This is a faithful, behavior-preserving extraction of the closure that
  # used to live ONLY inside configuration/interface/default.nix's
  # `extraArgs.mkArgs`. That closure is what actually makes a compositor
  # module (hyprland/niri/mango) work: protocol/session/uwsm resolution,
  # HM option-path detection (`programs.X` vs `wayland.windowManager.X`),
  # frontend auto-enable, and UWSM registration.
  #
  # Previously, only configuration/interface/default.nix could construct
  # this closure (it built it inline and injected it as `mkArgs` for the
  # modules it loaded itself). That's why hyprland/niri/mango had to be
  # excluded from configuration/applications/default.nix's generic walk --
  # loaded from applications/, they'd never receive `mkArgs`.
  #
  # mkBackendOptions is the same computation, callable directly by any
  # application module (self-sufficient, no injection required), so
  # hyprland/niri/mango can live under configuration/applications/ like
  # every other app and still get correct backend wiring.
  #
  # configuration/interface/default.nix keeps only the orchestration parts
  # that are genuinely about *choosing between* backends (primary/secondary/
  # tertiary resolution) -- not about defining any one backend's options.

  # get   :: the `get` record from mkModuleArgs (name, prettyName, cfg,
  #          cfgOr, apiOr -- see libraries/config/modules.nix)
  # set   :: the `set` record from mkModuleArgs (opt, bin, ...)
  # scope :: "core" | "home"
  # options :: the live module `options` arg (for hasAttrByPath probing)
  # top   :: the dots top-level namespace (e.g. "dots")
  mkBackendOptions = {
    get,
    set,
    scope,
    options,
    top,
    extraArgs ? {},
  }: let
    inherit (get) prettyName name cfg cfgOr apiOr;
    inherit (set) opt bin;

    registry = let
      derived = {
        enable = apiOr "enable";
        protocol = apiOr "protocol";
        uwsm = apiOr "uwsm";
        session = apiOr "session";
        needsXwaylandSatellite = apiOr "needsXwaylandSatellite";
        frontend = apiOr "frontend";
        greeter = apiOr "greeter";
        package = apiOr "package";
        configType = apiOr "configType";
        applications = apiOr "applications";
        bindings = apiOr "bindings";
      };
      defaults' = {
        inherit (get) package;
        enable = false;
        protocol = null;
        greeter = null;
        uwsm = null;
        session = name;
        needsXwaylandSatellite = false;
        frontend = null;
        applications = {
          browser = null;
          editor = null;
          visual = null;
          launcher = null;
          terminal = null;
        };
        bindings = {
          modifier = "SUPER";
          swapCapsEscape = false;
        };
      };

      updated =
        attrsets.mapAttrs
        (
          key: value: let
            derivedValue = derived.${key} or null;
          in
            if derivedValue != null
            then derivedValue
            else value
        )
        (attrsets.foldMerge [defaults' extraArgs]);
    in
      updated
      // {
        uwsm =
          if derived.uwsm != null
          then derived.uwsm
          else updated.protocol == "wayland" && updated.enable;
      };

    fields =
      (mkRegistryOptions registry)
      // {
        enable = set.enable {default = registry.enable;};

        package = mkOption {
          type = nullPkg;
          default = registry.package;
          description = "Package backing the ${prettyName} compositor component.";
        };

        protocol = mkOption {
          type = nullOr (enum ["x11" "wayland"]);
          default = registry.protocol;
          description = "Display protocol for ${prettyName}. Defaults to the backend registry or host/user override.";
        };

        session = mkOption {
          type = nullStr;
          default = registry.session;
          description = "Session name exported by ${prettyName}. Defaults to the backend registry or host/user override.";
        };

        greeter = mkOption {
          type = nullStr;
          default = registry.greeter;
          description = "Greeter or display manager preferred for ${prettyName}. Defaults to the backend registry or host/user override.";
        };

        frontend = mkOption {
          type = nullStr;
          default = registry.frontend;
          description = "Frontend layer paired with ${prettyName}. Defaults to the backend registry or host/user override.";
        };

        needsXwaylandSatellite =
          mkEnableOption "xwayland-satellite support for ${prettyName}"
          // {default = registry.needsXwaylandSatellite;};
      }
      // optionalAttrs (scope == "core") {
        uwsm = mkOption {
          description = "UWSM configuration for ${prettyName}. Set to `null` to disable UWSM integration.";
          type = submodule {
            options = {
              enable = mkEnableOption "${prettyName} UWSM support." // {default = registry.uwsm;};
              name = mkOption {
                type = str;
                description = "Human-readable name shown by UWSM.";
                default = prettyName;
              };
              description = mkOption {
                type = str;
                description = "Comment shown by UWSM.";
                default = "${prettyName} compositor managed by UWSM";
              };
              binary = mkOption {
                type = str;
                description = "Absolute path to the compositor binary.";
                default = (bin {}).path;
              };
            };
          };
        };
      };

    target = findFirst (candidate: hasAttrByPath candidate options) null [
      ["wayland" "windowManager" name]
      ["programs" name]
    ];
    hasSub = key: target != null && hasAttrByPath (target ++ [key]) options;
  in {
    inherit fields cfgOr;
    options = opt fields;
    config =
      if scope == "home"
      then
        optionalAttrs (target != null) (setAttrByPath target (
          optionalAttrs (hasSub "enable") {inherit (cfg) enable;}
          // optionalAttrs (hasSub "package") {inherit (cfg) package;}
        ))
      else
        mkMerge [
          (mkIf (cfg.enable or false) (
            optionalAttrs
            (hasSub "enable")
            (setAttrByPath (target ++ ["enable"]) cfg.enable)
          ))
          (mkIf (cfg.enable or false) (
            optionalAttrs
            (hasSub "package")
            (setAttrByPath (target ++ ["package"]) cfg.package)
          ))

          # --- AUTOMATIC SWITCHBOARD ROUTER ---
          (mkIf ((cfg.enable or false) && registry.frontend != null) {
            ${top}.applications.${registry.frontend}.enable = true;
          })

          (mkIf ((cfg.enable or false)
            && cfg.protocol == "wayland"
            && (cfg.uwsm.enable or false)) {
            programs.uwsm = {
              enable = true;
              waylandCompositors.${name} = {
                prettyName = cfg.uwsm.name;
                comment = cfg.uwsm.description;
                binPath = cfg.uwsm.binary;
              };
            };
          })
        ];
  };
in
  exports
