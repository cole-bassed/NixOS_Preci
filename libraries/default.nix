{
  lib,
  defaults,
}: let
  inherit (lib.attrsets) attrNames hasAttr mapAttrs;
  inherit (lib.lists) filter foldl';
  inherit (lib.strings) concatStringsSep;

  # ── 1. declare libraries in dependency order ──────────────────────────────
  all = let
    predicates = import ./predicates.nix {inherit lib;};
    lists = import ./lists.nix {inherit lib;};
    debug = import ./debug.nix {inherit lib;};
    options = import ./options.nix {inherit lib;};
    system = import ./system.nix {inherit lib;};

    strings = import ./strings.nix {
      inherit lib;
      debug = debug.internal;
      predicates = predicates.internal;
    };
    attrsets = import ./attrsets.nix {
      inherit lib;
      lists = lists.internal;
    };
    modules = import ./modules.nix {
      inherit lib defaults;
      lists = lists.internal;
      predicates = predicates.internal;
    };
  in {inherit predicates lists debug options system strings attrsets modules;};

  # ── 2. namespaced surface: lix.<libname> = lib.internal ─────────────────

  namespaced = mapAttrs (_: lib: lib.internal) all;

  # ── 3. flat surface: collision-checked merge of all external aliases ──────
  flat =
    foldl'
    (
      acc: name: let
        incoming = all.${name}.external or {};
        collisions = filter (k: hasAttr k acc) (attrNames incoming);
      in
        if collisions == []
        then acc // incoming
        else
          throw ''
            libraries: external alias collision(s) detected in '${name}':
              ${concatStringsSep ", " collisions}
            Each name in external must be unique across all libs.
          ''
    )
    {}
    (attrNames all);
in
  # ── 4. final surface: flat aliases + namespaced (namespaced wins on clash) ─
  {inherit lib;} // flat // namespaced
