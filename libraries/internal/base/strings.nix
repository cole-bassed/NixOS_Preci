{
  attrsets,
  lists,
  types,
  filesystem,
  ...
}: let
  exports = {
    scoped = {
      inherit
        cat
        concat
        orEmpty
        split'
        trim
        ;
      split = split';
      infix = substring;
      length = stringLength;
      regex = match;
    };

    global = {
      inherit
        (builtins)
        concatStringsSep
        replaceStrings
        stringLength
        substring
        toString
        ;
      inherit cat;
      joinStrings = concat;
      matchRegex = match;
      orEmptyString = orEmpty;
      splitString = split';
      trimString = trim;
    };
  };

  inherit (attrsets) namesOf;
  inherit (builtins) concatStringsSep split substring match stringLength;
  inherit (filesystem) readDir readFile readFileType;
  inherit (lists) head select concatLists sort;
  inherit (types) isAttrs isList isString lessThan;

  /**
  Concatenate a list of strings with an optional delimiter, safely filtering out null values.

  Supports three hybrid invocation patterns: an explicit configuration attribute set,
  a curried positional layout (delimiter string then parts list), or a shorthand parts
  list (which defaults the delimiter to an empty string `""`).

  # Type
  ```nix
  concat :: AttrSet -> String
  concat :: String -> List String -> String
  concat :: List String -> String

  # Dependencies
  ```nix
  - builtins.concatStringsSep
  - builtins.filter
  - builtins.isAttrs
  - builtins.isString
  - builtins.isList
  ```

  # Arguments
  arg
  : An configuration attribute set { delim ?, parts }, a delimiter string, or a direct list of string parts.

  # Examples
  Nix
  # Pattern 1: Explicit Attribute Set Configuration
  concat { delim = "-"; parts = [ "foo" "bar" ]; }
  # => "foo-bar"

  # Pattern 2: Curried Positional (Delimiter then Parts)
  concat "/" [ "usr" "local" "bin" ]
  # => "usr/local/bin"

  # Pattern 3: Shorthand List (Omits Delimiter)
  concat [ "a" "b" "c" ]
  # => "abc"

  # Built-in Null Safety
  concat { delim = "_"; parts = [ "core" null "system" ]; }
  # => "core_system"
  */
  concat = arg: let
    exec = delim: parts:
      concatStringsSep delim (select (part: part != null) parts);
  in
    if isAttrs arg
    then exec (arg.delim or "") arg.parts
    else if isString arg
    then parts: exec arg parts
    else if isList arg
    then exec "" arg
    else exec "" [];

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
      names = sort lessThan (namesOf entries);
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

  /**
  Splits a string by a literal string separator.
  Safe for bootstrap as it only relies on basic builtins.
  */
  split' = sep: str: let
    # Basic regex escaping for common delimiters like '.' or '-'
    # If your paths only use dots, escaping the dot is the main priority.
    escapedSep =
      if sep == "."
      then "\\."
      else if sep == "*"
      then "\\*"
      else if sep == "+"
      then "\\+"
      else sep;

    rawSplit = split escapedSep str;
  in
    select isString rawSplit;
in
  exports
