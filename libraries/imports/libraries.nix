{
  bootstrap,
  attrsets,
  paths,
  excludes,
  ...
}: let
  exports = {
    scoped = {
      inherit classified normalized excluded;
      default = merged;
    };
  };

  inherit (bootstrap) inputs;
  inherit (attrsets) asAttrsIf mapAttrs filterAttrs;

  excluded = excludes.libraries or [];
  classified =
    mapAttrs
    (_: input: input.lib)
    inputs.classified.libraries;

  treefmt = inputs.normalized.treefmt or {};

  normalized =
    (
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
      asAttrsIf
      (treefmt ? lib)
      {treefmt = treefmt.lib // {projectRoot = paths.store.src;};}
    );

  merged =
    normalized.nixpkgs
    // classified
    // normalized;
in
  exports
