{lix, ...}: let
  inherit (lix.systems) forEachSystem;
in {
  devShells = forEachSystem (pkgs: {
    default = pkgs.mkShell {
      name = "dots";
      packages = with pkgs; [git sops];
    };
  });
}
