{lists, ...}: let
  exports = {
    scoped = {inherit entrypoint entrypoints;};
    global = {inherit entrypoint entrypoints;};
  };

  # inherit (debug) withContext;
  inherit (lists) head;
  entrypoints.nix = let
    ext = "nix";
    candidates = map (name: "${name}.${ext}") [
      "default"
      "shell"
      "flake"
      "configuration"
      "_"
    ];
    primary = head candidates;
  in {inherit ext candidates primary;};
  entrypoint = entrypoints.nix.primary;
in
  exports
