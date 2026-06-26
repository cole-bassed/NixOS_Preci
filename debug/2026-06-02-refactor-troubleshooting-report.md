# Refactor troubleshooting report - 2026-06-02

Generated: 2026-06-02T18:31:26-05:00
Repository: `/home/craole/.dots`
Branch: `main` tracking `origin/main`
Scope requested: review and test only; do not switch; do not change code; document necessary changes in `debug/`.

## Executive summary

The flake can enumerate outputs and the host name, but the NixOS configuration does not currently evaluate or build. I did not run any switch/activation command.

Current first blocking error:

```text
error: attribute 'libraries' missing
at /home/craole/.dots/assembly/configurations/base/default.nix:13:1:
  flake.libraries.modules.importModules {
```

This blocks:

- `nix flake check --no-build`
- `nix eval .#nixosConfigurations.Preci.config.system.stateVersion --show-trace`
- `nixos-rebuild build --flake .#Preci --show-trace`

There is also an independent formatting check failure in `libraries/debug.nix`.

The likely main architectural issue is that the new shared import helper path mixes two incompatible module shapes:

1. repository assembly/orchestration functions shaped like `flake: ...`, expecting a full repository flake context with `libraries`, `modules`, `defaults`, etc.
1. NixOS/Home Manager module functions shaped like `{ config, lib/lix, pkgs, top, ... }: ...`, expecting module-system arguments.

When `libraries/modules.nix.importModules` recursively scans folders, it imports `assembly/configurations/base/default.nix` as if it were a normal collected module. During NixOS module evaluation that file is called without the complete repo flake context, so `flake.libraries` is missing.

## Repository state observed

Command:

```bash
git status --short --branch && git remote -v && git log --oneline -8
```

Observed:

```text
## main...origin/main
 D USER.md
 D dump.txt
 D secrets.yaml
?? .tree
?? .txt

origin  git@github_cole-bassed:cole-bassed/-NixOS_Preci.git (fetch)
origin  git@github_cole-bassed:cole-bassed/-NixOS_Preci.git (push)

a9955c4 removed collectUserSpecs
19818d5 assembly
d04291b assembly
d7b5389 assembly
1a67530 assembly
2b4a53d utilities
297e5e1 base modules
6c81778 base modules
```

Notes:

- The repo is dirty before this report.
- Tracked root files `USER.md`, `dump.txt`, and `secrets.yaml` are deleted in the working tree.
- Untracked `.tree` and `.txt` exist.
- This report intentionally does not attempt to fix, stage, commit, push, or switch.

## Commands run and results

### 1. Nix version

Command:

```bash
nix --version
```

Result:

```text
nix (Nix) 2.34.7
```

### 2. Flake output discovery

Command:

```bash
nix flake show --all-systems
```

Result: exit 0.

Important observed outputs:

```text
git+file:///home/craole/.dots
├───checks
│   ├───aarch64-linux
│   │   └───formatting: derivation 'treefmt-check'
│   └───x86_64-linux
│       └───formatting: derivation 'treefmt-check'
├───devShells
│   ├───aarch64-linux
│   │   └───default: development environment 'dots'
│   └───x86_64-linux
│       └───default: development environment 'dots'
├───formatter
│   ├───aarch64-linux: package 'treefmt'
│   └───x86_64-linux: package 'treefmt'
├───home-manager: unknown
├───imports: unknown
├───nixosConfigurations
│   └───Preci: NixOS configuration
└───templates
```

Interpretation:

- The flake outputs are syntactically visible.
- `home-manager` and `imports` are currently non-standard/unknown flake outputs. This is allowed as a warning but should be intentional and documented or renamed if accidental.

### 3. Host name evaluation

Command:

```bash
nix eval .#nixosConfigurations --apply builtins.attrNames --json
```

Result: exit 0.

```json
["Preci"]
```

Interpretation:

- Host discovery reaches `nixosConfigurations` far enough to expose `Preci`.
- This does not mean the configuration itself evaluates.

### 4. Flake check without build

Command:

```bash
nix flake check --no-build --show-trace
```

Result: exit 1.

First concrete blocking error:

```text
error: attribute 'libraries' missing
at /home/craole/.dots/assembly/configurations/base/default.nix:13:1:
  flake.libraries.modules.importModules {
```

