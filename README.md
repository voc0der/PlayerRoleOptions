<h1 align="center">PlayerRoleOptions</h1>

<p align="center">
  Restore the missing right-click role assignment menu for party leaders, raid leaders, and raid assistants in TBC Anniversary Classic.
</p>

<p align="center"><strong>Current version:</strong> <code>0.1.0</code></p>

## Scope

- Target client: TBC Anniversary Classic
- TOC interface: `20505`

## Features

- Adds role assignment options back to the unit right-click menu for other players in your party or raid
- Supports `Tank`, `Healer`, `DPS`, and `Clear Role`
- Shows the menu only when you have permission to assign roles:
  - Party leader in parties
  - Raid leader or raid assistant in raids
- Uses Blizzard's existing `UnitSetRole` API instead of replacing backend behavior

## Installation

1. Download or clone this repository.
2. Place the `PlayerRoleOptions` folder in:
   - `World of Warcraft/_classic_/Interface/AddOns/`
3. Launch the game and enable `PlayerRoleOptions` in the AddOns list.

## Usage

- Right-click another player in your party or raid.
- Use the restored `Set Role` section to choose `Tank`, `Healer`, `DPS`, or `Clear Role`.

## Limitations

- This addon restores the missing client-side menu entry.
- It depends on Blizzard still allowing role assignments through `UnitSetRole`. If Blizzard removes the API behavior itself, no addon can force the assignment to succeed.

## Development

Run local tests:

```bash
lua tests/run.lua
```

Syntax check:

```bash
luac -p PlayerRoleOptions.lua
```

## Releasing

Release workflow details are in [`RELEASING.md`](RELEASING.md).

## License

MIT. See [LICENSE](LICENSE).

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=voc0der/PlayerRoleOptions&type=Date)](https://star-history.com/#voc0der/PlayerRoleOptions&Date)
