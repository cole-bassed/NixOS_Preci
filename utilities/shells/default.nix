{lix, ...}: let
  inherit (lix.config) forEachSystem;
in {
  devShells = forEachSystem (pkgs: {
    default = pkgs.mkShell {
      name = "dots";
      packages = with pkgs; [git sops];
    };
  });
}
