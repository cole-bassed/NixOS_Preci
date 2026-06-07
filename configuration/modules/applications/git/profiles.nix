{
  lib,
  pkgs,
  mod,
  packages,
  mkArgs,
  ...
}: let
  name = "profiles";
  inherit (lib.attrsets) attrNames attrValues mapAttrs mapAttrs' optionalAttrs;
  inherit (lib.lists) all optionals;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.types) attrsOf literalExpression str;
in {
  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config scope;}) cfg opt;

    home = config.home.homeDirectory;

    mkUser = profile: {
      name = profile;
      email = cfg.${name}.${profile};
    };

    mkGitInclude = path: profile: {
      condition = "gitdir:${path}";
      contents.user = mkUser profile;
    };

    mkGithubHost = profile: {
      HostName = "github.com";
      User = "git";
      IdentityFile = "${home}/.ssh/github/${profile}";
      IdentitiesOnly = true;
    };

    autoRepos =
      mapAttrs'
      (profile: _: {
        name = "${cfg.projectRoot}/${profile}/";
        value = profile;
      })
      cfg.${name};

    allRepos = autoRepos // cfg.extraRepositories;

    hasProfiles = cfg.${name} != {};

    ghClone = pkgs.writeShellApplication {
      name = "gh-clone";
      runtimeInputs = [packages.${mod} pkgs.coreutils];
      text = ''
        usage() {
          cat <<'EOF'
        usage:
          gh-clone <profile> <owner/repo>
          gh-clone <profile> <owner/repo> <target-name>

        examples:
          gh-clone craole-cc craole-cc/dots
          gh-clone craole Craole/example
          gh-clone cole-bassed cole-bassed/site website
        EOF
        }

        profile="''${1:-}"
        repo="''${2:-}"
        target="''${3:-}"

        if [ -z "$profile" ] || [ -z "$repo" ]; then
          usage
          exit 2
        fi

        case "$profile" in
          ${concatStringsSep "|" (attrNames cfg.${name})})
            ;;
          *)
            echo "error: unknown profile: $profile" >&2
            echo "valid ${name}: ${concatStringsSep ", " (attrNames cfg.${name})}" >&2
            exit 2
            ;;
        esac

        case "$repo" in
          */*)
            ;;
          *)
            echo "error: repo must look like owner/repo" >&2
            exit 2
            ;;
        esac

        owner="''${repo%%/*}"
        name="''${repo##*/}"
        name="''${name%.git}"

        [ -z "$target" ] && target="$name"

        base="${cfg.projectRoot}/$profile"
        dest="$base/$target"
        url="git@github_$profile:$owner/$name.git"

        mkdir -p "$base"

        if [ -e "$dest" ]; then
          echo "error: destination already exists: $dest" >&2
          exit 1
        fi

        git clone "$url" "$dest"
      '';
    };
  in {
    options = opt {
      ${name} = mkOption {
        type = attrsOf str;
        default = {};
        description = "Git ${name} mapping username to email address.";
        example = literalExpression ''
          {
            craole = "32288735+Craole@users.noreply.github.com";
          }
        '';
      };

      defaultProfile = mkOption {
        type = str;
        default = "";
        description = "Default profile name for git user configuration.";
      };

      projectRoot = mkOption {
        type = str;
        default = "${home}/Projects";
        description = "Base directory for project repositories.";
      };

      extraRepositories = mkOption {
        type = attrsOf str;
        default = {};
        description = ''
          Extra repository path-to-profile mappings. Paths not under
          ''${projectRoot}/<<profile>/ must be declared here.
        '';
      };
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = !hasProfiles || cfg.${name} ? ${cfg.defaultProfile};
          message = "applications.git.defaultProfile must be a key in applications.git.${name}";
        }
        {
          assertion = !hasProfiles || all (p: cfg.${name} ? ${p}) (attrValues cfg.extraRepositories);
          message = "All ${name} in applications.git.extraRepositories must exist in applications.git.${name}";
        }
      ];

      home.packages = optionals hasProfiles [ghClone];

      programs = {
        ${mod} = {
          settings = optionalAttrs hasProfiles {
            user = mkUser cfg.defaultProfile;
          };
          includes = optionals hasProfiles (attrValues (mapAttrs mkGitInclude allRepos));
        };

        ssh = mkIf hasProfiles {
          enable = mkDefault true;
          enableDefaultConfig = mkDefault false;
          settings =
            {
              "*" = {
                AddKeysToAgent = "no";
                ForwardAgent = false;
                ServerAliveInterval = 0;
              };
            }
            // mapAttrs'
            (profile: _: {
              name = "github_${profile}";
              value = mkGithubHost profile;
            })
            cfg.${name};
        };
      };
    };
  };
}
