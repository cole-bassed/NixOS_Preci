{
  lix,
  top,
  host,
  ...
} @ base: let
  inherit (lix.modules) importModules;
in
  importModules (base
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
    })
