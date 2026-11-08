# mdn.nvim conceal demo

Open this file in your normal Neovim setup, on a nightly from 2026-10-31 or newer, then check:

```vim
:setlocal conceallevel? concealcursor?
```

The expected values are `conceallevel=2` and an empty `concealcursor=`.

## Links and images

Move the cursor away from the next lines. The URL syntax should disappear, leaving only the label with no reserved gap before the following text.

Before [label only](https://example.com) directly after.

Before ![image alt](https://example.com/image.png) directly after.

Move the cursor onto one of those lines. Its full source should reappear. Press `yl` on a link to yank the whole Markdown link.

A bare URL stays as it is, and `yl` yanks just the URL: https://example.com/bare

Malformed source should stay readable rather than swallowing nearby text:

Before [unfinished](https://example.com directly after.

## Inline formatting

Away from the cursor these markers disappear: **bold text**, *italic text*, ~~struck text~~ and `inline code`. On the cursor line they come back.

## Wrapping

This section is the one that needs conceal-aware `wrap`. Make the window narrow and turn on the options:

```vim
:vsplit | vertical resize 60
:setlocal wrap linebreak breakindent breakindentopt=list:-1
```

Each row should fill up to the window edge using the width you can see. The hidden URL must not push a word to the next row or leave a hole at the end of a row.

Read the [installation guide](https://example.com/a/very/long/path/that/would/otherwise/eat/most/of/the/row/on/its/own) first, then the [configuration reference](https://example.com/another/very/long/path/that/would/otherwise/eat/a/row) and finally the short [changelog](https://example.com/changelog) before you open an issue.

Formatting wraps the same way: this **sentence carries several bold words** and *some italic ones*, and a bit of `inline code` so the hidden markers add up across more than one row of the window.

List items hang under their text, not under their marker. Every continuation row should start in the same column as the first word of its item.

- A top-level bullet whose text is long enough that it has to wrap onto at least one further row of the window.
  - A nested bullet whose text is long enough that it has to wrap onto at least one further row of the window.
    - A deeply nested bullet whose text is long enough that it has to wrap onto at least one further row.
- [ ] An unchecked task whose text is long enough that it has to wrap onto at least one further row of the window.
  - [x] A nested completed task whose text is long enough that it has to wrap onto at least one further row.
- [~] A task in progress with a [link inside it](https://example.com/a/long/path/that/must/not/count/towards/the/row) that also has to wrap.

1. An ordered item whose text is long enough that it has to wrap onto at least one further row of the window.
2. A second ordered item with a [link inside it](https://example.com/a/long/path/that/must/not/count/towards/the/row) that has to wrap as well.

Now move the cursor through those lines with `j` and `k`:

- A line reveals its source when the cursor lands on it, and may gain a row. The rows below shift by that amount and return when the cursor leaves.
- On a revealed task the continuation rows sit two columns in, under the `[`. Once concealed they line up with the text again.
- `gj`, `gk`, `g0` and `g$` follow the rows you see, and a mouse click lands on the character under the pointer, also on rows after a hidden URL.

Finally page through this section with `<C-f>` and `<C-b>`. No row should be cut off or shown twice.

## Tables

Pipes draw as box lines, the delimiter row becomes a solid rule, and cell text keeps its source so columns line up.

| Status  | Score    | Detail                          |
| ------- | -------- | ------------------------------- |
| Passing | **100%** | [updated](https://example.com)  |
| Pending | **67%**  | [previous](https://example.com) |

Move onto the delimiter row. Its source should reappear. Add characters to a cell and leave Insert mode. The cells should pad themselves so the columns line up in the source too.

## Bullets and nested bullets

Move the cursor away from these lines. Bullet markers should use the configured symbols while every indentation level stays aligned.

- Top-level item
  - Nested item
    - Deeply nested item
  - Nested sibling
- Top-level sibling

Move onto a list line. Its Markdown marker should reappear for editing. Press `o` or `O` to check that a new item keeps the current indentation and bullet style.

## Ordered lists

Delete the middle item with `dd`, or add one with `o`. The numbers should fix themselves.

1. First item
2. Second item
3. Third item

## Checkboxes

The checkbox marker should render as its configured symbol away from the cursor. Its full Markdown source should reappear on the cursor line. Each state has its own symbol.

- [ ] Unchecked task
  - Nested bullet
  - [~] Nested task in progress
- [~] Task in progress
- [x] Completed task
- [>] Deferred task
- [<] Scheduled task
- [o] Event
- [-] Canceled task

Put the cursor on a checkbox and press the configured cycle key (`<C-k>` by default). The state should advance without changing the task text or indentation. Select several lines in Visual mode: their source should reappear, and the cycle key should apply to all of them.

## Fenced code

Move the cursor outside this block. Both fence lines should remain as screen rows, but their backticks and the `lua` language marker should be invisible. The payload must remain visible.

```lua
local payload = "this line must stay visible"
print(payload)
```

Move the cursor onto either fence line. Its full source should reappear without shifting the surrounding rows.

List and checkbox syntax inside a code block stays as source:

```markdown
- [ ] this is not a real task
- neither is this a bullet
```

## Edit directly before a closing fence

The payload line below sits immediately before the closing fence.

```text
payload-before-closing-fence
```

Put the cursor at the end of `payload-before-closing-fence`, press `A`, and type a few characters. While editing and after leaving Insert mode, look for all three:

1. The payload remains visible.
2. The opening and closing fence rows remain in place.
3. Text below the block does not jump upward or disappear.

This line must remain visible after the edit.

## Two-window reveal

Run `:vsplit`. In one window, place the cursor on the valid-link line. In the other, place it on a fence line.

Each window should reveal source only for its own cursor line. The other window's cursor position must not decide what this window conceals.

## Conceal options

Run `:setlocal conceallevel=0`. All source should appear. Open another file with `:edit /tmp/other.txt` and come back with `:edit #`. The level should still be 0. Run `:setlocal conceallevel=2` to restore it.

Open another filetype with `:new | setfiletype lua`, then check `:setlocal conceallevel?`. It should be 0: the Markdown level stays in Markdown windows.

## Quick failure signs

- A gap at the end of a wrapped row, or a word pushed down early, means the Neovim build predates conceal-aware `wrap`.
- A blank gap after `label only` means level-1-style link conceal has leaked back in.
- Continuation rows indented deeper than a task's text mean `formatlistpat` counts the `[ ]` as part of the marker.
- A missing screen row around a code block means vertical fence conceal is active.
- Missing payload near a closing fence means stale `conceal_lines` marks survived.
- Source staying hidden on the cursor line means `concealcursor` is wrong.
