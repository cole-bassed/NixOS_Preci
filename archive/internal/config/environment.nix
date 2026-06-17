{
  api,
  debug,
  types,
  attrsets,
  external,
  flake,
  strings,
  paths,
  names,
  defaults,
  ...
}: let
  exports = {
    scoped = {inherit source mkCdAliases mkVariables;};
    global = {
      inherit mkCdAliases;
      mkSrc = source;
      mkEnvVars = mkVariables;
    };
  };

  inherit (debug) expect;
  inherit (types) isAttrs isString;
  inherit (attrsets) foldlAttrs recursiveUpdate;
  inherit (strings) concat toUpper;

  defaultHost = api.hosts.${defaults.host};

  /**
  Build the basic `dots` path configuration for a host.

  # Type
  ```nix
  source :: { host :: AttrSet?, libraries :: AttrSet?, overrides :: AttrSet? } -> AttrSet
  ```

  # Dependencies
  ```nix
  - debug.expect
  - attrsets.recursiveUpdate
  ```

  # Arguments
  host
  : Target machine profile configurations. Defaults to the system primary host.

  libraries
  : Target environment specific shared code injection.

  overrides
  : Explicit framework and configuration adjustments to overlay on the defaults.
  */
  source = {
    host ? defaultHost,
    libraries ? {},
    overrides ? {},
  }: let
    _name = "config.environment.mkSrc";

    checked = {
      host = expect {
        name = _name;
        type = "attrs";
        value = host;
        context = "validating target host specifications";
      };

      overrides = expect {
        name = _name;
        type = "attrs";
        value = overrides;
        context = "validating environment value overrides";
      };
    };

    args =
      (
        if builtins.hasAttr names.src external
        then builtins.getAttr names.src external
        else {}
      )
      // {
        name = flake.names.src or names.src;
        inherit names defaults host external;
        paths = {
          local = let
            src =
              checked.host.paths.src or (
                checked.host.paths.dots or (
                  checked.host.paths.home or (
                    checked.host.dots or (
                      checked.host.home or paths.local.src
                    )
                  )
                )
              );
          in
            recursiveUpdate paths.local (
              recursiveUpdate {inherit src;} (checked.host.paths or {})
            );
          store = recursiveUpdate (
            paths.store or {
              src = flake.paths.src or paths.src;
            }
          ) (checked.overrides.paths or {});
        };
      };

    libs = {${names.lib} = checked.overrides.libraries or libraries;};
    src = recursiveUpdate args checked.overrides // libs;
  in
    src
    // {
      inherit src;
      ${args.name} = src;
    }
    // libs;

  /**
  Flatten structured attribute paths downwards into a standard uppercase
  POSIX shell environment variable map.

  # Type
  ```nix
  mkVariables :: { prefix :: String?, attrs :: AttrSet } -> AttrSet
  ```

  # Dependencies
  ```nix
  - debug.expect
  - attrsets.foldlAttrs
  - strings.toUpper
  ```

  # Arguments
  prefix
  : String token block to pre-append to key configurations.

  attrs
  : The structured dataset map targeted for environment emission.
  */
  mkVariables = arg: let
    _name = "config.environment.mkVariables";
    checked = expect {
      name = _name;
      type = "attrs";
      value = arg;
      context = "flattening attribute architecture maps into shell constants";
    };

    prefix = checked.prefix or null;
    attrs = checked.attrs or {};
  in
    foldlAttrs (
      acc: name: value: let
        # The hybrid curried pattern removes the entire conditional block!
        key = toUpper (concat "_" [prefix name]);
      in
        if isAttrs value && value ? base
        then
          acc
          // {"${key}" = value.base;}
          // mkVariables {
            prefix = key;
            attrs = value;
          }
        else if isString value
        then acc // {"${key}" = value;}
        else acc
    ) {}
    attrs;

  /**
  Generate shell directory jumping aliases based on existing framework path maps.

  # Type
  ```nix
  mkCdAliases :: AttrSet -> AttrSet
  ```

  # Dependencies
  ```nix
  - debug.expect
  - attrsets.foldlAttrs
  ```

  # Arguments
  attrs
  : Base directory mapping layouts providing a path schema.
  */
  mkCdAliases = attrs: let
    _name = "config.environment.mkCdAliases";
    _attrs = expect {
      name = _name;
      type = "attrs";
      value = attrs;
      context = "generating filesystem path alias macros";
    };
  in
    foldlAttrs (
      acc: name: value:
        if isAttrs value && value ? base
        then acc // {"cd${name}" = "cd ${value.base}";}
        else acc
    ) {}
    _attrs;
in
  exports
