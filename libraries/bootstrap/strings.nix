let
  exports = {
    scoped = {
      inherit
        trim
        cat
        orEmpty
        ;
    };

    global = {
      inherit cat;
      trimString = trim;
      orEmptyString = orEmpty;
    };
  };

  inherit
    (builtins)
    attrNames
    concatLists
    concatStringsSep
    head
    substring
    isString
    isAttrs
    lessThan
    match
    readDir
    readFile
    readFileType
    sort
    stringLength
    ;

  /**
  Read a file, or recursively collect and label all regular files in a directory.

  When given a path to a regular file, returns its contents preceded by a
  visible path header using the path as provided.

  When given a path to a directory, walks it recursively — sorted
  lexicographically at each level — and returns each regular file's content
  preceded by a visible path header using the file's path relative to the
  given directory.

  Path headers use this format:

  ```nix
  #========================================
  #> PATH: relative/or/provided/path.nix
  #========================================

  Symlinks and unknown filesystem entries are silently skipped.

  # Type
  ```nix
  cat :: Path -> String
  ```

  # Dependencies
  None

  # Arguments
  path
  : A path to a file or directory to read.

  # Examples
  ```nix
  cat ./config.nix
  ```
  # => "#========================================\n#> PATH: ./config.nix\n#========================================\n\n{ foo = 1; }\n"

  cat ./parts
  # => "#========================================\n#> PATH: a.nix\n#========================================\n\n<content>\n\n#========================================\n#> PATH: sub/c.nix\n#========================================\n\n<content>"
  */
  cat = input: let
    args =
      if isAttrs input
      then input
      else {
        root = input;
        path = input;
      };

    inherit (args) root path;

    rootStr = toString root;

    pathHeader = pathString: ''
      #========================================
      #> PATH: ${pathString}
      #========================================
    '';

    relPath = child: let
      childStr = toString child;
      start = stringLength rootStr + 1;
      len = stringLength childStr - start;
    in
      substring start len childStr;

    fileBlock = pathString: child: ''
      ${pathHeader pathString}
      ${readFile child}
    '';

    collectFiles = dir: let
      entries = readDir dir;
      names = sort lessThan (attrNames entries);
    in
      concatLists (map (
          name: let
            child = dir + "/${name}";
          in
            if entries.${name} == "regular"
            then [(fileBlock (relPath child) child)]
            else if entries.${name} == "directory"
            then collectFiles child
            else []
        )
        names);
  in
    if readFileType path == "directory"
    then concatStringsSep "\n\n" (collectFiles path)
    else fileBlock (relPath path) path;

  /**
  Trim leading and trailing whitespace from a string.

  Non-string values are treated as the empty string.

  # Type
  ```nix
  trim :: a -> String
  ```

  # Dependencies
  None

  # Arguments
  value
  : The value to trim. Non-string values produce `""`.

  # Examples
  ```nix
  trim "  hello  "
  # => "hello"

  trim "\n  hi there\t"
  # => "hi there"

  trim null
  # => ""
  ```
  */
  trim = value: let
    string =
      if isString value
      then value
      else "";

    matches = match "[[:space:]]*(.*[^[:space:]])?[[:space:]]*" string;
  in
    if matches != null
    then head matches
    else "";

  /**
  Return a non-empty string as-is, otherwise return `""`.

  Strings containing only whitespace are treated as empty.

  # Type
  ```nix
  orEmpty :: a -> String
  ```

  # Dependencies
  ```nix
  - strings.trim
  ```
  # Arguments

  value
  : The value to normalize.

  # Examples
  ```nix
  orEmpty "hello"
  # => "hello"

  orEmpty "   "
  # => ""

  orEmpty null
  # => ""
  ```
  */
  orEmpty = value:
    if isString value && stringLength (trim value) > 0
    then value
    else "";
in
  exports
