# Release Process

## Automated Process

Every push to `main` triggers an automatic release via GitHub Actions:
- Reads the version from `PlayerRoleOptions.toc`
- Creates a git tag if one doesn't exist for that version
- Tag push triggers the packager workflow
- `BigWigsMods/packager` builds the release zip and uploads to CurseForge

**Update the version in `PlayerRoleOptions.toc` before pushing.**

## Prerequisites

- `RELEASE_PAT` repository secret:
  - Fine-grained PAT with repo `Contents: Read and write`
  - Required so workflow-created tag pushes can trigger downstream workflows
- `CF_API_KEY` repository secret:
  - Required for CurseForge upload in packager step
- `## X-Curse-Project-ID: <id>` in `PlayerRoleOptions.toc`:
  - Required by packager to know which CurseForge project to publish to

## Manual Steps (For Major/Minor Releases)

### 1. Update Version

Update `## Version:` in `PlayerRoleOptions.toc` to a version that is not already tagged.

### 2. Update CHANGELOG.md

```markdown
## [Unreleased]

### Added
- New feature description

### Fixed
- Bug fix description
```

### 3. Commit and Push

```bash
git add PlayerRoleOptions.toc CHANGELOG.md
git commit -m "Release v0.1.X"
git push
```

The CI pipeline handles tagging and packaging automatically.

If no new tag appears, check whether the tag for that version already exists.

## Version Numbering

Following [Semantic Versioning](https://semver.org/):
- **MAJOR** (`v2.0.0`): Breaking changes
- **MINOR** (`v0.2.0`): New features, backwards-compatible
- **PATCH** (`v0.1.1`): Bug fixes, backwards-compatible
