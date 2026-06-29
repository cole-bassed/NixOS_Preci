{lix, ...} @ args:
lix.importModules (args
  // {
    base = ./.;
    excludes = [
      "git"
      "kitty"
      "starship"
      "noctalia"
      "vicinae"
      "zen-browser"
    ];
  })
