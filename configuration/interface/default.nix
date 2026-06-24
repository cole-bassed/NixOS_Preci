{lix, ...} @ args:
lix.importModules (
  args
  // {
    base = ./.;
    excludes = [
      "browsers"
      "control"
      "gaming"
      "keyd"
      "login"
      "protocols"
      "sessions"
      "default.nix"
    ];
    includeFiles = true;
  }
)
