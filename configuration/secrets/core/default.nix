flake: {
  config,
  host,
  pkgs,
  ...
}: let
  inherit (builtins) attrNames concatLists listToAttrs pathExists;

  hostName = host.name;
  enabledUsers = host.users.byStatus.enabled.values or {};
  enabledUserNames = attrNames enabledUsers;

  hostSecretFile = let
    canonical = ../../api/hosts/${hostName}/secrets.yaml;
    review = ../../api/hosts/review/${hostName}/secrets.yaml;
  in
    if pathExists canonical
    then canonical
    else review;

  userSecretFile = userName: ../../api/users/${userName}/secrets.yaml;

  homeDir = userName: "/home/${userName}";
  sshDir = userName: "${homeDir userName}/.ssh";
  githubDir = userName: "${sshDir userName}/github";

  githubIdentities = userName:
    attrNames (enabledUsers.${userName}.git or {});

  mkAttrs = listToAttrs;

  mkDirRules = userName: let
    identities = githubIdentities userName;
  in
    ["d ${sshDir userName} 0700 ${userName} users - -"]
    ++ (if identities == [] then [] else ["d ${githubDir userName} 0700 ${userName} users - -"]);

  dirRules = concatLists (map mkDirRules enabledUserNames);

  hostSecrets = {
    "services/hermes/env" = {
      sopsFile = hostSecretFile;
    };
    "services/tailscale/authKey" = {
      sopsFile = hostSecretFile;
    };
  };

  mkPasswordSecret = userName: {
    name = "users/${userName}/passwordHash";
    value = {
      sopsFile = userSecretFile userName;
      neededForUsers = true;
    };
  };

  mkPrimarySshSecrets = userName: [
    {
      name = "ssh/${userName}/id_ed25519/private";
      value = {
        sopsFile = userSecretFile userName;
        owner = userName;
        path = "${sshDir userName}/id_ed25519";
        mode = "0600";
      };
    }
    {
      name = "ssh/${userName}/id_ed25519/public";
      value = {
        sopsFile = userSecretFile userName;
        owner = userName;
        path = "${sshDir userName}/id_ed25519.pub";
        mode = "0644";
      };
    }
  ];

  mkGithubSecrets = userName:
    concatLists (
      map
      (identity: [
        {
          name = "ssh/${userName}/github/${identity}/private";
          value = {
            sopsFile = userSecretFile userName;
            owner = userName;
            path = "${githubDir userName}/${identity}";
            mode = "0600";
          };
        }
        {
          name = "ssh/${userName}/github/${identity}/public";
          value = {
            sopsFile = userSecretFile userName;
            owner = userName;
            path = "${githubDir userName}/${identity}.pub";
            mode = "0644";
          };
        }
      ])
      (githubIdentities userName)
    );

  userSecrets = mkAttrs (
    concatLists (
      map
      (userName:
        [mkPasswordSecret userName]
        ++ mkPrimarySshSecrets userName
        ++ mkGithubSecrets userName)
      enabledUserNames
    )
  );

  passwordAssignments = mkAttrs (
    map (userName: {
      name = userName;
      value.hashedPasswordFile =
        config.sops.secrets."users/${userName}/passwordHash".path;
    }) enabledUserNames
  );
in {
  environment.systemPackages = with pkgs; [
    age
    ssh-to-age
    ssh-to-pgp
    sops
    gnupg
    openssh
  ];

  systemd.tmpfiles.rules = dirRules;

  sops = {
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    secrets = hostSecrets // userSecrets;
  };

  users.users = passwordAssignments;
}
