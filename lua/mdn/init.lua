---@module 'mdn'

---@class Mdn.Plugin
local M = {}

M.did_setup = false

---Setup the mdn.nvim plugin.
---Must be called once before using other functions.
---@param opts? Mdn.Config plugin options
function M.setup(opts)
  if M.did_setup then
    local Util = require("mdn.util")
    return Util.warn("mdn.nvim is already setup")
  end
  M.did_setup = true
  require("mdn.config").setup(opts)
end

---Toggle the checkbox on the current line.
---`[ ]` becomes `[x]`, `[x]` becomes `[ ]`.
---If the line is a list item without a checkbox, a `[ ]` is added.
---Does nothing if the line is not a list item.
function M.toggle_checkbox()
  require("mdn.checkbox").toggle()
end

---Continue the current list by inserting a new list item below.
---Use from keymaps — called by `<CR>` and `o` remaps.
function M.continue_list()
  require("mdn.list").continue("o")
end

---Continue the current list by inserting a new list item above.
---Use from keymaps — called by `O` remap.
function M.continue_list_above()
  require("mdn.list").continue("O")
end

---Continue the current list on Enter (for Insert mode `<CR>` remap).
function M.continue_list_enter()
  require("mdn.list").continue("<CR>")
end

return M
