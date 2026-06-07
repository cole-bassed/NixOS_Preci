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
  };

  defaults =
    {
      # ── Hybrid Host Resolution Loop ────────────────────────────────────────
      # Order of priority:
      # 1. Explicitly passed flake argument (e.g., via deployment wrappers)
      # 2. Impure local environment discovery ($HOSTNAME)
      # 3. Safe baseline fallback configuration
      host = let
        envHost = builtins.getEnv "HOSTNAME";
      in
        if flake ? currentHost && flake.currentHost != ""
        then flake.currentHost
        else if envHost != ""
        then envHost
        else "ExampleHost";
      # ───────────────────────────────────────────────────────────────────────

      # host = "example";
      # host = "ExampleHost";
      # host = "Preci";

      excludes = [
        "archive"
        "backup"
        "review"
        "temp"

        "default.nix"
        "flake.nix"
      ];

      tags = ["core" "home"];
    }
    // (flake.defaults or {});

  libraries = import paths.libraries {
    inherit defaults paths names;
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
