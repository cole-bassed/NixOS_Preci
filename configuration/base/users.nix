{
  lix,
  top,
  host,
  ...
}: let
  inherit (lix.assembly) mkCoreUsers mkSudoRules mkHomeUsers;
  inherit (lix.options) mkOption;
  inherit (lix.types) attrsOf anything;
  inherit (lix) lib;

  data = host.users or {};

  mk = scope: _: {
    options.${top}.users = mkOption {
      type = attrsOf anything;
      default = {};
      description = "User account declarations. Overrides host.api default specifications.";
    };

    config =
      {${top}.users = data;}
      // (
        if scope == "core"
        then {
          users = mkCoreUsers host;
          security.sudo = {
            execWheelOnly = true;
            extraRules = mkSudoRules host;
          };
          home-manager.users = mkHomeUsers host;
        }
        else {}
      );
  };
in {
  core = mk "core";
  home = mk "home";
}
