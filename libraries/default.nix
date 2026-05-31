{
  inputs,
  lib,
  defaults,
}: let
  inherit
    (lib.attrsets)
    attrByPath
    filterAttrs
    genAttrs
    mapAttrs
    mapAttrsToList
    setAttrByPath
    ;
  inherit (lib.filesystem) baseNameOf pathIsRegularFile readDir;
  inherit (lib.lists) concatMap elem filter findFirst optionals toList;
  inherit (lib.options) mkEnableOption;
  inherit (lib.strings) hasSuffix removeSuffix;
  inherit (lib.trivial) isFunction;

  mkNix = {
    alpha ? defaults.user,
    dots ? defaults.dots,
    extraArgs ? {},
    modules ? defaults.modules,
    system ? defaults.system,
    top ? defaults.top,
  }:
    lib.nixosSystem {
      inherit modules system;
      specialArgs =
        {inherit inputs alpha dots top;}
        // extraArgs;
    };

  mkNixConfigurations = extraArgs: {
    nixosConfigurations =
      mapAttrs
      (name: config: mkNix (config // {inherit extraArgs;}))
      extraArgs.hosts or defaults.api.hosts;
  };

  mkEnable = {
    name ? null,
    mod ? null,
    description ? null,
    scope ? "core",
  }: let
    module =
      if name != null && name != ""
      then name
      else if mod != null && mod != ""
      then mod
      else null;

    description' =
      if description != null
      then description
      else if module != null
      then "Whether ${module} should be enabled ${
        if scope == "core"
        then "system-wide"
        else if scope == "home"
        then "for the user"
        else throw "Expected scope to be one of [core home], got ${scope}"
      }"
      else "Whether to enable this module";
  in {
    false = mkEnableOption description';
    true = mkEnableOption description' // {default = true;};
  };

  mkCfg = {
    config,
    path,
  }:
    attrByPath (toList path) {} config;

  mkOpt = {
    options,
    path,
  }:
    setAttrByPath (toList path) options;

  mkEnableMod = {
    mod,
    scope,
  }:
    mkEnable {inherit mod scope;};

  mkModuleArgs = {
    config,
    top,
    dom,
    mod,
    scope ? "core",
  }: let
    path = [top dom mod];
  in {
    cfg = mkCfg {inherit config path;};
    opt = options: mkOpt {inherit options path;};
    mkEnableMod = mkEnableMod {inherit mod scope;};
  };

  readDirAttrs = {
    base,
    ignore ? defaults.ignore,
    predicate ? (name: type: type == "directory"),
  }:
    filterAttrs
    (name: type: predicate name type && !(elem name ignore))
    (readDir base);

  importModule = {
    args ? {},
    base,
    name,
    path ? defaults.entrypoint,
  }: let
    module = import (base + "/${name}/${path}");
  in
    if isFunction module
    then module args
    else module;

  asList = val: optionals (val != null) (toList val);

  moduleEntries = {
    base,
    ignore ? defaults.ignore,
    includeFiles ? false,
  }:
    mapAttrsToList
    (name: type: let
      isDirectory = type == "directory";
      isFile = type == "regular";
    in {
      inherit isDirectory isFile name;
      mod =
        if isFile
        then removeSuffix ".nix" name
        else name;
      path =
        if isFile
        then base + "/${name}"
        else base + "/${name}/${defaults.entrypoint}";
      spec = isDirectory;
      raw = isFile;
    })
    (readDirAttrs {
      inherit base ignore;
      predicate = name: type:
        type
        == "directory"
        || (
          includeFiles
          && type == "regular"
          && hasSuffix ".nix" name
          && name != defaults.entrypoint
        );
    });

  collectModules = {
    args,
    extraArgs ? {},
    base,
    ignore ? defaults.ignore,
    includeFiles ? false,
    rawTag ? "core",
    path ? defaults.entrypoint,
    tags ? defaults.tags,
  }: let
    entries = moduleEntries {inherit base ignore includeFiles;};

    specFor = entry:
      if entry.raw
      then {${rawTag} = entry.path;}
      else
        importModule {
          inherit base path;
          name = entry.name;
          args =
            args
            // {
              dom = baseNameOf (toString base);
              mod = entry.mod;
            }
            // extraArgs;
        };

    specs = map specFor entries;
  in
    genAttrs tags (tag: concatMap (spec: asList (spec.${tag} or null)) specs);

  importModules = args @ {
    base,
    ignore ? defaults.ignore,
    includeFiles ? false,
    rawTag ? "core",
    path ? defaults.entrypoint,
    tags ? defaults.tags,
    extraArgs ? {},
    ...
  }: let
    modules = collectModules {
      inherit args base ignore includeFiles rawTag path tags extraArgs;
    };
  in {
    imports = modules.core or [];
    home-manager.sharedModules = modules.home or [];
  };

  findNix = base: name: stem:
    findFirst pathIsRegularFile null [
      (base + "/${name}/${stem}.nix")
      (base + "/${name}/${stem}/${defaults.entrypoint}")
    ];

  profileEntries = {
    base,
    ignore ? defaults.ignore,
  }:
    readDirAttrs {inherit base ignore;};

  mkProfileConfig = base: user: let
    default = base + "/${user}/${defaults.entrypoint}";
    core = findNix base user "core";
    home = findNix base user "home";
    flat =
      if core == null && home == null && pathIsRegularFile default
      then default
      else null;
  in {
    inherit core;
    home =
      if home != null
      then home
      else flat;
  };

  importProfiles = {
    base,
    ignore ? defaults.ignore,
  }: let
    users = profileEntries {inherit base ignore;};
  in {
    imports =
      filter
      (module: module != null)
      (mapAttrsToList (user: _: (mkProfileConfig base user).core) users);

    home-manager.users = genAttrs (mapAttrsToList (user: _: user) users) (
      user: let
        cfg = mkProfileConfig base user;
      in
        if cfg.home != null
        then import cfg.home
        else {}
    );
  };
in {
  inherit
    asList
    mkEnable
    mkCfg
    mkOpt
    mkModuleArgs
    moduleEntries
    collectModules
    importModules
    importProfiles
    mkNix
    mkNixConfigurations
    ;
}
