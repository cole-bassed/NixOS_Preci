{
  attrsets,
  lists,
  types,
  ...
}: let
  exports = {
    scoped = {inherit resolveTiers getAppCmd;};
    global = {inherit getAppCmd;};
  };

  inherit (lists) elemAt length;
  inherit (types) isList;

  # Smart cascading command resolver that reads fallbacks directly from a base registry
  getAppCmd = list: baseRegistry: index: let
    len =
      if list == null || !isList list
      then 0
      else length list;
    regLen = length baseRegistry;
    resolve = idx:
      if len > idx
      then (elemAt list idx).command
      else if idx > 0
      then resolve (idx - 1) # Cascade downwards to the user's next best configured option
      else if regLen > 0
      then (elemAt baseRegistry 0).command # Absolute emergency registry floor
      else "";
  in
    resolve index;

  # Meta-helper to dynamically map standard primary/alt/tertiary structures without repetition
  resolveTiers = prefix: list: baseRegistry: {
    "${prefix}" = getAppCmd list baseRegistry 0;
    "${prefix}Alt" = getAppCmd list baseRegistry 1;
    "${prefix}Tertiary" = getAppCmd list baseRegistry 2;
  };
in
  exports
