{
  api,
  debug,
  types,
  attrsets,
  external,
  flake,
  filesystem,
  strings,
  paths,
  names,
  defaults,
  ...
}: let
  exports = {
    scoped = {inherit source mkCdAliases mkVariables mkPaths mkUserPaths;};
    global = {
      inherit mkCdAliases;
      mkSrc = source;
      mkEnvVars = mkVariables;
    };
  };

  inherit (filesystem) mkPaths mkUserPaths;
  inherit (attrsets) getAttr hasAttr foldlAttrs recursiveUpdate;
  inherit (debug) expect;
  inherit (strings) concat toUpper;
  inherit (types) isAttrs isString;

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

    # Resolve which key supplies the host's flake checkout path, and
    # remember *which* key it was (`usedKey`) so `mkPaths` can exclude only
    # that one from the local extras -- without blacklisting `dots`/`home`
    # by name, since a host may legitimately use either as a genuine extra
    # (e.g. `home` meaning "primary user's home directory") when it wasn't
    # also the key chosen here to resolve `src`.
    hostPaths = checked.host.paths or {};
    resolution =
      if hostPaths ? src
      then {
        usedKey = "src";
        value = hostPaths.src;
      }
      else if hostPaths ? dots
      then {
        usedKey = "dots";
        value = hostPaths.dots;
      }
      else if hostPaths ? home
      then {
        usedKey = "home";
        value = hostPaths.home;
      }
      else if checked.host ? dots
      then {
        usedKey = null;
        value = checked.host.dots;
      }
      else if checked.host ? home
      then {
        usedKey = null;
        value = checked.host.home;
      }
      else {
        usedKey = null;
        value = paths.local.src;
      };

    # The primary user, if the host defines one, supplies sane defaults
    # for standard folders (Downloads, Pictures, ...) via `mkUserPaths`.
    # These sit at the *lowest* precedence in the merge below -- a global
    # `paths.local` default, or an explicit host override, still wins.
    primaryUser =
      ((checked.host.users or {}).primary or {}).value or null;
    userDefaults =
      if primaryUser != null
      then mkUserPaths {user = primaryUser;}
      else {};

    args =
      (
        if hasAttr names.src external
        then getAttr names.src external
        else {}
      )
      // {
        name = flake.names.src or names.src;
        inherit names defaults host external;
        paths = mkPaths {
          store = paths.store;
          local =
            recursiveUpdate
            (recursiveUpdate userDefaults paths.local)
            hostPaths
            // {src = resolution.value;};
          meta =
            if resolution.usedKey != null
            then {inherit (resolution) usedKey;}
            else {};
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
