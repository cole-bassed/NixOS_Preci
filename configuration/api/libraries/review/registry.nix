# TODO: Breakout into domains
{
  attrsets,
  defaults,
  lists,
  # paths,
  ingestion,
  strings,
  ...
}: let
  exports = {
    scoped = {
      inherit
        hosts
        users
        displays
        ;
    };

    global = {};
  };

  inherit (attrsets) attrNames mapAttrs;
  inherit (lists) head elemAt;
  inherit (ingestion) collectNamedSpecs;
  inherit (strings) match;
  inherit (specs) users displays;

  collectSpecs = {
    tags,
    base,
    includeFiles ? false,
    rekey ? true,
    args ? {inherit attrsets;},
  }:
    collectNamedSpecs {inherit base tags includeFiles rekey args;};

  specs = {
    hosts =
      mapAttrs
      (_: host:
        normalizeHost (
          host
          // {
            users = resolveUsers host;
            devices.display = resolveDisplays host;
          }
        )) (
        collectSpecs {
          tags = "core";
          base = paths.hosts;
        }
      );

    users = collectSpecs {
      tags = "home";
      base = paths.users;
    };

    displays = collectSpecs {
      tags = "core";
      base = paths.displays;
    };
  };

  hosts = let
    known = specs.hosts;
    # TODO: Use withContext to add proper error messagin if there are no defined hosts.
    fallback = known.${defaults.host} or known.${head (attrNames known)};
    normalized = normalizeHost fallback;
  in
    known // {default = normalized;};

  normalizeHost = host: let
    class = host.class or "nixos";

    systemInfo = let
      system =
        host.system or (
          if host ? arch && host ? os
          then "${host.arch}-${host.os}"
          else throw "normalizeHost: Complete 'system' string or both 'arch' and 'os' must be defined for host '${host.name or "unknown"}'"
        );

      fromSys = let
        parsed = match "([^-]+)-(.*)" system;
      in {
        arch =
          if parsed != null
          then elemAt parsed 0
          else null;
        os =
          if parsed != null
          then elemAt parsed 1
          else null;
      };
    in {
      inherit system;
      arch = host.arch or fromSys.arch;
      os = host.os or fromSys.os;
    };
  in
    host // systemInfo // {inherit class;};
in
  exports
