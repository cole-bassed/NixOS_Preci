{
  attrsets,
  environment,
  ingestion,
  lists,
  strings,
  ...
}: let
  exports = {
    scoped = {
      inherit
        getAll
        mkHomeUser
        collectImports
        mkHomeUsers
        mkCoreUsers
        mkSudoRules
        ;
      all = getAll;
      admins = getAdmins;
      nonService = getNonService;
      login = getNonService;
    };
    global = {
      inherit mkHomeUser mkHomeUsers mkSudoRules;
      collectHostImports = collectImports;
      mkHostUsers = mkCoreUsers;
      getUsers = getAll;
      getAdminUsers = getAdmins;
      getNonServiceUsers = getNonService;
    };
  };

  inherit
    (attrsets)
    namesOf
    valuesOf
    filterAttrs
    genAttrs
    mapAttrs
    listToAttrs
    optionalAttrs
    orEmpty
    ;
  inherit (environment) mkVariables mkCdAliases;
  inherit (lists) asList concatMap length;
  inherit (ingestion) collectNamedSpecs;
  inherit (strings) concat;

  getAll = spec: let
    mkGroup = attrs: let
      names = namesOf attrs;
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

  getAdmins = host:
    (
      if host.users ? values
      then host.users
      else getAll host.users
    ).byRole.administrator.values;

  getNonService = host:
    filterAttrs (_: user: (user.role or "") != "service")
    (
      if host.users ? values
      then host.users
      else getAll host.users
    ).values;

  mkCoreUsers = host: let
    principals =
      (
        if host.users ? values
        then host.users
        else getAll host.users
      ).values;
  in {
    users =
      mapAttrs (_: user: {
        inherit (user) description;
        group = user.group or user.name;
        isNormalUser = (user.role or "") != "service";
        isSystemUser = (user.role or "") == "service";
        extraGroups =
          if user.role == "administrator"
          then ["networkmanager" "wheel"]
          else if user.role == "service"
          then ["networkmanager"]
          else [];
      })
      principals;

    groups = mapAttrs (_: _user: {}) principals;
  };

  /**
  Generate Home Manager targets for all interactive users tracked by the host.
  */
  mkHomeUsers = {
    lib,
    host,
    dom,
    mod,
  }: let
    byName = collectNamedSpecs {
      args = {inherit host lib dom mod;};
      base = mod;
    };
  in
    mapAttrs (
      name: _user:
        mkHomeUser (byName.${name} or {})
    ) (getNonService host);

  /**
  UNIFIED RULE: Generates a Home Manager configuration layout for an individual user profile.
  Automatically merges system-wide flake paths with user-specific custom paths.
  */
  mkHomeUser = spec: {
    config,
    osConfig,
    top,
    src,
    ...
  }: let
    paths = let
      flake = osConfig.${top}.paths.local or {};
      host = listToAttrs (map (name: {
        name = concat "_" [src.name name];
        value = flake.${name};
      }) (namesOf flake));
      user = orEmpty spec.paths;
    in {
      inherit host user;
      merged = host // user;
      resolved = config.${top}.paths.local;
    };
  in {
    imports =
      [
        {
          ${top}.paths.local = paths.merged;
          home = {
            sessionVariables = mkVariables paths.config;
            shellAliases = mkCdAliases paths.config;
          };
          programs.home-manager.enable = true;
        }
        (
          optionalAttrs
          (osConfig ? system.stateVersion)
          {home = {inherit (osConfig.system) stateVersion;};}
        )
      ]
      ++ asList (spec.home or null);
  };

  mkSudoRules = host:
    map (user: {
      users = [user.name];
      commands = [
        {
          command = "ALL";
          options = ["SETENV" "NOPASSWD"];
        }
      ];
    }) (valuesOf (getAdmins host));

  /**
  Reads your active host users and injects their respective operating system core modules.
  */
  collectImports = {
    host,
    top,
    base,
  }: let
    byName = collectNamedSpecs {
      args = {inherit top host;};
      inherit base;
    };
  in
    concatMap (
      user: let
        spec = byName.${user.name} or {};
      in
        asList (spec.core or null)
    ) (valuesOf (getNonService host));
in
  exports
