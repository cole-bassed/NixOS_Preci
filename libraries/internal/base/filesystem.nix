{
  paths,
  strings,
  ...
}: let
  exports = {
    scoped = {
      inherit bat mapStoreToLocal mkPaths;
      cat = readFile;
      ls = readDir;
      type = readFileType;
    };
    global = {
      inherit
        (builtins)
        baseNameOf
        currentSystem
        dirOf
        filterSource
        findFile
        path
        pathExists
        readDir
        readFile
        readFileType
        storeDir
        storePath
        toPath
        ;
    };
  };

  inherit
    (builtins)
    attrNames
    concatLists
    concatStringsSep
    filter
    isAttrs
    isPath
    isString
    lessThan
    mapAttrs
    path
    readDir
    readFile
    readFileType
    sort
    stringLength
    substring
    typeOf
    ;
  inherit (strings) hasPrefix quote split;

  /**
  Maps a set of pure store paths into absolute local path strings relative to local.src
  */
  mapStoreToLocal = {
    store ? (paths.store or ../../../.),
    local ? toString (store.src or ""),
  }:
    mapAttrs (_: path:
      concatStringsSep "" [
        local
        (
          substring
          (stringLength (toString (store.src or "")))
          (-1)
          (toString path)
        )
      ])
    store;

  mkPaths = {
    paths ? {src = ./../../../.;},
    store ? paths.store or paths,
    local ? paths.local.src or paths.local or null,
  }: let
    _name = "filesystem::mkPaths";
    root = {
      path = store.src or store;
      asStr = toString root.path;
    };

    src = {
      store = path {
        path = root.path;
        name = "source";
      };
      local =
        if local == null
        then toString root.path
        else toString local;
    };

    files = let
      raw =
        if isAttrs store
        then removeAttrs store ["src"]
        else {};

      stems =
        mapAttrs (
          _: value: let
            pathAsStr = toString value;
          in
            if hasPrefix root.asStr pathAsStr
            then substring (stringLength root.asStr) (-1) pathAsStr
            else if hasPrefix "/" pathAsStr
            then pathAsStr
            else "/" + pathAsStr
        )
        raw;
    in {
      store = mapAttrs (_: stem: src.store + stem) stems;
      local = mapAttrs (_: stem: concatStringsSep "" [src.local stem]) stems;
    };
  in
    assert if isAttrs paths
    then true
    else throw "${_name}: 'paths' argument must be an attribute set.";
    assert if (isPath store || isAttrs store)
    then true
    else throw "${_name}: 'store' must be a path literal or an attribute set containing file mappings.";
    assert !isAttrs store
    || (store ? src && isPath store.src)
    || throw "${_name}: 'store' set is missing a valid path for 'src'.";
      mapAttrs (name: _: {src = src.${name};} // files.${name}) {
        store = null;
        local = null;
      };

  mkPathParts = path: let
    pathStr = toString path;
    clean =
      if hasPrefix "./" pathStr
      then substring 2 (-1) pathStr
      else pathStr;
  in
    if pathStr == "."
    then ["."]
    else filter (x: x != "") (split "/" clean);

  /**
  Read a file, or recursively collect and label all regular files in a directory.

  # Behavior
  ```nix
  - Single file:
    - If `label` is provided, it is shown directly.
    - Else if the input `path` is a string, it is shown directly.
    - Else if `root` is provided, the file is shown relative to `root`.
    - Else the absolute/normalized Nix path string is shown.
  - Directory:
    - Walks recursively in lexicographic order.
    - If `root` is provided, every file is shown relative to `root`.
    - Else every file is shown relative to the walked directory.
  ```

  Path headers use this format:

  ```nix
  #========================================
  #> PATH: relative/or/provided/path.nix
  #========================================

  Symlinks and unknown filesystem entries are silently skipped.

  # Type
  ```nix
  bat :: Path -> String
  bat :: String -> String
  bat :: {
    path :: Path | String;
    root ? :: Path | String;
    label ? :: String;
    projectRoot ? :: Path | String;
  } -> String
  ```


  # Dependencies
  None

  # Arguments
  path
  : A path to a file or directory to read.

  # Examples
  ```nix
  bat ./config.nix
  ```
  */
  # bat = input: let
  #   _name = "filesystem.bat";
  #   args =
  #     if isAttrs input
  #     then input
  #     else {path = input;};

  #   path = let
  #     candidate = args.path;
  #   in
  #     if
  #       isPath candidate
  #       || (isString candidate && substring 0 1 candidate == "/")
  #       || (isString candidate && substring 0 2 candidate == "./")
  #       || (isString candidate && substring 0 3 candidate == "../")
  #       || (isString candidate && substring 0 2 candidate == "~/")
  #     then candidate
  #     else
  #       throw "${_name}: expected `path` to be a path or path-like string, got ${
  #         typeOf candidate
  #       }: ${
  #         toString candidate
  #       }";

  #   root = let
  #     candidate = args.root or null;
  #   in
  #     if candidate == null
  #     then {
  #       store = paths.store.src;
  #       local = paths.local.src;
  #     }
  #     else if isAttrs candidate
  #     then {
  #       store =
  #         if candidate ? store
  #         then candidate.store
  #         else if candidate ? local
  #         then candidate.local
  #         else throw "${_name}: `root` attrset must have `store` or `local`";
  #       local =
  #         if candidate ? local
  #         then candidate.local
  #         else if candidate ? store
  #         then toString candidate.store
  #         else throw "${_name}: `root` attrset must have `store` or `local`";
  #     }
  #     else {
  #       store = candidate;
  #       local = toString candidate;
  #     };

  #   label = args.label or (args.name or null);

  #   toRelativePath = root: path: let
  #     pathStr = toString path;
  #     prefix =
  #       if pathStr == root.local
  #       then root.local
  #       else root.local + "/";
  #   in
  #     if pathStr == root.local
  #     then "."
  #     else "./" + substring (stringLength prefix) (-1) pathStr;

  #   mkPath = path: let
  #     pathStr = toString path;
  #     normalizeForParts =
  #       if substring 0 2 pathStr == "./"
  #       then substring 2 (-1) pathStr
  #       else pathStr;
  #   in
  #     if pathStr == "."
  #     then ["."]
  #     else split "/" normalizeForParts;

  #   mkHeader = shownPath: let
  #     headerLines =
  #       []
  #       ++ ["#************************************************"]
  #       ++ (
  #         if root.store != root.local
  #         then [
  #           "#> STORE: ${root.store}"
  #           "#> LOCAL: ${root.local}"
  #         ]
  #         else ["#>  ROOT: ${root.local}"]
  #       )
  #       ++ ["#>  PATH: ${quote (mkPath shownPath)}"]
  #       ++ ["#************************************************"];
  #   in
  #     concatStringsSep "\n" headerLines;

  #   fileBlock = shown: child:
  #     mkHeader shown + "\n" + readFile child;

  #   collectFiles = displayRoot: dir: let
  #     entries = readDir dir;
  #     names = sort lessThan (attrNames entries);
  #   in
  #     concatLists (map
  #       (name: let
  #         child = dir + "/${name}";
  #         shown =
  #           if displayRoot != null
  #           then toRelativePath displayRoot child
  #           else
  #             toRelativePath {
  #               local = toString path;
  #               store = path;
  #             }
  #             child;
  #       in
  #         if entries.${name} == "regular"
  #         then [(fileBlock shown child)]
  #         else if entries.${name} == "directory"
  #         then collectFiles displayRoot child
  #         else [])
  #       names);

  #   shownPath =
  #     if label != null
  #     then label
  #     else if isString path
  #     then path
  #     else toRelativePath root path;

  #   displayRoot =
  #     if readFileType path == "directory"
  #     then root
  #     else null;
  # in
  #   if readFileType path == "directory"
  #   then concatStringsSep "\n\n" (collectFiles displayRoot path)
  #   else fileBlock shownPath path;
  bat = input: let
    _name = "filesystem::bat";

    args =
      if isAttrs input
      then input
      else {path = input;};

    path = let
      candidate = args.path;
      isValidString =
        isString candidate
        && (
          false
          || hasPrefix "/" candidate
          || hasPrefix "./" candidate
          || hasPrefix "../" candidate
          || hasPrefix "~/" candidate
        );
    in
      if isPath candidate || isValidString
      then candidate
      else
        throw "${_name}: expected `path` to be a path or path-like string, got ${
          typeOf candidate
        }: ${toString candidate}";

    root = let
      candidate = args.root or null;
    in
      if candidate == null
      then mkPaths {inherit paths;}
      else if isAttrs candidate && (candidate ? store || candidate ? local)
      then
        mkPaths {
          store = candidate.store or candidate.local;
          local = candidate.local or toString candidate.store;
        }
      else mkPaths {store = candidate;}; # Single path override

    label = args.label or (args.name or null);

    toRelativePath = activeRoot: targetPath: let
      targetStr = toString targetPath;
      baseStr =
        if hasPrefix activeRoot.store.src targetStr
        then activeRoot.store.src
        else activeRoot.local.src;
    in
      if targetStr == baseStr
      then "."
      else if hasPrefix baseStr targetStr
      then "./" + substring (stringLength baseStr + 1) (-1) targetStr
      else "./" + targetStr;

    mkHeader = shownPath:
      concatStringsSep "\n" (
        []
        ++ ["#************************************************"]
        ++ (
          if root.store.src != root.local.src
          then [
            "#> STORE: ${root.store.src}"
            "#> LOCAL: ${root.local.src}"
          ]
          else ["#>  ROOT: ${root.local.src}"]
        )
        ++ ["#>  PATH: ${quote (mkPathParts shownPath)}"]
        ++ ["#************************************************"]
      );

    fileBlock = shown: child:
      mkHeader shown + "\n" + readFile child;

    collectFiles = displayRoot: dir: let
      entries = readDir dir;
      names = sort lessThan (attrNames entries);
    in
      concatLists (map (
          name: let
            child = dir + "/${name}";
            shown =
              if displayRoot != null
              then toRelativePath displayRoot child
              else toRelativePath root child;
          in
            if entries.${name} == "regular"
            then [(fileBlock shown child)]
            else if entries.${name} == "directory"
            then collectFiles displayRoot child
            else []
        )
        names);

    shownPath =
      if label != null
      then label
      else if isString path
      then path
      else toRelativePath root path;

    displayRoot =
      if readFileType path == "directory"
      then root
      else null;
  in
    if readFileType path == "directory"
    then concatStringsSep "\n\n" (collectFiles displayRoot path)
    else fileBlock shownPath path;
in
  exports
