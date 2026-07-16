# Architectural Restructure

### The Problem

We wanted to avoid nesting custom frontend configurations (like `dank-material-shell` settings) directly inside specific backend schemas (like `dots.interface.hyprland.frontend.dank-material`). If we did that, every time we added a new shell, we would have to modify the option definitions of *every* compositor/window manager, leading to massive code duplication and tight architectural coupling.

### The Solution (Method B: Backend Dictates Tweaks)

We chose a highly decoupled, flat-module layout where components remain pure, and configurations are injected dynamically using global Nix option evaluation:

1. **Flat Modules (`configuration/applications/`):** Both backends (`hyprland`, `niri`) and frontends (`dank-material-shell`) live flat under the applications directory. They are dynamically loaded via your framework’s `mkModules` and `mkModuleArgs`.
2. **Decoupled Schemas:** Frontends declare their own options (e.g., `dots.applications.dank-material-shell.dgop`) without knowing which backend is running them.
3. **Policy Router (`dots.interface`):** A thin global interface policy acts as a switchboard. It defines simple string options:
```nix
dots.interface.backend = "hyprland";
dots.interface.frontend = "dank-material-shell";

```


And then automatically evaluates to:
```nix
dots.applications.hyprland.enable = true;
dots.applications.dank-material-shell.enable = true;

```


4. **Backend-Driven Injection:** When a backend is enabled, it reads the active `dots.interface.frontend` string. Using a custom library helper (`mkFrontendTweaks`), it conditionally injects overrides directly into the active frontend's global namespace (e.g., forcing `dgop = false` on Dank Material Shell only when Hyprland is active).

---

## Your Updated Prompt Template

Copy and paste the block below directly into your next AI session to perfectly convey the state of your configuration and the architecture we are targeting:

```markdown
# Context & Goal
 I am refactoring my custom NixOS desktop environment configuration. I want to establish a clean, decoupled boundary between my window managers/compositors (backends) and my desktop shells/panels (frontends).

I have abandoned the idea of nesting frontend schemas inside backend option schemas (e.g., nesting `dms` configuration blocks directly inside `dots.interface.hyprland`). Instead, I am implementing **"Method B: The Backend Dictates Tweaks"** using a flat application architecture and global Nix option injections.

---

## System Architecture

### 1. File Structure
All backends and frontends are loaded flat inside `configuration/applications/` using my system's dynamic module importer framework:

```text
├── configuration/
│   ├── applications/
│   │   ├── default.nix                 # Dynamic loader using mkModules & mkModuleArgs
│   │   ├── hyprland/
│   │   │   └── default.nix             # Backend module
│   │   ├── niri/
│   │   │   └── default.nix             # Backend module
│   │   ├── dank-material-shell/
│   │   │   └── default.nix             # Frontend module
│   │   └── caelestia-shell/
│   │       └── default.nix             # Frontend module
│   └── interface/
│       ├── default.nix                 # Dynamic policy loader
│       └── policy.nix                  # Switchboard routing logic

```

### 2. The Switchboard Router (`dots.interface`)

The interface directory contains a thin policy layer that reads string targets and automatically enables the corresponding flat modules:

```nix
options.dots.interface = {
  backend = mkOption { type = types.str; };
  frontend = mkOption { type = types.str; };
};

config = {
  dots.applications.${config.dots.interface.backend}.enable = true;
  dots.applications.${config.dots.interface.frontend}.enable = true;
};

```

### 3. The Backend-Driven Injection Pattern

The backend modules are responsible for overriding frontend options if they need specialized tweaks to run correctly. To keep this DRY and clean, we use a custom library helper:

```nix
# Custom Library Helper
mkFrontendTweaks = frontend: tweaks:
  mkMerge (
    mapAttrsToList (name: value:
      mkIf (frontend == name) value
    ) tweaks
  );

```

When a backend evaluates, it uses this helper to inject overrides into whatever frontend is currently set in `dots.interface.frontend`.

---

## Example Implementation Target

This is the shape we are chasing for a backend module (e.g., Hyprland) using my custom framework's `mkArgs` utility (which handles compositor metadata, UWSM, and packages dynamically):

```nix
# configuration/applications/hyprland/default.nix
{ config, lib, mkArgs, ... } @ args:
let
  backend = mkArgs args;
  frontend = config.dots.interface.frontend;

  mkFrontendTweaks = frontend: tweaks:
    mkMerge (
      mapAttrsToList (name: value:
        mkIf (frontend == name) value
      ) tweaks
    );
in {
  options = backend.evaluated.options;

  config = mkMerge [
    backend.evaluated.config

    (mkIf (backend.cfg.enable or false) (mkMerge [
      {
        # Base Hyprland compositor configuration
        wayland.windowManager.hyprland.enable = true;
      }

      # Inject backend-specific adjustments to the active frontend
      (mkFrontendTweaks frontend {
          dots.applications = {
            dank-material-shell = {
              dgop = {...};
              enableAudioWavelength = true;
            };
            caelestia-shell = {
              blur = true;
            };
        };
      })

        caelestia-shell = {
          dots.applications.caelestia-shell.blur = true;
        };
    ]))
  ];
}
