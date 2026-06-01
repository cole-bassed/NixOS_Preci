{
  inputs,
  host,
  top,
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) attrValues mapAttrs;
  inherit (lib.lists) concatMap;
  inherit (lix.lists) asList;
  inherit (lix.modules) collectUserSpecs getUsers mkCdAliases mkEnvVars;

  hostUsers = getUsers host.users;
  normalUsers = hostUsers.byRole.normal.values;
  adminUsers = hostUsers.byRole.administrator.values;
in {
  imports =
    [inputs.home-manager.nixosModules.home-manager]
    ++ concatMap
    (user:
      concatMap (spec: asList (spec.core or null))
      (collectUserSpecs {
        inherit user;
        args = {inherit top host inputs lix;};
      }))
    (attrValues normalUsers);

  users.users =
    mapAttrs (_: user: {
      inherit (user) description;
      isNormalUser = (user.role or "") != "service";
      autoLogin = user.autoLogin or false;
      extraGroups =
        if user.role == "administrator"
        then ["networkmanager" "wheel"]
        else if user.role == "service"
        then ["networkmanager"]
        else [];
    })
    hostUsers.values;

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
    extraSpecialArgs = {inherit inputs lix top host;};
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
            args = {inherit top host inputs lix;};
          });
      })
      normalUsers;
  };
}
