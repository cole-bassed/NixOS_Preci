{
  config,
  pkgs,
  dots,
  ...
}: let
  apps = config.programs;

  dotsRun = pkgs.writeShellApplication {
    name = "dots-run";

    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gnugrep
      sudo
    ];

    text = ''
      dots="''${DOTS:-${dots}}"

      if [ "$#" -eq 0 ]; then
        echo "usage: dots-run <command> [args...]" >&2
        exit 2
      fi

      dots_writable() {
        [ -w "$dots" ] &&
          ! find "$dots" -not -user "$(id -un)" -print -quit | grep -q .
      }

      if dots_writable; then
        "$@"
      else
        sudo "$@"
      fi
    '';
  };

  dotsEdit = pkgs.writeShellApplication {
    name = "dots-edit";

    runtimeInputs = [
      dotsRun
    ];

    text = ''
      editor="''${EDITOR:-hx}"
      dots="''${DOTS:-${dots}}"

      dots-run "$editor" "$dots"
    '';
  };

  dotsCode = pkgs.writeShellApplication {
    name = "dots-code";

    runtimeInputs = [
      dotsRun
    ];

    text = ''
      visual="''${VISUAL:-code}"
      dots="''${DOTS:-${dots}}"

      dots-run "$visual" "$dots"
    '';
  };

  dotsFormat = pkgs.writeShellApplication {
    name = "dots-format";

    runtimeInputs = with pkgs; [
      alejandra
      statix
      dotsRun
    ];

    text = ''
      dots="''${DOTS:-${dots}}"

      dots-run statix fix "$dots"
      dots-run alejandra "$dots"
    '';
  };

  dotsUpdate = pkgs.writeShellApplication {
    name = "dots-update";

    runtimeInputs = with pkgs; [
      nix
      dotsRun
    ];

    text = ''
      dots="''${DOTS:-${dots}}"

      cd "$dots"
      dots-run nix flake update
    '';
  };
in {
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  environment = {
    sessionVariables = {
      DOTS = dots;
      EDITOR = "hx";
      VISUAL = "code";
    };

    shellAliases = {
      ede-dots = "dots-edit";
      ide-dots = "dots-code";

      cddots = ''cd "$DOTS"'';
      up = "dots-update";
      hix = "dots-edit";
      edots = "dots-edit";
      vdots = "dots-code";
      fdots = "dots-format";
      fix = "dots-format";

      llx = ''ll "$DOTS"'';
      ltx = ''lt "$DOTS"'';
      ltr = ''lr "$DOTS"'';

      build = ''nh os build "$DOTS"'';
      check = ''nh os test "$DOTS"'';
      switch = ''nh os switch "$DOTS"'';
    };

    systemPackages = with pkgs; [
      #~@ dotDots - helper commands
      dotsRun # ? Run commands against DOTS with sudo only when needed
      dotsEdit # ? Open DOTS using EDITOR with sudo only when needed
      dotsCode # ? Open DOTS using VISUAL with sudo only when needed
      dotsFormat # ? Format DOTS using alejandra with sudo only when needed
      dotsUpdate # ? Update DOTS flake lock with sudo only when needed

      #~@ Nix - formatters, LSPs, cache, prefetchers
      alejandra # ? Opinionated Nix formatter (primary)
      nixfmt # ? RFC-style Nix formatter (secondary)
      statix # ? Lints and suggestions for Nix - fixes antipatterns
      cachix # ? Binary cache management CLI
      nil # ? Nix LSP for static analysis
      nixd # ? Nix language server daemon
      nix-index # ? Index nixpkgs files for nix-locate
      nix-info # ? System info helper for bug reports
      nix-output-monitor # ? Pretty build progress - pipe via nom
      nix-prefetch # ? Prefetch arbitrary sources
      nix-prefetch-docker # ? Prefetch Docker image hashes
      nix-prefetch-github # ? Prefetch GitHub repo hashes
      nix-prefetch-scripts # ? Common prefetch script helpers
      nvfetcher # ? Auto-update/pin flake sources

      #~@ System - core utilities, hardware inspection
      coreutils # ? GNU core utilities
      uutils-coreutils-noprefix # ? Rust reimplementation of coreutils
      findutils # ? GNU find, xargs, locate
      gawk # ? GNU awk for text processing
      getent # ? Query Name Service Switch databases
      gnused # ? GNU stream editor
      lshw # ? Detailed hardware lister
      pciutils # ? PCI tools - lspci
      usbutils # ? USB tools - lsusb
      gnome-randr # ? Display configuration for GNOME/Wayland
      wlr-randr # ? Display configuration for wlroots WMs
      wl-clipboard-rs # ? Command-line copy/paste utilities for Wayland, written with Rust
      procs # ? Modern ps replacement with tree view

      #~@ Files - navigation, search, sync, cleanup
      dua # ? Interactive disk usage analyzer (TUI)
      dust # ? Intuitive du replacement
      eza # ? Modern ls with git integration
      fd # ? Fast, user-friendly find alternative
      fzf # ? General-purpose fuzzy finder
      lsd # ? Stylish ls with icons and Git integration
      ouch # ? 7zip wrapper for [de]compressing archives with progress
      p7zip # ? 7zip CLI for archive management
      rsync # ? Fast incremental file sync/transfer
      sad # ? CLI find-and-replace (batch sed)
      sd # ? CLI find and replace (sed alternative)
      trashy # ? Safe trash-aware rm alternative

      #~@ Network - transfer, GitHub
      curl # ? Command-line HTTP client
      wget # ? Non-interactive network downloader

      #~@ Dev - editors, VCS, data, media
      # bat # ? Cat clone with syntax highlighting and paging
      helix # ? Modal editor with native LSP + tree-sitter
      vscode-fhs
      zed-editor-fhs
      imagemagick # ? Image conversion and manipulation
      jql # ? JSON Query Language CLI tool built with Rust
      jq # ? Lightweight and flexible command-line JSON processor
      qimgv # ? Fast image viewer with minimal UI
      ripgrep # ? Fast recursive grep (rg)
      viu # ? Fast terminal image viewer with truecolor support

      #~@ Shell - monitoring, productivity, aesthetics
      btop # ? Rich resource monitor (htop replacement)
      fastfetch # ? Fast system info fetcher
      fend # ? Arbitrary-precision calculator REPL
      figlet # ? ASCII art text banners
    ];
  };

  programs = {
    bash = {
      enable = true;
      blesh.enable = true;
      undistractMe = {
        enable = true;
        timeout = 60;
        playSound = false;
      };
      vteIntegration = true;
    };

    bcc = {
      enable = true;
    };

    direnv = {
      enable = true;
      silent = true;
      settings = {
        global = {
          log_format = "-";
          log_filter = "^$";
        };
      };
    };

    git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
      config = {
        init = {
          defaultBranch = "main";
        };
      };
    };
    nix-ld.enable = true;

    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        # batdiff
        # batman
        # prettybat
      ];
      settings = {};
    };

    fzf = {
      fuzzyCompletion = true;
      keybindings = true;
    };

    starship = {
      enable = true;
    };

    nh = {
      enable = true;
      flake = dots;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5 --keep-since 3d";
      };
    };

    television = {
      enable = true;
      enableBashIntegration = apps.bash.enable;
      enableFishIntegration = apps.fish.enable;
      enableZshIntegration = apps.zsh.enable;
    };

    tmux = {
      enable = true;
    };
  };

  services = {};
}
