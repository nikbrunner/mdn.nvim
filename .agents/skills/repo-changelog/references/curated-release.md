# Curated release

Before a release ships, its section is rewritten for a human reader: a curated top that reads by impact, then the mechanical
log trimmed and grouped below it. The most recent curated section is the reference shape.

## Workflow

1. Read every entry in the release section and rank the outcomes by impact on a user.
2. Write `### Highlights` in impact order (below).
3. Trim the mechanical log: remove every entry a highlight fully covers, carrying its links into the highlight, and group the
   rest under topic roots ([`mechanical-log.md`](mechanical-log.md#topic-roots)), ordered by impact.
4. Set the heading version to the release PR's version and the date to the release day.
5. Run the `humanizer` skill on the highlights.

The curation is done when a reader who stops after the highlights knows every change worth acting on, and no entry below
repeats a highlight.

## Highlights

Highlights are the one place where prose addresses the reader, and they carry no author suffix. In order:

1. **Feature blocks** (`#### Name`): the largest outcomes first. Promote undersold work hiding in the log; a new workflow
   often matters more than a new option. Show config or usage as a code block when the reader will copy it.
2. **Important fixes**: fixes a user would notice or has worked around.
3. **Upgrading from X.Y**: last, one sentence per step and the change as a `diff` block, old line `-`, new line `+`.

## Screenshots

Store screenshots under `docs/assets/changelog/<version>-<topic>.webp`, captured clean at a fixed size. Reference them with
an absolute URL pinned to the release tag, `https://raw.githubusercontent.com/nikbrunner/mdn.nvim/v<version>/...`, so they render in
the GitHub Release notes and keep showing that release after later captures replace the files on `main`.
