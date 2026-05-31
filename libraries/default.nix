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
  inherit (lib.filesystem) baseNameOf readDir;
  inherit (lib.lists) elem concatMap optionals toList;
  inherit (lib.options) mkEnableOption;

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
    inherit mkEnableMod;
    cfg = mkCfg {inherit config path;};
    opt = options: mkOpt {inherit options path;};
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
    path ? "default.nix",
  }:
    import (base + "/${name}/${path}") args;

  asList = val: optionals (val != null) (toList val);

  collectModules = {
    args,
    extraArgs ? {},
    base,
    ignore ? defaults.ignore,
    path ? defaults.entrypoint,
    tags ? defaults.tags,
  }: let
    entries = readDirAttrs {inherit base ignore;};

    specs =
      mapAttrsToList
      (name: _:
        importModule {
          inherit base path name;
          args =
            args
            // {
              dom = baseNameOf (toString base);
              mod = name;
            }
            // extraArgs;
        })
      entries;
  in
    genAttrs tags (tag: concatMap (spec: asList (spec.${tag} or null)) specs);

  importModules = args @ {
    base,
    ignore ? defaults.ignore,
    path ? defaults.entrypoint,
    tags ? defaults.tags,
    extraArgs ? {},
    ...
  }: let
    modules = collectModules {
      inherit args base ignore path tags extraArgs;
    };
  in {
    imports = modules.core or [];
    home-manager.sharedModules = modules.home or [];
  };
in {
  inherit
    asList
    mkEnable
    mkCfg
    mkOpt
    mkModuleArgs
    collectModules
    importModules
    mkNix
    mkNixConfigurations
    ;
}
