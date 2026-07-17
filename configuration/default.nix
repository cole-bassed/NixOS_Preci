{lix, ...} @ args: let
  inherit (lix.modules) mkModules;
  moduleArgs = {
    base = ./.;
    excludes = [
      # "applications"
      # "base"
      "displays"
      # "interface"
      "secrets"
      "services"
    ];
  };
in
  mkModules (args // moduleArgs)
