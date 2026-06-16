{
  defaults ? {},
  flake ? {},
  names ? {},
  paths ? {},
}: let
  paths' = {
    src = paths.src or ../../.;
    libraries = {
      bootstrap = paths.libraries.bootstrap or(paths.bootstrap or ./bootstrap.nix);
      external = paths.libraries.external or  (paths.external or ./external);
      internal = paths.libraries.internal or  (paths.internal or ./.);
    };
  };
  bootstrap = import paths'.libraries.bootstrap;
  inherit (bootstrap.attrsets) recursiveAttrs removePaths;

  external = import paths'.libraries.external {
    inherit defaults flake names;
    paths = recursiveAttrs (paths paths');
  };

  internal = import ./internal {
    inherit defaults flake external names;
    paths = recursiveAttrs (paths paths');
  };
in
  removePaths (recursiveAttrs external internal) [
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