Relevant trace path:

```text
/home/craole/.dots/libraries/config.nix:56
  in {${type} = mapAttrs (_: builder) hosts;};

/home/craole/.dots/libraries/modules.nix:280
  imports = specs.core or [];

/home/craole/.dots/libraries/modules.nix:116
  module = importModule {

/home/craole/.dots/libraries/modules.nix:99
  then imported args

/home/craole/.dots/assembly/configurations/base/default.nix:12-13
  flake:
  flake.libraries.modules.importModules {
```

### 5. Direct system config evaluation

Command:

```bash
nix eval .#nixosConfigurations.Preci.config.system.stateVersion --show-trace
```

Result: exit 1.

Same first concrete blocker:

```text
error: attribute 'libraries' missing
at /home/craole/.dots/assembly/configurations/base/default.nix:13:1
```

### 6. Non-switching system build

Command:

```bash
nixos-rebuild build --flake .#Preci --show-trace
```

Result: exit 1.

Same first concrete blocker:

```text
error: attribute 'libraries' missing
at /home/craole/.dots/assembly/configurations/base/default.nix:13:1
```

No switch was run.

### 7. Formatting check

Command:

```bash
nix build .#checks.x86_64-linux.formatting --no-link --print-build-logs
```

Result: exit 1.

Formatting diff reported by treefmt:

```diff
diff --git a/libraries/debug.nix b/libraries/debug.nix
index 4d9508e..73b7c07 100644
--- a/libraries/debug.nix
+++ b/libraries/debug.nix
@@ -29,7 +29,8 @@
     assertion,
     message,
     context,
-  }: addErrorContext
+  }:
+    addErrorContext
     "while ${context}"
     (assert assertMsgFunc {
       inherit name assertion message;
```

Interpretation:

- The repo currently fails formatting independently of NixOS evaluation.
- This is a low-risk mechanical fix, but I did not apply it because the request was review/test/report only.

### 8. Dev shell derivation evaluation

Command:

```bash
nix eval .#devShells.x86_64-linux.default.drvPath --raw
```

Result: exit 0.

```text
/nix/store/0pjr7rhkxnvhrpyakkrpp4405qcakkcc-dots.drv
```

Interpretation:

- Dev shell derivation evaluation currently works.

## Important files inspected

### Flake entrypoint

`flake.nix`:

- imports `./assembly` with the output of `import ./. { ... }`.
- passes upstream NixOS and Home Manager modules under `modules.core` and `modules.home`.
- passes library mappings under `libraries.nixpkgs`, `libraries.home-manager`, `libraries.treefmt`, and optional `libraries.darwin`.

### Repository context builder

`default.nix`:

- defines `info.name = "dots"`.
- defines `info.names.lib = "lix"`.
- defines `info.names.top = "_"`.
- returns `inputs`, `packages`, `modules`, `defaults`, `name`, and `libraries`.

Concern:

- The preferred/user-facing option namespace should be `dots`, not `_`, for modules that use `${top}`.
- The root return set does not expose `top` directly even though nested library construction uses `inherit (info.names) top` internally.
- `libraries/config.nix` expects a `top` argument to be available to modules and Home Manager modules, but the current `specialArgs` construction does not obviously provide `top = "dots"`.

### Configuration builder

`assembly/configurations/default.nix`:

```nix
flake: let
  inherit (flake.libraries.modules) importModules;

  core =
    (flake.modules.core or [])
    ++ [
      (importModules {
        base = ./.;
        args = flake;
        excludes =
          flake.defaults.excludes
          ++ [
            "ai"
            "applications"
            "interface"
          ];
      })
    ];
in
  flake.libraries.mkConfigurations {
    class = "nixos";
    flake = flake // {modules = flake.modules // {inherit core;};};
  }
```

Concern:

- The top-level `importModules { base = ./.; ... }` scans `assembly/configurations/` and encounters `base/default.nix`.
- `base/default.nix` itself is a repository assembly wrapper (`flake: ...`), not a raw module spec with `{ core = ...; home = ...; }` tags.
- This recursive wrapper/importer mixture is the immediate failure path.

### Shared module importer

`libraries/modules.nix`:

Key current behavior:

