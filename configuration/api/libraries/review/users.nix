# TODO: Breakout into domains
{
  attrsets,
  lists,
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

  inherit (attrsets) attrNames genAttrs filterAttrs mapAttrs;
  inherit (lists) length;
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
in
  exports
