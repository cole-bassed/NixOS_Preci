_flake: {
  config,
  host,
  pkgs,
  top,
  ...
}: let
  inherit (builtins) attrNames concatLists filter listToAttrs map pathExists readDir;

  hostName = host.name;
  enabledUsers = host.users.byStatus.enabled.values or {};
  enabledUserNames = attrNames enabledUsers;

  normalizeValue = value:
    if builtins.isBool value
    then {enable = value;}
    else if builtins.isAttrs value
    then ({enable = value.enable or true;} // value)
    else {
      enable = true;
      inherit value;
    };

  normalizeServices = value:
    if builtins.isList value
    then
      builtins.listToAttrs (map (name: {
          inherit name;
          value = {enable = true;};
        })
        value)
    else if builtins.isAttrs value
    then builtins.mapAttrs (_: normalizeValue) value
    else {};

  hostServices = normalizeServices (host.services or {});
  aiServices = hostServices.ai or {};
  hermesCfg = aiServices.hermes or {};
  hermesSecretCfg = hermesCfg.envSecret or {};
  tailscaleCfg = hostServices.tailscale or {};
  tailscaleSecretCfg = tailscaleCfg.authKeySecret or {};

  hostSecretFile = let
    hostRoots = filter pathExists [
      ../../../data/hosts
    ];

    dirNames = root:
      filter
      (name:
        ((readDir root).${name} == "directory")
        && pathExists (root + "/${name}/default.nix"))
      (attrNames (readDir root));

    nameMapped = root: dirName: let
      specPath = root + "/${dirName}/default.nix";
      spec = import specPath;
    in
      if (spec.name or dirName) == hostName
      then root + "/${dirName}/secrets.yaml"
      else null;

    discovered = concatLists (
      map
      (root:
        map
        (dirName: nameMapped root dirName)
        (dirNames root))
      hostRoots
    );

    existing = filter (file: file != null && pathExists file) (
      [
        ../../../data/hosts/${hostName}/secrets.yaml
      ]
      ++ discovered
    );
  in
    if existing == []
    then null
    else builtins.head existing;

  userSecretFile = userName: ../../../data/users/${userName}/secrets.yaml;

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
    ++ (
      if identities == []
      then []
      else ["d ${githubDir userName} 0700 ${userName} users - -"]
    );

  dirRules = concatLists (map mkDirRules enabledUserNames);

  mkHostSecret = name: {
    inherit name;
    value.sopsFile = hostSecretFile;
  };

  hostSecrets =
    if hostSecretFile == null
    then {}
    else
      mkAttrs (
        (
          if hermesSecretCfg.enable or hermesCfg.enable or false
          then [
            (mkHostSecret (hermesSecretCfg.name or "services/ai/hermes/env"))
          ]
          else []
        )
        ++ (
          if tailscaleSecretCfg.enable or false
          then [
            (mkHostSecret (tailscaleSecretCfg.name or "services/tailscale/authKey"))
          ]
          else []
        )
      );

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
        [(mkPasswordSecret userName)]
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
    })
    enabledUserNames
  );

  hermesSecretName = hermesSecretCfg.name or "services/ai/hermes/env";
  tailscaleSecretName = tailscaleSecretCfg.name or "services/tailscale/authKey";
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

  sops =
    {
      defaultSopsFormat = "yaml";
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      secrets = hostSecrets // userSecrets;
    }
    // (
      if hostSecretFile == null
      then {}
      else {defaultSopsFile = hostSecretFile;}
    );

  ${top}.services =
    (
      if hostSecretFile != null && (hermesSecretCfg.enable or hermesCfg.enable or false)
      then {
        ai.hermes.envSecret.path = config.sops.secrets.${hermesSecretName}.path;
      }
      else {}
    )
    // (
      if hostSecretFile != null && (tailscaleSecretCfg.enable or false)
      then {
        tailscale.authKeySecret.path = config.sops.secrets.${tailscaleSecretName}.path;
      }
      else {}
    );

  users.users = passwordAssignments;
}
