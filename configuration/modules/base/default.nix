# {
#   lix,
#   pkgs,
#   ...
# } @ args:
# lix.importModules (args
#   // {
#     inherit pkgs;
#     base = ./.;
#     includeFiles = true;
#   })
flake:
flake.libraries.modules.importModules {
  base = ./.;
  args = flake;
  includeFiles = true;
}
