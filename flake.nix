{
  description = "Configuration Flake";

  outputs = inputs: let
    nixpkgs = "nixCore";
    excludes = let
      core = [
        "nixCore"
        "nixLegacy"
        "nixDarwin"
        "nixEdge"
      ];
    in {
      modules = core ++ ["treeFormatter" "treefmt"];
      overlays = core ++ ["nixHM" "home-manager"];
    };
    defaults = {allowUnfree = true;};

    src = import ./. {flake = {inherit nixpkgs excludes defaults inputs;};};
  in
    {inherit src;}
    # // src.${src.names.lib}.mkFlake {
    #   base = src;
    #   mods = {
    #     configurations = true;
    #     utilities = true;
    #     devShells = true;
    #     templates = true;
    #   };
    # }
    // {};

  inputs = {
    #~@ Core/Nix Infrastructure
    nixCore.url = "nixpkgs/nixos-unstable";
    nixLegacy.url = "nixpkgs/nixos-25.11";
    nixDarwin = {
      repo = "nix-darwin";
      owner = "LnL7";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    nixEdge = {
      ref = "nyxpkgs-unstable";
      repo = "nyx";
      owner = "chaotic-cx";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixCore";
        home-manager.follows = "nixHM";
        rust-overlay.follows = "rust";
      };
    };
    nixHM = {
      repo = "home-manager";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Display/Window Managers
    compositorNiri = {
      repo = "niri-flake";
      owner = "sodiboo";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Utilities:= formatting, tooling, secrets
    aiToolkit = {
      repo = "llm-agents.nix";
      owner = "numtide";
      type = "github";
      # inputs.nixpkgs.follows = "nixCore"; #? See llm-agents documentation
    };
    aiHermes = {
      repo = "hermes-agent";
      owner = "NousResearch";
      type = "github";
    };
    rust = {
      owner = "oxalica";
      repo = "rust-overlay";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    treeFormatter = {
      repo = "treefmt-nix";
      owner = "numtide";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    secretsManager = {
      repo = "sops-nix";
      owner = "Mic92";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ UI/UX:= shells, launchers, styling
    shellCaelestia = {
      repo = "shell";
      owner = "caelestia-dots";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixCore";
        quickshell.follows = "shellQuick";
      };
    };
    shellDankMaterial = {
      # ref = "stable";
      repo = "DankMaterialShell";
      owner = "AvengeMedia";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    shellDankMaterialPlugins = {
      repo = "dms-plugin-registry";
      owner = "AvengeMedia";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    shellNoctalia = {
      repo = "noctalia-shell";
      owner = "noctalia-dev";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    shellQuick = {
      repo = "quickshell";
      owner = "outfoxxed";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    styleManager = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Applications
    zenBrowser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixCore";
        home-manager.follows = "nixHM";
      };
    };
    vicinae = {
      repo = "vicinae";
      owner = "vicinaehq";
      type = "github";
    };
  };
}
