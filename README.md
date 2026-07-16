<div align="center">
  <h1>📝&nbsp;&nbsp;mdn.nvim&nbsp;&nbsp;📝</h1>

  <p><em>Minimal Markdown utilities for Neovim</em></p>
</div>

---

## 💡 Motivation

Most Markdown plugins do too much. mdn.nvim does exactly a few things:

1. **Smart list continuation** — press Enter and the next list item appears automatically
2. **Three-state checkbox cycle** — `<C-CR>` cycles: blank → bullet → checkbox → toggle

Built from the [base.nvim](https://github.com/S1M0N38/base.nvim) template.

## ⚡️ Requirements

- [Neovim](https://github.com/neovim/neovim) ≥ 0.10

## 📦 Installation

### lazy.nvim

```lua
{
  "nikbrunner/mdn.nvim",
  ft = { "markdown" },
  opts = {},
}
```

## 🚀 Usage

### List Continuation (auto_continue = true)

- Unordered lists (`-`, `*`, `+`): continues with same marker
- Ordered lists (`1.`, `2)`, ...): auto-increments number
- Task lists (`- [ ]`): continues with empty checkbox
- Empty items (`- `): terminates (inserts blank line)

### Checkbox Cycle (`<C-CR>`)

| Step | Starting line | `<C-CR>` result |
|------|--------------|----------------|
| 1 | *(blank)* | `- ` (or configured `bullet_marker`) |
| 2 | `- buy milk` | `- [ ] buy milk` |
| 3 | `- [ ] buy milk` | `- [~] buy milk` |
| 4 | `- [~] buy milk` | `- [x] buy milk` |
| 4' | `- [x] buy milk` | `- [ ] buy milk` |

Works in both Normal and Insert mode.

> [!TIP]
> For indenting/outdenting list items in Insert mode, use Neovim's built-in
> `<C-t>` / `<C-d>` (see `:h i_CTRL-T`).

### Commands

| Command | Action |
|---------|--------|
| `:Mdn toggle` | Toggle checkbox (no bullet creation) |

## ⚙️ Configuration

```lua
require("mdn").setup({
    lists = {
        auto_continue = true,      -- enable/disable list continuation
        bullet_marker = "-",       -- marker for new bullets ("-", "*", "+")
    },
    mappings = {
      cycle_key = "<C-CR>",      -- three-state cycle key (set to "" to disable)
    },
})
```

## 📖 Documentation

Full docs: `:help mdn.txt`  |  Health: `:checkhealth mdn`

## 🙏 Acknowledgments

- [base.nvim](https://github.com/S1M0N38/base.nvim) — plugin template
- [mdnotes.nvim](https://github.com/ymic9963/mdnotes.nvim) — reference patterns
