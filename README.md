# PlayerRoleOptions

`PlayerRoleOptions` is a small addon for TBC Anniversary Classic.

It does two things:

- puts the missing `Set Role` options back into the unit right-click menu when you have permission to assign roles
- lets you save a default Blizzard LFG role selection and reapply it on login

Current version: `1.0.4`

## What It Does

- Restores `Tank`, `Healer`, `DPS`, and `Clear Role` in the unit menu
- Works for party leaders, raid leaders, and raid assistants
- Adds `Game` -> `AddOns` -> `PlayerRoleOptions` with an `LFG Default Role` dropdown
- Supports any Blizzard LFG role combination, including single-role, dual-role, and all-role selections
- Uses Blizzard's existing APIs instead of replacing role-assignment behavior

## Install

1. Download the latest release from GitHub or CurseForge.
2. Extract the `PlayerRoleOptions` folder into:
   `World of Warcraft/_anniversary_/Interface/AddOns/`
3. Start the game and make sure the addon is enabled.

## Use

- Right-click a player in your party or raid to assign `Tank`, `Healer`, `DPS`, or `Clear Role`.
- Open `Game` -> `AddOns` -> `PlayerRoleOptions` to choose which LFG roles Blizzard should have prechecked after login.

## Notes

- Target client: TBC Anniversary Classic
- TOC interface: `20505`
- This addon restores missing client UI and uses Blizzard's `UnitSetRole` and LFG role APIs.
- If Blizzard changes or removes that backend behavior, the addon cannot override it.

## Development

Run tests:

```bash
lua tests/run.lua
```

Syntax check:

```bash
luac -p PlayerRoleOptions.lua tests/run.lua
```

Release workflow notes are in [`RELEASING.md`](RELEASING.md).

## Star History

<p align="center">
  <a href="https://star-history.com/#voc0der/PlayerRoleOptions&Date">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=voc0der/PlayerRoleOptions&type=Date&theme=dark" />
      <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=voc0der/PlayerRoleOptions&type=Date" />
      <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=voc0der/PlayerRoleOptions&type=Date" />
    </picture>
  </a>
</p>
