{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues mapAttrs mapAttrs';

  home = config.home.homeDirectory;

  profiles = {
    craole = "32288735+Craole@users.noreply.github.com";
    craole-cc = "134658831+craole-cc@users.noreply.github.com";
    cole-bassed = "75517056+cole-bassed@users.noreply.github.com";
  };

  default = "craole-cc";
  projectRoot = "${home}/Projects";

  repos =
    {
      "${home}/.dots/" = "cole-bassed";
    }
    // mapAttrs'
    (
      profile: _: {
        name = "${projectRoot}/${profile}/";
        value = profile;
      }
    )
    profiles;

  mkUser = profile: {
    name = profile;
    email = profiles.${profile};
  };

  mkGitInclude = path: profile: {
    condition = "gitdir:${path}";
    contents = {
      user = mkUser profile;
    };
  };

  mkGithubHost = profile: {
    HostName = "github.com";
    User = "git";
    IdentityFile = "${home}/.ssh/github/${profile}";
    IdentitiesOnly = true;
  };

  ghClone = pkgs.writeShellApplication {
    name = "gh-clone";

    runtimeInputs = with pkgs; [
      coreutils
      git
    ];

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
                craole|craole-cc|cole-bassed)
                  ;;
                *)
                  echo "error: unknown profile: $profile" >&2
                  echo "valid profiles: craole, craole-cc, cole-bassed" >&2
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

              if [ -z "$target" ]; then
                target="$name"
              fi

              base="${projectRoot}/$profile"
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
  home.packages = [
    ghClone
  ];

  programs = {
    git = {
      settings = {
        user = mkUser default;
      };

      includes = attrValues (mapAttrs mkGitInclude repos);
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings =
        {
          "*" = {
            AddKeysToAgent = "no";
            ForwardAgent = false;
            ServerAliveInterval = 0;
          };
        }
        // mapAttrs'
        (
          profile: _: {
            name = "github_${profile}";
            value = mkGithubHost profile;
          }
        )
        profiles;
    };
  };
}
