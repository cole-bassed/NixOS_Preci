# TODO: Breakout into domains
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
      specs = users;
      admins = getAdminUsers;
      normalUsers = getNormalUsers;
      enabledUsers = getEnabledUsers;
      loginUsers = getInteractiveUsers;
    };

    global = {
      inherit
        getUsers
        getEnabledUsers
        getAdminUsers
        getNormalUsers
        getInteractiveUsers
        ;
    };
  };

  inherit (attrsets) attrNames listToAttrs genAttrs filterAttrs mapAttrs;
  inherit (lists) isList imap0 elemAt filter length;
  # inherit (specs) users;

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
in
  exports
