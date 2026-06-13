{
  debug,
  types,
  strings,
  ...
}: let
  exports = {
    scoped = {
      inherit
        mkTest
        mkTest'
        mkThrows
        assertMsgFunc
        assertWithContext
        warnWithContext
        expect
        ;
      withContext = assertWithContext;
    };
    global = {
      inherit
        assertWithContext
        expect
        warnWithContext
        ;
    };
  };

  inherit (debug) addErrorContext assertMsg deepSeq traceIf tryEval;
  inherit (types) isAttrs isBool isPath isString typeOf;
  inherit (strings) toJSON;

  assertMsgFunc = {
    name,
    assertion,
    message,
  }:
    assertMsg assertion "${name}: ${message}";

  assertWithContext = {
    name,
    assertion,
    message,
    context,
  }:
    addErrorContext
    "while ${context}"
    (assert assertMsgFunc {
      inherit name assertion message;
    }; true);

  _build = desired: outcome: command: let
    value = deepSeq outcome outcome;
  in {
    inherit desired command;
    result = value;
    passed = desired == value;
  };

  warnWithContext = {
    name,
    assertion,
    message,
    context,
  }:
    deepSeq
    (traceIf (!assertion) "[${name}] while ${context}: ${message}" true)
    assertion;

  /**
  Create a named test case with desired output, outcome expression, and an
  optional command string for display in test results.

  # Type
  ```nix
  mkTest :: { desired :: a, outcome :: a, command :: string? } -> Test
  ```

  # Examples
  ```nix
  mkTest {
    desired = "foo-bar";
    command = ''normalize "Foo Bar"'';
    outcome = normalize "Foo Bar";
  }
  ```
  */
  mkTest = {
    desired,
    outcome,
    command ? null,
  }:
    _build desired outcome command;

  /**
  Positional shorthand for `mkTest` - no command string.

  Useful in enum and validator test blocks where the expression is self-evident.

  # Type
  ```nix
  mkTest' :: a -> a -> Test
  ```

  # Examples
  ```nix
  validatesRust = mkTest' true  (languages.validator.check "rust")
  correctCount  = mkTest' 4     (length cpuBrands.values)
  ```
  */
  mkTest' = desired: outcome: _build desired outcome null;

  /**
  Create a test case that expects evaluation to throw.

  Uses `builtins.tryEval` to catch the error - the test passes only if
  evaluation fails.

  # Type
  ```nix
  mkThrows :: a -> Test
  ```

  # Examples
  ```nix
  mkThrows (validate { fnName = "f"; argName = "x"; desired = "set"; predicate = isAttrs; outcome = "oops"; })
  ```
  */
  mkThrows = outcome:
    mkTest {
      desired = {
        success = false;
        value = false;
      };
      outcome = tryEval outcome;
    };

  expect = {
    type,
    value,
    context,
    name,
  }:
    assert debug.withContext {
      inherit name context;
      assertion =
        if type == "bool"
        then isBool value
        else if type == "attrs"
        then isAttrs value
        else if type == "path"
        then (isPath value || (isString value && value != ""))
        else false;
      message = "Expected type '${type}', but got '${typeOf value}' with value: ${toJSON value}";
    }; value;
in
  exports
