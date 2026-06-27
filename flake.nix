{
  description = "Configuration Flake";

  outputs = inputs: let
    nixpkgs = "nixCore";
    lib = inputs.${nixpkgs}.lib;
    defaults = {allowUnfree = true;};

    core = ["nixCore" "nixLegacy" "nixDarwin" "nixEdge"];

    registry = let
      inherit (lib.attrsets) attrNames genAttrs listToAttrs mapAttrs optionalAttrs;
      inherit (lib.lists) elem findFirst optionals toList;
      inherit (lib.strings) toLower;
      optionalList = check: value: optionals check (toList value);

      resolveModules = {
        name,
        source,
        profiles,
        modules,
      }: let
        keys = {
          nixos = ["nixosModules"];
          darwin = ["darwinModules"];
          home = ["homeModules" "homeManagerModules" "hmModules"];
        };
        keyOf = class:
          findFirst (key: source ? ${key}) null keys.${class};

        resolve = class: let
          key = keyOf class;
          set = optionalAttrs (key != null) (src.${key} or {});
        in
          set.${name} or (set.default or []);

        classes =
          genAttrs
          (attrNames keys)
          (class: optionalList (elem class modules) (resolve class));
      in
        listToAttrs (
          map
          (profile: {
            name = profile;
            value = classes;
          })
          profiles
        );

      resolveLibraries = source: let
        key = findFirst (name: toLower name == "lib") null (attrNames src);
        lib = optionalAttrs (key != null) source.${key};
      in
        lib
        // optionalAttrs (lib ? hm) lib.hm
        # // optionalAttrs (lib ? internal) lib.internal
        # // optionalAttrs (lib ? _internal) lib._internal
        // {};

      resolveOverlays = {
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

      mkInput = name: {
        input,
        profiles ? [],
        modules ? ["nixos" "darwin" "home"],
      }: let
        source = inputs.${input} // {name = input;};
      in {
        inherit profiles source;
        modules = resolveModules {
          inherit name source profiles;
          modules = toList modules;
        };
        overlays = resolveOverlays {inherit name source;};
        libraries = resolveLibraries source;
      };
    in
      mapAttrs mkInput {
        nixpkgs = {
          input = nixpkgs;
          profiles = ["core" "infrastructure" "unstable"];
        };
        nixpkgs-stable = {
          input = "nixLegacy";
          profiles = ["core" "infrastructure" "stable"];
        };
        nix-darwin = {
          input = "nixDarwin";
          profiles = ["core" "darwin"];
        };
        nyx = {
          input = "nixEdge";
          profiles = ["core" "infrastructure" "unstable"];
        };
        home-manager = {
          input = "nixHome";
          profiles = ["core"];
        };
        niri = {
          input = "wmNiri";
          profiles = ["desktop" "windowManager"];
        };
        mango = {
          input = "wmMango";
          profiles = ["desktop" "windowManager"];
        };
        disko = {
          input = "deployDisks";
          profiles = ["deployment" "storage"];
        };
        deploy-rs = {
          input = "deployRS";
          profiles = ["deployment"];
        };
        colmena = {
          input = "deployColmena";
          profiles = ["deployment"];
        };
        nixos-anywhere = {
          input = "deployAnywhere";
          profiles = ["deployment"];
        };
        llm-agents = {
          input = "aiToolkit";
          profiles = ["tooling" "ai"];
        };
        hermes-agent = {
          input = "aiHermes";
          profiles = ["tooling" "ai" "assistant"];
        };
        rust-overlay = {
          input = "langRust";
          profiles = ["development" "language" "rust"];
        };
        treefmt = {
          input = "treeFormatter";
          profiles = ["tooling" "formatting"];
        };
        sops = {
          input = "secretsManager";
          profiles = ["secrets"];
        };
        caelestia-shell = {
          input = "shellCaelestia";
          profiles = ["desktop" "shell" "ui"];
        };
        dank-material-shell = {
          input = "shellDankMaterial";
          profiles = ["desktop" "shell" "ui"];
        };
        dms-plugin-registry = {
          input = "shellDankMaterialPlugins";
          profiles = ["desktop" "shell" "ui"];
        };
        noctalia = {
          input = "shellNoctalia";
          profiles = ["desktop" "shell" "ui"];
        };
        quickshell = {
          input = "shellQuick";
          profiles = ["desktop" "shell" "ui"];
        };
        stylix = {
          input = "styleManager";
          profiles = ["desktop" "theming"];
        };
        vicinae = {
          input = "vicinae";
          profiles = ["desktop" "launcher"];
        };
        vscode-server = {
          input = "vscodeServer";
          profiles = ["desktop" "editor"];
        };
        zen-browser = {
          input = "browserZen";
          profiles = ["desktop" "browser"];
        };
      };

    modules = {
      includes = {
        nixos = [];
        darwin = [];
        home = [];
      };

      excludes = {
        nixos = [];
        home = [];
        darwin = [];
      };

      select = {
        nixos = {};
        home = {};
        darwin = {};
      };

      all = {
        nixos = [];
        home = [];
        darwin = [];
      };

      # mkFlakeModules = class:
      #   map
      #   (entry: entry.value)
      #   (builtins.attrValues (
      #     builtins.filterAttrs (_: entry: entry.class == class) registry.modules
      #   ));
    };

    overlays = {
      registry = builtins.mapAttrs (_: entry: entry.value) registry.overlays;
    };

    excludes = {
      overlays = core ++ ["nixHM" "home-manager"];
    };

    src = import ./. {
      flake = {
        inherit defaults excludes modules inputs nixpkgs overlays registry;
      };
    };
    base = src.${src.names.src};
    libs = src.${src.names.lib};
  in
    {
      lib = base;
      inherit registry;
    }
    // libs.mkFlake {
      inherit base;
      mods = {
        configuration = true;
        utilities = true;
        shells = true;
        templates = true;
      };
    };

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
}
