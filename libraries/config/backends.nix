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

  inherit (attrsets) filterAttrs hasAttrByPath listToAttrs asAttrsIf setAttrByPath;
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
      listToAttrs (map (e: {
          name = toBindKey e;
          value = toSpawn e.action;
        })
        valid)
    );

  mkBackendOptions = {
    get,
    set,
    scope,
    options,
    top,
    extraArgs ? {},
    ...
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
        # enable = set.enable {default = true;};
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
      // asAttrsIf (scope == "core") {
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

    config = mkMerge [
      # ╔════════════════════════════════════════════════╗
      # ╠ CORE TIER ADJUSTMENTS                          ╣
      # ╚════════════════════════════════════════════════╝
      (mkIf (scope == "core") (mkMerge [
        (mkIf (cfg.enable or false) (
          asAttrsIf (hasSub "enable") (setAttrByPath (target ++ ["enable"]) cfg.enable)
        ))
        (mkIf (cfg.enable or false) (
          asAttrsIf (hasSub "package") (setAttrByPath (target ++ ["package"]) cfg.package)
        ))

        {
          programs.uwsm = mkIf ((cfg.enable or false) && (cfg.protocol == "wayland") && (cfg.uwsm.enable or false)) {
            enable = true;
            waylandCompositors.${name} = {
              prettyName = cfg.uwsm.name;
              comment = cfg.uwsm.description;
              binPath = cfg.uwsm.binary;
            };
          };
        }
      ]))

      # ╔════════════════════════════════════════════════╗
      # ╠ HOME TIER ADJUSTMENTS                          ╣
      # ╚════════════════════════════════════════════════╝
      (mkIf (scope == "home") (mkMerge [
        (mkIf (cfg.enable or false) (asAttrsIf (hasSub "enable")
            (setAttrByPath (target ++ ["enable"]) cfg.enable)))
        (mkIf (cfg.enable or false) (asAttrsIf (hasSub "package")
            (setAttrByPath (target ++ ["package"]) cfg.package)))
      ]))

      # ╔════════════════════════════════════════════════╗
      # ╠ DYNAMIC REGISTRY SWITCHBOARD ROUTERS           ╣
      # ╚════════════════════════════════════════════════╝
      (
        mkMerge [
          # --------------------------------------------------
          # --> Frontend Router
          # --------------------------------------------------
          (mkIf ((cfg.enable or false) && (registry.frontend == name)) {
            ${top}.applications.${name}.enable = true;
          })

          # --------------------------------------------------
          # --> Greeter Router
          # --------------------------------------------------
          (mkIf ((cfg.enable or false) && (registry.greeter == name)) {
            ${top}.applications.${name}.enable = true;
          })
        ]
      )
    ];
  };
in
  exports
