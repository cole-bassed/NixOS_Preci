let
  exports = {
    scoped = {
      inherit
        isEmpty
        isNotEmpty
        ;
    };

    global = {
      inherit
        isEmpty
        isNotEmpty
        ;
    };
  };

  inherit
    (builtins)
    isAttrs
    isFunction
    isList
    isString
    stringLength
    ;

  inherit ((import ./strings.nix).scoped) trim;

  /**
  Check if a value is considered empty for defaulting purposes.

  # Emptiness Rules

  - `null`: empty
  - Strings: empty when `""` or whitespace-only
  - Lists: empty when `[]`
  - Attrsets: empty when `{}`
  - Numbers, booleans, and paths: never empty
  - Functions: unsupported and cause an error

  # Type

  ```nix
  isEmpty :: a -> Bool
  ```

  # Dependencies

  - strings.trim

  # Arguments

  value
  : The value to test.

  # Examples

  ```nix
  isEmpty null
  # => true

  isEmpty "   "
  # => true

  isEmpty {}
  # => true

  isEmpty [ 1 ]
  # => false
  ```
  */
  isEmpty = value:
    assert !isFunction value || throw "isEmpty:= functions are not supported";
      if value == null
      then true
      else if isString value
      then value == "" || stringLength (trim value) == 0
      else if isList value
      then value == []
      else if isAttrs value
      then value == {}
      else false;

  /**
  Return whether a value is not empty according to `isEmpty`.

  # Type

  ```nix
  isNotEmpty :: a -> Bool
  ```

  # Dependencies

  - types.isEmpty

  # Arguments

  value
  : The value to test.

  # Examples

  ```nix
  isNotEmpty "hello"
  # => true

  isNotEmpty []
  # => false
  ```
  */
  isNotEmpty = value: !isEmpty value;
in
  exports
