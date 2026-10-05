---Mdn.nvim Markdown buffer-local keymaps

-- Capture the buffer this ftplugin is sourced for — deferring and relying on
-- "current buffer" would attach maps to whatever buffer has focus by then.
local buf = vim.api.nvim_get_current_buf()

local Config = require("mdn.config")

require("mdn.render").attach(buf)

-- List continuation (only when auto_continue is enabled)
if Config.lists.auto_continue then
  vim.keymap.set("i", "<CR>", function()
    require("mdn.list").continue("<CR>")
  end, {
    buffer = buf,
    desc = "Mdn: Continue list on Enter",
  })

  vim.keymap.set("n", "o", function()
    require("mdn.list").continue("o")
  end, {
    buffer = buf,
    desc = "Mdn: Continue list below",
  })

  vim.keymap.set("n", "O", function()
    require("mdn.list").continue("O")
  end, {
    buffer = buf,
    desc = "Mdn: Continue list above",
  })
end

-- Bullet/checkbox cycle: blank → bullet → [ ] → [~] → [x] → bullet
-- Same key in both Normal and Insert mode
if Config.mappings.cycle_key ~= "" then
  vim.keymap.set({ "n", "i" }, Config.mappings.cycle_key, function()
    require("mdn.checkbox").cycle()
  end, {
    buffer = buf,
    desc = "Mdn: Cycle bullet/checkbox",
  })

  vim.keymap.set("v", Config.mappings.cycle_key, function()
    local line1 = vim.fn.line("v")
    local line2 = vim.fn.line(".")
    if line1 > line2 then
      line1, line2 = line2, line1
    end
    require("mdn.checkbox").cycle_range(line1, line2)
  end, {
    buffer = buf,
    desc = "Mdn: Cycle bullets/checkboxes in selection",
  })
end

-- Yank link under cursor: full Markdown link, or bare URL
if Config.mappings.yank_link_key ~= "" then
  vim.keymap.set("n", Config.mappings.yank_link_key, function()
    require("mdn.link").yank()
  end, {
    buffer = buf,
    desc = "Mdn: Yank link under cursor",
  })
end
