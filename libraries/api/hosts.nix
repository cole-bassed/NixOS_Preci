{
  defaults,
  attrsets,
  lists,
  users,
  displays,
  api,
  ...
}: let
  exports = {
    scoped = {
      inherit registry getScopes normalize;
      inherit (registry) default;
    };

    global = {
      hostAPI = registry;
      getHostScopes = getScopes;
      normalizeHost = normalize;
    };
  };
  inherit (attrsets) attrNames mapAttrs;
  inherit (lists) asListIf elem head unique;

  normalize = host: let
    arch = host.arch or "x86_64";
    os = host.os or "linux";
    class = host.class or "nixos";
    system = host.system or "${arch}-${os}";
  in
    host // {inherit arch os class system;};

  registry = let
    specs =
      mapAttrs
      (_: host:
        normalize (
          host
          // {
            users = users.resolveUsers host;
            devices = (host.devices or {}) // {display = displays.resolveDisplays host;};
          }
        ))
      api.hosts;

    known = specs;
    fallback = known.${defaults.host} or known.${head (attrNames known)};
  in
    known // {default = normalize fallback;};

  getScopes = host: let
    type = host.type or "desktop";
    isDesktop = type == "laptop" || type == "desktop";

    iface = host.interface or {};
    wm = iface.windowManager or null;
    de = iface.desktopEnvironment or null;
    hasUI = isDesktop && (wm != null || de != null);

    funcs = host.functionalities or [];
  in
    unique (
      [
        "core"
        "infrastructure"
        "secrets"
        "deployment"
      ]
      ++ (
        asListIf isDesktop [
          "ai"
          "browser"
          "code"
          "desktop"
          "development"
          "editor"
          "formatter"
          "language"
          "launcher"
          "theming"
          "ui"
        ]
      )
      ++ (asListIf hasUI ["window-manager" "shell"])
      ++ (asListIf (elem "storage" funcs) "storage")
    );
in
  exports
