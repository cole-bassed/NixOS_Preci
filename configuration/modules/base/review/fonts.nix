{
  lix,
  top,
  host,
  dom,
  mod,
  pkgs,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) bool;

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;
  in {
    options = opt {
      enable = mkEnableMod.true;
      console = mkOption {
        type = bool;
        default = true;
        description = "Enable enhanced console fonts.";
      };
      kmscon = mkOption {
        type = bool;
        default = true;
        description = "Enable kmscon with custom fonts.";
      };
    };

    config = mkIf enable (
      if scope == "core"
      then {
        boot.kernelParams = mkIf cfg.console ["fbcon=font:TER16x32"];

        console = mkIf cfg.console {
          packages = [pkgs.terminus_font];
          font = "ter-v32n";
        };

        services.kmscon = mkIf cfg.kmscon {
          enable = true;
          hwRender = true;
          fonts = [
            {
              name = "Maple Mono NF";
              package = pkgs.maple-mono.NF;
            }
          ];
          extraConfig = "font-size=32";
          extraOptions = "--term xterm-256color";
        };
      }
      else {}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
