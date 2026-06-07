# {flake, libraries, ...} @ base: let
#   inherit (libraries.lib.lists) concatMap;
#   inherit (libraries.modules) importModules;
#   pkgs = flake.packages.nixpkgs.x86_64-linux;
#   moduleArgs =
#     base
#     // {
#       inherit pkgs;
#       inherit (base.names) top;
#       inherit (flake) inputs;
#       inherit (libraries) lib lix;
#     };
# modules = importModules (moduleArgs // {base = ./modules;});
# secrets = importModules (moduleArgs // {base = ../secrets;});
# groupImports = groups: concatMap (group: group.imports or []) groups;
# groupHome = groups: concatMap (group: group.home-manager.sharedModules or []) groups;
{libraries, ...} @ base:
libraries.assemble.configurations base {
  modules = ./modules/base;
  # modules.core = [
  #   ({host, ...}: {
  #     system.stateVersion = host.stateVersion or null;
  #     # config.system.stateVersion = config.system.nixos.release;
  #   })
  # ]
  # ++ groupImports (modules.imports or []) ++ (secrets.imports or []);

  # modules.home =
  #   groupHome (modules.imports or [])
  #   ++ (modules.home-manager.sharedModules or [])
  #   ++ (secrets.home-manager.sharedModules or []);
}
