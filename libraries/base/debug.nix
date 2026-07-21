_: let
  exports = {
    scoped = {
      inherit
        assertWith
        traceIf'
        traceWith
        tryWith
        warnWith
        ;
    };
    global = {
      inherit
        assertWith
        traceIf'
        traceWith
        tryWith
        warnWith
        ;
    };
  };

  inherit (builtins) addErrorContext deepSeq trace tryEval;

  /**
  Conditionally trace a message based on a predicate, returning `value`
  unchanged either way.

  # Type

  ```nix
  traceIf' :: Bool -> String -> a -> a
  ```

  # Dependencies
  - builtins.trace

  # Arguments
  predicate
  : Whether to trace `message`.

  message
  : The message to trace when `predicate` is `true`.

  value
  : The value returned unchanged.

  # Examples
  - __traceIf'__ _true_ `"hello"` `3`

  ```sh
  trace: hello
  3
  ```

  ---
  - __traceIf'__ _false_ `"hello"` `3`

  ```sh
  3
  ```
  */
  traceIf' = predicate: message: value:
    if predicate
    then trace message value
    else value;

  # TODO: Improve the docs to include Arguments, Dependencies
  /**
  Always trace a message, prefixed with `"${name}: "`. If `context` is
  given, appends `"(while ${context})"`. Forces `value` fully before
  tracing, so a lurking error inside it surfaces at this trace point
  rather than staying lazy until something else forces it later. Never
  throws - purely informational.

  # Type

  ```nix
  traceWith :: {
    name :: String,
    message :: String,
    context :: String?
  } -> a -> a
  ```

  # Examples
  - __traceWith__ { `name` = _"strings.trim"_; `message` = _"set value"_; } `payload`

  ```sh
  trace: strings.trim: set value
  payload
  ```

  ---
  - __traceWith__ { `name` = _"strings.trim"_; `message` = _"set value"_; `context` = _"accumulate"_; } `payload`

  ```sh
  trace: strings.trim: set value (while accumulate)
  payload
  ```
  */
  traceWith = {
    name,
    message,
    context ? null,
  }: x: let
    msg =
      if context != null
      then "${name}: ${message} (while ${context})"
      else "${name}: ${message}";
  in
    deepSeq x (trace msg x);

  /**
  Attempt to evaluate `x`, forcing it fully (deep, not just WHNF) so a throw
  nested inside an attrset/list is actually caught rather than staying lazy
  until something else forces it later. Returns `{ success; value; }` like
  `builtins.tryEval`, but is safe to use on structured values - a plain
  `tryEval` on an attrset only proves the attrset itself was constructed,
  not that its fields don't throw.

  # Type

  ```nix
  tryWith :: a -> { success :: Bool, value :: a | Null }
  ```

  # Examples
  - __tryWith__ `{ x = 1; }`

  ```sh
  { success = true; value = { x = 1; }; }
  ```

  ---
  - __tryWith__ `(throw "boom")`

  ```sh
  { success = false; value = null; }
  ```

  ---
  - __tryWith__ `{ x = throw "boom"; }` (caught, unlike plain `tryEval`)

  ```sh
  { success = false; value = null; }
  ```
  */
  tryWith = x: tryEval (deepSeq x x);

  /**
  Assert `assertion`, tracing `"${name}: ${message}"` on failure before
  throwing. If `context` is given, wraps the assertion in
  `builtins.addErrorContext` so a failure elsewhere during evaluation of
  the surrounding expression also carries this context. Returns `true`
  directly, without tracing, when `assertion` holds.

  # Type

  ```nix
  assertWith :: {
    name :: String,
    assertion :: Bool,
    message :: String?,
    context :: String?
  } -> Bool
  ```

  # Dependencies
  - builtins.addErrorContext
  - builtins.trace

  # Arguments
  name
  : Label prefixed to the failure message.

  assertion
  : Condition that must hold.

  message
  : Failure text. Defaults to `"failure"`.

  context
  : Optional context added as `"while evaluating ${context}"`.

  # Examples
  - __assertWith__ { `name` = _"config"_; `assertion` = _true_; }

  ```sh
  true
  ```

  ---
  - __assertWith__ { `name` = _"config"_; `assertion` = _false_; `message` = _"missing key"_; }

  ```sh
  trace: config: missing key
  error: config: missing key
  ```
  */
  assertWith = {
    name,
    assertion,
    message ? "failure",
    context ? null,
  }: let
    prep =
      if assertion
      then true
      else trace "${name}: ${message}" false;
    exec = assert prep; true;
  in
    if context != null
    then addErrorContext "while evaluating ${context}" exec
    else exec;

  /**
  Assert `assertion` without throwing. When it is false, forces `value`
  fully, traces `"${name}: ${message}"`, and returns `value` unchanged. If
  `context` is given, appends `"(while ${context})"` to the message. When
  the assertion is true, returns `value` directly without forcing it.

  # Type

  ```nix
  warnWith :: {
    name :: String,
    assertion :: Bool,
    message :: String?,
    context :: String?
  } -> a -> a
  ```

  # Dependencies
  - builtins.deepSeq
  - builtins.trace

  # Arguments
  name
  : Label prefixed to the warning message.

  assertion
  : Whether to return `value` without warning.

  message
  : Warning text. Defaults to `"warning"`.

  context
  : Optional context appended as `"(while ${context})"`.

  value
  : The value forced and returned unchanged.

  # Examples
  - __warnWith__ { `name` = _"config"_; `assertion` = _true_; } `value`

  ```sh
  value
  ```

  ---
  - __warnWith__ { `name` = _"config"_; `assertion` = _false_; } `value`

  ```sh
  trace: config: warning
  value
  ```

  ---
  - __warnWith__ { `name` = _"config"_; `assertion` = _false_; `message` = _"deprecated"_; } `value`

  ```sh
  trace: config: deprecated
  value
  ```

  ---
  - __warnWith__ { `name` = _"config"_; `assertion` = _false_; `context` = _"loading options"_; } `value`

  ```sh
  trace: config: warning (while loading options)
  value
  ```
  */
  warnWith = {
    name,
    assertion,
    message ? "warning",
    context ? null,
  }: value:
    if !assertion
    then
      deepSeq value (trace (
          if context != null
          then "${name}: ${message} (while ${context})"
          else "${name}: ${message}"
        )
        value)
    else value;
in
  exports
