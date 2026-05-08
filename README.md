<div align="center">
  <h1>📝&nbsp;&nbsp;mdn.nvim&nbsp;&nbsp;📝</h1>

  <p><em>Minimal Markdown utilities for Neovim</em></p>
</div>

---

## 💡 Motivation

Most Markdown plugins do too much. mdn.nvim does exactly two things:

1. **Smart list continuation** — press Enter and the next list item appears automatically
2. **Checkbox toggling** — toggle `[ ]` ↔ `[x]` in Normal or Insert mode

That's it. No wikilinks, no tables, no ToC generation. Just the two features you miss most when writing Markdown in vanilla Neovim.

Built from the [base.nvim](https://github.com/S1M0N38/base.nvim) template for clean architecture: tests, CI, type annotations, health checks.

## ⚡️ Requirements

- [Neovim](https://github.com/neovim/neovim) ≥ 0.10
- Markdown filetype (set automatically for `.md` files)

## 📦 Installation

### lazy.nvim

```lua
{
  "nikbrunner/mdn.nvim",
  ft = { "markdown" },
  opts = {},
}
```

### vim.pack

```lua
vim.pack.add("https://github.com/nikbrunner/mdn.nvim")
require("mdn").setup()
```

## 🚀 Usage

### List Continuation

When `auto_continue` is enabled (default), pressing `<CR>`, `o`, or `O` on a list item automatically inserts the next one:

```
- item          →  - item       →  - item
  ^ Enter           - |            - new item  ← cursor
```

- **Unordered lists** (`-`, `*`, `+`): continues with the same marker
- **Ordered lists** (`1.`, `2)`, ...): auto-increments the number
- **Task lists** (`- [ ]`): continues with an empty checkbox
- **Empty items** (`- `): terminates continuation (inserts blank line)

### Checkbox Toggle

| Mode   | Default Key | Command       |
| ------ | ----------- | ------------- |
| Normal | `<leader>x` | `:Mdn toggle` |
| Insert | `<C-Space>` | (built-in)    |

Toggles:

- `[ ]` → `[x]` (check)
- `[x]` → `[ ]` (uncheck)
- No checkbox → adds `[ ]` after the list marker

## ⚙️ Configuration

```lua
require("mdn").setup({
  auto_continue = true,           -- enable/disable list continuation
  keymaps = {
    toggle_checkbox = "<leader>x",        -- Normal mode key (set to "" to disable)
    toggle_checkbox_insert = "<C-Space>", -- Insert mode key (set to "" to disable)
  },
})
```

## 📖 Documentation

Full documentation is available with `:help mdn.txt`.

Run `:checkhealth mdn` to verify your setup.

## 🙏 Acknowledgments

- [base.nvim](https://github.com/S1M0N38/base.nvim) — the Neovim plugin template this is built on
- [mdnotes.nvim](https://github.com/ymic9963/mdnotes.nvim) — reference for list continuation and checkbox toggle patterns