- `readDirAttrs` scans directories containing a candidate entrypoint such as `default.nix`.
- `importModule` imports the resolved file and, if it is a function, calls it with `args`.
- `collectSpecs` expects imported entries to either:
  - be a raw file module mapped to `{ ${rawTag} = module; }`, or
  - return an attrset containing tags such as `core` and `home`.
- `importAll` returns a NixOS module:

```nix
{
  imports = specs.core or [];
  home-manager.sharedModules = specs.home or [];
}
```

Concerns:

1. It has no clear distinction between repository-level wrapper functions and module-spec functions.
1. `collectSpecs` currently drops wrapper outputs that return module-shaped attrsets without `core`/`home` tags, but during NixOS module evaluation the wrapper still gets forced in the trace.
1. `importProfiles` and `mkHomeUsers` appear stale relative to the newer `getUsers` shape:
   - `mkHomeUsers` reads `(getUsers host).normal.raw`, but `getUsers` returns `.values`, `.byStatus`, and `.byRole`, not `.normal.raw`.
   - `importProfiles` calls `mkHomeUser { inherit config name profile; }`, but `mkHomeUser` expects `{ user, config, osConfig, top }`.

### User and host API

`api/default.nix`:

- builds `specs.hosts` and `specs.users` via `collectNamedSpecs`.
- resolves host users with `getUsers`.
- creates `host.users.primary`.

`api/hosts/preci/default.nix`:

- host name is `Preci`.
- declares user `craole` as administrator/primary/autologin.
- imports `./hardware-configuration.nix`.

`api/users/craole/default.nix`:

- pure user spec imports `./applications` and `./paths`.
- uses `mapOrderedAttrs` from custom attrset library.

`api/users/craole/applications.nix` and `paths.nix`:

- are Home Manager module-shaped files that require `{ config, top, ... }`.
- they set/read `${top}.applications` and `${top}.paths`.

Concerns:

- These user files are module-shaped and should be imported into Home Manager user module lists, not blindly merged as plain user spec data unless the import pipeline intentionally supports this.
- They require `top`; the repo should pass `top = "dots"` through NixOS `specialArgs` and Home Manager `extraSpecialArgs`.

### Application/interface/AI wrappers

Examples:

`assembly/configurations/applications/default.nix`:

```nix
{
  lib,
  pkgs,
  ...
} @ args:
lib.importModules (args // { ... })
```

`assembly/configurations/interface/default.nix`:

```nix
{lib, ...} @ args:
lib.importModules (args // { base = ./.; })
```

`assembly/configurations/ai/default.nix`:

```nix
{ lib, pkgs, inputs, ... } @ args:
lib.importModules (args // { ... })
```

Concerns:

- The repo library namespace is currently named `lix` in `default.nix`/`libraries/config.nix`, not `lib`.
- NixOS already passes nixpkgs `lib` by default, so using `lib.importModules` likely points at nixpkgs lib, not the custom importer, unless `lib` has been intentionally overridden. The current `specialArgs` adds `lix`, not `lib`.
- These wrappers are excluded right now from the active `assembly/configurations/default.nix` top-level scan, but they are likely to fail when re-enabled unless they use the custom library namespace consistently.

## Root cause hypothesis

Primary root cause:

The import graph currently calls repository assembly wrapper files through the generic module-spec collector. The collector and the wrappers disagree about the shape of the argument and the shape of the returned value.

Evidence:

- Directly evaluating the host list works: `nix eval .#nixosConfigurations --apply builtins.attrNames --json` returns `["Preci"]`.
- The first failure happens only once the NixOS module graph starts evaluating imports.
- The failure path goes through `libraries/modules.nix.importAll -> collectSpecs -> importModule -> assembly/configurations/base/default.nix`.
- The failing file expects `flake.libraries`, but the argument provided during module evaluation lacks `libraries`.

Secondary root causes and expected next blockers:

