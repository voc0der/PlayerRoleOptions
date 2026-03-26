# Releasing to CurseForge

## TBC Anniversary Support

PlayerRoleOptions targets TBC Anniversary Classic. The TOC file specifies:

```
## Interface: 20505
```

## Workflow Prerequisites

Before automated release can work end-to-end, configure:

1. GitHub Actions secret `RELEASE_PAT`
   - Fine-grained token with repository `Contents: Read and write`
   - Needed so tag push can trigger the release workflow
2. GitHub Actions secret `CF_API_KEY`
   - CurseForge API token used by `BigWigsMods/packager`
3. CurseForge project metadata in addon TOC
   - Add `## X-Curse-Project-ID: <your_project_id>` to `PlayerRoleOptions.toc`
   - Without this, packager can still build archives but cannot upload to CurseForge

## Release Process

### Automated (GitHub Actions)

1. Update version in `PlayerRoleOptions.toc`
2. Update `CHANGELOG.md` with release notes
3. Commit and push to `main`
4. CI automatically creates a tag from the TOC version and triggers the packager

### Troubleshooting

- No new tag created:
  - Check `## Version:` in `PlayerRoleOptions.toc` is bumped (for example `1.0.3`)
  - If tag already exists (for example `v1.0.3`), workflow will skip by design
- Tag created but no release upload:
  - Confirm `CF_API_KEY` exists in repo secrets
  - Confirm `## X-Curse-Project-ID:` is set to a valid numeric project ID
- Tag workflow failing authentication:
  - Confirm `RELEASE_PAT` exists and has repo contents write permissions
  - If using org SSO, ensure the token is authorized for the org

### Manual Upload to CurseForge

1. Create a zip file:
   ```bash
   cd /home/vocoder/Code
   zip -r PlayerRoleOptions-v1.0.X.zip PlayerRoleOptions -x "*.git*" -x "*README.md"
   ```
2. Upload at your CurseForge project files page.

## What Gets Released

The `.pkgmeta` file controls what gets included:
- PlayerRoleOptions.lua
- PlayerRoleOptions.toc
- CHANGELOG.md
- README.md (excluded)
- .git files (excluded)
