{
  bootstrap,
  attrsets,
  flake,
  paths,
  excludes,
  ...
}: let
  exports = {
    scoped = {
      inherit classified normalized excluded hasLibraries merged;
      default = merged;
    };
    global = {inherit hasLibraries;};
  };
  inherit (bootstrap) inputs hasLibraries;
  inherit (attrsets) asAttrsIf mapAttrs filterAttrs removeAttrPaths;
  registry = flake.registry or {};
  registryLibraries =
    if registry ? libraries
    then mapAttrs (_: entry: entry.value) registry.libraries
    else {};

  excluded =
    excludes
    // {
      libraries =
        (excludes.libraries or [])
        ++ [
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
    };

  exclusions = [
    {
      scopes = ["lib" "lists" "modules"];
      items = excluded.libraries or [];
    }
  ];
  stripExclusions = libraries: removeAttrPaths libraries exclusions;

  classified =
    mapAttrs
    (_: input: input.lib)
    inputs.classified.libraries;

  normalized = stripExclusions (
    registryLibraries
    // (
      mapAttrs
      (_: input: input.lib)
      (
        filterAttrs
        (_: value: value != null && value ? lib)
        inputs.normalized
      )
    )
    // {
      nixpkgs = let
        lib = inputs.normalized.nixpkgs.lib or (import <nixpkgs/lib>);
        inherit (lib) asserts attrsets debug filesystem lists strings trivial types;
      in
        lib
        // {
          filesystem =
            filesystem
            // {
              inherit (trivial) pathExists;
              inherit (builtins) path;
            };
        }
        // {
          debug =
            debug
            // {
              inherit (builtins) seq tryEval;
              inherit (asserts) assertMsg;
              inherit (trivial) deepSeq;
              seqRecursive = trivial.deepSeq;
            };
        }
        // {
          lists =
            lists
            // (with lists; {
              firstList = findFirst;
              first = head;
              lastDropped = init;
              firstItem = head;
              lastItem = tail;
              itemFirst = head;
              itemLast = tail;
              itemIndexed = elemAt;
            });
        }
        // {
          types = removeAttrs (
            types
            // {
              inherit (filesystem) isPath;
              inherit (attrsets) isAttrs isDerivation;
              inherit (trivial) isBool isFloat isFunction isInOldestRelease;
              inherit
                (strings)
                isConvertibleWithToString
                isInt
                isList
                isStorePath
                isString
                isStringLike
                isValidPosixName
                typeOf
                ;
              type = strings.typeOf;
            }
            // bootstrap.types
          ) ["types"];
        };
    }
    // (
      let
        treefmt = inputs.normalized.treefmt or {};
      in
        asAttrsIf
        (treefmt ? lib)
        {treefmt = treefmt.lib // {projectRoot = paths.store.src;};}
    )
  );

  merged =
    stripExclusions
    (
      normalized.nixpkgs
      // classified
      // normalized
    );
in
  exports
