# Common desktop layer

This note documents the current compositor-agnostic desktop layer without changing the root README/Licensing/Contributing layout.

## Scope

The reusable defaults live under `applications/` and the personal enablement lives under `profiles/craole/`.

Current layer:

- `modules/interface/keybinds`: semantic session/interface actions translated separately into Hyprland and Niri syntax.
- `applications/vicinae`: launcher application profile. Vicinae is the primary launcher app and Fuzzel remains installed as a safe fallback.
- `applications/noctalia`: current common panel/bar shell. It uses Noctalia for now and keeps compositor startup explicit.
- `applications/browsers`: desktop browser defaults. Zen/Twilight should become the primary browser target when a real browser flake/package is available; Chromium is the current safe fallback.

## Launcher

The shared `primaryLauncher` action stays semantic in `modules/interface/keybinds`. It runs Vicinae, while the `secondaryLauncher` action runs Fuzzel:

```sh
vicinae open
# secondary launcher
fuzzel
```

Hyprland binds Win alone to the primary launcher and Win+Space to the secondary launcher. Niri does not safely expose a bare Mod-only bind through niri-flake, so it keeps Win+Space as the launcher recovery path. Both translators keep compositor-specific syntax inside `modules/interface/keybinds/home.nix`.

Home Manager exposes `programs.vicinae`, so `applications/vicinae/home.nix` enables that option while using the cached `pkgs.vicinae` package. The flake input for Vicinae is still present, but its package would need a local source build on this host and is intentionally not used for this low-risk phase.

## Panel/bar

Noctalia remains the current common shell target. The module sets `programs.noctalia-shell` with cached `pkgs.noctalia-shell` and keeps startup explicit:

- Hyprland: `exec-once = [ "noctalia-shell" ]`
- Niri: `spawn-at-startup = [{ argv = [ "noctalia-shell" ]; }]`

The upstream Noctalia Home Manager module warns that its systemd integration is deprecated, so this phase does not enable it. Its flake default package also wants a local Quickshell/Noctalia build on this host, so the app profile forces the cached nixpkgs package while still using the upstream module schema.

## Browsers

No Zen/Twilight browser flake input is currently present. `pkgs.twilight` exists, but it is an OpenGL IRIX backdrop demo, not a browser. Therefore the browser module leaves the primary Zen/Twilight target unset and installs/configures Chromium as the safe fallback/default secondary browser.

## Future MangoWM hook

MangoWM should be added by writing a new translator from the existing semantic action model rather than changing action names. Divergent binding syntax should stay compositor-local, as it does for Hyprland and Niri today.
