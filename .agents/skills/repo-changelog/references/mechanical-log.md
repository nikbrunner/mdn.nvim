# Mechanical log

The entry records the user-facing result of one change, not the files it edited. Write it as part of the implementation.

## Workflow

1. Inspect the diff and name its user-facing outcomes.
2. Pick the category: `Breaking`, `Added`, `Changed`, or `Fixed`. Infer it from the diff and history, not from commit
   prefixes. Create a missing category when the change needs it.
3. Place the entry under the topic root it belongs to.
4. Check it lands in the right release section with its author suffix.

The step is done when every outcome has exactly one entry and nothing the change did is missing.

## Entry rules

- One neutral line in present tense: what mdn.nvim now does or has. No instruction to the reader, no "so that" clause.
- Name config keys, commands, and flags in backticks, as a user would type them.
- Link an issue or PR only when one exists: `([#123](https://github.com/nikbrunner/mdn.nvim/pull/123))`.
- `**Breaking:**` entries go under `### Breaking`, with nested bullets only for separate facts a reader acts on, such as a
  renamed config key.

## Topic roots

Changes gather under a topic root instead of piling up as loose lines. A root is a bare label with the author suffix, and
each change is a sub-bullet:

```md
- Configuration — Name <email>
  - The config file accepts a `theme` key.
  - An unknown key prints its file and line.
```

Put the link on the root when every sub-bullet shares it, otherwise on each sub-bullet. Reuse an existing root before adding
one; current roots are Lists, Checkboxes, Conceal, Rendering, Links, Configuration, Documentation, CI and releases.

## Exceptions

No entry is needed when the whole change is formatting-only, a generated-output refresh with no documentation or behavior
change, changelog-only, or a merge or revert that adds no new user-facing result. When the classification is unclear, ask
one focused question.
