flake: let
  inherit (flake.libraries) forEachSystem;
in {
  packages = forEachSystem (pkgs: {});
  devShells = forEachSystem (pkgs: {
    default = pkgs.mkShell {
      inherit (flake) name;
      packages = with pkgs; [git sops];
    };
  });
}
