---@module 'mdn'

---@class Mdn.Plugin
local M = {}

local Config = require("mdn.config")
Config.setup(vim.g.mdn_config)
require("mdn.conceal").setup()

---Bullet/checkbox cycle: blank → bullet → [ ] → [~] → [x] → bullet.
---Works in both Normal and Insert mode.
function M.cycle()
  require("mdn.checkbox").cycle()
end

---Toggle the checkbox on the current line (or add one if it's a list item).
---Used by the :Mdn toggle command.
function M.toggle_checkbox()
  require("mdn.checkbox").toggle()
end

---Continue the current list by inserting a new list item below.
function M.continue_list()
  require("mdn.list").continue("o")
end

---Continue the current list by inserting a new list item above.
function M.continue_list_above()
  require("mdn.list").continue("O")
end

---Continue the current list on Enter (for Insert mode <CR> remap).
function M.continue_list_enter()
  require("mdn.list").continue("<CR>")
end

return M
