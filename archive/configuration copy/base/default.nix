{lix, ...} @ args: let
  inherit (lix.modules) mkModules;
  moduleArgs = {base = ./.;};
in
  mkModules (args // moduleArgs)
