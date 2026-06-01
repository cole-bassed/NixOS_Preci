{
  config,
  inputs,
  host,
  pkgs,
  lib ? pkgs.lib,
  ...
}: let
  inherit (inputs) sops-nix;
  inherit (lib.attrsets) attrValues mapAttrs mapAttrs' nameValuePair;
  inherit (lib.lists) optionals toList unique;
  inherit (lib.strings) concatStringsSep;

  names = {
    user = host.users.primary.name;
    host = host.name;
  };

  join = {
    prefix ? [],
    name,
    suffix ? [],
    sep ? "-",
  }:
    concatStringsSep sep (
      optionals (prefix != null) (toList prefix)
      ++ [name]
      ++ optionals (suffix != null) (toList suffix)
    );

  resolved = config.sops.secrets;

  ssh = {
    host.paths.key = join {
      name = "ssh_host_ed25519_key";
      prefix = ["/etc" "ssh"];
      sep = "/";
    };

    user = let
      name = names.user;
      sys = names.host;
      home = "/home/${name}";

      mk = {
        secret = {
          prefix,
          suffix ? null,
        }:
          join {
            inherit name prefix suffix;
            sep = "/";
          };

        path = {
          base ? [],
          file,
          ext ? null,
        }:
          join {
            name =
              if ext != null
              then file + ext
              else file;
            prefix = [home] ++ base;
            sep = "/";
          };
      };

      github = let
        base = [".ssh" "github"];
      in {
        craole = {
          inherit base;
          file = "craole";
        };
        craole-cc = {
          inherit base;
          file = "craole-cc";
        };
        cole-bassed = {
          inherit base;
          file = "cole-bassed";
        };
      };

      spec =
        {
          ${sys} = {
            base = [".ssh"];
            file = "id_ed25519";
          };
        }
        // mapAttrs' (n: v: nameValuePair "github-${n}" v) github;

      keys =
        mapAttrs (_: key: {
          private = mk.secret {
            prefix = ["ssh"];
            suffix = [key.file "private"];
          };
          public = mk.secret {
            prefix = ["ssh"];
            suffix = [key.file "public"];
          };
        })
        spec;

      paths =
        mapAttrs (_: key: {
          private = mk.path {
            base = key.base or [".ssh"];
            inherit (key) file;
          };
          public = mk.path {
            base = key.base or [".ssh"];
            inherit (key) file;
            ext = key.ext or ".pub";
          };
        })
        spec;

      secrets = mapAttrs' (n: _:
        nameValuePair keys.${n}.private {
          owner = name;
          path = paths.${n}.private;
          mode = "0600";
        })
      spec;

      dirs = unique (
        map (key:
          join {
            name = concatStringsSep "/" (key.base or [".ssh"]);
            prefix = [home];
            sep = "/";
          })
        (attrValues spec)
      );

      dirRules = map (dir: "d ${dir} 0700 ${name} users - -") dirs;
    in {inherit spec keys paths secrets dirs dirRules;};
  };

  user = {
    name = names.user;
    sys = names.host;
    home = "/home/${names.user}";
    keys.login.${names.host} = join {
      name = names.user;
      prefix = ["users"];
      suffix = "passwordHash";
      sep = "/";
    };
    inherit (ssh) user;
  };

  secrets = {
    login = user.keys.login.${names.host};
    ssh = ssh.user.secrets;
  };
in {
  imports = [sops-nix.nixosModules.sops];

  environment.systemPackages = with pkgs; [
    age
    ssh-to-age
    ssh-to-pgp
    sops
    gnupg
    openssh
  ];

  systemd.tmpfiles.rules = ssh.user.dirRules;

  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";

    age.sshKeyPaths = [ssh.host.paths.key];

    secrets =
      {${secrets.login}.neededForUsers = true;}
      // secrets.ssh;
  };

  users.users.${names.user}.hashedPasswordFile =
    resolved.${secrets.login}.path;
}
