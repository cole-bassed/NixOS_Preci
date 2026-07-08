{
  lix,
  top,
  host,
  path,
  registry,
  selection,
  ...
} @ args: let
  inherit (lix.api) getInteractiveUsers;
  inherit (lix.attrsets) attrByPath attrNames attrValues foldMerge hasAttr hasAttrByPath mapAttrs optionalAttrs recursiveUpdate setAttrByPath;
  inherit (lix.lists) elemAt filter findFirst length;
  inherit (lix.modules) mkDefault mkIf mkMerge mkModules;
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) attrs enum nullOr package submodule;

  path' = path;

  aliases = {
    dms = "dank-material";
  };

  frontendValues = [
    "dms"
    "dank-material"
    "noctalia"
    "caelestia"
    "gnome"
    "plasma"
    "cosmic"
  ];

  normalize = frontend:
    if frontend == null
    then null
    else aliases.${frontend} or frontend;

  registryFrontendOf = spec: let
    backendNames = attrNames (selection spec);
    backend =
      if length backendNames > 0
      then elemAt backendNames 0
      else null;
    env =
      if backend != null
      then registry.${backend} or {}
      else {};
  in
    normalize (env.frontend or null);

  selectedFrontend = spec: normalize ((spec.interface or {}).frontend or (registryFrontendOf spec));

  materialize = selected:
    mapAttrs
    (_: extra: {enable = true;} // extra)
    (foldMerge (map (name: setAttrByPath [name] {}) (filter (name: name != null) selected)));

  required = let
    main = [
      (selectedFrontend host)
    ];
  in {
    core = materialize (main ++ map selectedFrontend (attrValues (getInteractiveUsers host)));
    home = user: materialize (main ++ [(selectedFrontend user)]);
  };

  activeBackendNames = attrNames (selection host);
  primaryBackend =
    if length activeBackendNames > 0
    then elemAt activeBackendNames 0
    else null;
  primaryEnv =
    if primaryBackend != null
    then registry.${primaryBackend} or {}
    else {};
  registryFrontend = registryFrontendOf host;
  isWayland = primaryEnv.protocol or null == "wayland";

  mkMod = {
    config,
    scope ? "core",
    pkgs,
    path ? path',
  }: let
    users = getInteractiveUsers host;
    module = mkModuleArgs {inherit top config path scope pkgs users;};
    inherit (module.get) name prettyName;
    opt = module.set.options.module;

    fields = {
      enable = mkEnable {
        inherit name scope;
        default =
          if scope == "home"
          then hasAttr name (required.home module.user)
          else hasAttr name required.core;
      };
      package = mkOption {
        type = nullOr package;
        default = attrByPath [name] (attrByPath ["${name}-shell"] null pkgs) pkgs;
        description = "Package backing the ${prettyName} frontend layer.";
      };
    };
  in {
    inherit fields;
    args = {inherit module;};
    options = module.set.options.module fields;
    config = mkMerge [
      (opt {enable = mkDefault fields.enable.default;})
      (mkIf (fields.package.default != null) (opt {package = mkDefault fields.package.default;}))
    ];
  };

  inner = mkModules (args
    // {
      base = ./.;
      excludes = [];
      declareRegistry = false;
      childPath = path;
      extraArgs = let
        buildChild = {
          config,
          options ? {},
          path,
          pkgs ? {},
          scope ? "core",
          osConfig ? config,
          defaults ? {},
        }: let
          mod = mkMod {inherit config path pkgs scope;};
          module = mod.args.module;
          cfgOr = key:
            attrByPath
            ([top] ++ path ++ [key]) (defaults.${key} or null)
            osConfig;
          enableTarget = {
            options,
            enabled,
            target ? null,
            targets ? [],
          }: let
            target' =
              if target != null
              then target
              else findFirst (candidate: hasAttrByPath candidate options) null targets;
            hasSub = key: target' != null && hasAttrByPath (target' ++ [key]) options;
            frontendCfg = optionalAttrs (hasSub "enable") {enable = enabled;};
          in
            optionalAttrs (target' != null && frontendCfg != {}) (setAttrByPath target' frontendCfg);
        in
          module
          // {
            inherit cfgOr enableTarget;
            inherit (mod) options config;
          };

        mkChild = {
          path,
          scope ? "core",
          target ? null,
          targets ? [],
          mkOptions ? (_: {}),
          extraConfig ? (_: {}),
        }: {
          config,
          options,
          pkgs,
          ...
        }: let
          child = buildChild {inherit config options path pkgs scope;};
          cfg = child.get.config.module;
          enabled = cfg.enable or (cfg.isRequired or false);
          extraOptions = mkOptions child;
        in {
          options =
            if extraOptions == {}
            then child.options
            else recursiveUpdate child.options (child.set.options.module extraOptions);
          config = mkMerge [
            child.config
            (child.enableTarget {inherit options enabled target targets;})
            (extraConfig {inherit child cfg enabled config options pkgs;})
          ];
        };
      in {
        inherit mkChild;
        mkArgs = buildChild;
      };
    });

  mk = scope: {config, ...}: let
    mod = mkModuleArgs {
      inherit config top scope;
      path = ["interface"];
    };
    opt = mod.set.options.module;
    cfg = mod.get.config.module;
  in {
    options = opt {
      frontend = mkOption {
        type = submodule {
          freeformType = attrs;
          options.selected = mkOption {
            type = nullOr (enum frontendValues);
            apply = normalize;
            default = normalize (host.interface.frontend or registryFrontend);
            description = "Graphical frontend layer for the selected desktop session backend. `dms` is accepted as an alias for `dank-material`.";
          };
        };
        default = {};
        description = "Graphical frontend configuration.";
      };
    };

    config.assertions = [
      {
        assertion = cfg.frontend.selected == null || primaryBackend != null;
        message = "interface.frontend requires an active interface.backend.";
      }
      {
        assertion = cfg.frontend.selected == null || isWayland;
        message = "The selected interface.frontend requires a Wayland session.";
      }
      {
        assertion = cfg.frontend.selected == null || cfg.frontend.selected == registryFrontend;
        message = "interface.frontend.selected (${toString cfg.frontend.selected}) doesn't match the frontend the registry declares for '${toString primaryBackend}' (${toString registryFrontend}).";
      }
    ];
  };
in {
  core.imports = (inner.imports or []) ++ [(mk "core")];
  home.imports = (inner.home-manager.sharedModules or []) ++ [(mk "home")];
}
