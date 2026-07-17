{lix, ...} @ args: let
  inherit (lix.modules) mkModules;
in
  mkModules (
    args
    // {
      base = ./.;
      recurse = true;
      extraArgs = args.extraArgs or {};
    }
  )
