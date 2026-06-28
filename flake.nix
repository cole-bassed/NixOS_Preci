{
  description = "Configuration Flake";

  inputs = {
    #~@ Core/Nix Infrastructure
    nixCore.url = "nixpkgs/nixos-unstable";
    nixLegacy.url = "nixpkgs/nixos-26.05";
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
        home-manager.follows = "nixHome";
      };
    };
    nixHome = {
      repo = "home-manager";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Display/Window Managers
    wmNiri = {
      repo = "niri-flake";
      owner = "sodiboo";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    wmMango = {
      repo = "mango";
      owner = "mangowm";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Deployment
    deployDisks = {
      repo = "disko";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    deployRS = {
      repo = "deploy-rs";
      owner = "serokell";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    deployColmena = {
      repo = "colmena";
      owner = "zhaofengli";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    deployAnywhere = {
      repo = "nixos-anywhere";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Utilities:= formatting, tooling, secrets
    aiToolkit = {
      repo = "llm-agents.nix";
      owner = "numtide";
      type = "github";
    };
    aiHermes = {
      repo = "hermes-agent";
      owner = "NousResearch";
      type = "github";
    };
    langRust = {
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
      inputs = {
        nixpkgs.follows = "nixCore";
        quickshell.follows = "shellQuick";
      };
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
      repo = "noctalia";
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
      repo = "stylix";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Applications
    vicinae = {
      repo = "vicinae";
      owner = "vicinaehq";
      type = "github";
    };
    vscodeServer = {
      repo = "nixos-vscode-server";
      owner = "nix-community";
      inputs.nixpkgs.follows = "nixCore";
      type = "github";
    };
    browserZen = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixCore";
        home-manager.follows = "nixHome";
      };
    };
  };

  outputs = inputs: let
    inputs' = {
      nixpkgs = {
        input = "nixCore";
        scopes = ["core" "infrastructure"];
      };
      nixpkgs-stable = {
        input = "nixLegacy";
        scopes = ["core" "infrastructure"];
      };
      nix-darwin = {
        input = "nixDarwin";
        scopes = ["core" "infrastructure"];
      };
      nyx = {
        input = "nixEdge";
        scopes = ["core" "infrastructure"];
      };
      home-manager = {
        input = "nixHome";
        scopes = ["core"];
      };
      niri = {
        input = "wmNiri";
        scopes = ["desktop" "window-manager"];
      };
      mango = {
        input = "wmMango";
        scopes = ["desktop" "window-manager"];
      };
      disko = {
        input = "deployDisks";
        scopes = ["deployment" "storage"];
      };
      deploy-rs = {
        input = "deployRS";
        scopes = ["deployment"];
      };
      colmena = {
        input = "deployColmena";
        scopes = ["deployment"];
      };
      nixos-anywhere = {
        input = "deployAnywhere";
        scopes = ["deployment"];
      };
      llm-agents = {
        input = "aiToolkit";
        scopes = ["development" "ai"];
      };
      hermes-agent = {
        input = "aiHermes";
        scopes = ["development" "ai"];
      };
      rust-overlay = {
        input = "langRust";
        scopes = ["development" "code" "language"];
      };
      treefmt = {
        input = "treeFormatter";
        scopes = ["development" "code" "formatter"];
      };
      sops = {
        input = "secretsManager";
        scopes = ["secrets"];
      };
      caelestia-shell = {
        input = "shellCaelestia";
        scopes = ["desktop" "ui" "shell"];
      };
      dank-material-shell = {
        input = "shellDankMaterial";
        scopes = ["desktop" "ui" "shell"];
      };
      dms-plugin-registry = {
        input = "shellDankMaterialPlugins";
        scopes = ["desktop" "ui" "shell"];
      };
      noctalia = {
        input = "shellNoctalia";
        scopes = ["desktop" "ui" "shell"];
      };
      quickshell = {
        input = "shellQuick";
        scopes = ["desktop" "ui" "shell"];
      };
      stylix = {
        input = "styleManager";
        scopes = ["desktop" "theming" "ui"];
      };
      vicinae = {
        input = "vicinae";
        scopes = ["desktop" "launcher"];
      };
      vscode-server = {
        input = "vscodeServer";
        scopes = ["development" "editor"];
      };
      zen-browser = {
        input = "browserZen";
        scopes = ["desktop" "browser"];
      };
    };

    lib = inputs.${inputs'.nixpkgs.input}.lib;
    inherit (lib.attrsets) attrNames attrValues filterAttrs genAttrs mapAttrs optionalAttrs recursiveUpdate;
    inherit (lib.lists) any elem concatMap filter findFirst foldl' optionals toList;
    inherit (builtins) isFunction isPath;
    optionalList = check: value: optionals check (toList value);

    classes = {
      modules = {
        nixos = ["nixosModules"];
        darwin = ["darwinModules"];
        home = ["homeModules" "homeManagerModules" "hmModules"];
      };
      names = attrNames classes.modules;
    };

    registerInputs = name: {
      input,
      scopes,
      modules ? [], #TODO: This should eventually be removed as scopes should drive entries
    }: let
      source = inputs.${input} // {name = input;};
    in {
      inherit scopes source;
      overlays = registerOverlays {inherit name source;};
      libraries = registerLibraries source;
      packages = registerPackages source;
      modules = registerModules {inherit name source scopes modules;};
    };

    registerModules = {
      name,
      source,
      scopes,
      modules,
    }: let
      excludes = {
        entry = [
          # TODO: This is noise as well, it's obviously all the infrastructure inputs (filter entries with intrstructure in scope)
          "nixpkgs"
          "nixpkgs-stable"
          "nix-darwin"
          "nyx"
        ];

        # TODO: Why are we blocking scopes, or is this a test? At this rate maybe we need an excludes, but then why not comment our the inputs' we want to exclude. i uunderstand this is jts for modules, so why even is is not defined inside register modules. HAVING THIS STILL DOESN"T FIX        error: The option `nixpkgs' in module `/nix/store/pfwrb65dsv8phlsf1m98bvz11cvgb290-source/flake.nix' would be a parent of the following options, but its type `unspecified value' does not support nested options.
        # - option(s) with prefix `nixpkgs.buildPlatform' in module `/nix/store/pfwrb65dsv8phlsf1m98bvz11cvgb290-source/nixos/modules/misc/nixpkgs.nix'
        # - option(s) with prefix `nixpkgs.config' in module `/nix/store/pfwrb65dsv8phlsf1m98bvz11cvgb290-source/nixos/modules/misc/nixpkgs.nix'
        # - option(s) with prefix `nixpkgs.crossSystem' in module `/nix/store/pfwrb65dsv8phlsf1m98bvz11cvgb290-source/nixos/modules/misc/nixpkgs.nix'
        # - option(s) with prefix `nixpkgs.flake' in module `/nix/store/pfwrb65dsv8phlsf1m98bvz11cvgb290-source/nixos/modules/misc/nixpkgs-flake.nix'
        # - option(s) with prefix `nixpkgs.hostPlatform' in module `/nix/store/pfwrb65dsv8phlsf1m98bvz11cvgb290-source/nixos/modules/misc/nixpkgs.nix'
        # - option(s) with prefix `nixpkgs.initialSystem' in module `/nix/store/pfwrb65dsv8phlsf1m98bvz11cvgb290-source/nixos/modules/misc/nixpkgs.nix'
        # - option(s) with prefix `nixpkgs.localSystem' in module `/nix/store/pfwrb65dsv8phlsf1m98bvz11cvgb290-source/nixos/modules/misc/nixpkgs.nix'
        # - option(s) with prefix `nixpkgs.overlays' in module `/nix/store/pfwrb65dsv8phlsf1m98bvz11cvgb290-source/nixos/modules/misc/nixpkgs.nix'
        # - option(s) with prefix `nixpkgs.pkgs' in module `/nix/store/pfwrb65dsv8phlsf1m98bvz11cvgb290-source/nixos/modules/misc/nixpkgs.nix'
        # - option(s) with prefix `nixpkgs.system' in module `/nix/store/pfwrb65dsv8phlsf1m98bvz11cvgb290-source/nixos/modules/misc/nixpkgs.nix'
        scope = [
          "ai"
          "browser"
          "code"
          "editor"
          "formatter"
          "language"
          "launcher"
          "shell"
        ];
      };

      fromClass = class: let
        key = findFirst (k: source ? ${k}) null classes.modules.${class};
      in
        optionalAttrs (key != null) source.${key};

      includes = let
        explicit = toList modules;
        hasBlockedScope = any (scope: elem scope excludes.scope) scopes;
        hasBlockedEntry = elem name excludes.entry;
      in
        if explicit != []
        then explicit
        else if hasBlockedEntry || hasBlockedScope
        then []
        else filter (class: fromClass class != {}) classes.names;

      fromSet = set: let
        candidate = set.${name} or (set.default or set);
      in
        if isFunction candidate || isPath candidate
        then toList candidate
        else if (candidate ? config || candidate ? options || candidate ? imports)
        then toList candidate
        else attrValues candidate;

      modulesOf = class: let
        resolved = fromClass class;
        shouldInclude = resolved != {} && elem class includes;
      in
        optionals shouldInclude (fromSet resolved);
    in
      genAttrs
      (classes.names)
      (class: genAttrs scopes (_: modulesOf class));

    registerLibraries = source: let
      set = source.lib or {};
    in
      set
      // optionalAttrs (set ? hm) set.hm
      # // optionalAttrs (set ? internal) set.internal
      # // optionalAttrs (set ? _internal) set._internal
      // {};

    registerOverlays = {
      name,
      source,
    }: let
      set = source.overlays or {};
      target =
        if set ? ${name}
        then name
        else "default";
    in
      set // {default = set.${target} or null;};

    registerPackages = source:
      source.packages or {};

    # mkInput = name: {
    #   input,
    #   scopes ? [],
    #   ...
    # }: let
    #   source = inputs.${input} // {name = input;};
    # in {
    #   inherit scopes source;
    #   overlays = registerOverlays {inherit name source;};
    #   libraries = registerLibraries source;
    #   packages = registerPackages source;
    # };

    # mkModules = name: {
    #   input,
    #   scopes ? [],
    #   modules ? [],
    #   ...
    # }: let
    #   source = inputs.${input} // {name = input;};
    # in
    #   registerModules {
    #     inherit name source scopes;
    #     modules = toList modules;
    #   };

    registry = let
      entries =
        mapAttrs
        (name: spec: (registerInputs name spec))
        # (name: spec: (mkInput name spec) // {modules = mkModules name spec;})
        inputs';

      skip = ["nixpkgs-stable" "nyx"];
      flat = ["nix-darwin"];

      aggregated = {
        libraries = let
          base = entries.nixpkgs.libraries;
          flatExtras =
            foldl'
            (acc: name: recursiveUpdate acc entries.${name}.libraries)
            {}
            flat;
          named =
            mapAttrs
            (_: entry: entry.libraries)
            (filterAttrs
              (name: entry:
                !elem name (["nixpkgs"] ++ skip ++ flat)
                && entry.libraries != {})
              entries);
        in
          recursiveUpdate (recursiveUpdate base flatExtras) named;

        modules = let
          scopes = lib.lists.unique (concatMap (entry: entry.scopes or []) (attrValues entries));
          modulesFor = type:
            filterAttrs
            (_: value: value != [])
            (genAttrs scopes (scope:
              concatMap
              (entry: entry.modules.${type}.${scope} or [])
              (attrValues entries)));
        in
          genAttrs classes.names modulesFor;

        overlays =
          concatMap
          (
            entry: let
              d = entry.overlays.default or null;
            in
              optionalList (d != null) d
          )
          (attrValues entries);

        packages =
          mapAttrs
          (_: entry: entry.packages)
          (filterAttrs (_: entry: entry.packages != {}) entries);
      };
    in
      entries // {inherit aggregated;};
    defaults = {allowUnfree = true;};
    flake = {inherit defaults registry;};
    src = import ./. {inherit flake;};
    base = src.${src.names.src};
    libs = src.${src.names.lib};
  in
    {lib = base;}
    // flake
    // libs.mkFlake {
      inherit base;
      mods = {
        configuration = true;
        utilities = true;
        shells = true;
        templates = true;
      };
    };
}
