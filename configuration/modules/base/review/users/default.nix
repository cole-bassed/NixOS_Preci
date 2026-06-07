{
  inputs,
  host,
  top,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrValues filterAttrs mapAttrs;
  inherit (lib.lists) asList concatMap;
  inherit (lib.modules) collectUserSpecs getUsers mkCdAliases mkEnvVars;

  hostUsers =
    if host.users ? values
    then host.users
    else getUsers host.users;
  loginUsers = filterAttrs (_: user: (user.role or "") != "service") hostUsers.values;
  adminUsers = hostUsers.byRole.administrator.values;
in {
  imports =
    [inputs.home-manager.nixosModules.home-manager]
    ++ concatMap
    (user:
      concatMap (spec: asList (spec.core or null))
      (collectUserSpecs {
        inherit user;
        args = {inherit lib top host inputs;};
      }))
    (attrValues loginUsers);

  users.users =
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
    hostUsers.values;

  users.groups = mapAttrs (_: user: {}) hostUsers.values;

  security.sudo = {
    execWheelOnly = true;
    extraRules =
      map (user: {
        users = [user.name];
        commands = [
          {
            command = "ALL";
            options = ["SETENV" "NOPASSWD"];
          }
        ];
      })
      (attrValues adminUsers);
  };

  home-manager = {
    backupFileExtension = "BaC";
    # extraSpecialArgs = {inherit inputs  top host;};
    useGlobalPkgs = true;
    useUserPackages = true;
    users =
      mapAttrs (_: user: {
        config,
        osConfig,
        top,
        ...
      }: {
        imports =
          [
            {
              home = {
                inherit (osConfig.system) stateVersion;
                sessionVariables = mkEnvVars "" (config.${top}.paths or {});
                shellAliases = mkCdAliases (config.${top}.paths or {});
              };
              programs.home-manager.enable = true;
            }
          ]
          ++ concatMap
          (spec: asList (spec.home or null))
          (collectUserSpecs {
            inherit user;
            args = {inherit lib top host inputs;};
          });
      })
      loginUsers;
  };
}
