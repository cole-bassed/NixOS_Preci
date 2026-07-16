{lix, ...} @ args: let
  inherit (lix.modules) mkModules;
  moduleArgs = {
    base = ./.;
    recurse = true;
    excludes = [
      "applications"
      "base"
      "displays"
      # "interface"
      "secrets"
      "services"
    ];
  };
in
  mkModules (args // moduleArgs)
