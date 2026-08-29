<div align="center">
  <h1>📝&nbsp;&nbsp;mdn.nvim&nbsp;&nbsp;📝</h1>

  <p><em>Minimal Markdown utilities for Neovim</em></p>
</div>

---

## 💡 Motivation

Most Markdown plugins do too much. mdn.nvim does exactly a few things:

1. **Smart list continuation** — press Enter and the next list item appears automatically
2. **Bullet/checkbox cycle** — `<S-CR>` cycles: blank → bullet → [ ] → [~] → [x] → bullet
3. **Concealed list markers** — shows padded symbols for list items and checkbox states; keeps the current line editable

Built from the [base.nvim](https://github.com/S1M0N38/base.nvim) template.

## ⚡️ Requirements

- [Neovim](https://github.com/neovim/neovim) ≥ 0.10

## 📦 Installation

### vim.pack (Neovim 0.12+)

```lua
vim.pack.add({ "https://github.com/nikbrunner/mdn.nvim" }, { load = true })
```

### lazy.nvim

```lua
{
  "nikbrunner/mdn.nvim",
  ft = { "markdown" },
}
```

## 🚀 Usage

### List Continuation (auto_continue = true)

- Unordered lists (`-`, `*`, `+`): continues with same marker
- Ordered lists (`1.`, `2)`, ...): auto-increments number
- Task lists (`- [ ]`): continues with empty checkbox
- Empty items (`- `): terminates (inserts blank line)

### Checkbox Cycle (`<S-CR>`)

| Step | Starting line    | `<S-CR>` result                      |
| ---- | ---------------- | ------------------------------------ |
| 1    | _(blank)_        | `- ` (or configured `bullet_marker`) |
| 2    | `- buy milk`     | `- [ ] buy milk`                     |
| 3    | `- [ ] buy milk` | `- [~] buy milk`                     |
| 4    | `- [~] buy milk` | `- [x] buy milk`                     |
| 5    | `- [x] buy milk` | `- buy milk`                         |

Works in both Normal and Insert mode.

> [!TIP]
> For indenting/outdenting list items in Insert mode, use Neovim's built-in
> `<C-t>` / `<C-d>` (see `:h i_CTRL-T`).

### Commands

| Command       | Action                                                        |
| ------------- | ------------------------------------------------------------- |
| `:Mdn toggle` | Toggle checkbox (no bullet creation). Accepts a visual range. |

## ⚙️ Configuration

```lua
vim.g.mdn_config = {
    lists = {
        auto_continue = true,      -- enable/disable list continuation
        bullet_marker = "-",       -- marker for new bullets ("-", "*", "+")
    },
    mappings = {
      cycle_key = "<S-CR>",      -- bullet/checkbox cycle key (set to "" to disable)
    },
    conceal = {
      listitem = { pattern = "[-+*]%s", replace = " " },
      unchecked = { pattern = "%[%s%]%s", replace = "󰄱 " },
      checked = { pattern = "%[[xX]%]%s", replace = "󰄲 " },
      partial = { pattern = "%[~%]%s", replace = "󰡖 " },
      defer = { pattern = "%[>%]%s", replace = "󰁔 " },
      scheduled = { pattern = "%[<%]%s", replace = "󰃰 " },
      event = { pattern = "%[o%]%s", replace = "󰃭 " },
      canceled = { pattern = "%[%-]%s", replace = "󱋭 " },
    },
}
```

Set `vim.g.mdn_config` before the package manager loads the plugin.

## 📖 Documentation

Full docs: `:help mdn.txt` | Health: `:checkhealth mdn`

## 🙏 Acknowledgments

- [base.nvim](https://github.com/S1M0N38/base.nvim) — plugin template
- [mdnotes.nvim](https://github.com/ymic9963/mdnotes.nvim) — reference patterns
