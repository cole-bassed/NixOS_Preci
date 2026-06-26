# 2026-06-05 lib/devShell/template review and non-switching tests

Scope: review current committed work on branch `main` at `6e47520` (`lib config working`) and test bringing `devShells` and `templates` into the assembled flake. User explicitly requested: DO NOT SWITCH.

No switch was run.
No commit or push was made.
Working tree was clean before the report file was written.

## Repository state before report

- Branch: `main`
- Upstream: `origin/main`
- HEAD: `6e47520`
- Changed scope in recent lib/config sequence (`HEAD~7..HEAD`):
  - `configurations/default.nix`
  - `default.nix`
  - `flake.nix`
  - `libraries/config.nix`
  - `libraries/default.nix`
  - `libraries/imports/default.nix`
  - `utilities/default.nix`
  - `utilities/code-quality.nix` renamed to `utilities/formatting.nix`

## Tests run

### `nix flake show --all-systems --json`

Result: PASS for shallow output discovery.

Output shape:

```json
{
  "checks": { "x86_64-linux": { "formatting": { "type": "derivation" } } },
  "formatter": { "x86_64-linux": { "type": "derivation" } },
  "nixosConfigurations": { "Preci": { "type": "nixos-configuration" } },
  "src": { "type": "unknown" }
}
```

Note: current `flake.nix` still exposes `src`, so `nix flake check` warns about unknown flake output `src`.

### `nix eval` assembled `templates + devShells` attr names

Command shape:

```sh
nix eval --impure --json --expr '
  let f = builtins.getFlake (builtins.toString ./.);
  in builtins.attrNames (f.src.libraries.assemble.flake f.src { devShells = true; templates = true; })
'
```

Result: PASS for shallow assembly.

Output:

```json
["devShells", "packages", "templates"]
```

### `nix eval` assembled templates only

Result: PASS.

Output:

```json
[]
```

The templates importer works structurally, but currently exposes no actual templates because `templates/default.nix` contains an empty `templates = {}` set.

### `nix eval` assembled devShell system keys

Result: PASS for shallow system-key discovery.

Output:

```json
["x86_64-linux"]
```

### `nix eval` actual assembled devShell default name

Result: FAIL / BLOCKER.

Error:

```text
error: attribute 'name' missing
at /home/craole/.dots/packages/default.nix:7:23:
     6|     default = pkgs.mkShell {
     7|       inherit (flake) name;
       |                       ^
     8|       packages = with pkgs; [git sops];
Did you mean names?
```

Cause: `packages/default.nix` receives the repo base attrset as its single argument named `flake`. That base attrset has `names.src = "dots"`, but it does not have top-level `name`. Therefore `inherit (flake) name;` fails as soon as the devShell derivation is forced.

Low-risk fix options:

1. In `packages/default.nix`, replace `inherit (flake) name;` with `name = flake.names.src;`.
1. Or add `name = names.src;` to the base attrset returned by root `default.nix`.

A no-code-edit hypothetical test using `base = f.src // { name = "dots"; }` succeeded:

```text
nix eval ... out.devShells.x86_64-linux.default.name
=> dots

nix eval ... out.devShells.x86_64-linux.default.drvPath
=> /nix/store/0pjr7rhkxnvhrpyakkrpp4405qcakkcc-dots.drv

nix build --impure --no-link --expr '... out.devShells.x86_64-linux.default'
=> built /nix/store/0pjr7rhkxnvhrpyakkrpp4405qcakkcc-dots.drv
```

This confirms the importer path itself is good and the devShell blocker is specifically the missing name attribute.

### `nix build .#checks.x86_64-linux.formatting --no-link`

Result: PASS.

No formatting output was emitted on the successful standalone run.

### `nix flake check --no-build`

Result: FAIL / BLOCKER.

Relevant output:

```text
warning: unknown flake output 'src'
evaluation warning: stylix: flake output `homeManagerModules` has been renamed to `homeModules` and will be removed after 26.05.
error: The option `home-manager.users.craole.programs.niri.finalConfig' in `/nix/store/...-source/nixos/common.nix' is already declared in `/nix/store/...-source/nixos/common.nix'.
```

Probable cause: `flake.nix` includes both `niri.homeModules.config` and `niri.homeModules.niri` in `flake.modules.home`. The duplicate declaration is coming from the same upstream niri `nixos/common.nix`, which is consistent with importing two overlapping niri Home Manager modules.

Low-risk fix: remove the overlapping niri HM module and keep only the one required for this config path. Based on the current error, start by testing `flake.modules.home` with only one of:

- `niri.homeModules.niri`
- `niri.homeModules.config`

Do this before any switch.

### `nix build .#nixosConfigurations.Preci.config.system.build.toplevel --no-link`

Result: FAIL with the same niri duplicate `programs.niri.finalConfig` declaration blocker.

No switch was run.

## Review findings

### Critical / blockers

1. `packages/default.nix:7` blocks enabling `devShells`.
   - `inherit (flake) name;` expects a top-level `name` attr that the assembled base does not currently provide.
   - The intended source name appears to be `flake.names.src` (`"dots"`).
   - Verified that adding `name = "dots"` only in the evaluation expression lets the devShell derivation evaluate and build.

1. `flake.nix:74-77` appears to import overlapping niri Home Manager modules.
   - `nix flake check --no-build` and the Preci toplevel build both fail because `home-manager.users.craole.programs.niri.finalConfig` is declared twice from niri's upstream `nixos/common.nix`.
   - This blocks safe build verification.

### Warnings

1. `flake.nix` exposes non-standard flake output `src`.
   - This is convenient for debugging, but `nix flake check` warns: `unknown flake output 'src'`.
   - Not a functional blocker, but if you want clean flake checks, consider hiding/debug-gating `src` or accepting the warning during this refactor.

1. `stylix.homeManagerModules.stylix` still works but emits a deprecation warning.
   - Nix reports: `stylix: flake output homeManagerModules has been renamed to homeModules and will be removed after 26.05`.
   - Prefer `stylix.homeModules.stylix` when ready.

1. `templates/default.nix` currently exposes no templates.
   - The template importer works structurally, but enabling `templates = true` produces `templates = {}`.

### Looks good

- `assemble.flake` now correctly maps enabled path specs through `base.paths` and can shallowly assemble `devShells`, `packages`, and `templates`.
- `devShells = true` shallowly discovers `x86_64-linux`, confirming `forEachSystem` / supported-system plumbing is working enough to reach the devShell derivation.
- The formatting check builds successfully.
- Current `main` and `origin/main` were aligned at `6e47520` before this report file was written.

## Suggested next repair order

1. Fix `packages/default.nix` shell name:
   - preferred: `name = flake.names.src;`
   - or add top-level `name = names.src;` in root `default.nix`.
1. Temporarily enable `devShells = true; templates = true;` in `flake.nix` and rerun:
   - `nix flake show --all-systems`
   - `nix eval .#devShells.x86_64-linux.default.name --raw`
   - `nix build .#devShells.x86_64-linux.default --no-link`
1. Resolve the niri duplicate HM module import, then rerun:
   - `nix flake check --no-build`
   - `nix build .#nixosConfigurations.Preci.config.system.build.toplevel --no-link`
1. Only after those pass should switching be considered. This review intentionally did not switch.
