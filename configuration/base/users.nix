{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs;
  inherit (lix.config) mkCoreUsers mkSudoRules mkHomeUsers;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) attrsOf nullOr str bool either listOf;

  mk = scope: {config, ...}: let
    initial = mkModuleArgs {inherit config top dom mod scope;};
    inherit (initial) cfg opt mkEnableMod;
    resolved = {
      inherit top dom mod;
      lib = lix;
      host = host // {inherit (cfg) users;};
      base = mod;
    };
    inherit (cfg) enable;
  in {
    options = opt {
      enable = mkEnableMod.true;
      users = mkOption {
        type = attrsOf (attrsOf (nullOr (either str bool (listOf str))));
        default = host.users or {};
        description = "User account declarations. Overrides host.api default specifications.";
      };
    };

    config = mkIf enable (
      optionalAttrs (scope == "core") {
        users = mkCoreUsers resolved.host;

        security.sudo = {
          execWheelOnly = true;
          extraRules = mkSudoRules resolved.host;
        };

        home-manager.users = mkHomeUsers resolved;
      }
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
