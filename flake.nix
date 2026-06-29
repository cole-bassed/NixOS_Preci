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
        modules.home = ["default"];
      };
      colmena = {
        input = "deployColmena";
        scopes = ["deployment"];
        # modules.nixos = [
        #   "deploymentOptions"
        #   "assertionModule"
        #   "keyChownModule"
        #   "keyServiceModule"
        #   "metaOptions"
        # ];
      };
      dank-material-shell = {
        input = "shellDankMaterial";
        scopes = ["desktop" "ui" "shell"];
        # modules = {
        #   nixos = ["default"];
        #   home = ["default" "niri"];
        # };
      };
      dms-plugin-registry = {
        input = "shellDankMaterialPlugins";
        scopes = ["desktop" "ui" "shell"];
        # modules = {
        #   nixos = ["default"];
        #   home = ["default"];
        # };
      };
      deploy-rs = {
        input = "deployRS";
        scopes = ["deployment"];
        # overlays = ["default"];
      };
      disko = {
        input = "deployDisks";
        scopes = ["deployment" "storage"];
        # modules.nixos = ["default"];
      };
      hermes-agent = {
        input = "aiHermes";
        scopes = ["development" "ai"];
        # modules.nixos = ["default"];
      };
      home-manager = {
        input = "nixHome";
        scopes = ["core"];
        modules = {
          darwin = ["default"];
          nixos = ["default"];
        };
      };
      llm-agents = {
        input = "aiToolkit";
        scopes = ["development" "ai"];
        overlays = ["default"];
      };
      mango = {
        input = "wmMango";
        scopes = ["desktop" "window-manager"];
        modules = {
          home = ["mango"];
          nixos = ["mango"];
        };
        overlays = ["default"];
      };
      niri = {
        input = "wmNiri";
        scopes = ["desktop" "window-manager"];
        modules.nixos = ["niri"];
        overlays = ["niri"];
      };
      nix-darwin = {
        input = "nixDarwin";
        scopes = ["core" "infrastructure"];
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
        # modules = {
        #   home = ["default"];
        #   nixos = ["default"];
        # };
        overlays = ["default"];
      };
      nyx = {
        input = "nixEdge";
        scopes = ["core" "infrastructure"];
        # modules = {
        #   home = [
        #     "default"
        #     "nyx-cache"
        #     "nyx-overlay"
        #     "nyx-registry"
        #   ];
        #   nixos = [
        #     "appmenu-gtk3-module"
        #     "default"
        #     "duckdns"
        #     "hdr"
        #     "mesa-git"
        #     "nordvpn"
        #     "nyx-cache"
        #     "nyx-home-check"
        #     "nyx-overlay"
        #     "nyx-registry"
        #     "zfs-impermanence-on-shutdown"
        #   ];
        # };
        overlays = ["default"];
      };
      quickshell = {
        input = "shellQuick";
        scopes = ["desktop" "ui" "shell"];
        overlays = ["default"];
      };
      rust-overlay = {
        input = "langRust";
        scopes = ["development" "code" "language"];
        overlays = ["default"];
      };
      sops = {
        input = "secretsManager";
        scopes = ["secrets"];
        modules = {
          darwin = ["default"];
          home = ["default"];
          nixos = ["default"];
        };
        overlays = ["default"];
      };
      stylix = {
        input = "styleManager";
        scopes = ["desktop" "theming" "ui"];
        # modules = {
        #   darwin = ["default"];
        #   home = ["default"];
        #   nixos = ["default"];
        # };
      };
      treefmt = {
        input = "treeFormatter";
        scopes = ["development" "code" "formatter"];
      };
      vicinae = {
        input = "vicinae";
        scopes = ["desktop" "launcher"];
        # modules = {
        #   home = ["default"];
        #   nixos = ["default"];
        # };
        overlays = ["default"];
      };
      vscode-server = {
        input = "vscodeServer";
        scopes = ["development" "editor"];
        # modules = {
        #   home = ["default"];
        #   nixos = ["default"];
        # };
      };
      zen-browser = {
        input = "browserZen";
        scopes = ["desktop" "browser"];
        modules.home = ["default"];
      };
    };

    lib = inputs.${inputs'.nixpkgs.input}.lib;
    inherit (lib.attrsets) attrNames attrValues filterAttrs getAttr genAttrs hasAttr mapAttrs optionalAttrs recursiveUpdate;
    inherit (lib.lists) any concatMap elem filter findFirst foldl' optionals unique;
    inherit (lib.strings) concatStringsSep;

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
      modules ? {},
      overlays ? [],
    }: let
      source = inputs.${input} // {name = input;};
    in {
      inherit scopes source;
      overlays = registerOverlays {inherit name source overlays;};
      libraries = registerLibraries source;
      packages = registerPackages source;
      modules = registerModules {inherit name source modules;};
    };

    registerModules = {
      name,
      source,
      modules,
    }: let
      fromClass = class: let
        key = findFirst (k: source ? ${k}) null classes.modules.${class};
      in
        optionalAttrs (key != null) source.${key};

      pickModules = class: set: let
        selected = modules.${class} or [];
        missing = filter (key: !(hasAttr key set)) selected;
      in
        if missing == []
        then map (key: getAttr key set) selected
        else
          throw "flake.registry.modules: ${name}.${class} missing module(s): ${
            concatStringsSep ", " missing
          }";

      modulesOf = class: let
        resolved = fromClass class;
        shouldInclude = resolved != {} && (modules.${class} or []) != [];
      in
        optionals shouldInclude (pickModules class resolved);
    in
      genAttrs classes.names modulesOf;

    registerLibraries = source: let
      set = source.lib or {};
    in
      set
      // optionalAttrs (set ? hm) set.hm
      // {};

    registerOverlays = {
      name,
      source,
      overlays,
    }: let
      set = source.overlays or {};
      missing = filter (key: !(hasAttr key set)) overlays;
      auto = let
        target =
          if set ? ${name}
          then name
          else "default";
      in
        set // {default = set.${target} or null;};
    in
      if overlays == []
      then auto
      else if missing == []
      then genAttrs overlays (key: getAttr key set)
      else throw "flake.registry.overlays: ${name} missing overlay(s): ${concatStringsSep ", " missing}";

    registerPackages = source:
      source.packages or {};

    registry = let
      entries =
        mapAttrs
        (name: spec: (registerInputs name spec))
        inputs';

      matchingScopes = wanted:
        filterAttrs (_: entry: any (scope: elem scope entry.scopes) wanted) entries;

      aggregated = {
        libraries = let
          base = entries.nixpkgs.libraries;
          extra =
            foldl'
            (acc: name: recursiveUpdate acc entries.${name}.libraries)
            {}
            ["nix-darwin"];
          named =
            mapAttrs
            (_: entry: entry.libraries)
            (
              filterAttrs
              (
                _: entry:
                  !elem "infrastructure" entry.scopes
                  && entry.libraries != {}
              )
              entries
            );
        in
          recursiveUpdate (recursiveUpdate base extra) named;

        modules = let
          entryList = attrValues entries;
          byScope = class: scope:
            concatMap
            (
              entry:
                optionals
                (elem scope entry.scopes)
                (entry.modules.${class} or [])
            )
            entryList;
          scopes = unique (concatMap (entry: entry.scopes) entryList);
          forClass = class:
            {
              all = concatMap (entry: entry.modules.${class} or []) entryList;
              select = wanted:
                concatMap
                (entry: entry.modules.${class} or [])
                (attrValues (matchingScopes wanted));
            }
            // genAttrs scopes (byScope class);
        in
          genAttrs classes.names forClass;

        overlays = let
          entryList = attrValues entries;
          values = entry: filter (v: v != null) (attrValues entry.overlays);
          byScope = scope:
            concatMap
            (entry: optionals (elem scope entry.scopes) (values entry))
            entryList;
          scopes = unique (concatMap (entry: entry.scopes) entryList);
        in
          {
            all = concatMap values entryList;
            select = wanted:
              concatMap
              values
              (attrValues (matchingScopes wanted));
          }
          // genAttrs scopes byScope;

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
    {
      lib = base;
      inherit flake;
    }
    // libs.mkFlake {
      inherit base;
      mods = {
        configuration = true;
        utilities = true;
        shells = true;
        templates = true;
      };
    }
    // {};
}
