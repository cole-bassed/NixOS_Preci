{
  attrsets,
  defaults,
  lists,
  paths,
  ingestion,
  strings,
  ...
}: let
  exports = {
    scoped = {
      inherit hosts users displays getHostScopes;
      admins = getAdminUsers;
      normalUsers = getNormalUsers;
      enabledUsers = getEnabledUsers;
      loginUsers = getInteractiveUsers;
    };

    global = {
      hostAPI = hosts;
      userAPI = users;
      displayAPI = displays;
      inherit
        getUsers
        getEnabledUsers
        getAdminUsers
        getNormalUsers
        getHostScopes
        getInteractiveUsers
        ;
    };
  };

  inherit (attrsets) attrNames listToAttrs genAttrs filterAttrs mapAttrs mapAttrsToList;
  inherit (lists) asListIf elem foldl' head isList imap0 elemAt filter length sort unique;
  inherit (ingestion) collectNamedSpecs;
  inherit (strings) isString splitString toInt;
  inherit (specs) users displays;

  api = let
    base = paths.store.api or paths.api or ../.;
    hosts = base + "/hosts";
    users = base + "/users";
    displays = base + "/displays";
  in {
    inherit hosts users displays;
  };

  collectSpecs = {
    tags,
    base,
    includeFiles ? false,
  }:
    collectNamedSpecs {
      inherit base tags includeFiles;
      rekey = true;
      args = {inherit attrsets;};
    };

  specs = {
    hosts =
      mapAttrs
      (_: host:
        normalizeHost (
          host
          // {
            users = resolveUsers host;
            devices =
              host.devices or {}
              // {
                display = resolveDisplays host;
              };
          }
        ))
      (collectSpecs {
        tags = "core";
        base = api.hosts;
      });

    users = collectSpecs {
      tags = "home";
      base = api.users;
    };

    displays = collectSpecs {
      tags = "core";
      base = api.displays;
      includeFiles = true;
    };
  };

  hosts = let
    known = specs.hosts;
    fallback = known.${defaults.host} or known.${head (attrNames known)}; #! Fail if no hosts defined
    normalized = normalizeHost fallback;
  in
    known // {default = normalized;};

  normalizeHost = host: let
    arch = host.arch or "x86_64";
    os = host.os or "linux";
    class = host.class or "nixos";
    system = host.system or "${arch}-${os}";
  in
    host // {inherit arch os class system;};

  getUsers = spec: let
    mkGroup = attrs: let
      names = attrNames attrs;
      values =
        mapAttrs
        (name: user:
          user
          // {
            inherit name;
            # home = user.home or "/home/${name}";
            description = user.description or name;
          })
        attrs;
      count = length names;
    in {
      inherit names values count;
    };

    filterByStatus = status: attrs:
      filterAttrs
      (_: user: (user.enable or true) == (status == "enabled"))
      attrs;

    filterByRole = wantedRole: attrs:
      filterAttrs
      (
        _: user: let
          role = user.role or "";
          isNormal = role == "" || role == "user" || role == "normal";
        in
          if wantedRole == "normal"
          then isNormal
          else role == wantedRole
      )
      attrs;

    mkStatusIndex = attrs:
      genAttrs ["enabled" "disabled"] (status: let
        subset = filterByStatus status attrs;
      in
        (mkGroup subset) // {byRole = mkRoleIndex subset;});

    mkRoleIndex = attrs:
      genAttrs ["normal" "administrator" "service" "guest"] (role: let
        subset = filterByRole role attrs;
      in
        (mkGroup subset) // {byStatus = mkStatusIndex subset;});

    users =
      mapAttrs
      (_: user:
        {
          role = "user";
          enable = true;
        }
        // user)
      spec;
  in
    (mkGroup users)
    // {
      byStatus = mkStatusIndex users;
      byRole = mkRoleIndex users;
    };

  usersOf = host:
    if host.users ? values
    then host.users
    else getUsers host.users;

  getEnabledUsers = host:
    (usersOf host).byStatus.enabled.values;

  getAdminUsers = host:
    (usersOf host).byStatus.enabled.byRole.administrator.values;

  getNormalUsers = host:
    (usersOf host).byStatus.enabled.byRole.normal.values;

  getInteractiveUsers = host: let
    users = (usersOf host).byStatus.enabled.byRole;
  in
    users.administrator.values
    // users.normal.values
    // users.guest.values;

  resolveUsers = host: let
    hostPath = "api/hosts/${host.name}";
    fail = msg: throw "${hostPath}: ${msg}";

    rawUsers = host.users or {};

    declared =
      if isList rawUsers
      then
        listToAttrs (
          imap0
          (
            idx: user: {
              name =
                user.name or (
                  fail "user at index ${toString idx} missing 'name'"
                );
              value =
                removeAttrs user ["name"]
                // {primary = user.primary or (idx == 0);};
            }
          )
          rawUsers
        )
      else rawUsers;

    isSingleUser = length (attrNames declared) == 1;

    resolveUser = userName: config: let
      spec =
        specs.users.${userName}
        or (fail "user '${userName}' not found in api/users");

      defaults' = {
        role =
          if isSingleUser
          then config.role or "administrator"
          else "user";

        enable =
          if isSingleUser
          then config.enable or true
          else true;

        primary =
          if isSingleUser
          then config.primary or true
          else false;

        autoLogin = false;
      };
    in
      spec // defaults' // config;

    resolved = getUsers (mapAttrs resolveUser declared);

    primary = let
      enabled = resolved.byStatus.enabled;
      candidates =
        filter
        (n: enabled.values.${n}.primary or false)
        enabled.names;

      name =
        if enabled.count == 0
        then null
        else if length candidates == 0 && enabled.count == 1
        then elemAt enabled.names 0
        else if length candidates == 0
        then fail "expected exactly one primary enabled user, found none"
        else if length candidates > 1
        then fail "expected exactly one primary enabled user, found ${toString (length candidates)}"
        else elemAt candidates 0;
    in {
      inherit name;
      value =
        if name == null
        then null
        else enabled.values.${name};
    };
  in
    resolved // {inherit primary;};

  resolveDisplays = host: let
    hostPath = "api/hosts/${host.name}";
    fail = msg: throw "${hostPath}: ${msg}";
    raw = (host.devices or {}).display or [];

    cleanDisplay = display:
      removeAttrs display [
        "display"
        "monitor"
        "name"
        "output"
        "tags"
      ];

    parseSize = resolution: let
      parts = splitString "x" resolution;
    in {
      width = toInt (elemAt parts 0);
      height = toInt (elemAt parts 1);
    };

    parsePoint = position: let
      parts = splitString "x" position;
    in {
      x = toInt (elemAt parts 0);
      y = toInt (elemAt parts 1);
    };

    isPoint = position:
      isString position && length (splitString "x" position) == 2;

    resolveDisplay = idx: cfg: let
      output =
        cfg.output
      or (fail "display at index ${toString idx} missing 'output'");

      display =
        if cfg ? display || cfg ? monitor
        then let
          name =
            cfg.display or (cfg.monitor or (
              fail "display '${output}' missing 'display'"
            ));
        in
          displays.${name}
          or (fail "display '${output}' references unknown display '${name}'")
        else cfg;

      merged =
        cleanDisplay display
        // {
          enable = cfg.enable or true;
          priority = cfg.priority or idx;
          primary = cfg.primary or (idx == 0);
          position = cfg.position or "right";
        }
        // (removeAttrs cfg ["display" "monitor" "output"]);

      size =
        if merged.resolution != null
        then parseSize merged.resolution
        else {
          width = 0;
          height = 0;
        };
    in {
      name = output;
      value =
        merged
        // {
          layout = {
            inherit size;
            position = {
              x = 0;
              y = 0;
            };
          };
        };
    };

    resolved =
      if isList raw
      then listToAttrs (imap0 resolveDisplay raw)
      else
        mapAttrs
        (output: cfg:
          (resolveDisplay 0 (cfg // {inherit output;})).value)
        raw;

    ordered =
      sort
      (a: b: a.value.priority < b.value.priority)
      (mapAttrsToList (name: value: {inherit name value;}) resolved);

    leftWidth =
      foldl'
      (total: item:
        if item.value.position == "left"
        then total + item.value.layout.size.width
        else total)
      0
      ordered;

    topHeight =
      foldl'
      (total: item:
        if item.value.position == "top"
        then total + item.value.layout.size.height
        else total)
      0
      ordered;

    place = item: let
      display = item.value;
      inherit (display) position;

      point =
        if position == null
        then {
          x = 0;
          y = 0;
        }
        else if isPoint position
        then parsePoint position
        else if position == "left"
        then {
          x = 0;
          y = topHeight;
        }
        else if position == "right"
        then {
          x = leftWidth;
          y = topHeight;
        }
        else if position == "top"
        then {
          x = 0;
          y = 0;
        }
        else if position == "bottom"
        then {
          x = 0;
          y = topHeight;
        }
        else if position == "center"
        then {
          x = leftWidth;
          y = topHeight;
        }
        else fail "display '${item.name}' has invalid position '${position}'";
    in {
      inherit (item) name;
      value =
        display
        // {
          layout =
            (display.layout or {})
            // {
              position = point;
            };
        };
    };
  in
    listToAttrs (map place ordered);

  /**
  Derives the set of module-scope tags that are relevant for a given host.
  The result is passed to registry.aggregated.modules.${class}.select in
  assembly.nix, which returns only the modules whose flake.nix `scopes`
  field intersects with this set.

  Scope tag → what it enables (mirrors flake.nix inputs' scopes):

    > core            home-manager, nixpkgs infrastructure
    > infrastructure  nix-darwin, stable nixpkgs, nyx overlay
    > secrets         sops-nix
    > deployment      colmena options, disko disk layout
    > desktop         stylix, vicinae, zen-browser, and other UI inputs
    > ui              quickshell, caelestia, noctalia
    > theming         stylix
    > browser         zen-browser
    > launcher        vicinae
    > window-manager  niri, mango
    > shell           desktop shell inputs (dms, caelestia, noctalia)
    > development     vscode-server, rust-overlay, treefmt, hermes, llm-agents
    > code            rust-overlay, treefmt
    > language        rust-overlay
    > formatter       treefmt
    > editor          vscode-server
    > ai              hermes-agent, llm-agents
    > storage         disko (also covered by deployment)

  # Decision table:

    always             → core  infrastructure  secrets  deployment
    laptop / desktop   → desktop  ui  theming  browser  launcher
                         development  code  language  formatter  editor  ai
    + has WM or DE     → window-manager  shell
    + "storage" in     → storage
      functionalities
  */
  getHostScopes = host: let
    type = host.type or "desktop";
    isDesktop = type == "laptop" || type == "desktop";

    # Safe access in case interface is absent (e.g. TheOracle)
    iface = host.interface or {};
    wm = iface.windowManager or null;
    de = iface.desktopEnvironment or null;
    hasUI = isDesktop && (wm != null || de != null);

    funcs = host.functionalities or [];
  in
    unique (
      # ── Always required ──────────────────────────────────────────────────
      [
        "core"
        "infrastructure"
        "secrets"
        "deployment" # colmena / disko options needed on every managed host
      ]
      # ── Desktop / laptop only ────────────────────────────────────────────
      ++ (
        asListIf isDesktop [
          "ai"
          "browser"
          "code"
          "desktop"
          "development"
          "editor"
          "formatter"
          "language"
          "launcher"
          "theming"
          "ui"
        ]
      )
      # ── Compositor layer: only when a WM or DE is declared ───────────────
      ++ (asListIf hasUI ["window-manager" "shell"])
      # ── Block-device management ──────────────────────────────────────────
      ++ (asListIf (elem "storage" funcs) "storage")
    );
in
  exports
