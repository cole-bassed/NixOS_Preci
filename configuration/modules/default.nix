{lix, ...} @ base: let
  inherit (lix.config) assemble;
  inherit (lix.modules) importModules;

  collected = importModules (base
    // {
      base = ./.;
      excludes = [
        "ai"
        "applications"
        "interface"
        "review"
        "default.nix"
        "flake.nix"
      ];
    });
in
  assemble.configurations base {
    modules = {
      core = collected.imports;
      home = collected.home-manager.sharedModules;
    };
  }
