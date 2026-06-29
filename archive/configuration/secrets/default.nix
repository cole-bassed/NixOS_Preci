{lix, ...} @ args:
lix.importModules (
  args
  // {
    base = ./.;
    recurse = true;
    extraArgs = args.extraArgs or {};
  }
)
