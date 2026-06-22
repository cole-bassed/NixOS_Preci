{
  lib,
  top,
  config,
  osConfig,
  userName,
  userHome,
  ...
}: let
  inherit (lib.attrsets) mapAttrs optionalAttrs;

  home = userHome;
  gitProfiles = config.${top}.applications.git.profiles or {};

  local = {
    documents = home + "/Documents";
    downloads = home + "/Downloads";
    music = home + "/Music";
    pictures = home + "/Pictures";
    projects = home + "/Projects";
    videos = home + "/Videos";
  };

  pictures = let
    base = local.pictures;
  in {
    inherit base;
    avatars = {
      inherit base;
      session = base + "/Avatars/avatar.jpg";
      whatsapp = base + "/Avatars/avatar.jpg";
    };
    wallpapers = {
      inherit base;
      light = base + "/Wallpapers/light";
      dark = base + "/Wallpapers/dark";
    };
  };

  projects = let
    base = local.projects;
  in {
    inherit base;
    repos =
      optionalAttrs (gitProfiles != {})
      (mapAttrs (name: _: base + "/${name}") gitProfiles);
  };
in {
  config.${top} = {
    paths.local = local;
    paths.pictures = pictures;
    paths.projects = projects;
  };
}
