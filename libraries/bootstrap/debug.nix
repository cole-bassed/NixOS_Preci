let
  exports = {
    scoped = {
      inherit inspect;
    };

    global = {
      inspectAttrs = inspect;
    };
  };

  inherit
    (builtins)
    isAttrs
    isFunction
    isList
    mapAttrs
    typeOf
    ;

  /**
  Recursively inspect an attrset or list to a bounded depth.

  Functions and paths are rendered as placeholders to keep inspection safe
  and REPL-friendly.

  # Type

  ```nix
  inspect :: Int -> a -> a
  ```

  # Dependencies

  - debug.inspect

  # Arguments

  level
  : Maximum inspection depth.

  value
  : The value to inspect.

  # Examples

  ```nix
  inspect 1 { a.b = 1; }
  # => { a = "..."; }
  ```
  */
  inspect = level: let
    fn = depth: value: let
      type = typeOf value;
    in
      if depth <= 0
      then "..."
      else if isFunction value
      then "<function>"
      else if isList value
      then map (fn (depth - 1)) value
      else if isAttrs value
      then mapAttrs (_: fn (depth - 1)) value
      else if type == "path"
      then "<path>"
      else value;
  in
    fn level;
in
  exports
