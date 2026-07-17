{
  attrsets,
  lists,
  strings,
  ...
}: let
  exports = {
    scoped = {inherit mkHyprlandBinds mkNiriBinds;};
    global = {
      mkBackendHyprlandBinds = mkHyprlandBinds;
      mkBackendNiriBinds = mkNiriBinds;
    };
  };

  inherit (attrsets) filterAttrs;
  inherit (lists) filter;
  inherit (strings) concatStringsSep;

  # ---------------------------------------------------------------------
  # Shared input shape, everywhere in this file:
  #   entries :: [ { key :: String; mod :: [String]; action :: String; } ]
  # This is exactly `(mkBindings { ... }).entries` from
  # libraries/config/assembly.nix -- already backend-agnostic. These
  # helpers are pure formatters: they turn that one list into each
  # compositor's native bind syntax. No re-derivation from `actions`
  # happens here; if `entries` is wrong, fix it at the mkBindings layer,
  # not per-backend.
  # ---------------------------------------------------------------------

  # Hyprland's bind syntax: "MOD1 MOD2, KEY, exec, ACTION"
  mkHyprlandBinds = entries: let
    valid = filter (e: e.action != null && e.key != null) entries;
    format = e: "${concatStringsSep " " e.mod}, ${e.key}, exec, ${e.action}";
  in
    map format valid;

  # Niri's bind syntax: attrset keyed "Mod+Key" -> { action.spawn = [...]; }
  mkNiriBinds = entries: let
    valid = filter (e: e.action != null && e.key != null) entries;
    toBindKey = e: concatStringsSep "+" (e.mod ++ [e.key]);
    toSpawn = action: {action.spawn = ["sh" "-lc" action];};
  in
    filterAttrs (_: v: v != null) (
      builtins.listToAttrs (map (e: {
          name = toBindKey e;
          value = toSpawn e.action;
        })
        valid)
    );
in
  exports
