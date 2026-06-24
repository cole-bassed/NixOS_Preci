{lix, ...} @ args:
lix.importModules (
  args
  // {
    base = ./.;
    extraArgs = (args.extraArgs or {}) // {registry = import ./_.nix;};

    # excludes = [
    #   "_"
    # ];
  }
)