1. Formatting blocker in `libraries/debug.nix`.
1. Custom namespace mismatch: code uses both `lix` and `lib` for custom library helpers.
1. `top` namespace mismatch: user preference and module code want `dots`, but `default.nix` has `info.names.top = "_"` and root flake context does not expose `top` directly.
1. Stale Home Manager helper code in `libraries/modules.nix` (`mkHomeUsers`, `mkHomeUser`, `importProfiles`) does not match current `getUsers` output shape or call signatures.
1. `libraries/attrsets.nix` references `isNull` but does not inherit it from `types`; this may surface after the first blocker is fixed.
1. `assembly/configurations/base/default.nix` and `assembly/secrets/default.nix` are wrapper-style recursive importers. They should not be collected as ordinary child modules unless the collector understands this shape.
1. `api/users/craole/default.nix` imports extensionless `./applications` and `./paths`; Nix resolves these today, but for consistency and readability use `./applications.nix` and `./paths.nix` if/when editing.
1. Root-level tracked files were deleted and new untracked scratch files exist; decide whether these are intentional before any commit.

## Detailed repair plan

Do not switch until the full non-switching verification sequence passes.

### Phase 0 - Preserve current state intentionally

Objective: avoid losing in-flux work and make future debugging reproducible.

Files to inspect only:

- `USER.md`
- `dump.txt`
- `secrets.yaml`
- `.tree`
- `.txt`

Steps:

1. Decide whether root `USER.md`, `dump.txt`, and `secrets.yaml` deletions are intentional.
1. Decide whether `.tree` and `.txt` should be ignored, kept as debug artifacts, or removed.
1. Do not commit these until the repo owner confirms intent.

Verification:

```bash
git status --short --branch
```

Expected:

- Still dirty while in flux, but all dirty entries should be understood.

### Phase 1 - Fix formatting only

Objective: clear the independent treefmt blocker.

File:

- `libraries/debug.nix`

Required change:

- Format `assertWithContext` so `}:` is followed by a newline and indented `addErrorContext`.

Verification:

```bash
nix build .#checks.x86_64-linux.formatting --no-link --print-build-logs
```

Expected:

- exit 0.

Commit guidance:

- If only formatting is changed and verification passes, use a small docs/code-style commit such as `fmt: normalize debug helper formatting`.
- Do not switch.

### Phase 2 - Establish canonical custom library namespace and top namespace

Objective: make all module wrappers agree on the same custom helper namespace and option namespace.

Files likely involved:

- `default.nix`
- `libraries/config.nix`
- `assembly/configurations/applications/default.nix`
- `assembly/configurations/interface/default.nix`
- `assembly/configurations/ai/default.nix`
- any modules that currently expect `lib.importModules` for custom helpers

Required decisions:

1. Keep custom library arg named `lix` as currently indicated by `info.names.lib = "lix"`.
1. Do not override nixpkgs `lib` with custom helpers unless intentionally planned.
1. Set/pass `top = "dots"`, not `_`, for both NixOS and Home Manager modules.

Recommended shape:

- `default.nix`: expose `top = "dots"`, either directly or through `names.top`.
- `libraries/config.nix`: include `top = "dots"` in `specialArgs` and therefore in `home-manager.extraSpecialArgs`.
- Custom importer wrappers should use the custom helper namespace, e.g. `{ lix, ... } @ args: lix.importModules (...)`, not `lib.importModules`, unless `lib` is intentionally custom.

Verification probes after this phase:

```bash
nix eval --impure --expr 'let flake = import ./. {}; in flake.names.top or flake.top or null' --json
nix eval .#nixosConfigurations --apply builtins.attrNames --json
```

Expected:

- first probe should return `"dots"` or an attr path that clearly resolves to `"dots"`.
- second probe should still return `["Preci"]`.

### Phase 3 - Split repository wrappers from collected module specs

Objective: stop `importModules` from recursively treating assembly wrapper files as raw module specs.

Files likely involved:

- `assembly/configurations/default.nix`
- `assembly/configurations/base/default.nix`
- `assembly/secrets/default.nix`
- `libraries/modules.nix`

Recommended direction:

1. Decide which directories are assembly orchestration layers and which directories are spec/module layers.
1. Keep `assembly/configurations/default.nix` as the orchestration entrypoint.
1. Ensure the children it collects return explicit `{ core = ...; home = ...; }` specs, or adjust `importModules` to accept already-module-shaped outputs safely.
1. Do not allow wrapper files like `base/default.nix` to be called by the module system with incomplete module args.

Low-risk options:

- Option A: make child directories such as `base/`, `secrets/`, `applications/`, and `interface/` return explicit tagged specs when they are collected by `collectSpecs`.
- Option B: change the top-level collector to import specific wrapper modules manually rather than auto-discovering wrappers recursively.
- Option C: teach `collectSpecs` to distinguish `{ imports = ...; home-manager.sharedModules = ...; }` module-shaped results and include them directly as `core`, but be careful to avoid nested Home Manager duplication.

