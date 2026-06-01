{lib ? (import <nixpkgs/lib>), ...}: let
  inherit (lib.lists) head;

  lix = import ./libraries {inherit lib defaults;};
  api = import ./api {inherit lib lix defaults;};

  modules = [
    ./ai
    ./applications
    ./interface
    ./modules
    ./secrets
  ];

  defaults = {
    inherit modules;
    # };
    namespace = "dots";
    dots = "/etc/nixos";
    ignore = [
      "archive"
      "backup"
      "review"
      "temp"
    ];
    entrypoints.nix = let
      ext = "nix";
      candidates = map (name: "${name}.${ext}") [
        "default"
        "shell"
        "flake"
        "configuration"
        "_"
      ];
    in {
      inherit candidates;
      main = head candidates;
    };
    tags = ["core" "home"];
  };
in {inherit lix api defaults modules;}
