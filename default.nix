/**
Root entrypoint for the dotDots configuration framework.

This file wires together the repository's bootstrap layer, canonical path
registry, default evaluation settings, library namespace, and host-specific
configuration output.

It is the main import target for consumers that need the fully assembled
dotDots interface rather than an individual module, library, template, or
utility.

# Repository Layout

```text
.
├── archive
├── configuration
│   ├── api
│   │   ├── hosts
│   │   └── users
│   ├── modules
│   │   ├── ai
│   │   ├── applications
│   │   ├── base
│   │   └── interface
│   └── secrets
│       ├── core
│       └── home
├── debug
├── documentation
├── libraries
│   ├── bootstrap
│   ├── external
│   └── internal
├── templates
└── utilities
    └── shells
```

# Responsibilities

- Define canonical repository names.
- Define canonical repository paths.
- Load the minimal bootstrap library layer.
- Resolve default settings used by loaders and host selection.
- Load the main library namespace.
- Expose the API namespace.
- Build the selected host configuration through `mkDots`.
- Export useful metadata for inspection and downstream imports.

# Naming Registry

```nix
names = {
  src = "dots";
  top = "dots";
  lib = "lix";
};
```

src
: Human/project-facing name for the source tree.

top
: Top-level namespace name for the configuration framework.

lib
: Public alias used for the assembled library namespace.

# Path Registry

The `paths` attribute set centralizes important repository locations so that
other loaders and modules can refer to stable names instead of repeating
relative paths.

Important path groups:

api
: Host and user API declarations under `configuration/api`.

configurations
: NixOS/Home Manager module tree under `configuration/modules`.

secrets
: Secret module definitions and encrypted values under `configuration/secrets`.

libraries
: Main library root under `libraries`.

bootstrap
: Minimal early library layer under `libraries/bootstrap`.

utilities
: Utility outputs such as formatting and development shell support.

templates
: Project templates.

documentation
: Repository documentation.

dbg
: Debug notes, reports, and troubleshooting material.

# Bootstrap Layer

```nix
bootstrap = import paths.bootstrap;
```

The bootstrap layer provides the small set of helpers needed before the full
library stack is available.

Used here:

```nix
inherit (bootstrap.attrsets) is inspect orEmpty update;
inherit (bootstrap.config) getEnv mkDots;
```

is
: Predicate/helper used to check whether `flake` has a usable shape.

inspect
: Debug/inspection helper exported for interactive use.

orEmpty
: Normalizes missing or empty values during merges.

update
: Merges caller-provided defaults into the base defaults.

getEnv
: Reads local environment variables for impure host discovery.

mkDots
: Builds the selected host output from the resolved API and path registry.

# Defaults

The `defaults` value starts with a local baseline and is then updated by
`flake.defaults` when provided.

```nix
defaults = update base (orEmpty flake.defaults);
```

This allows external callers, flake outputs, or REPL sessions to override
specific framework defaults without rewriting the root entrypoint.

# Host Resolution

The active host is resolved in this order:

1. `flake.currentHost`
2. `$HOSTNAME`
3. `$NAME`
4. `"ExampleHost"`

This supports both pure flake-driven evaluation and impure local development
workflows.

The final host is used here:

```nix
mkDots paths api.hosts.${defaults.host}
```

# Discovery Exclusions

These paths are excluded from automatic discovery and module loading:

```nix
[
  "archive"
  "backup"
  "review"
  "temp"

  "default.nix"
  "flake.nix"
]
```

archive
: Preserved legacy files that should not be loaded automatically.

backup
: Backup material that should not be part of evaluation.

review
: Work-in-progress or review-only material.

temp
: Temporary files.

default.nix
: Entrypoint files are loaded explicitly, not by discovery.

flake.nix
: Flake definition is handled separately from module discovery.

# Library Assembly

```nix
libraries =
  import paths.libraries {
    inherit bootstrap defaults paths names;
  }
  // flake;
```

The main library layer receives the bootstrap helpers, resolved defaults,
path registry, and naming registry. The incoming `flake` attribute set is then
merged over the imported libraries so caller-provided flake context remains
available to downstream code.

# Final Export

The final value combines three layers:

```nix
orEmpty libraries.flake
// mkDots paths api.hosts.${defaults.host}
// {
  inherit api defaults inspect libraries names paths;
  "${names.lib}" = libraries;
}
```

Layer 1: `orEmpty libraries.flake`
: Optional flake-provided exports.

Layer 2: `mkDots paths api.hosts.${defaults.host}`
: Selected host configuration output.

Layer 3: metadata and aliases
: Stable exports for inspection, reuse, and downstream imports.

# Exported Attributes

api
: Loaded API namespace from `configuration/api`.

defaults
: Resolved framework defaults.

inspect
: Bootstrap inspection helper.

libraries
: Fully assembled library namespace.

lix
: Alias to `libraries`, produced dynamically through `names.lib`.

names
: Canonical naming registry.

paths
: Canonical path registry.

# Notes

The current internal loader design still needs improved support for regular
`.nix` file nodes. Some loaders currently expect module directories containing
a nested `default.nix`, so standalone files may be skipped unless imported
explicitly.

This is why the root entrypoint keeps `default.nix` and `flake.nix` excluded
from discovery and loads important entrypoints directly.
*/
{flake ? {}, ...}: let
  # -----------------------------------------------------------------------
  # TODO: Update libraries/internal loaders to parse regular files (.nix).
  # Currently, file nodes are skipped by readDirAttrs or dropped by
  # importModule because it searches for a nested default.nix.
  # -----------------------------------------------------------------------
  names = {
    src = "dots";
    top = "dots";
    lib = "lix";
  };

  paths = {
    src = ./.;
    api = ./configuration/api;
    dbg = ./debug;
    documentation = ./documentation;
    configurations = ./configuration/modules;
    templates = ./templates;
    devShells = ./utilities/shells;
    utilities = ./utilities;
    secrets = ./configuration/secrets;
    libraries = ./libraries;
    bootstrap = ./libraries/bootstrap;
  };

  bootstrap = import paths.bootstrap;
  inherit (bootstrap.attrsets) is inspect orEmpty update;
  inherit (bootstrap.config) getEnv mkDots;

  defaults = let
    base = {
      host = let
        env = {
          host = getEnv "HOSTNAME";
          name = getEnv "NAME";
        };
      in
        if is flake && (flake.currentHost or "") != ""
        then flake.currentHost
        else if env.host != ""
        then env.host
        else if env.name != ""
        then env.name
        else "ExampleHost";

      excludes = {
        paths = [
          "archive"
          "backup"
          "review"
          "temp"

          "default.nix"
          "flake.nix"
        ];
      };

      tags = ["core" "home"];
    };
  in
    update base (orEmpty flake.defaults);

  libraries =
    import paths.libraries {
      inherit bootstrap defaults paths names;
    }
    // flake;
  inherit (libraries) api;
in
  orEmpty libraries.flake
  // mkDots paths api.hosts.${defaults.host}
  // {
    inherit api defaults inspect libraries names paths;
    "${names.lib}" = libraries;
  }
