{
  lix,
  top,
  dom,
  mod,
  config,
  pkgs,
  dots,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) bool;

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
    runtimeInputs = [dotsRun];
    text = ''
      editor="''${EDITOR:-hx}"
      dots="''${DOTS:-${dots}}"
      dots-run "$editor" "$dots"
    '';
  };

  dotsCode = pkgs.writeShellApplication {
    name = "dots-code";
    runtimeInputs = [dotsRun];
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

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;
  in {
    options = opt {
      enable = mkEnableMod.true;
      nh = mkOption {
        type = bool;
        default = true;
        description = "Enable nh (Nix helper) with auto-cleanup.";
      };
      shellHelpers = mkOption {
        type = bool;
        default = true;
        description = "Enable dotfiles shell helpers.";
      };
    };

    config = mkIf enable (
      if scope == "core"
      then {
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        environment = {
          sessionVariables = {
            DOTS = dots;
            EDITOR = "hx";
            VISUAL = "code";
          };

          shellAliases = mkIf cfg.shellHelpers {
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

          systemPackages = with pkgs;
            [
              # Nix tooling
              alejandra
              nixfmt
              statix
              cachix
              nil
              nixd
              nix-index
              nix-info
              nix-output-monitor
              nix-prefetch
              nix-prefetch-docker
              nix-prefetch-github
              nix-prefetch-scripts
              nvfetcher

              # Core utils
              coreutils
              uutils-coreutils-noprefix
              findutils
              gawk
              getent
              gnused
              lshw
              pciutils
              usbutils
              wl-clipboard-rs
              procs

              # Files
              dua
              dust
              eza
              fd
              fzf
              lsd
              ouch
              p7zip
              rsync
              sad
              sd
              trashy

              # Network
              curl
              wget

              # Dev
              helix
              vscode-fhs
              zed-editor-fhs
              imagemagick
              jql
              jq
              qimgv
              ripgrep
              viu

              # Shell
              btop
              fastfetch
              fend
              figlet
            ]
            ++ (lib.optionals cfg.shellHelpers [
              dotsRun
              dotsEdit
              dotsCode
              dotsFormat
              dotsUpdate
            ]);
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

          bcc.enable = true;

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
            config.init.defaultBranch = "main";
          };

          nix-ld.enable = true;

          bat.enable = true;

          fzf = {
            fuzzyCompletion = true;
            keybindings = true;
          };

          starship.enable = true;

          nh = mkIf cfg.nh {
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
            enableFishIntegration = apps.fish.enable or false;
            enableZshIntegration = apps.zsh.enable or false;
          };

          tmux.enable = true;
        };
      }
      else {}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
