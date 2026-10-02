---@module 'mdn'

---@class Mdn.Plugin
local M = {}

local Config = require("mdn.config")
Config.setup(vim.g.mdn_config)
require("mdn.conceal").setup()
require("mdn.render").setup()

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

---Yank the link under the cursor: the full Markdown link, or the bare URL.
function M.yank_link()
  require("mdn.link").yank()
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
