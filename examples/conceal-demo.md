# mdn.nvim conceal demo

Open this file in your normal Neovim setup, then check:

```vim
:setlocal conceallevel? concealcursor?
```

The expected values are `conceallevel=2` and an empty `concealcursor=`.

## Links

Move the cursor away from the next line. The URL syntax should disappear, leaving
only the label with no reserved gap before the following text.

Before [label only](https://example.com) directly after.

Move the cursor onto that line. The full `[label](url)` source should reappear.

## Tables

Set `concealcursor` to `n`, then move through this table in Normal mode. Bold
and link delimiters should remain concealed on the cursor row, so every row keeps
the same layout. Start Insert mode on a cell to reveal its source for editing.

```vim
:setlocal concealcursor=n
```

| Status | Score | Detail |
| ------ | ----- | ------ |
| Passing | **100%** | [updated](https://example.com) |
| Pending | **67%** | [previous](https://example.com) |

Malformed source should stay readable rather than swallowing nearby text:

Before [unfinished](https://example.com directly after.

## Bullets and nested bullets

Move the cursor away from these lines. Bullet markers should use the configured
symbols while every indentation level stays aligned.

- Top-level item
  - Nested item
    - Deeply nested item
  - Nested sibling
- Top-level sibling

Move onto a list line. Its Markdown marker should reappear for editing. Press `o`
or `O` to check that a new item keeps the current indentation and bullet style.

## Checkboxes

The checkbox marker should render as its configured symbol away from the cursor.
Its full Markdown source should reappear on the cursor line.

- [ ] Unchecked task
  - Nested unchecked task
  - [~] Nested task in progress
- [~] Task in progress
- [x] Completed task

Put the cursor on a checkbox and press the configured cycle key (`<S-CR>` by
default). The state should advance without changing the task text or indentation.

## Fenced code

Move the cursor outside this block. Both fence lines should remain as screen rows,
but their backticks and the `lua` language marker should be invisible. The payload
must remain visible.

```lua
local payload = "this line must stay visible"
print(payload)
```

Move the cursor onto either fence line. Its full source should reappear without
shifting the surrounding rows.

## Edit directly before a closing fence

The payload line below sits immediately before the closing fence.

```text
payload-before-closing-fence
```

Put the cursor at the end of `payload-before-closing-fence`, press `A`, and type a
few characters. While editing and after leaving Insert mode, look for all three:

1. The payload remains visible.
2. The opening and closing fence rows remain in place.
3. Text below the block does not jump upward or disappear.

This line must remain visible after the edit.

## Two-window reveal

Run `:vsplit`. In one window, place the cursor on the valid-link line. In the other,
place it on a fence line.

Each window should reveal source only for its own cursor line. The other window's
cursor position must not decide what this window conceals.

## Quick failure signs

- A blank gap after `label only` means level-1-style link conceal has leaked back in.
- A missing screen row around a code block means vertical fence conceal is active.
- Missing payload near a closing fence means stale `conceal_lines` marks survived.
- Source staying hidden on the cursor line means `concealcursor` is wrong.
