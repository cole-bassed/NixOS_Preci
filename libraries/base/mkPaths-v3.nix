{
  attrsets,
  paths ? {src = ./../../../.;},
  store ? paths.store or paths,
  local ? paths.local.src or paths.local or null,
}: let
  _name = "filesystem::mkPaths";

  inherit (builtins) attrNames concatMap foldl' head isAttrs isPath stringLength substring tail;
  inherit (attrsets) recursiveUpdate;

  hasPrefix = pre: str: let
    preLen = stringLength pre;
  in
    preLen <= stringLength str && substring 0 preLen str == pre;

  nest = path: value:
    if path == []
    then value
    else {${head path} = nest (tail path) value;};

  # Walk an arbitrarily nested attrset of paths/strings into a flat list
  # of { path :: [String]; value :: Path|String; } leaf entries. A node
  # is a leaf if its value isn't an attrset; an attrset's own `src` key
  # (if present) is also captured as a leaf at that branch's path.
  walk = prefix: node:
    if isAttrs node
    then concatMap (name: walk (prefix ++ [name]) node.${name}) (attrNames node)
    else [
      {
        path = prefix;
        value = node;
      }
    ];

  unwrapLocalSrc = l:
    if l == null
    then null
    else if isAttrs l
    then l.src or null
    else l;

  root = {
    path = store.src or store;
    asStr = toString root.path;
  };

  localRoot = let
    unwrapped = unwrapLocalSrc local;
  in
    if unwrapped == null
    then toString root.path
    else toString unwrapped;

  storeLeaves = walk [] store;

  # local-only extras (no `store` counterpart) can arrive nested under
  # `paths.local`, or directly via the `local` parameter when callers
  # pass `store`/`local` independently. Merge both if present.
  localExtrasRaw =
    (
      if isAttrs (paths.local or null)
      then removeAttrs paths.local ["src"]
      else {}
    )
    // (
      if isAttrs local
      then removeAttrs local ["src"]
      else {}
    );
  localExtraLeaves = walk [] localExtrasRaw;

  # Every store path is relative to the single top-level root, so the
  # stem is computed once, here, against that one root — no per-level
  # root-tracking needed. A value with no root prefix (absolute path
  # outside the project) has no stem and passes through unchanged.
  toStem = value: let
    str = toString value;
  in
    if hasPrefix root.asStr str
    then substring (stringLength root.asStr) (-1) str
    else null;

  storeTree =
    foldl' (acc: leaf: recursiveUpdate acc (nest leaf.path leaf.value)) {} storeLeaves;

  localTree = let
    fromStore =
      foldl' (
        acc: leaf: let
          stem = toStem leaf.value;
          localValue =
            if stem == null
            then toString leaf.value
            else localRoot + stem;
        in
          recursiveUpdate acc (nest leaf.path localValue)
      ) {}
      storeLeaves;

    fromExtras =
      foldl' (acc: leaf: recursiveUpdate acc (nest leaf.path (toString leaf.value))) {} localExtraLeaves;
  in
    recursiveUpdate fromStore fromExtras;
in
  assert if isAttrs paths
  then true
  else throw "${_name}: 'paths' argument must be an attribute set.";
  assert if (isPath store || isAttrs store)
  then true
  else throw "${_name}: 'store' must be a path literal or an attribute set containing file mappings.";
  assert !isAttrs store
  || (store ? src && isPath store.src)
  || throw "${_name}: 'store' set is missing a valid path for 'src'."; {
    store = storeTree;
    local = localTree;
  }
