# Agent guide

Dotshell is a Quickshell (QML) desktop shell for niri, packaged as a Nix flake with a Home Manager module and a NixOS module. Document only what is not obvious from the code.

## Layout

| Path | Contents |
| --- | --- |
| `shell/shell.qml` | Root: the per-screen windows and the `IpcHandler`s |
| `shell/config/` | `Config`: `config.json` (Home Manager) over `settings.json` (settings window) over built-in defaults, per key |
| `shell/theme/` | `Theme` (colors, type, sizes), `Motion` (springs, curves) and the animation types `SpatialFast`, `SpatialStandard`, `SpatialSlow`, `Effects`, `EffectsColor`, `Exit` |
| `shell/components/` | Shared controls and visuals: dot glyphs, `Panel`, `Reveal`, `MorphButton`, form controls, `Tooltip` and so on |
| `shell/services/` | Singletons: niri IPC, audio, power, clipboard, notifications, weather, persistence (`Store`) and so on |
| `shell/bar/`, `panels/`, `quicksettings/`, `notifications/`, `dashboard/`, `system/`, `battery/`, `launcher/`, `lock/`, `osd/`, `polkit/`, `wallpaper/`, `desktop/`, `cheatsheet/`, `settings/` | One directory per piece of the shell |
| `shell/scripts/` | Helper scripts the shell runs: `clipdb` (the clipboard store), `sysmon` (the system monitor) |
| `niri/` | `rules.kdl` and `binds.kdl`, written to `~/.config/niri/dotshell/` by the Home Manager module |
| `nix/home-manager.nix` | `programs.dotshell` options, including every setting with its description |
| `nix/nixos.nix` | `programs.dotshell.enable` on NixOS: the system services the shell talks to |
| `flake.nix` | Packages (`dotshell`, `dev`, `lint`, `fonts`) and the runtime tools on `PATH` |
| `tools/` | Development tooling that does not ship with the shell |

## Commands

```sh
nix run .#dev    # run ./shell (or $DOTSHELL_DIR) with the packaged environment
nix run .#lint   # qmllint against the Quickshell and Qt type info
```

Lint warnings about types missing from Quickshell's qmltypes (`missing-type`, `unresolved-type`, `uncreatable-type` on `PanelWindow`, `signal-handler-parameters` on `QProcess`) are expected; anything else is real.

Every dependency is declared here, never assumed from the system: runtime tools go into `runtimeInputs` in `flake.nix`, system services into `nix/nixos.nix`. The one exception is `niri`, which must match the running compositor and comes from `niriPackage` or `PATH`.

A new setting needs a default in `Config`, an option in `nix/home-manager.nix`, and a row in the settings window.

## Conventions

- Write everything in English. No code comments; carry intent in names and structure.
- Match the surrounding QML: `pragma ComponentBehavior: Bound`, `required property` in delegates, colors and sizes from `Theme`, motion from `Motion` and the animation types, `Motion.reduced` respected everywhere.
- Commits follow [Conventional Commits](https://www.conventionalcommits.org): `type(scope): summary` in the imperative, with scopes such as `bar`, `launcher`, `clipboard`, `quicksettings`, `notifications`, `lock`, `osd`, `settings`, `services`, `nix`.
- Keep commit messages short: a summary line under 72 characters, and a body only when the reason is not obvious, a few lines at most.

## Testing

`nix run .#dev` reloads on every file change. While it runs, never swap files out from under it (`git stash`, `checkout` of other revisions): a reload in between breaks singletons until the next restart.

For screenshots and input without touching the live session, run a headless sway:

- Use a short `XDG_RUNTIME_DIR` (the socket path must stay under 108 bytes), a private `dbus-run-session`, and separate `XDG_STATE_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, plus a copy of `shell/` as `DOTSHELL_DIR` so IPC reaches the bench instance only.
- Start sway with `WLR_BACKENDS=headless WLR_RENDERER=gles2 WLR_LIBINPUT_NO_DEVICES=1`, drive the shell with `<runner> ipc call …`, type with `wtype`, capture with `grim -g`.
- `wtype` drops the first key event of every call: lead with `-k Shift_L -s 120`.
- Pointer clicks and wheel events do not reach layer surfaces there; test those live, or force the state in the bench copy.
- sway has no background blur, so glass renders unblurred.
- For audio, start a private `pipewire` and `wireplumber` with the ALSA and BlueZ monitors disabled, and create devices with `pw-cli create-node adapter '{ factory.name=support.null-audio-sink … }'`.
- The Quickshell process is named `.quickshell-wra`; match it by name or environment, not with `pkill -f` on a pattern that also matches your own shell.

## QML pitfalls

- Every Quickshell window shares one GUI thread, so a slow paint or binding anywhere stalls the whole shell. `QSG_RENDER_TIMING=1` logs per-window `polish` time.
- `ListView` `add`, `displaced` and `move` transitions break under fast model changes (rows stack or stay half faded). Animate inside the delegate instead, as `LauncherList` does.
- A property named `on<Upper>…` is parsed as a signal handler; `root.onToday` reads as `undefined`.
- An `id` shadows a property of the same name in scope: `id: offset` on a `Translate` replaced the `offset` property in every binding.
- Singletons are created on first use. A service that must run from startup (the clipboard watcher) needs a reference from `shell.qml`.
- Quickshell must come from the system's nixpkgs revision, or it fails with `EGL not available`. `flake.lock` pins it for `nix run .#dev`; after a system update, re-pin with `nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/$(nixos-version --revision)`.
