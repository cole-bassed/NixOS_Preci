{
  description = "NixOS host configuration";

  outputs = inputs: let
    src = import ./. {flake = {inherit inputs;};};
  in
    src.lix.assemble.flake src {
      configurations = true;
    };

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
}
