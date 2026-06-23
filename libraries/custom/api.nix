{
  attrsets,
  defaults,
  lists,
  paths,
  ingestion,
  ...
}: let
  exports = {
    scoped = {
      inherit hosts users displays;
      admins = getAdminUsers;
      normalUsers = getNormalUsers;
    };

    global = {
      hostAPI = hosts;
      userAPI = users;
      displayAPI = displays;
      inherit
        getAdminUsers
        getNormalUsers
        ;
    };
  };

  inherit (attrsets) attrNames listToAttrs genAttrs filterAttrs mapAttrs;
  inherit (lists) head isList imap0 elemAt filter length;
  inherit (ingestion) collectNamedSpecs;
  inherit (specs) users displays;

  api = let
    base = paths.store.api or paths.api or ../../configuration/api;
    hosts = base + "/hosts";
    users = base + "/users";
    displays = base + "/display";
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
            home = user.home or "/home/${name}";
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

  getAdminUsers = host:
    (
      if host.users ? values
      then host.users
      else getUsers host.users
    )
    .byRole
    .administrator
    .values;

  getNormalUsers = host:
    filterAttrs
    (_: user: (user.role or "") != "service")
    (
      if host.users ? values
      then host.users
      else getUsers host.users
    )
    .values;

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
            i: user: let
              uName = user.name or (fail "user at index ${toString i} missing 'name'");
              uAttrs =
                removeAttrs user ["name"]
                // {
                  primary = user.primary or (i == 0);
                };
            in {
              name = uName;
              value = uAttrs;
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

    resolveDisplay = idx: cfg: let
      output =
        cfg.output or (
          fail "display at index ${toString idx} missing 'output'"
        );

      displayName =
        cfg.display or cfg.monitor or (
          fail "display '${output}' missing 'display'"
        );

      display =
        displays.${
          displayName
        } or (
          fail "display '${output}' references unknown display '${displayName}'"
        );

      local = removeAttrs cfg ["display" "monitor" "output"];
    in {
      name = output;
      value =
        display
        // {
          priority = cfg.priority or idx;
          primary = idx == 0;
          position = cfg.position or "right";
        }
        // local;
    };
  in
    if isList raw
    then listToAttrs (imap0 resolveDisplay raw)
    else raw;
in
  exports
