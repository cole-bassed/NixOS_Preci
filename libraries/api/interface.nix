{
  api,
  attrsets,
  lists,
  paths,
  ...
}: let
  exports = {
    scoped = {inherit registry inferredOf selectionOf selectedModules backendsOf;};
    global = {
      interfaceRegistry = registry;
      interfaceSelection = selectionOf;
      interfaceInferred = inferredOf;
      interfaceBackends = backendsOf;
      interfaceModules = selectedModules;
    };
  };

  inherit (attrsets) as filterAttrs valuesOf mapAttrs recursiveUpdate;
  inherit (lists) concatMap elem filter unique;

  raw = api.interface;

  # data/interface/default.nix -- common/wayland/x11-shaped defaults.
  # wayland/x11 already have common's applications concatenated in (via ++
  # at the data layer). resolveProtocol still merges common underneath,
  # since only common declares bindings/variables and those must fall
  # through even for the categories wayland/x11 don't redeclare.
  # default.nix is never picked up as a sibling registry entry
  # (readDirAttrs excludes it), so it must be imported directly.
  shared = import (paths.store.api + "/interface");
  common = shared.common or {};
  resolveProtocol = protocol: recursiveUpdate common (shared.${protocol} or {});

  # protocol (lowest) -> entry (highest), with applications.<category>
  # concatenated rather than replaced: an entry's own list becomes the new
  # primary/prepended entries, and whatever the protocol tier already had
  # (which itself already has common concatenated in via ++) falls back
  # after it. Every other key (bindings, variables, protocol, greeter, ...)
  # keeps plain override-wins semantics.
  mergeLayer = entry: let
    protocol = resolveProtocol (entry.protocol or "common");
    entryApps = entry.applications or {};
    protocolApps = protocol.applications or {};
    mergedApps =
      protocolApps
      // mapAttrs
      (category: list: list ++ (protocolApps.${category} or []))
      entryApps;
  in
    (recursiveUpdate protocol entry) // {applications = mergedApps;};

  registry =
    mapAttrs
    (_: entry: mergeLayer entry)
    (removeAttrs raw ["default"]);

  rawBackendsOf = spec: let
    interface = spec.interface or {};
  in
    interface.backends
    or (
      unique (
        filter (x: x != null && x != "") (
          (interface.backend.managers or [])
          ++ (interface.backend.desktops or [])
          ++ [
            (interface.windowManager or null)
            (interface.desktopEnvironment or null)
          ]
        )
      )
    );

  selectionOf = spec: spec.applications or {};
  inferredOf = spec: as (rawBackendsOf spec);
  normalizeName = name: registry.${name} or name;

  backendsOf = spec:
    unique (
      map
      normalizeName
      (concatMap valuesOf (valuesOf (selectionOf spec)))
    );

  selectedModules = spec: let
    names = backendsOf spec;
  in
    filterAttrs (name: _: elem name names) registry;
in
  exports



