---
name: repo-release
description:
  "Prepare and ship a mdn.nvim release. Use this when opening the next release, checking whether a release is ready,
  cutting a version, preparing release notes, or merging the release-please PR. Ask for approval before merging the
  release PR."
argument-hint: "[prepare <version> | status | <version>; defaults to shipping the release PR's version]"
allowed-tools: Bash Read Edit
disable-model-invocation: true
---

# Release mdn.nvim

| Argument                    | Mode                                                |
| --------------------------- | --------------------------------------------------- |
| `prepare <version>`         | [Prepare](#prepare): open the next release          |
| `status`                    | [Status](#status): report how close a release is    |
| `<version>`, or no argument | [Ship](#ship): curate, merge the release PR, verify |

## Prepare

Opens a release before its PR exists, so the work in between aims at it.

1. Add the release heading for `<version>` to `CHANGELOG.md` above the newest section, dated with the planned release
   day, in the format of [`repo-changelog`](../repo-changelog/SKILL.md). Move every entry from `## [Unreleased]` into it
   and drop the empty `## [Unreleased]` heading. From then on new entries go into this section.
2. Create the milestone and assign the issues the release should close:

   ```sh
   gh api repos/nikbrunner/mdn.nvim/milestones -f title="v<version>"
   gh issue edit <number> --milestone "v<version>"
   ```

3. Commit as `docs: open the <version> release`.

release-please computes the next version from the commits. When it would pick another version than `<version>`, a commit
with a `Release-As: <version>` footer pins it.

Prepare is done when the section exists, `## [Unreleased]` is gone, and the milestone exists.

## Status

Reports and changes nothing. Collect:

- **Release PR:** `gh pr list --label "autorelease: pending" --json number,title`, and the version in its title, or that
  none is open.
- **Changelog:** whether `CHANGELOG.md` has a section for that version, and whether it matches the release PR.
- **Unlogged changes:** commits since the latest `v*` tag whose type counts toward a release and that leave
  `CHANGELOG.md` untouched:

  ```sh
  tag=$(git describe --tags --abbrev=0 --match 'v*')
  for sha in $(git log "$tag"..HEAD --format=%h -E --grep='^(feat|fix|docs|refactor|perf)'); do
    git diff-tree --no-commit-id --name-only -r "$sha" | grep -qx CHANGELOG.md || git log -1 --format='%h %s' "$sha"
  done
  ```

- **Milestone:** `gh issue list --milestone "v<version>" --state open`.
- **CI:** `gh run list --branch main --limit 1` on the latest commit.

End the report with one line: ready to ship, or what blocks it.

## Ship

Follow [`docs/releases.md`](../../../docs/releases.md). It is the maintainer source of truth for the release PR, the curated
changelog commit, and checking the GitHub Release.

Prepare the release notes with [`repo-changelog`](../repo-changelog/SKILL.md) in release mode before merging:
it curates the section and sets the release date. The section's version must match the release PR title. Read the title
after release-please has finished its run for the latest push to `main`; each run can change the version.

Ask for explicit approval immediately before merging the release PR. After the release, close the milestone:

```sh
gh api -X PATCH repos/nikbrunner/mdn.nvim/milestones/<number> -f state=closed
```
