{
  api,
  attrsets,
  debug,
  defaults,
  excludes,
  filesystem,
  flake,
  names,
  paths,
  lists,
  staged,
  strings,
  types,
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
  inherit (attrsets) attrNames genAttrs foldlAttrs optionalAttrs recursiveUpdate;
  inherit (debug) expect;
  inherit (lists) head;
  inherit (strings) concat toUpper;
  inherit (types) isAttrs isString;

  defaultHost = api.hosts.${defaults.host} or api.hosts.${(head (attrNames api.hosts))};

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
    libraries ? null,
    extraArgs ? {},
  }: let
    _name = "environment::mkSrc";

    checked = {
      host = expect {
        name = _name;
        type = "attrs";
        value = host;
        context = "validating target host specifications";
      };

      extraArgs = expect {
        name = _name;
        type = "attrs";
        value = extraArgs;
        context = "validating environment value extraArgs";
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

    paths' = mkPaths {
      inherit (paths) store;
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

    flake' = recursiveUpdate flake {
      name =
        flake.name or (
          flake.names.src or (
            names.src or "dots"
          )
        );
      path = flake.path or flake.paths.src or paths'.store.src or null;
    };

    defaults' =
      libraries'.charged.defaults or (
        recursiveUpdate
        defaults
        (flake'.defaults or {})
      );

    excludes' =
      libraries'.charged.excludes or (
        recursiveUpdate
        excludes
        (flake'.excludes or {})
      );

    libraries' = let
      raw =
        checked.extraArgs.libraries or (
          if libraries != null
          then libraries
          else staged
        );
      name = raw.name or names.lib or "lix";
      custom = raw.${name} or raw.merged or raw;
      lib = raw.lib or custom;
    in {
      libraries =
        raw
        // {
          inherit lib name;
          "${name}" = custom;
        };
      "${name}" = custom;
    };

    names' = recursiveUpdate names {
      src = flake'.name;
      lib = libraries'.libraries.name;
    };

    updated = let
      base = {
        names = names';
        paths = paths';
        defaults = defaults';
        excludes = excludes';
      };
    in
      genAttrs
      (attrNames base)
      (name: recursiveUpdate base.${name} (extraArgs.${name} or {}));

    args =
      updated
      // {
        inherit host;
        name = updated.names.src;
      }
      // libraries'
      // (
        optionalAttrs
        (flake.enable or false)
        {flake = flake';}
      );
  in
    args // {${args.names.src} = args;};

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
        then acc // {"cd_${name}" = "cd ${value.base}";}
        else if isString value
        then acc // {"cd_${name}" = "cd ${value}";}
        else acc
    ) {}
    _attrs;
in
  exports
