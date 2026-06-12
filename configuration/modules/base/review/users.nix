{
  lix,
  top,
  host,
  dom,
  mod,
  lib,
  inputs,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) attrsOf nullOr str bool either listOf;
  inherit (lix.attrsets) attrValues filterAttrs mapAttrs;
  inherit (lix.lists) asList concatMap;
  inherit (lix.config) collectUserSpecs mkCdAliases mkEnvVars;

  hostUsers =
    if host.users ? values
    then host.users
    else lib.getUsers host.users;
  loginUsers = filterAttrs (_: user: (user.role or "") != "service") hostUsers.values;
  adminUsers = hostUsers.byRole.administrator.values;

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;
  in {
    options = opt {
      enable = mkEnableMod.true;
      users = mkOption {
        type = attrsOf (attrsOf (nullOr (either str bool (listOf str))));
        default = host.users or {};
        description = "User account declarations.";
      };
    };

    config = mkIf enable (
      if scope == "core"
      then {
        imports =
          [inputs.home-manager.nixosModules.home-manager]
          ++ concatMap
          (user:
            concatMap (spec: asList (spec.core or null))
            (lib.collectUserSpecs {
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
          backupFileExtension = "backup";
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
      else {}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
