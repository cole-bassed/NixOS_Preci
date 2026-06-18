{
  api,
  debug,
  attrsets,
  lists,
  external,
  types,
  flake,
  strings,
  defaults,
  ...
}: let
  exports = {
    scoped = {
      inherit per classification builder;
      forEach = per;
      getBuilder = builder;
      getClassification = classification;
    };
    global = {
      forEachSystem = per;
    };
  };

  inherit (attrsets) attrValues genAttrs;
  inherit (debug) withContext;
  inherit (lists) elem unique;
  inherit (types) isFunction;
  inherit (api) hosts;
  inherit (strings) concat;
  defaultHost = api.hosts.${defaults.host};

  classification = class:
    assert withContext {
      name = "config.systemType";
      assertion = elem class ["nixos" "darwin"];
      message = ''expected one of ["nixos" "darwin"], got ${class}'';
      context = "parsing system type from class";
    };
      if class == "darwin"
      then "darwinConfigurations"
      else "nixosConfigurations";

  builder = class: let
    opts = ["nixos" "darwin"];
  in
    assert withContext {
      name = "config.systemBuilder";
      assertion = elem class opts;
      message = ''expected one of [${concat {
          delim = ", ";
          parts = opts;
        }}], got ${class}'';
      context = "parsing system builder from class";
    };
      if class == "nixos"
      then external.nixpkgs.nixosSystem
      else external.nix-darwin.darwinSystem;

  supported = {extra ? []}:
    unique (
      extra
      ++ map (host: host.system or host.platform or defaultHost.system)
      (attrValues hosts)
    );

  per = arg: let
    opts =
      if isFunction arg
      then {fn = arg;}
      else arg;
    packages = opts.packages or flake.packages.default;
    extra = opts.extra or [];
  in
    genAttrs
    (supported {inherit extra;})
    (system: opts.fn packages.${system});
  # TODO: add kind (get via parsing input or pkgs.stdenv.hostPaltform) and getOrDefault (via kind or builtins.currentSystem or most common system from api hosts)
in
  exports
