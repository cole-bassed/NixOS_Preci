{
  api,
  assembly,
  defaults,
  attrsets,
  ingestion,
  flake,
  lists,
  modules,
  options,
  strings,
  types,
  names,
  ...
}: let
  exports = {
    scoped = {
      inherit mkModules mkModuleArgs mkCfg mkCfgIf mkOpt mkIf' mkProgramToggle mkAutostartCollector;
      ingest = mkModules;
      configure = mkModuleArgs;
    };
    global = {inherit mkModules mkModuleArgs mkCfgIf mkIf' mkProgramToggle mkAutostartCollector;};
  };

  inherit
    (attrsets)
    asAttrs
    foldMerge
    genAttrs
    hasAttr
    hasAttrByPath
    namesOf
    mapAttrs
    mapAttrsToList
    mkNamespaced
    asAttrsIf
    recursiveUpdate
    setAttrByPath
    valuesOf
    attrByPath
    isNotEmptyAttr
    ;
  inherit (ingestion) collectSpecs;
  inherit (lists) asList asListIf concatMap elem filter foldl' hasAny head init last optionals;
  inherit (types) attrs;
  inherit (assembly) mkBindings mkRegistryVariables;
  inherit (modules) mkIf mkMerge mkDefault mkForce;
  inherit (options) mkAppOption mkEnable mkOption;
  inherit (strings) concatStringsSep toSentenceCase;
  inherit (types) isList isNotEmpty isString str;

  mkModules = args @ {
    base,
    data ? (
      let
        domain =
          if path != []
          then (last path)
          else null;
      in
        args.extraArgs.registry or (
          asAttrsIf
          (domain != null && api ? ${domain}.registry)
          api.${domain}.registry
        )
    ),
    excludes ? null,
    extraArgs ? {},
    includeFiles ? true,
    includes ? [],
    path ? [],
    childPath ? path,
    recurse ? true,
    tags ? defaults.tags,
    top,
    declareRegistry ? isNotEmptyAttr data,
    ...
  }: let
    hasData = isNotEmptyAttr data && declareRegistry;

    specs = collectSpecs {
      inherit args base excludes includes tags includeFiles recurse;
      path = childPath;
      extraArgs =
        recursiveUpdate (args.extraArgs or {}) extraArgs
        // asAttrsIf hasData {registry = data;};
    };

    registryModule = {
      options = setAttrByPath ([top] ++ path ++ ["registry"]) (mkOption {
        type = attrs;
        default =
          mapAttrs
          (
            _: entry: let
              hasVars = entry ? variables;
              hasApps = entry ? applications;
              hasBinds = entry ? bindings;
              updates =
                asAttrsIf hasBinds {
                  bindings =
                    (mkBindings {
                      inherit (entry) bindings;
                      applications = entry.applications or {};
                    }).options;
                }
                // asAttrsIf hasApps {inherit (entry) applications;}
                // asAttrsIf hasVars {variables = mkRegistryVariables entry;};
            in
              entry // updates
          )
          data;
        readOnly = true;
      });
    };
    registryModules = asListIf hasData [registryModule];
  in {
    imports = (specs.core or []) ++ registryModules;
    home-manager.sharedModules = (specs.home or []) ++ registryModules;
  };

  mkCfg = {
    config,
    path,
  }:
    attrByPath (asList path) {} config;

  mkOpt = {
    options,
    path,
  }:
    setAttrByPath (asList path) options;

  mkCfgIf = {
    cfg,
    condition ? cfg.enable or false,
  }: args:
    mkIf condition (
      if isList args
      then mkMerge args
      else args
    );

  mkIf' = cfg: condition: args:
    mkCfgIf {inherit cfg condition;} args;

  /**
  Shared shape for "this app has a Home Manager `programs.<name>`
  module and should be enabled/disabled/pinned to a package by the
  dots-level toggle" -- which is nearly every entry under
  configuration/applications/*, regardless of whether it autostarts,
  runs as a systemd service, or is just a CLI tool.

  Deliberately does NOT touch compositor exec-once / spawn-at-startup.
  Autostart is cross-cutting orchestration, not a per-app concern: if
  every app module independently appends to
  `wayland.windowManager.hyprland.settings.exec-once`, you get an
  implicit, unordered, hard-to-reason-about merge across independently
  authored files. Instead this only exposes an `autostart` bool (off
  by default) plus the resolved `command` -- an interface/backend-level
  collector (see mkAutostartCollector below) reads those from every
  enabled app and assembles the actual exec-once list in one place.

    core: declares the option schema only (so `dots.<...>.enable` etc
          are settable/visible from NixOS-level config); no config
          output of its own.
    home: builds on `core`'s schema plus:
          - `programs.<name>.enable/package/systemd.enable` wiring,
            tracking the app's own `cfg.enable`
          - an `autostart` bool option (does nothing by itself --
            purely a signal for mkAutostartCollector to read)
          - `command`, resolved from the package via `set.bin` (not a
            separately-defaulted string that can drift from the
            actual binary), overridable per-app if the binary name
            genuinely differs from the package's main program.

  extraOptions / extraHomeConfig let a specific app bolt on fields or
  config this shape doesn't cover, without forking the whole file
  back into a hand-rolled `mk`.
  */
  mkProgramToggle = {
    top,
    path,
    program ? null, #? attr name under `programs.`; defaults to the module's own name
    command ? null, #? override for the resolved binary name/path (see set.bin)
    systemdTracksEnable ? true, #? false to leave systemd.enable independently defaulted off
    supportsAutostart ? true, #? false to omit the `autostart` option entirely (app has no sensible startup command)
    extraOptions ? (_mod: {}), #? mod -> extra option attrs, merged into `app`
    extraHomeConfig ? (_mod: {}), #? mod -> extra HM config, mkMerge'd alongside toggle wiring
  }: {
    core = {
      config,
      pkgs,
      options,
      ...
    }: let
      mod = mkModuleArgs {inherit config top path pkgs options;} // {scope = "core";};
    in {
      options = mod.opt (mod.app // extraOptions mod);
      config = {};
      imports = [];
    };

    home = {
      config,
      pkgs,
      options,
      ...
    }: let
      mod = mkModuleArgs {
        inherit config top path pkgs options;
        scope = "home";
      };
      inherit (mod) cfg get set;

      program' =
        if program != null
        then program
        else get.names.name;
      bin = set.bin {
        module = program';
        package = get.package;
      };
      resolvedCommand =
        if command != null
        then command
        else bin.name;
    in {
      options = set.opt (
        set.app
        // extraOptions mod
        // asAttrsIf supportsAutostart {
          autostart =
            (mkEnable {name = "${get.prettyName} autostart";}).false;
        }
      );

      config = mkIf cfg.enable (mkMerge [
        {
          programs.${program'} = {
            enable = mkForce cfg.enable;
            package = mkForce cfg.package;
            systemd.enable =
              if systemdTracksEnable
              then mkForce cfg.enable
              else mkDefault false;
          };
        }
        (extraHomeConfig (mod
          // {
            command = resolvedCommand;
            inherit bin;
          }))
      ]);
    };
  };

  # ---------------------------------------------------------------------
  # mkAutostartCollector
  #
  # Orchestration-level counterpart to mkProgramToggle's `autostart`
  # option. Meant to be called once from the interface/compositor-backend
  # layer (e.g. configuration/interface/hyprland or .../niri), not from
  # individual application modules.
  #
  # Given the fully-resolved `dots.applications.*` config tree, walks
  # every app, keeps the ones with `autostart = true` and `enable =
  # true` and a resolved `command`, and returns the assembled command
  # list -- so there is exactly one place that builds the exec-once /
  # spawn-at-startup list, instead of N independently authored app
  # modules each appending to it.
  #
  # `apps` is expected to be the attrset of per-app config under
  # whatever top-level namespace your applications live at (e.g.
  # `config.dots.applications`), where each value may or may not have
  # `enable`/`autostart`/`command` fields (apps built without
  # mkProgramToggle, or with supportsAutostart = false, simply won't
  # match and are skipped).
  #
  # Returns just a list of command strings, in `apps` attrset order
  # (i.e. alphabetical, since Nix attrsets are). If you need explicit
  # ordering (e.g. bar before notification daemon), that's a reason to
  # extend this with a priority field later -- not something to solve
  # by going back to per-app exec-once mutation.
  # ---------------------------------------------------------------------
  mkAutostartCollector = apps: let
    eligible =
      filter
      (entry:
        (entry.enable or false)
        && (entry.autostart or false)
        && (entry.command or null) != null)
      (valuesOf apps);
  in
    map (entry: entry.command) eligible;

  mkModuleArgs = {
    config ? {}, #? We usually want this
    host ? api.hosts.default,
    hostPath ? path,
    extraArgs ? {},
    options ? {}, #? We usually want this
    osConfig ? {},
    path,
    pkgs ? null, #? We usually want this
    scope ? "core",
    selection ? null,
    top ? null,
    userPath ? path,
    users ? api.users.getInteractiveUsers host,
    ...
  }: let
    targets = [
      "main" #? top-level config
      "custom" #? dots
      "domain" #? applications, interface, etc
      "parent"
      "module"
    ];

    get = {
      inherit host scope users;

      names = let
        base =
          if isNotEmpty top
          then top
          else names.src;
        raw =
          if path != []
          then last path
          else null;

        domain =
          if path != []
          then head path
          else null;

        registry =
          if domain != null
          then api.${domain}.registry or {}
          else {};

        collect = {
          name ? null,
          keys ? [],
          set ?
            asAttrsIf
            (isNotEmpty name && registry ? ${name})
            (registry.${name}),
        }:
          concatMap
          (key: asListIf (set ? ${key}) set.${key})
          (asList keys);

        collectPrefix = {
          name ? canonical,
          categories ? [],
        }: let
          #? Prioritized cascades of potential prefixes
          known =
            if hasAny ["greeter" "display-manager"] categories
            then [["services" "displayManager"] ["services"]]
            else if
              hasAny [
                "window-manager"
                "compositor"
                "desktop-manager"
                "backend"
              ]
              categories
            then
              if scope == "home"
              then [
                ["wayland" "windowManager"]
                ["programs"]
                ["services"]
              ]
              else [
                ["programs"]
                ["services" "desktopManager"]
                ["services" "xserver" "windowManager"]
                ["services"]
              ]
            else if hasAny ["service" "daemon"] categories
            then [["services"] ["programs"]]
            else [["programs"] ["services"]];

          #> Check which option path actually exists in the active scope tree
          valid =
            filter
            (prefix: hasAttrByPath (prefix ++ [name]) options)
            known;
        in
          if valid != []
          then head valid
          else head known;

        collectAliases = name:
          collect {
            inherit name;
            keys = ["alias" "aliases"];
          };
        collectCategories = name:
          collect {
            inherit name;
            keys = ["category" "categories"];
          };

        canonical =
          if registry ? ${raw}
          then raw
          else let
            matchingKeys = filter (name:
              (name == raw)
              || (elem raw (collectAliases name)))
            (namesOf registry);
          in
            if matchingKeys != []
            then head matchingKeys
            else raw;

        leaf = api.${domain}.aliases.${canonical} or canonical;

        entry = let
          item = registry.${canonical} or {};
          categories = collectCategories item;
          aliases = collectAliases item;
          prefix = collectPrefix {inherit categories;};
        in {
          inherit categories aliases prefix;
          raw = item.entryPoints.${scope} or (item.entryPoint or null);
          path =
            if entry.raw != null
            then asList entry.raw
            else prefix ++ [canonical];
          name =
            if entry.path != []
            then last entry.path
            else canonical;
        };
      in
        genAttrs targets (
          target: let
            check = get.paths.validate target;
          in
            if check != []
            then last check
            else "main"
        )
        // {
          inherit base raw leaf entry;
          name = canonical;
          user =
            get.config.main.home.username or (
              get.config.custom.users.primary.name or null
            );
          pretty = set.name {pretty = true;};
          package = get.pkg.name or null;
        };
      prettyName = get.names.pretty;
      inherit (get.names) name aliases alias;

      paths = let
        inherit (get.names) leaf;

        path' =
          if path == []
          then path
          else (init path) ++ [leaf];
      in {
        validate = target:
          if elem target targets
          then get.paths.${target}
          else
            throw "Invalid target: '${target}'. Valid targets are: ${
              concatStringsSep ", " targets
            }";
        main = [];
        custom = [get.names.base];
        module = get.paths.custom ++ path';
        parent = init get.paths.module;
        domain = get.paths.custom ++ [(head path')];
      };

      user = let
        name = get.names.user;
      in
        asAttrsIf
        (name != null)
        ((users.${name} or {}) // {inherit name;});

      top =
        if top != null
        then top
        else get.names.custom;

      config =
        genAttrs targets
        (target: set.config {inherit target;});
      cfg = get.config.module;
      cfgOr = key: let
        fromConfig = attrByPath (get.paths.module ++ [key]) null config;
      in
        if fromConfig != null
        then fromConfig
        else
          attrByPath
          (get.paths.module ++ [key]) (extraArgs.${key} or null)
          osConfig;

      options =
        genAttrs targets
        (target: attrByPath (get.paths.validate target) {} options);

      enabled = {
        criteria ? elem (host.type or "laptop") ["desktop" "laptop"],
        selectFrom ? set.selection,
      }: let
        materialize = selected:
          mapAttrs
          (_: extra: {enable = true;} // extra)
          (foldMerge selected);

        required = let
          byHost = [(selectFrom host)];
          byUser =
            optionals
            criteria
            (map selectFrom (valuesOf users));
        in {
          core = materialize (byHost ++ byUser);
          home =
            materialize
            (byHost ++ (optionals criteria [(selectFrom get.user)]));
        };
      in
        hasAttr get.name required.${scope};

      # Compositor presence, resolved once here so callers (and helpers
      # like mkProgramToggle) don't each re-derive it, and so detection
      # stays consistent (option-tree existence, not a config flag that
      # may not be set yet).
      hasHypr =
        config ? programs.hyprland
        || config ? wayland.windowManager.hyprland;
      hasNiri = config ? programs.niri;

      pkg = let
        override = get.apiOr "package";

        specs = {
          override =
            if override == null
            then null
            else attrByPath (asList override) null pkgs;

          fallback =
            if pkgs != null
            then let
              candidates =
                get.names.aliases
                ++ [get.names.raw]
                ++ (
                  asListIf
                  (get.names.leaf != null && get.names.leaf != get.names.raw)
                  get.names.leaf
                );

              fromPkgs =
                foldl'
                (found: candidate:
                  if found != null
                  then found
                  else if isString candidate
                  then pkgs.${candidate} or null
                  else null)
                null
                candidates;

              fromFlake =
                if fromPkgs != null
                then null
                else
                  foldl'
                  (found: candidate:
                    if found != null
                    then found
                    else if isString candidate && flake ? registry.${candidate}
                    then let
                      registryFlake = flake.registry.${candidate};
                      system = pkgs.stdenv.hostPlatform.system or "x86_64-linux";
                    in
                      if registryFlake ? packages.${system}
                      then registryFlake.packages.${system}.${candidate} or
                        (registryFlake.packages.${system}.default or null)
                      else null
                    else null)
                  null
                  candidates;
            in
              if fromPkgs != null
              then fromPkgs
              else fromFlake
            else null;
        };

        resolved = {
          path =
            if override != null
            then asList override
            else asList get.names.name;
          name = last resolved.path;
          spec =
            if specs.override != null
            then specs.override
            else specs.fallback;
        };
      in {inherit (resolved) path name spec;};
      package = get.pkg.spec;

      hostEntry = attrByPath hostPath {} host;
      userEntry = attrByPath userPath {} get.user;
      # Resolved HM option-tree path for this app's entry point (e.g.
      # ["programs" "dank-material-shell"], or ["wayland" "windowManager"
      # "hyprland"] for compositor-shaped entries). Prefer this over
      # hand-rolling ["programs" name] in app modules -- it accounts for
      # registry-declared entryPoints overrides and the category-based
      # prefix cascade above.
      entryPath = get.names.entry.path;
      dataEntry = genAttrs targets (
        target: let
          domain = head path;
          name = get.names.leaf;
          registry =
            if target == "module"
            then api.${domain}.registry.${name} or {}
            else if target == "parent"
            then api.parent.registry or {} # TODO: Not tested
            else if target == "domain"
            then api.${domain}.registry or {}
            else if target == "custom"
            then api.custom.registry or {}
            else if target == "main"
            then api.main.registry or {}
            else {};
        in {
          inherit registry;
          names = namesOf registry;
          values = valuesOf registry;
        }
      );
      apiOr = key:
        get.hostEntry.${key} or
            (get.userEntry.${key} or
              (get.dataEntry.module.registry.${key} or
                (get.dataEntry.parent.registry.${key} or
                  (get.dataEntry.domain.registry.${key} or
                    (get.dataEntry.custom.registry.${key} or
                      (get.dataEntry.main.registry.${key} or null))))));
    };

    set = {
      config = {
        target ? "module",
        extra ? {},
      }: let
        targetPath = get.paths.validate target;
      in
        attrByPath targetPath {} (
          recursiveUpdate config
          (setAttrByPath targetPath extra)
        );

      options =
        genAttrs
        targets (target: extra: setAttrByPath (get.paths.validate target) extra);
      opt = set.options.module;
      app = mkAppOption get;

      name = {
        name ? get.names.module,
        pretty ? true,
      }:
        if pretty
        then toSentenceCase name
        else name;
      enable = {default ? false}:
        mkEnable {
          inherit (get) scope name;
          inherit default;
        };
      package = mkOption {
        type = with types; nullOr package;
        default = get.package;
        description = "Package backing the ${get.prettyName} compositor component.";
      };

      selection = spec:
        if selection != null
        then selection spec
        else asAttrs spec;

      bin = {
        module ? get.names.module,
        package ? get.package,
      }: let
        name =
          if package != null
          then package.NIX_MAIN_PROGRAM or module
          else module;
        path =
          if package != null
          then "/run/current-system/sw/bin/${module}"
          else null;
      in {inherit package name path;};

      frontend = tweaks: let
        inherit (get.config) custom;
        active = attrByPath ["interface" "frontend"] null custom;
      in
        mkIf (active != null) (
          mkMerge (
            mapAttrsToList (
              name: value:
                mkIf (active == name) {
                  ${get.names.custom}.applications.${name} = value;
                }
            )
            tweaks
          )
        );
    };
  in
    (mkNamespaced {inherit get set;})
    // get
    // {
      inherit get set;
      inherit (set) opt app;
      inherit (get) hasHypr hasNiri;
      mkCfg = spec: mkIf get.cfg.enable spec;
      mkOpt = spec: set.opt (set.app // spec);
    };
in
  exports
