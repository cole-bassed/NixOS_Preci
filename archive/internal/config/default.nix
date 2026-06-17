let
  mk = {
    input,
    output ? [],
    dependencies ? [
      "api"
      "assembly"
      "attrsets"
      "config"
      "debug"
      "defaults"
      "environment"
      "external"
      "filesystem"
      "flake"
      "ingestion"
      "lists"
      "names"
      "options"
      "paths"
      "strings"
      "systems"
      "types"
      "types"
      "users"
    ],
  }: {inherit input dependencies output;};
in {
  prefix = ["config"];
  specs = [
    (mk {input = ./assembly.nix;})
    (mk {input = ./environment.nix;})
    (mk {input = ./ingestion.nix;})
    (mk {input = ./systems.nix;})
    (mk {input = ./users.nix;})
  ];
}
