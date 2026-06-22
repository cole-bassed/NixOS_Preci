{
  attrsets,
  lists,
  paths,
  ingestion,
  ...
}: let
  exports = {
    scoped = {
      inherit hosts users;
      admins = getAdminUsers;
      normalUsers = getNormalUsers;
    };
    global = {
      hostSpecs = hosts;
      userSpecs = users;
      inherit getAdminUsers;
      inherit getNormalUsers;
    };
  };
  inherit (attrsets) attrNames attrValues listToAttrs genAttrs filterAttrs mapAttrs optionalAttrs;
  inherit (lists) asList concatLists isList imap0 elemAt filter length;
  inherit (ingestion) collectNamedSpecs;
  inherit (specs) users hosts;

  api = let
    base = paths.store.api or paths.api or ../../configuration/api;
    hosts = base + "/hosts";
    users = base + "/users";
  in {inherit hosts users;};

  collectSpecs = tags: base:
    collectNamedSpecs {
      inherit base tags;
      rekey = true;
      args = {inherit attrsets;};
    };

  specs = {
    hosts =
      mapAttrs
      (_: host: host // {users = resolveUsers host;})
      (collectSpecs "core" api.hosts);
    users = collectSpecs "home" api.users;
  };

  # TODO: Keep schema as a list — fix api.nix to convert list→attrset before processing
  getUsers = spec: let
    mkGroup = attrs: let
      names = attrNames attrs;
      values = mapAttrs (name: user:
        user
        // {
          inherit name;
          home = user.home or "/home/${name}";
          description = user.description or name;
        })
      attrs;
      count = length names;
    in {inherit names values count;};

    filterByStatus = status: attrs:
      filterAttrs (_: u: (u.enable or true) == (status == "enabled")) attrs;

    filterByRole = wantedRole: attrs:
      filterAttrs (
        _: u: let
          role = u.role or "";
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

    users = mapAttrs (_: u:
      {
        role = "user";
        enable = true;
      }
      // u)
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
    ).byRole.administrator.values;

  getNormalUsers = host:
    filterAttrs (_: user: (user.role or "") != "service")
    (
      if host.users ? values
      then host.users
      else getUsers host.users
    ).values;

  resolveUsers = host: let
    hostPath = "api/hosts/${host.name}";
    fail = msg: throw "${hostPath}: ${msg}";

    rawUsers = host.users or {};

    # Convert list → attrset, preserving first-element-as-primary
    declared =
      if isList rawUsers
      then
        listToAttrs (
          imap0 (
            i: user: let
              uName = user.name or (fail "user at index ${toString i} missing 'name'");
              uAttrs =
                removeAttrs user ["name"]
                // {
                  primary = user.primary or (i == 0); # first is primary
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
in
  exports
