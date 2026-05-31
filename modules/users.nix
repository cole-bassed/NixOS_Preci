# modules/users/default.nix
{
  inputs,
  host,
  top,
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) concatMap;
  inherit (lix.lists) asList;
  inherit (lix.modules) collectUserSpecs getUsers mkCdAliases mkEnvVars;
  hostUsers = getUsers host;
in {
  imports =
    [inputs.home-manager.nixosModules.home-manager]
    # merge core specs from all normal users into system imports
    ++ concatMap
    (
      user:
        concatMap (spec: asList (spec.core or null))
        (collectUserSpecs {
          inherit user;
          args = {inherit top host inputs lix;};
        })
    )
    hostUsers.normal.values;

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
    hostUsers.all;

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
      (hostUsers.administrator.values);
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
            (let
              paths = config.${top}.paths or {};
            in {
              home = {
                inherit (osConfig.system) stateVersion;
                sessionVariables = mkEnvVars "" paths;
                shellAliases = mkCdAliases paths;
              };
              programs.home-manager.enable = true;
            })
          ]
          ++ concatMap
          (spec: asList (spec.home or null))
          (collectUserSpecs user);
      })
      (hostUsers.normal.raw);
  };
}
