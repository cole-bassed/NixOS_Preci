{
  projectRootFile = "flake.nix";

  settings.excludes = [
    "flake.lock"
    ".envrc"
    "secrets/secrets.yaml"
    ".sops.yaml"
    "secrets/ssh/**"
    "*.min.js"
    "*.min.css"
    "node_modules/*"
    "target/*"
    "result*"
    ".direnv/*"
  ];

  programs = {
    #~@ Nix
    alejandra.enable = true;
    statix.enable = true;
    deadnix.enable = true;

    #~@ Shellscript
    shfmt.enable = true;
    shellcheck.enable = true;

    #~@ Rust
    rustfmt.enable = true;
    leptosfmt.enable = true;

    #~@ Web / Frontend
    biome.enable = true;
    prettier.enable = true;

    #~@ Data
    taplo.enable = true; #? TOML
    yamlfmt.enable = true; #? YAML
    jsonfmt.enable = true; #? JSON
    sql-formatter = {
      enable = true;
      dialect = "sqlite";
    };

    #~@ Documentation
    mdformat = {
      enable = true;
      plugins = ps:
        with ps; [
          mdformat-gfm
          mdformat-footnote
        ];
    };
    typstyle = {
      enable = true;
      lineWidth = 100;
      wrapText = true;
    };

    #~@ GitHub Actions
    actionlint.enable = true;

    #~@ Images (lossless PNG optimization for web assets)
    oxipng.enable = true;
  };
}
