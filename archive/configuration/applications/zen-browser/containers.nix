{
  lib,
  mkArgs,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs bool;
in {
  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config scope;}) opt;
  in {
    options = opt {
      profile.containersForce = mkOption {
        type = bool;
        default = true;
        description = "Whether to delete containers not declared in this module.";
      };
      profile.containers = mkOption {
        type = attrs;
        default = {
          Personal = {
            color = "purple";
            icon = "fingerprint";
            id = 1;
          };
          Work = {
            color = "blue";
            icon = "briefcase";
            id = 2;
          };
          Shopping = {
            color = "yellow";
            icon = "dollar";
            id = 3;
          };
        };
        description = "Declarative Zen containers for the configured profile.";
      };
    };
  };
}
