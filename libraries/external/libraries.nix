{
  bootstrap,
  inputs,
  path,
  ...
}: let
  inherit (bootstrap.attrsets) mapAttrs filterAttrs;
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
          ) ["types"];
        };
    }
    // (
      if (treefmt ? lib)
      then {treefmt = treefmt.lib // {projectRoot = path;};}
      else {}
    );

  merged =
    normalized.nixpkgs
    // classified
    // normalized;
in {
  inherit classified normalized merged;
  scoped = normalized;
  global = merged;
}