Verification after this phase:

```bash
nix flake check --no-build --show-trace
```

Expected:

- The current `attribute 'libraries' missing` error should be gone.
- A new blocker may appear; document it and fix one concrete error at a time.

### Phase 4 - Repair stale Home Manager/user helper code

Objective: make user resolution and Home Manager module construction match current API shape.

Files likely involved:

- `libraries/modules.nix`
- `libraries/config.nix`
- `api/default.nix`
- `api/users/craole/default.nix`
- `api/users/craole/applications.nix`
- `api/users/craole/paths.nix`

Known suspicious code:

```nix
mkHomeUsers = host: ... (getUsers host).normal.raw;
```

Problem:

- `getUsers` returns a group shape with `.names`, `.values`, `.count`, `.byStatus`, and `.byRole`.
- It does not return `.normal.raw`.

Also suspicious:

```nix
mkHomeUser {inherit config name profile;}
```

Problem:

- `mkHomeUser` currently expects `{ user, config, osConfig, top }`.

Recommended direction:

- Either remove stale helpers that are no longer used, or update them to use `host.users.byStatus.enabled.values` and the current `mkHomeUser` signature.
- Keep user API data separate from Home Manager modules: user metadata belongs in `api/users/<name>/default.nix`; HM option modules belong in `user.imports` or `user.modules` and should receive `config`, `osConfig`, and `top` from Home Manager.

Verification:

```bash
nix eval .#nixosConfigurations.Preci.config.home-manager.users --apply builtins.attrNames --json --show-trace
```

Expected:

- Should include `"craole"` once the NixOS module graph evaluates far enough.

### Phase 5 - Fix next library blockers exposed after the first error

Objective: clean likely latent library errors once evaluation reaches them.

Known likely issue:

- `libraries/attrsets.nix` uses `isNull` but imports only `isAttrs isEmpty typeOf isString` from `types`.

Recommended change:

- Add `isNull` to the `inherit (types)` line in `libraries/attrsets.nix`, preserving style.

Verification:

```bash
nix flake check --no-build --show-trace
```

Expected:

- No `undefined variable 'isNull'` from `libraries/attrsets.nix`.

### Phase 6 - Re-enable application/interface/AI layers incrementally

Objective: wire the restructured folders back in one layer at a time.

Current active top-level excludes:

```nix
[ "ai" "applications" "interface" ]
```

Recommended sequence:

1. Get `base` and `secrets` evaluating first.
1. Enable `applications` next, after fixing `lib` vs `lix` importer use.
1. Enable `interface` after application option declarations exist.
1. Enable `ai` last because it includes Hermes module/document paths and likely depends on the rest of the graph.

Verification at each step:

```bash
nix flake check --no-build --show-trace
nixos-rebuild build --flake .#Preci --show-trace
```

Expected:

- Evaluation should pass before build is trusted.
- Build should pass before any commit/push/switch sequence.
- Do not switch while the repo is in flux unless explicitly approved later.

### Phase 7 - Full non-switching verification gate

Run these in order:

```bash
nix build .#checks.x86_64-linux.formatting --no-link --print-build-logs
nix flake check --no-build --show-trace
nix eval .#nixosConfigurations --apply builtins.attrNames --json
nix eval .#nixosConfigurations.Preci.config.system.stateVersion --raw --show-trace
nixos-rebuild build --flake .#Preci --show-trace
```

Pass criteria:

- formatting check exits 0.
- flake check exits 0 or only accepted unknown-output warnings remain.
- host list is `["Preci"]`.
- stateVersion evaluates.
- non-switching build exits 0.

Do not run:

```bash
nixos-rebuild switch --flake .#Preci
```

unless the repo owner explicitly approves switching after the flux period.

## Suggested next command for the next troubleshooting pass

Start by fixing only the first concrete blocker, then rerun:

```bash
nix flake check --no-build --show-trace
```

If the first blocker changes, add a new dated report in `debug/` instead of overwriting this one.

## Files created by this review

- `debug/README.md`
- `debug/2026-06-02-refactor-troubleshooting-report.md`

No code files were intentionally modified by this review.
