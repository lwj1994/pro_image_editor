---
name: release-new-version
description: >
  Use this skill when releasing a new version of
  pro_image_editor. It updates pubspec/changelog,
  commits, pushes the current branch, and pushes
  a vX.Y.Z tag.
---

# Release New Version Skill

## When to Use
- When the user wants to release a new version
- When updating `pubspec.yaml` and `CHANGELOG.md` for release
- When creating and pushing a `vX.Y.Z` tag

## Prerequisites
- Release-related code changes are already finalized
- Git remote is configured for push

## Release Checklist

### Step 1: Confirm Version
- Confirm target version `X.Y.Z`.
- Git tag format must be `vX.Y.Z`.

### Step 2: Update Release Files
- Update `CHANGELOG.md` by inserting a new top section:
  - `## X.Y.Z`
  - release bullet list in existing style.
- Update root `pubspec.yaml`:
  - `version: X.Y.Z`
- If present, update `example/pubspec.yaml` version to `X.Y.Z+1`.

### Step 3: Commit
Run git commands directly:

```bash
git status -sb
git add CHANGELOG.md pubspec.yaml example/pubspec.yaml
git commit -m "chore: release vX.Y.Z"
```

If `example/pubspec.yaml` does not exist or has no `version`, adjust `git add` accordingly.

### Step 4: Create Tag

```bash
git tag vX.Y.Z
```

If `vX.Y.Z` already exists, stop and ask the user before proceeding.

### Step 5: Push Branch and Tag

```bash
git push
git push origin vX.Y.Z
```

Always push the current branch before pushing the tag.

## Important Notes

### Version Format
- `pubspec.yaml` uses `12.0.0` (no `v`)
- Git tags use `v12.0.0` (with `v`)
- `CHANGELOG.md` uses `## 12.0.0` (no `v`)

### CHANGELOG Format Rules
1. New versions are added at the **top** of the file
2. Each version starts with `## x.y.z`
3. Changes are listed as bullet points with type and scope
4. Keep prior history entries unchanged

### File Locations
- `/Users/luwenjie/Documents/GitHub/pro_image_editor/pubspec.yaml`
- `/Users/luwenjie/Documents/GitHub/pro_image_editor/example/pubspec.yaml`
- `/Users/luwenjie/Documents/GitHub/pro_image_editor/CHANGELOG.md`
