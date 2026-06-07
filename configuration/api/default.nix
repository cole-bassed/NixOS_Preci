{
  attrsets,
  lists,
  modules,
  defaults,
  ...
}: let
  exports = {
    scoped = {inherit getUsers;};
    global = {inherit hosts users;};
  };

  inherit (attrsets) attrNames mapAttrs;
  inherit (lists) elemAt filter length;
  # inherit (modules) getUsers;
  inherit (modules) collectNamedSpecs getUsers;
  inherit (defaults) excludes;

  # ---------------------------------------------------------------------------
  # TODO: Allow flat files (e.g., example.nix) alongside directories.
  # Currently, readDirAttrs/importModule drops flat files or expects a directory.
  # FIX NEEDED: Modify `readDirAttrs` or wrap this block to check if an entry is
  # a "regular" file ending in ".nix". If it is a file, import it directly
  # via (base + "/${name}"); if it is a "directory", use the current logic.
  # ---------------------------------------------------------------------------
  collectSpecs = tags: base:
    collectNamedSpecs {
      inherit base excludes tags;
      rekey = true;
    };

  specs = {
    hosts = collectSpecs "core" ./hosts;
    users = collectSpecs "home" ./users;
  };

  # ── user resolution ────────────────────────────────────────────────────────

  resolveUsers = host: let
    hostPath = "api/hosts/${host.name}";
    fail = msg: throw "${hostPath}: ${msg}";

    declared = host.users or {};
    isSingleUser = length (attrNames declared) == 1;

    resolveUser = userName: config: let
      spec =
        specs.users.${userName}
        or (fail "user '${userName}' not found in api/users");

      defaults' = {
        role =
          if isSingleUser
          then config.role or "administrator"
          else "user";
        enable =
          if isSingleUser
          then config.enable or true
          else true;
        primary =
          if isSingleUser
          then config.primary or true
          else false;
        autoLogin = false;
      };
    in
      spec // defaults' // config;

    resolved = getUsers (mapAttrs resolveUser declared);

    primary = let
      enabled = resolved.byStatus.enabled;
      candidates =
        filter
        (n: enabled.values.${n}.primary or false)
        enabled.names;
      name =
        if enabled.count == 0
        then null
        else if length candidates == 0 && enabled.count == 1
        then elemAt enabled.names 0
        else if length candidates == 0
        then fail "expected exactly one primary enabled user, found none"
        else if length candidates > 1
        then fail "expected exactly one primary enabled user, found ${toString (length candidates)}"
        else elemAt candidates 0;
    in {
      inherit name;
      value =
        if name == null
        then null
        else enabled.values.${name};
    };
  in
    resolved // {inherit primary;};

  # ── top-level outputs ──────────────────────────────────────────────────────

  hosts =
    mapAttrs
    (_: host: host // {users = resolveUsers host;})
    specs.hosts;

  inherit (specs) users;
in
  exports
