{
  attrsets,
  lists,
  ...
}: let
  exports = {
    scoped = {inherit resolveTiers;};
    global = {};
  };

  inherit (attrsets) parseOrdered mapAttrs mkNamespaced;
  inherit (lists) asList;

  # Resolves, cascades, and namespaces multiple application sets at once
  resolveTiers = sets: let
    mapped =
      mapAttrs (_: list: let
        commands = parseOrdered (map (x: x.command) (asList list));
        primary = commands.primary;
        secondary =
          if commands.secondary != null
          then commands.secondary
          else primary;
        tertiary =
          if commands.tertiary != null
          then commands.tertiary
          else secondary;
      in {
        "" = primary;
        inherit secondary tertiary;
      })
      sets;
  in
    mkNamespaced mapped;
in
  exports
