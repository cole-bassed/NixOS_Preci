# User Profile

The user is craole on host Preci.

## Nix Style

- Prefer `lib` helpers over `builtins` when available.
- Prefer nested declarations, for example `programs = { ... };`.
- Keep existing comments.
- Avoid repetitive declarations.
- Dotfiles live at `~/.dots`.
- Secrets are managed with `sops-nix`.
