{flake ? {}, ...}: let
  # -----------------------------------------------------------------------
  # TODO: Update libraries/internal loaders to parse regular files (.nix).
  # Currently, file nodes are skipped by readDirAttrs or dropped by
  # importModule because it searches for a nested default.nix.
  # -----------------------------------------------------------------------
  names = {
    src = "dots";
    top = "dots";
    lib = "lix";
  };

  paths = {
    src = ./.;
    api = ./configuration/api;
    dbg = ./debug;
    documentation = ./documentation;
    configurations = ./configuration/modules;
    templates = ./templates;
    devShells = ./utilities/shells;
    utilities = ./utilities;
    secrets = ./configuration/secrets;
    libraries = ./libraries;
    bootstrap = ./libraries/bootstrap.nix;
  };

  bootstrap = import paths.bootstrap;
  inherit (bootstrap) getEnv recursiveUpdate;

  defaults = let
    base = {
      # ── Hybrid Host Resolution Loop ──────────────────────────────────────
      # Order of priority:
      # 1. Explicitly passed flake argument
      # 2. Impure local environment discovery ($HOSTNAME or $NAME fallbacks)
      # 3. Safe baseline fallback configuration
      host = let
        envHost = getEnv "HOSTNAME";
        envName = getEnv "NAME";
      in
        if flake ? currentHost && flake.currentHost != ""
        then flake.currentHost
        else if envHost != ""
        then envHost
        else if envName != ""
        then envName
        else "ExampleHost";
      # ─────────────────────────────────────────────────────────────────────

      excludes = {
        paths = [
          "archive"
          "backup"
          "review"
          "temp"

          "default.nix"
          "flake.nix"
        ];
      };

      tags = ["core" "home"];
    };
  in
    recursiveUpdate base (flake.defaults or {});

  libraries = import paths.libraries {
    inherit bootstrap defaults paths names;
    inherit (flake) inputs root;
  };
  inherit (libraries) api;
in
  libraries.orEmptyAttrs libraries.flake
  // libraries.mkDots paths api.hosts.${defaults.host}
  // {
    inherit api defaults libraries names paths;
    "${names.lib}" = libraries;
  }
