{
  api,
  attrsets,
  environment,
  lists,
  ...
}: let
  exports = {
    scoped = {
      inherit
        mkSrc
        mkHomeUser
        mkHomeUsers
        mkCoreUsers
        mkSudoRules
        ;
    };
    global = {
      inherit
        mkSrc
        mkHomeUser
        mkHomeUsers
        mkCoreUsers
        mkSudoRules
        ;
    };
  };

  inherit
    (attrsets)
    attrValues
    mapAttrs
    optionalAttrs
    ;
  inherit (api) getEnabledUsers getNormalUsers getAdminUsers;
  inherit (environment) mkSrc;
  inherit (lists) asList;

  homeOf = user:
    user.homeDirectory or user.home or "/home/${user.name}";

  mkCoreUsers = host: let
    principals = getEnabledUsers host;

    #| Role-based user classification
    #  administrator → full system access (wheel, networkmanager)
    #  normal        → standard interactive user (networkmanager)
    #  guest         → limited access, no extra groups
    #  service       → system daemon account (no login)
    roleOf = user: user.role or "normal";
    isAdmin = role: role == "administrator";
    isGuest = role: role == "guest";
    isService = role: role == "service";
  in {
    users =
      mapAttrs (_: user: let
        role = roleOf user;
      in {
        inherit (user) description;
        home = homeOf user;
        group = user.group or user.name;

        #| NixOS user type classification
        isNormalUser = !isService role;
        isSystemUser = isService role;

        #| Supplementary groups based on role privileges
        extraGroups =
          if isService role
          then []
          else if isGuest role
          then []
          else if isAdmin role
          then ["wheel" "networkmanager"]
          else ["networkmanager"];
      })
      principals;

    groups = mapAttrs (_: _: {}) principals;
  };

  mkHomeUsers = host:
    mapAttrs (
      name: user:
        mkHomeUser {
          inherit name;
          spec = user;
        }
    )
    (getNormalUsers host);

  mkHomeUser = {
    name,
    spec,
  }: {osConfig, ...}: {
    imports =
      [
        {
          _module.args.user = spec // {inherit name;};
          programs.home-manager.enable = true;
        }
        (
          optionalAttrs
          (osConfig ? system.stateVersion)
          {home = {inherit (osConfig.system) stateVersion;};}
        )
      ]
      ++ asList (spec.imports or []);
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
    }) (attrValues (getAdminUsers host));
in
  exports
