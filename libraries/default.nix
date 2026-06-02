{
  info,
  libraries,
  modules,
  paths,
  inputs,
  defaults,
}: let
  name = info.names.lib;
  legacy = import ./imports {inherit libraries;};

  inherit (legacy.attrsets) recursiveUpdate optionalAttrs mapAttrs;
  inherit (legacy.lists) elem;
  mkLix = includes:
    recursiveUpdate legacy (
      {inherit defaults;}
      // optionalAttrs (elem "api" includes) {inherit (scoped) api;}
      // optionalAttrs (elem "attrsets" includes) {inherit (scoped) attrsets;}
      // optionalAttrs (elem "config" includes) {inherit (scoped) config;}
      // optionalAttrs (elem "debug" includes) {inherit (scoped) debug;}
      // optionalAttrs (elem "filesystem" includes) {inherit (scoped) filesystem;}
      // optionalAttrs (elem "lists" includes) {inherit (scoped) lists;}
      // optionalAttrs (elem "modules" includes) {inherit (scoped) modules;}
      // optionalAttrs (elem "options" includes) {inherit (scoped) options;}
      // optionalAttrs (elem "strings" includes) {inherit (scoped) strings;}
      // optionalAttrs (elem "types" includes) {inherit (scoped) types;}
    );

  custom = {
    api = import defaults.paths.api (mkLix [
      "attrsets"
      "modules"
      "lists"
    ]);
    attrsets = import ./attrsets.nix (mkLix [
      "debug"
      "lists"
      "types"
    ]);
    config =
      import ./config.nix (mkLix [
        "api"
        "debug"
        "module"
        "filesystem"
        "lists"
        "types"
      ])
      // {inherit (modules) core home;};
    debug = import ./debug.nix (mkLix [
      "lists"
      "types"
    ]);
    filesystem = import ./filesystem.nix (mkLix [
      "debug"
      "lists"
    ]);
    lists = import ./lists.nix (mkLix [
      "debug"
      "types"
    ]);
    modules = import ./modules.nix (mkLix [
      "debug"
      "filesystem"
      "lists"
      "types"
    ]);
    options = import ./options.nix (mkLix [
      "debug"
      "lists"
      "types"
    ]);
    strings = import ./strings.nix (mkLix [
      "debug"
      "lists"
      "types"
    ]);
    types = import ./types.nix (mkLix [
      "debug"
    ]);
  };

  scoped =
    mapAttrs
    (_: value: (value.scoped or {}) // (value.global or {}))
    custom;

  global = scoped.attrsets.mergeUnique {
    items = custom;
    getAttrs = library: custom.${library}.global or (custom.${library} or {});
    what = "libraries";
    owner = library: "${name}.${library}.global";
  };
in
  recursiveUpdate legacy (
    {}
    // global
    // scoped
  )
