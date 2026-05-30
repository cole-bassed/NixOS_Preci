{
  description = "Configuration Flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
    };
    vicinae = {
      url = "github:vicinaehq/vicinae";
    };
    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        quickshell.follows = "quickshell";
      };
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = {nixpkgs, ...} @ inputs: let
    default = {
      modules = [
        ./modules
        ./applications
        ./profiles
        ./secrets
      ];
      system = "x86_64-linux";
      user = {
        name = "craole";
        description = "Craig 'Craole' Cole";
      };
      top = "dots";
      dots = "/etc/nixos";
      args = {inherit inputs;};
    };

    mkNix = {
      modules ? default.modules,
      system ? default.system,
      dots ? default.dots,
      top ? default.top,
      alpha ? default.user,
      extraArgs ? {},
    }:
      nixpkgs.lib.nixosSystem {
        inherit modules system;
        specialArgs =
          default.args
          // {
            inherit
              inputs
              alpha
              dots
              top
              ;
          }
          // extraArgs;
      };
  in {
    nixosConfigurations.Preci = mkNix {dots = "/home/craole/.dots";};
  };
}
