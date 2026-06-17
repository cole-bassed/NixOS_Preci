{...}: {
  prefix = ["config"];
  specs = [
    ./assembly.nix
    ./environment.nix
    ./ingestion.nix
    ./systems.nix
    ./users.nix
  ];
}
