{
  lix,
  top,
  host,
  ...
} @ args: let
  inherit (lix.modules) mkModules;

  # data = {
  #   git = {
  #     group = "vcs";
  #     package = "gitFull";
  #   };
  #   lfs = {
  #     group = "vcs";
  #     package = "git-lfs";
  #   };
  #   gh = {
  #     group = "vcs";
  #     package = "gh";
  #   };
  #   jj = {
  #     group = "vcs";
  #     package = "jujutsu";
  #   };
  #   gitui = {
  #     group = "vcs";
  #     package = "gitui";
  #   };
  #   delta = {
  #     group = "vcs";
  #     package = "delta";
  #   };
  #   claude = {
  #     group = "ai";
  #     package = "claude-code";
  #   };
  #   codex = {
  #     group = "ai";
  #     package = "codex";
  #   };
  #   helix = {
  #     group = "editors";
  #     package = "helix";
  #   };
  #   vscode = {
  #     group = "editors";
  #     package = "vscode-fhs";
  #   };
  #   zed = {
  #     group = "editors";
  #     package = "zed-editor-fhs";
  #   };
  #   alacritty = {
  #     group = "terminals";
  #     package = "alacritty";
  #   };
  #   foot = {
  #     group = "terminals";
  #     package = "foot";
  #   };
  #   kitty = {
  #     group = "terminals";
  #     package = "kitty";
  #   };
  #   tmux = {
  #     group = "terminals";
  #     package = "tmux";
  #   };

  #   tailscale = {
  #     group = "connectivity";
  #     package = "tailscale";
  #   };
  # };

  moduleArgs = {
    inherit extraArgs;
    base = ./.;
    excludes = [
      "alacritty"
      "claude"
      "dank-material"
      "delta"
      "gh"
      "gitui"
      "hyprland"
      "kitty"
      "niri"
      "ollama"
      "starship"
      "vicinae"
      "caelestia"
      "codex"
      "foot"
      "git"
      "hermes"
      "jj"
      "mango"
      "noctalia"
      "openclaw"
      "tailscale"
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
