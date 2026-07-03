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
    scoped = {inherit specs normalize;};
    global = {
      hostSpecs = specs;
      normalizeHost = normalize;
    };
  };

  inherit (attrsets) attrNames mapAttrs;
  inherit (lists) head elemAt;
  inherit (ingestion) collectNamedSpecs;
  inherit (strings) split';

  collected =
    mapAttrs
    (_: normalize)
    (
      collectNamedSpecs {
        tags = "core";
        base = paths.hosts;
        includeFiles = true;
        rekey = true;
      }
    );

  specs =
    collected
    // {
      default = collected.${defaults.host} or
        collected.${head (attrNames collected)};
    };

  normalize = host: let
    class = host.class or "nixos";

    systemInfo = let
      system =
        host.system or (
          if host ? arch && host ? os
          then "${host.arch}-${host.os}"
          else throw "normalizeHost: Complete 'system' string or both 'arch' and 'os' must be defined for host '${host.name or "unknown"}'"
        );

      fromSys = let
        parts = split' "-" system;
      in {
        arch = host.arch or (elemAt parts 0);
        os = host.os or (elemAt parts 1);
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
