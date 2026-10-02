---
name: repo-changelog
description:
  "Write CHANGELOG.md for mdn.nvim: the mechanical entry every implementation adds, and the curated release section before
  a release ships. Use it for every change; only formatting-only, generated-only, changelog-only, or merge/revert changes
  that leave an existing entry accurate can skip the entry."
argument-hint: "[entry | release <version>]"
allowed-tools: Read Edit Bash
---

# Write the changelog

`CHANGELOG.md` has two layers. The **mechanical log** grows one entry per change during development. The **curated release**
is the reader-facing top of a release section, written once before it ships. release-please never edits the file; the
curated section becomes the GitHub Release notes.

| Task                                        | Read                                                             |
| ------------------------------------------- | ---------------------------------------------------------------- |
| A change needs its entry                    | [`references/mechanical-log.md`](references/mechanical-log.md)   |
| A release is being prepared (`release X.Y`) | [`references/curated-release.md`](references/curated-release.md) |

## Shared format

- A release heading puts the backticked version, eight `&nbsp;`, and the release date:
  ``## `0.7.0` &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 2026.09.28``. The release workflow finds the section by the
  backticked version at the start of that line.
- While a release is prepared but unpublished, new entries go into its section. `## [Unreleased]` exists only while it holds entries.
- Every entry ends with `— Name <email>` from the committer's Git config; a breaking entry starts with `**Breaking:**`.
- Separate release sections with `---`, with a blank line on each side. The release notes end at the first `---`.
- Run the `humanizer` skill in embedded mode on every entry and highlight before handing it over.

Leave the edit unstaged with the change it describes, and tell the caller what was written or which exception applies.
