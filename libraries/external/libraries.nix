{
  bootstrap,
  inputs,
  path,
  ...
}: let
  inherit (bootstrap) attrsets;
  inherit (attrsets) asIf filter maps orEmpty;

  classified = (
    maps
    (_: input: input.lib)
    inputs.classified.libraries
  );

  treefmt = orEmpty inputs.normalized.treefmt;

  normalized =
    (
      maps
      (_: input: input.lib)
      (
        filter
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
              inherit (builtins) tryEval;
              inherit (asserts) assertMsg;
              inherit (trivial) deepSeq;
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
          types =
            types
            // {
              inherit (filesystem) isPath;
              inherit (attrsets) isAttrs isDerivation;
              inherit (trivial) isBool isFloat isFunction;
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
            };
        };
    }
    // asIf (treefmt ? lib) {
      treefmt = treefmt.lib // {projectRoot = path;};
    };

  merged =
    normalized.nixpkgs
    // classified
    // normalized;
in {inherit classified normalized merged;}
