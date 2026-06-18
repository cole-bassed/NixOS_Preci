{
  api,
  debug,
  types,
  attrsets,
  flake,
  filesystem,
  strings,
  paths,
  names,
  defaults,
  ...
}: let
  exports = {
    scoped = {inherit mkSrc mkCdAliases mkVariables mkPaths mkUserPaths;};
    global = {
      inherit mkCdAliases mkSrc;
      mkSource = mkSrc;
      mkEnvVars = mkVariables;
    };
  };

  inherit (filesystem) mkPaths mkUserPaths;
  inherit (attrsets) foldlAttrs optionalAttrs recursiveUpdate;
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
  mkSrc = {
    host ? defaultHost,
    libraries ? {},
    overrides ? {},
  }: let
    _name = "environment::mkSrc";

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

    primaryUser =
      ((checked.host.users or {}).primary or {}).value or null;

    userDefaults =
      optionalAttrs
      (primaryUser != null)
      (mkUserPaths {user = primaryUser;});

    commonArgs = {
      inherit names defaults host;
      paths = mkPaths {
        store = paths.store;
        local =
          (
            recursiveUpdate
            (recursiveUpdate userDefaults paths.local)
            hostPaths
          )
          // {src = resolution.value;};
        meta =
          optionalAttrs
          (resolution.usedKey != null)
          {inherit (resolution) usedKey;};
      };
    };

    flakeArgs = {
      name = flake.name or flake.names.src or names.src or "dots";
      defaults = flake.defaults or {};
      paths = flake.paths or {};
      names = flake.names or {};
    };

    libraryArgs = let
      raw = checked.overrides.libraries or libraries;
      name = raw.name or names.lib or "lix";
      custom =
        if raw ? ${name} && raw ? seeded
        then raw
        else {${name} = raw;};
      lib = raw.lib or custom.${name}.lib or custom.${name};
    in {
      libraries = removeAttrs (custom // {inherit lib name;}) ["lib" name];
      "${name}" = (custom.seeded) // custom;
      inherit name lib;
    };

    src =
      {
        defaults =
          recursiveUpdate
          defaults
          (flakeArgs.defaults or {});
        names = recursiveUpdate names {
          src = flakeArgs.name;
          lib = libraryArgs.name;
        };
        paths =
          recursiveUpdate
          (recursiveUpdate flakeArgs.paths paths)
          (
            mkPaths {
              store = paths.store;
              local =
                (
                  recursiveUpdate
                  (recursiveUpdate userDefaults paths.local)
                  hostPaths
                )
                // {src = resolution.value;};
              meta =
                optionalAttrs
                (resolution.usedKey != null)
                {inherit (resolution) usedKey;};
            }
          );
      }
      // optionalAttrs (flake != {}) {flake = flakeArgs;}
      // removeAttrs libraryArgs ["name"];
  in
    src // {${src.names.src} = src;};

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
