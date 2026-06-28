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
      caelestia-shell = {
        input = "shellCaelestia";
        scopes = ["desktop" "ui" "shell"];
      };
      colmena = {
        input = "deployColmena";
        scopes = ["deployment" "nixos"];
      };
      dank-material-shell = {
        input = "shellDankMaterial";
        scopes = ["desktop" "ui" "shell"];
      };
      deploy-rs = {
        input = "deployRS";
        scopes = ["deployment"];
      };
      disko = {
        input = "deployDisks";
        scopes = ["deployment" "storage" "nixos"];
      };
      dms-plugin-registry = {
        input = "shellDankMaterialPlugins";
        scopes = ["desktop" "ui" "shell"];
      };
      hermes-agent = {
        input = "aiHermes";
        scopes = ["development" "ai"];
      };
      home-manager = {
        input = "nixHome";
        scopes = ["core" "nixos" "darwin"];
      };
      llm-agents = {
        input = "aiToolkit";
        scopes = ["development" "ai"];
      };
      mango = {
        input = "wmMango";
        scopes = ["desktop" "window-manager" "nixos"];
      };
      niri = {
        input = "wmNiri";
        scopes = ["desktop" "window-manager" "nixos"];
      };
      nix-darwin = {
        input = "nixDarwin";
        scopes = ["core" "infrastructure" "darwin"];
      };
      nixos-anywhere = {
        input = "deployAnywhere";
        scopes = ["deployment"];
      };
      nixpkgs = {
        input = "nixCore";
        scopes = ["core" "infrastructure"];
      };
      nixpkgs-stable = {
        input = "nixLegacy";
        scopes = ["core" "infrastructure"];
      };
      noctalia = {
        input = "shellNoctalia";
        scopes = ["desktop" "ui" "shell"];
      };
      nyx = {
        input = "nixEdge";
        scopes = ["core" "infrastructure"];
      };
      quickshell = {
        input = "shellQuick";
        scopes = ["desktop" "ui" "shell"];
      };
      rust-overlay = {
        input = "langRust";
        scopes = ["development" "code" "language"];
      };
      sops = {
        input = "secretsManager";
        scopes = ["secrets" "nixos" "darwin" "home"];
      };
      stylix = {
        input = "styleManager";
        scopes = ["desktop" "theming" "ui" "nixos" "darwin" "home"];
      };
      treefmt = {
        input = "treeFormatter";
        scopes = ["development" "code" "formatter"];
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
    inherit (lib.attrsets) attrNames attrValues filterAttrs getAttr genAttrs hasAttr mapAttrs optionalAttrs recursiveUpdate;
    inherit (lib.lists) concatMap elem filter findFirst foldl' length optionals toList;
    inherit (lib.strings) isAttrs isPath concatStringsSep;
    inherit (lib.trivial) isFunction;

    optionalList = check: value: optionals check (toList value);
    modulePolicy = {
      excludes = {darwin = ["nix-darwin"];};
      select = {
        nixos = {
          colmena = [
            "deploymentOptions"
            "assertionModule"
            "keyChownModule"
            "keyServiceModule"
          ];
        };
      };
    };

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
      modules ? [], #TODO: This should eventually be removed as scopes should drive class participation
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
      pickModules = type: set: let
        selected = (modulePolicy.select.${type} or {}).${name} or [];
        allowAll = elem name ((modulePolicy.all or {}).${type} or []);
        values = attrValues set;
        missing = filter (key: !(hasAttr key set)) selected;
      in
        if !isAttrs set
        then []
        else if selected != []
        then
          if missing == []
          then map (key: getAttr key set) selected
          else throw "flake.registry.modules: ${name}.${type} selected missing module(s): ${concatStringsSep ", " missing}"
        else if set ? default
        then [set.default]
        else if length values == 1
        then values
        else if allowAll
        then values
        else throw "flake.registry.modules: ${name}.${type} has multiple modules and no default; set flake.modules.select.${type}.${name} or add '${name}' to flake.modules.all.${type}";

      fromClass = class: let
        key = findFirst (k: source ? ${k}) null classes.modules.${class};
      in
        optionalAttrs (key != null) source.${key};

      detected = filter (class: fromClass class != {}) classes.names;

      includes = let
        explicit = toList modules;
        fromScopes = filter (scope: elem scope classes.names) scopes;
      in
        if explicit != []
        then explicit
        else filter (class: elem class fromScopes) detected;

      fromSet = class: set: let
        candidate = set.${name} or (set.default or set);
      in
        if isFunction candidate || isPath candidate
        then toList candidate
        else if (candidate ? config || candidate ? options || candidate ? imports)
        then toList candidate
        else pickModules class candidate;

      modulesOf = class: let
        resolved = fromClass class;
        isExcluded = elem name ((modulePolicy.excludes or {}).${class} or []);
        shouldInclude = resolved != {} && elem class includes && !isExcluded;
      in
        optionals shouldInclude (fromSet class resolved);
    in
      genAttrs
      classes.names
      (class: modulesOf class);
    # genAttrs
    # classes.names
    # (class: genAttrs (optionals (elem class includes) [class]) (_: modulesOf class));

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

    registry = let
      entries =
        mapAttrs
        (name: spec: (registerInputs name spec))
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
    flake = {
      inherit defaults registry;
      modules = modulePolicy;
    };
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
