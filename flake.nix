{
  description = "Configuration Flake";

  inputs = {
    #~@ Core/Nix Infrastructure
    nixCore.url = "nixpkgs/nixos-unstable";
    nixLegacy.url = "nixpkgs/nixos-25.11";
    nixDarwin = {
      repo = "nix-darwin";
      owner = "LnL7";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    nixEdge = {
      ref = "nyxpkgs-unstable";
      repo = "nyx";
      owner = "chaotic-cx";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixCore";
        home-manager.follows = "nixHM";
        rust-overlay.follows = "rust";
      };
    };
    nixHM = {
      repo = "home-manager";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@
    compositorNiri = {
      repo = "niri-flake";
      owner = "sodiboo";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Utilities:= formatting, tooling, secrets
    aiToolkit = {
      repo = "llm-agents.nix";
      owner = "numtide";
      type = "github";
      # inputs.nixpkgs.follows = "nixCore"; #? See llm-agents documentation
    };
    aiHermes = {
      repo = "hermes-agent";
      owner = "NousResearch";
      type = "github";
    };
    rust = {
      owner = "oxalica";
      repo = "rust-overlay";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    treeFormatter = {
      repo = "treefmt-nix";
      owner = "numtide";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    secretsManager = {
      repo = "sops-nix";
      owner = "Mic92";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ UI/UX:= shells, launchers, styling
    shellCaelestia = {
      repo = "shell";
      owner = "caelestia-dots";
      type = "github";
      inputs.nixpkgs.follows = "nixLegacy";
    };
    shellDankMaterial = {
      # ref = "stable";
      repo = "DankMaterialShell";
      owner = "AvengeMedia";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    shellDankMaterialPlugins = {
      repo = "dms-plugin-registry";
      owner = "AvengeMedia";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    shellNoctalia = {
      repo = "noctalia-shell";
      owner = "noctalia-dev";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    shellQuick = {
      repo = "quickshell";
      owner = "outfoxxed";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    styleManager = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Applications
    zenBrowser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixCore";
        home-manager.follows = "nixHM";
      };
    };
    vicinae = {
      repo = "vicinae";
      owner = "vicinaehq";
      type = "github";
    };
  };

  outputs = {self, ...} @ inputs: let
    defaults = {
      allowUnfree = true;
      nixpkgs = inputs.nixCore;
    };

    lib = libraries.nixpkgs // libraries;
    inherit (lib.custom) collectModules filterInputs preferDefaultModules;
    inherit (lib.attrsets) attrValues mapAttrs filterAttrs;
    inherit (lib.lists) concatLists elem optionals;
    inherit (builtins) isAttrs isFunction isList isPath;

    libraries = with inputs; {
      nixpkgs = defaults.nixpkgs.lib;
      darwin = nixDarwin.lib;
      home-manager = nixHM.lib;
      treefmt = treeFormatter.lib;
      custom = rec {
        getAttrsDeep = level: let
          fn = depth: value:
            if depth <= 0
            then "..."
            else if isFunction value
            then "<function>"
            else if isPath value
            then "<path>"
            else if isList value
            then map (fn (depth - 1)) value
            else if isAttrs value
            then mapAttrs (_: fn (depth - 1)) value
            else value;
        in
          fn level;

        mkIncludes = excludes: set:
          filterAttrs (n: _: !(elem n excludes)) set;

        filterInputs = extraExcludes: let
          excludes =
            [
              #~@ Core infrastructure
              "self"
              "nixCore"
              "nixLegacy"
              "nixDarwin"
              "nixEdge"
            ]
            ++ extraExcludes;
          includes = mkIncludes excludes inputs;
        in {inherit excludes includes;};

        preferDefaultModules = modules:
          if modules ? default
          then [modules.default]
          else attrValues modules;

        collectModules = type: includes: let
          moduleAttr =
            {
              nixos = "nixosModules";
              darwin = "darwinModules";
              home = "homeModules";
            }.${
              type
            };
        in
          if type == "home"
          then
            concatLists (
              attrValues (
                mapAttrs (
                  _: input: let
                    hasHome = input ? homeModules;
                    mods =
                      if hasHome
                      then input.homeModules
                      else input.homeManagerModules or {};
                  in
                    preferDefaultModules mods
                )
                includes
              )
            )
          else
            concatLists (
              attrValues (
                mapAttrs (
                  _: input:
                    optionals
                    (input ? ${moduleAttr})
                    (preferDefaultModules input.${moduleAttr})
                )
                includes
              )
            );
      };
    };

    modules = let
      inputs' = filterInputs [
        #~@ Core infrastructure
        "rust"
        "treeFormatter"

        #~@ Conditional
        # "aiToolkit"
      ];
      collect = group: collectModules group inputs'.includes;

      config = {
        nixpkgs.config = {inherit (defaults) allowUnfree;};
      };

      mkCore = type: let
        nixos = collect "nixos" ++ [config];
        darwin = collect "darwin" ++ [config];
      in
        if type == "nixos"
        then nixos
        else if type == "darwin"
        then darwin
        else throw "modules::mkCore := Unknown module type '${type}'";
      home = collect "home";
    in
      inputs' // {inherit mkCore home;};

    overlays = let
      inputs' = filterInputs ["nixHM"];
      available = filterAttrs (_: v: v != []) (
        mapAttrs (
          _: input:
            optionals
            (input ? overlays)
            (preferDefaultModules input.overlays)
        )
        inputs'.includes
      );
      evaluated = concatLists (attrValues available);
    in
      inputs' // {inherit available evaluated;};

    packages = defaults.nixpkgs.legacyPackages;

    args = import ./. {
      flake = {
        inherit defaults inputs lib libraries modules overlays packages self;
      };
    };
  in
    {inherit args;}
    // args.libraries.assemble.flake args {
      configurations = true;
      utilities = true;
      devShells = false;
      templates = false;
    };
}
