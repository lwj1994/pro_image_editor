---
name: release-new-version
description: >
  Use this skill when preparing and releasing a new
  version of the pro_image_editor package. It guides
  through version bump, changelog update, code checks,
  and git tag creation for pub.dev publishing.
---

# Release New Version Skill

## When to Use
- When the user wants to release a new version
- When preparing a version bump (major, minor, or patch)
- When updating the CHANGELOG for a new release

## Prerequisites
- All feature/fix code changes are already committed
- The working directory is clean (no uncommitted changes)
- Tests are passing

## Release Checklist

### Step 1: Determine Version Type
Ask the user which type of version bump is needed:
- **Major** (`X.0.0`): Breaking changes
- **Minor** (`x.Y.0`): New features (backward compatible)
- **Patch** (`x.y.Z`): Bug fixes only

Read the current version from `pubspec.yaml` (line starting with `version:`).

### Step 2: Collect Release Notes
Ask the user for the changes in this release. Categorize each change using the existing CHANGELOG conventions:
- `**BREAKING**`: Breaking changes (major versions only)
- `**FEAT**`: New features
- `**FIX**`: Bug fixes
- `**PERF**`: Performance improvements
- `**REFACTOR**`: Code refactoring
- `**DOCS**`: Documentation updates
- `**STYLE**`: Code style changes
- `**CHORE**`: Dependency or tooling updates
- `**TEST**`: Test additions or changes

Each entry should follow this format:
```
- **TYPE**(scope): Description of the change.
```

Example:
```
- **FEAT**(text-editor): Add new font selection feature.
- **FIX**(paint-editor): Resolve crash when drawing on small canvas.
```

### Step 3: Update CHANGELOG.md
Insert a new version section at the **top** of `CHANGELOG.md` (after the `# Changelog` header on line 1), following the existing format:

```markdown
## <new_version>
- **TYPE**(scope): Description.
```

Leave one blank line between the `# Changelog` header and the new version entry.

### Step 4: Update pubspec.yaml
Update the `version:` field in `pubspec.yaml` to the new version number.

### Step 5: Run Code Quality Checks
You can run all checks automatically using the provided script:

```bash
# Run automated checks (Format, Analyze, Test)
bash .agents/skills/release-new-version/scripts/check_release.sh
```

Or run them manually in order. **Stop and report** if any check fails:

```bash
# 1. Check formatting (line width 80)
dart format --output=none --set-exit-if-changed --line-length=80 .

# 2. Analyze code
flutter analyze .

# 3. Run tests using ff
ff test
```

### Step 6: Dry Run Publish
Run a publish dry-run to verify the package is ready:

```bash
flutter pub publish --dry-run
```

Review the output for any warnings or errors. Report findings to the user.

### Step 7: Report Summary
After all steps are complete, provide a summary to the user:

```
📦 Release Summary
━━━━━━━━━━━━━━━━━━
Version:  <old_version> → <new_version>
Type:     <major|minor|patch>
Changes:  <number of changelog entries>
Checks:   ✅ Format | ✅ Analyze | ✅ Tests | ✅ Dry Run

Next steps (manual):
1. Review the changes in CHANGELOG.md and pubspec.yaml
2. Commit: git commit -am "chore: release v<new_version>"
3. Tag:    git tag v<new_version>
4. Push:   git push && git push --tags
5. GitHub Actions will auto-publish to pub.dev
```

## Important Notes

### Version Format
- `pubspec.yaml` uses: `12.0.0` (no `v` prefix)
- Git tags use: `v12.0.0` (with `v` prefix)
- CHANGELOG uses: `## 12.0.0` (no `v` prefix)

### CHANGELOG Format Rules
1. New versions are added at the **top** of the file
2. Each version starts with `## x.y.z`
3. Changes are listed as bullet points with type and scope
4. Breaking changes should include a `#### Breaking Changes` subsection
5. Use `<br/>` tags to separate different categories if needed

### Git Tag Publishing
The project uses GitHub Actions (`.github/workflows/publish.yml`) to auto-publish to pub.dev when a tag matching `v[0-9]+.[0-9]+.[0-9]+*` is pushed. **DO NOT** run git commands — only provide instructions to the user.

### File Locations
- Version: `pubspec.yaml` → `version:` field (line 3)
- Changelog: `CHANGELOG.md`
- Publish workflow: `.github/workflows/publish.yml`
- Analysis workflow: `.github/workflows/flutter_analysis.yml`

## Resources
- **Scripts**: `.agents/skills/release-new-version/scripts/check_release.sh` (Automated CI checks)
- **Examples**: `.agents/skills/release-new-version/examples/CHANGELOG_TEMPLATE.md` (Format reference)
