{
  lib,
  inputs,
}: let
  exports = {
    internal = {inherit mkNix mkNixConfigurations;};
    external = {inherit mkNixConfigurations;};
  };

  inherit (lib.attrsets) isAttrs mapAttrs;

  mkNix = {
    nixosSystem,
    dots,
    extraArgs ? {},
    modules,
    system,
    top,
  }:
    nixosSystem {
      inherit modules system;
      specialArgs = {inherit inputs dots top;} // extraArgs;
    };

  mkNixConfigurations = args:
    assert isAttrs args;
    assert lib ? nixosSystem != null; {
      nixosConfigurations = mapAttrs (_: host:
        mkNix {
          inherit (lib) nixosSystem;
          system = host.system or args.defaults.system;
          dots = host.dots or args.defaults.dots;
          top = host.namespace or args.defaults.namespace;
          modules = (args.modules or []) ++ (host.modules or []);
          extraArgs = {inherit host;} // args;
        })
      args.api.hosts or {};
    };
in
  exports
