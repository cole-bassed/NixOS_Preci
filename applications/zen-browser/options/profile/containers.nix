{
  lib,
  top,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs bool;

  dom = "applications";
  mod = "zen-browser";
in {
  options.${top}.${dom}.${mod}.profile = {
    containersForce = mkOption {
      type = bool;
      default = true;
      description = "Whether to delete containers not declared in this module.";
    };

    containers = mkOption {
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
}
