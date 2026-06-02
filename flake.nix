{
  description = "Configuration Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    hermes-agent.url = "github:NousResearch/hermes-agent";
    vicinae.url = "github:vicinaehq/vicinae";
    quickshell.url = "github:outfoxxed/quickshell";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {self, ...} @ inputs: let
    modules = {
      core = with inputs; [
        hermes-agent.nixosModules.default
        home-manager.nixosModules.home-manager
        niri.nixosModules.niri
        noctalia.nixosModules.default
        sops.nixosModules.default
        stylix.nixosModules.stylix
      ];

      home = with inputs; [
        niri.homeModules.config
        niri.homeModules.niri
        niri.homeModules.stylix
        noctalia.homeModules.default
        sops.homeModules.default
        stylix.homeManagerModules.stylix
        vicinae.homeManagerModules.default
        zen-browser.homeModules.default
      ];
    };
    libraries = with inputs; {
      nixpkgs = nixpkgs.lib;
      home-manager = home-manager.lib;
      treefmt-nix = treefmt.lib;
    };
    args = import ./. {inherit inputs modules libraries;};
    inherit (args.libraries.config) mkConfigurations;
  in (mkConfigurations {
    class = "nixos";
    inherit args;
  });
}
