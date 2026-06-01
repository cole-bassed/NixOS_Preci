{
  lib,
  lix,
  defaults,
}: let
  inherit (lib.attrsets) attrNames mapAttrs mapAttrs';
  inherit (lib.lists) elemAt filter length;
  inherit (lix) collectNamedSpecs;
  inherit (lix.modules) getUsers;

  # ── collect specs (spec.name wins over directory-derived key) ──────────────

  collectSpecs = base: let
    raw = collectNamedSpecs {
      inherit (defaults) ignore;
      args = {inherit lib lix defaults;};
      inherit base;
    };
  in
    mapAttrs' (_: spec: {
      name = spec.name or (throw "spec in ${toString base} is missing a name");
      value = spec;
    })
    raw;

  specs = {
    hosts = collectSpecs ./hosts;
    users = collectSpecs ./users;
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

  users = specs.users;
in {inherit hosts users;}
