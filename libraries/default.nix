{
  bootstrap ? import ./internal/base,
  defaults ? {},
  flake ? {},
  names ? {},
  paths ? {},
}: let
  inherit (bootstrap.attrsets) merge removePaths;

  external = import ./external {
    inherit bootstrap defaults flake names paths;
  };

  internal = import ./internal {
    inherit bootstrap defaults external names paths;
  };
in
  removePaths (merge external internal) [
    {
      scopes = [
        "lib"
        "lists"
        "modules"
      ];
      items = [
        "applyModuleArgsIfFunction"
        "collectModules"
        "dischargeProperties"
        "evalOptionValue"
        "fold"
        "isInOldestRelease"
        "mergeModules'"
        "mergeModules"
        "mkAliasOptionModuleMD"
        "mkFixStrictness"
        "nixpkgsVersion"
        "pushDownProperties"
        "unifyModuleSyntax"
      ];
    }
  ]
