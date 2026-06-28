{
  lix,
  top,
  host,
  dom,
  mod,
  pkgs,
  ...
}: let
  inherit (lix.attrsets) mapAttrsToList optionalAttrs;
  inherit (lix.options) mkModuleArgs mkOption mkEnableOption;
  inherit (lix.types) str nullOr attrsOf submodule;

  src = host.${mod} or {};

  cacheEntrySubmodule = submodule {
    options = {
      sub = mkOption {
        type = str;
        description = "Binary cache URL (substituter).";
      };
      key = mkOption {
        type = str;
        description = "Public signing key for verifying this cache.";
      };
    };
  };

  opts = {
    #? Schema S5. Stored/resolved here, but NOT wired to an overlay --
    #  enabling a nixpkgs-unstable overlay requires the unstable
    #  channel to be threaded through as a flake input/specialArg,
    #  which this module doesn't have visibility into.
    #TODO: wire this once the unstable input's plumbing into
    #  specialArgs (or an overlay in flake.nix) is settled.
    unstable = mkEnableOption "overlaying nixpkgs-unstable on top of the stable channel"
      // {default = src.unstable or false;};

    allowUnfree = mkEnableOption "unfree package licenses"
      // {default = src.allowUnfree or false;};

    kernel = mkOption {
      type = nullOr str;
      default = src.kernel or null;
      description = "NixOS kernel package attribute, e.g. \"linuxPackages_latest\".";
    };

    caches = mkOption {
      type = attrsOf cacheEntrySubmodule;
      default = src.caches or {};
      description = "Named binary-cache definitions, keyed by cache name.";
    };
  };

  mkArgs = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};
in {
  #? `packages.nix` is a `core`-only concern -- nixpkgs config, kernel
  #  selection, and binary caches are all system-level (NixOS), with
  #  no home-manager equivalent. `home` is a deliberate no-op kept
  #  for caller compatibility with the `{ core = ...; home = ...; }`
  #  import convention.
  core = {config, ...}: let
    inherit ((mkArgs config "core")) cfg opt;
  in {
    options = opt opts;
    config =
      {
        nixpkgs.config.allowUnfree = cfg.allowUnfree;
      }
      // optionalAttrs (cfg.kernel != null) {
        boot.kernelPackages = pkgs.${cfg.kernel};
      }
      // optionalAttrs (cfg.caches != {}) {
        nix.settings = {
          substituters = mapAttrsToList (_: cache: cache.sub) cfg.caches;
          trusted-public-keys = mapAttrsToList (_: cache: cache.key) cfg.caches;
        };
      };
  };

  home = {};
}
