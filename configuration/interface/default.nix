{lix, ...} @ args:
lix.importModules (
  args
  // {
    base = ./.;

    excludes = [
      "_"
      "browsers"
      "control"
      "default"
      "gaming"
      "keyd"
    ];

    extraArgs = (args.extraArgs or {}) // {registry = import ./_.nix;};
  }
)
