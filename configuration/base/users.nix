{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.users) mkCoreUsers mkSudoRules mkHomeUsers;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) attrsOf anything;

  data = host.users or {};

  opts = mkOption {
    type = attrsOf anything;
    default = {};
    description = "User account declarations. Overrides host.api default specifications.";
  };

  mkArgs = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};
in {
  core = {config, ...}: let
    inherit ((mkArgs config "core")) opt;
  in {
    options = opt opts;
    config = {
      ${top}.${dom}.${mod} = data;
      users = mkCoreUsers host;
      security.sudo = {
        execWheelOnly = true;
        extraRules = mkSudoRules host;
      };
      home-manager.users = mkHomeUsers host;
    };
  };

  home = {config, ...}: let
    inherit ((mkArgs config "home")) opt;
  in {
    options = opt opts;
    config = {
      ${top}.${dom}.${mod} = data;
    };
  };
}
