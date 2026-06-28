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
  inherit (lix.types) nullOr bool str attrsOf;
  inherit (lix.attrsets) attrValues mapAttrs;

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;
  in {
    options = opt {
      enable = mkEnableMod.true;
      unstable = mkOption {
        type = bool;
        default = host.packages.unstable or false;
        description = "Whether to use nixpkgs-unstable as the primary package set.";
      };
      allowUnfree = mkOption {
        type = bool;
        default = host.packages.allowUnfree or false;
        description = "Whether to allow unfree packages.";
      };
      kernel = mkOption {
        type = nullOr str;
        default = host.packages.kernel or null;
        description = "Kernel package set to use (e.g., linuxPackages_cachyos-lto).";
      };
      caches = mkOption {
        type = attrsOf (attrsOf str);
        default = host.packages.caches or {};
        description = "Binary cache configurations.";
      };
    };

    config = mkIf enable (
      if scope == "core"
      then {
        nixpkgs.config.allowUnfree = cfg.allowUnfree;
        boot.kernelPackages =
          if cfg.kernel != null
          then cfg.kernel
          else config.boot.kernelPackages or pkgs.linuxPackages;
        nix.settings = {
          substituters = attrValues (mapAttrs (_: c: c.sub or c.url or "") cfg.caches);
          trusted-public-keys = attrValues (mapAttrs (_: c: c.key or "") cfg.caches);
        };
      }
      else {}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
