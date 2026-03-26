# Contributing

Thanks for working on `PlayerRoleOptions`.

This repo is intentionally small. Changes should stay focused on the addon itself and avoid unnecessary UI, packaging, or process overhead.

## Local Setup

- Target client: TBC Anniversary Classic
- Addon install path: `World of Warcraft/_anniversary_/Interface/AddOns/`
- Main runtime files are listed in [PlayerRoleOptions.toc](PlayerRoleOptions.toc)

## Development

Run the local test suite:

```bash
lua tests/run.lua
```

Run a syntax check before opening a PR:

```bash
luac -p PlayerRoleOptions.lua tests/run.lua
```

If you change packaging or release behavior, also verify the runtime-only package contents:

```bash
./.github/scripts/verify-release-package.sh
```

## Project Expectations

- Keep the addon minimal. Avoid adding extra surfaces like chat commands, minimap buttons, or unrelated UI unless there is a strong project reason.
- Prefer small, targeted changes over broad refactors.
- If you add a new runtime file, include it in `PlayerRoleOptions.toc`.
- Player-facing packages should only include files the game client actually needs.

## Pull Requests

- Use conventional commit titles such as `feat(...)`, `fix(...)`, `docs(...)`, or `ci(...)`.
- Include a short summary of what changed and how you verified it.
- If the change affects game UI, include screenshots or a brief description of the visible behavior.
- Keep PRs scoped to one logical change when possible.

## Releases

- Release-specific steps are documented in [RELEASING.md](RELEASING.md).
- Version bumps should update the addon version in `PlayerRoleOptions.toc`, plus any matching references in docs or changelog entries.
- Packaging changes should continue to work with both the PR artifact workflow and the GitHub/CurseForge release workflow.
