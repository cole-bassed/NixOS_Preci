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
      "test"
      "default.nix"
    ];
    includeFiles = true;
  }
)
