{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) listOf str;

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;

    svcs = host.services or [];
    hasSvc = s: builtins.elem s svcs;
  in {
    options = opt {
      enable = mkEnableMod.true;
      items = mkOption {
        type = listOf str;
        default = svcs;
        description = "Additional services to enable.";
      };
    };

    config = mkIf enable (
      if scope == "core"
      then {
        services.tailscale = mkIf (hasSvc "tailscale") {
          enable = true;
          openFirewall = true;
        };

        # Streaming service placeholder (e.g., sunshine, moonlight, etc.)
        # services.sunshine = mkIf (hasSvc "streaming") { enable = true; openFirewall = true; };
      }
      else {}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
