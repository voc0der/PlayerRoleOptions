## [Unreleased]

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
