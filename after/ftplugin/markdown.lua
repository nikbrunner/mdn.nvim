---Mdn.nvim Markdown buffer-local keymaps

local ok, mdn = pcall(require, "mdn")
if not (ok and mdn.did_setup) then
  return
end

-- Capture the buffer this ftplugin is sourced for — deferring and relying on
-- "current buffer" would attach maps to whatever buffer has focus by then.
local buf = vim.api.nvim_get_current_buf()

local Config = require("mdn.config")

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

-- Three-state cycle: blank → bullet → checkbox → toggle
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
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    require("mdn.checkbox").toggle_range(line1, line2)
  end, {
    buffer = buf,
    desc = "Mdn: Toggle checkboxes in selection",
  })
end
