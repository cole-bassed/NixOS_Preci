{
  lix,
  top,
  host,
  path,
  registry,
  selection,
  ...
} @ args: let
  inherit (lix.api.users) getInteractiveUsers;
  inherit (lix.attrsets) attrByPath attrValues foldMerge hasAttr hasAttrByPath isAttrs mapAttrs optionalAttrs setAttrByPath;
  inherit (lix.lists) findFirst init;
  inherit (lix.modules) mkDefault mkIf mkMerge mkModules;
  inherit (lix.options) mkEnable mkEnableOption mkModuleArgs mkOption;
  inherit (lix.types) enum nullOr package str submodule;

  path' = path;

  materialize = selected:
    mapAttrs
    (_: extra: {enable = true;} // extra)
    (foldMerge selected);

  backendApiOf = spec: let
    interface = spec.interface or {};
    raw = interface.backends or null;
    legacy = interface.environment or {};
  in
    if isAttrs raw
    then raw
    else legacy;

  backendApiFor = spec: name: (backendApiOf spec).${name} or {};

  required = let
    main = [(selection host)];
    isDesktopHost = builtins.elem (host.type or "desktop") ["desktop" "laptop"];
    userSelections =
      if isDesktopHost
      then map selection (attrValues (getInteractiveUsers host))
      else [];
  in {
    core = materialize (main ++ userSelections);
    home = user:
      materialize (
        main
        ++ (
          if isDesktopHost
          then [(selection user)]
          else []
        )
      );
  };

  mkMod = {
    config,
    options ? {},
    scope ? "core",
    pkgs,
    path ? path',
  }: let
    users = getInteractiveUsers host;
    module = mkModuleArgs {inherit top config path scope pkgs users options;};
    parent = mkModuleArgs {
      inherit config top scope;
      path = init path;
    };
    bin = module.set.bin {};
    inherit (module.get) prettyName name user;
    cfg = module.get.config.module;
    opt = module.set.options.module;
    data = registry.${name} or {};
    api =
      if scope == "home"
      then (backendApiFor host name) // (backendApiFor user name)
      else backendApiFor host name;
    enabledDefault =
      if scope == "home"
      then hasAttr name (required.home user)
      else hasAttr name required.core;
    resolvedOr = key:
      api.${key} or (data.${key} or null);
    protocolDefault = resolvedOr "protocol";
    isWayland = protocolDefault == "wayland";

    fields =
      {
        enable = mkEnable {
          inherit name scope;
          default = enabledDefault;
        };
        package = mkOption {
          type = nullOr package;
          default = pkgs.${name} or null;
          description = "Package backing the ${prettyName} compositor component.";
        };
        protocol = mkOption {
          type = nullOr (enum ["x11" "wayland"]);
          default = protocolDefault;
          description = "Display protocol for ${prettyName}. Defaults to the backend registry or host/user API override.";
        };
        session = mkOption {
          type = nullOr str;
          default = let
            value = resolvedOr "session";
          in
            if value != null
            then value
            else name;
          description = "Session name exported by ${prettyName}. Defaults to the backend registry or host/user API override.";
        };
        greeter = mkOption {
          type = nullOr str;
          default = resolvedOr "greeter";
          description = "Greeter or display manager preferred for ${prettyName}. Defaults to the backend registry or host/user API override.";
        };
        frontend = mkOption {
          type = nullOr str;
          default = resolvedOr "frontend";
          description = "Frontend layer paired with ${prettyName}. Defaults to the backend registry or host/user API override.";
        };
        needsXwaylandSatellite =
          mkEnableOption "xwayland-satellite support for ${prettyName}"
          // {
            default = let
              value = resolvedOr "needsXwaylandSatellite";
            in
              if value != null
              then value
              else false;
          };
      }
      // optionalAttrs (scope == "core") {
        uwsm = mkOption {
          description = "UWSM configuration for ${prettyName}. Set to `null` to disable UWSM integration.";
          type = submodule {
            options = {
              enable =
                mkEnableOption "${prettyName} UWSM support."
                // {
                  default = let
                    choice = resolvedOr "uwsm";
                  in
                    if choice != null
                    then choice
                    else isWayland && enabledDefault;
                };
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
                default = bin.path;
              };
            };
          };
        };
      };
  in {
    inherit fields;
    args = {
      inherit module parent;
      registry = data;
    };
    options = module.set.options.module fields;
    config =
      if scope == "home"
      then let
        target = findFirst (path: hasAttrByPath path options) null [
          ["wayland" "windowManager" name]
          ["programs" name]
        ];
        hasSub = key: target != null && hasAttrByPath (target ++ [key]) options;
        homeCfg =
          optionalAttrs (hasSub "enable") {enable = mkDefault fields.enable.default;}
          // optionalAttrs (hasSub "package") {inherit (cfg) package;};
      in
        mkMerge [
          (opt {enable = mkDefault fields.enable.default;})
          (opt {
            protocol = mkDefault fields.protocol.default;
            session = mkDefault fields.session.default;
            greeter = mkDefault fields.greeter.default;
            frontend = mkDefault fields.frontend.default;
            needsXwaylandSatellite = mkDefault fields.needsXwaylandSatellite.default;
          })
          (optionalAttrs (target != null && homeCfg != {}) (setAttrByPath target homeCfg))
        ]
      else let
        target = findFirst (path: hasAttrByPath path options) null [
          ["wayland" "windowManager" name]
          ["programs" name]
        ];
        hasSub = key: target != null && hasAttrByPath (target ++ [key]) options;
      in
        mkMerge [
          (opt {
            enable = mkDefault fields.enable.default;
            protocol = mkDefault fields.protocol.default;
            session = mkDefault fields.session.default;
            greeter = mkDefault fields.greeter.default;
            frontend = mkDefault fields.frontend.default;
            needsXwaylandSatellite = mkDefault fields.needsXwaylandSatellite.default;
          })
          (mkIf (cfg.enable or false) (
            if hasSub "enable"
            then setAttrByPath (target ++ ["enable"]) cfg.enable
            else {}
          ))
          (mkIf (cfg.enable or false) (
            if hasSub "package"
            then setAttrByPath (target ++ ["package"]) cfg.package
            else {}
          ))
          (mkIf ((cfg.enable or false) && cfg.protocol == "wayland" && (cfg.uwsm.enable or false)) {
            programs.uwsm = {
              enable = true;
              waylandCompositors.${name} = with cfg.uwsm; {
                prettyName = name;
                comment = description;
                binPath = binary;
              };
            };
          })
        ];
  };

  inner = mkModules (args
    // {
      base = ./.;
      excludes = [];
      declareRegistry = false;
      childPath = path;
      extraArgs = {
        mkArgs = {
          config,
          options ? {},
          path,
          pkgs ? {},
          scope ? "core",
          osConfig ? config,
          defaults ? {},
        }: let
          mod = mkMod {inherit config options path pkgs scope;};
          initiated = mod.args.module;
          evaluated = {inherit (mod) options config;};
          api =
            if scope == "home"
            then (backendApiFor host initiated.get.name) // (backendApiFor initiated.user initiated.get.name)
            else backendApiFor host initiated.get.name;
          cfgOr = key:
            attrByPath
            ([top] ++ path ++ [key]) (defaults.${key} or null)
            osConfig;
          apiOr = key:
            api.${key} or (defaults.${key} or null);
        in
          initiated
          // {
            inherit initiated evaluated cfgOr apiOr;
            inherit (initiated) get set;
          };

        mkEnable = {
          config,
          pkgs ? {},
          scope,
          path ? path',
          ...
        }:
          (mkMod {inherit config pkgs scope path;}).fields;
      };
    });
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
