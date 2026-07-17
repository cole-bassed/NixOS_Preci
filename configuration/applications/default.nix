{
  lix,
  top,
  host,
  ...
} @ args: let
  inherit (lix.modules) mkModules;

  moduleArgs = {
    inherit extraArgs;
    base = ./.;
    excludes = [
      "alacritty"
      # "caelestia"
      "claude"
      "codex"
      "dank-material"
      "delta"
      "foot"
      "gh"
      "git"
      "gitui"
      "hermes"
      "hyprland"
      "jj"
      "kitty"
      "mango"
      "niri"
      "noctalia"
      "ollama"
      "openclaw"
      "starship"
      "tailscale"
      "vicinae"
      "zen-browser"
    ];
  };

  extraArgs = {
    # mkArgs = {
    #   config,
    #   path,
    #   pkgs ? {},
    #   scope ? "core",
    # }: let
    #   module = mkModuleArgs {
    #     inherit config top scope path pkgs host;
    #     lib = lix;
    #   };
    #   inherit (module) get set;
    #   inherit (get) name user hostEntry userEntry;

    #   entry = data.${name} or {};
    #   group = entry.group or name;
    #   # domain = head path;
    #   # hostEntry = attrByPath [domain group name] {} host;
    #   # userEntry = attrByPath [domain group name] {} user;
    #   # pkgName may be a flat string ("gitFull") or a nested path
    #   # (["llm-agents" "claude-code"]) — normalize to a list either way.
    #   pkg = {
    #     spec = get.package;
    #     path = toList pkg.spec;
    #     name = concatStringsSep "." pkg.path;
    #   };
    # in
    #   module
    #   // {
    #     fields = {
    #       enable = set.enable {
    #         default =
    #           hostEntry.enable or (
    #             userEntry.enable or (
    #               elem group (host.functionalities or [])
    #               || elem group (user.functionalities or [])
    #             )
    #           );
    #       };
    #       package = mkOption {
    #         type = package;
    #         default = attrByPath pkg.path null pkgs;
    #         description = "Package of '${pkg.name}' for ${scope}.";
    #       };
    #     };
    #   };
  };

  inner = mkModules (args // moduleArgs);
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
