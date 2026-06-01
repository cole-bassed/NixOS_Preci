{lib}: let
  exports = {
    internal = {inherit mkNixosConfigurations mkDarwinConfigurations;};
    external = exports.internal;
  };

  inherit (lib.attrsets) isAttrs mapAttrs;
  inherit (lib) nixosSystem darwinSystem;

  mkConfigurations = builder: outputAttr: args: let
    inherit (args) defaults;
    hosts = args.api.hosts or {};
  in
    assert isAttrs args;
    assert args ? inputs || throw "inputs must be provided in args"; {
      ${outputAttr} = mapAttrs (_: host: let
        modules = (args.modules or []) ++ (host.modules or []);
        system = host.system or defaults.system;
        dots = host.dots or defaults.dots;
        top = host.namespace or defaults.namespace;
        extraArgs = {inherit host;} // args // (args.extraArgs or {});
      in
        builder {
          inherit modules system;
          specialArgs = {inherit dots top;} // extraArgs;
        })
      hosts;
    };

  mkNixosConfigurations = mkConfigurations nixosSystem "nixosConfigurations";
  mkDarwinConfigurations = mkConfigurations darwinSystem "darwinConfigurations";
in
  exports
