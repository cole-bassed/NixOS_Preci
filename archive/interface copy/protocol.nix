{
  lix,
  top,
  path,
  ...
} @ args: let
  inherit (lix.attrsets) optionalAttrs;
  inherit (lix.modules) mkIf mkModuleArgs;
  inherit (lix.options) mkOption;
  inherit (lix.types) enum listOf package nullOr;

  mk = scope: {
    config,
    pkgs,
    ...
  }: let
    mod = mkModuleArgs (args // {inherit config pkgs scope;});
    inherit (mod) get set;
    inherit (get) cfg;
    policy = get.config.custom.interface.policy or {};
  in {
    options = set.opt {
      name = mkOption {
        type = nullOr (enum ["x11" "wayland"]);
        default = policy.default.protocol or null;
        description = "Protocol used by the interface (x11 or wayland). Defaults to the resolved default session's protocol.";
      };
      packages = mkOption {
        type = listOf package;
        default = [];
        description = "Packages required to support the selected protocol.";
      };
    };

    config = mkIf (cfg.enable or false) (optionalAttrs (scope == "core") {
      services.xserver.enable = (cfg.name or "wayland") == "x11";
    });
  };
in {
  core = mk "core";
  home = mk "home";
}
