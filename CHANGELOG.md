## [Unreleased]

## [1.0.4] - 2026-03-26

### Changed
- Package only runtime addon files in PR artifacts, GitHub releases, and CurseForge uploads
- Verify the release package matches the runtime addon tree before packager upload runs

## [1.0.3] - 2026-03-26

### Added
- Added an AddOns settings entry with an `LFG Default Role` dropdown
- Added support for saving and restoring any Blizzard LFG role combination, including mixed `Tank`, `Healer`, and `DPS` selections

### Changed
- Apply the configured LFG default role on login so Blizzard's LFG UI opens with the saved roles prechecked

## [1.0.1] - 2026-03-22

### Changed
- Follow-up metadata release under the `1.0.x` version line with no gameplay changes

## [1.0.0] - 2026-03-22

### Changed
- Adopted the `1.0.x` public release version line with no gameplay changes from `0.1.2`

## [0.1.2] - 2026-03-21

### Fixed
- Allowed leaders and assistants to assign roles to themselves when grouped
- Restored the compact `Set Role` submenu on clients using Blizzard's newer menu system
- Hardened load-time menu registration to avoid intermittent blank errors during `/reload`

## [0.1.1] - 2026-03-21

### Fixed
- Avoided a load-time error on clients where `UnitPopup_ShowMenu` no longer exists
- Added support for Blizzard's newer tagged unit context menus so role options still appear on current clients
- Expanded regression coverage for both legacy and modern menu registration paths

## [0.1.0] - 2026-03-21

### Added
- Initial release
- Restored right-click role assignment options for party leaders, raid leaders, and raid assistants
- Added local regression tests for role menu injection and role assignment dispatch
- Added GitHub Actions tagging and release packaging automation

### Fixed
- Ensured `UnitSetRole` targets the unit token when available instead of relying on a player name string
