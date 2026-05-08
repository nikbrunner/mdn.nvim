---@class Mdn.Config
---@field auto_continue boolean
---@field keymaps? Mdn.Keymaps
local M = {}

---@class Mdn.DefaultOptions
---@field auto_continue boolean Automatically continue lists on <CR>/o/O (default: true)
---@field keymaps Mdn.Keymaps Keymap configuration

---@class Mdn.Keymaps
---@field toggle_checkbox? string Key for toggling checkbox in Normal mode (set to "" to disable)
---@field toggle_checkbox_insert? string Key for toggling checkbox in Insert mode (set to "" to disable)

local defaults = {
  auto_continue = true,
  keymaps = {
    toggle_checkbox = "<leader>x",
    toggle_checkbox_insert = "<C-Space>",
  },
}

-- Access config values directly: Config.auto_continue, Config.keymaps
local config = vim.deepcopy(defaults)

-- Created at module load — always available
M.augroup = vim.api.nvim_create_augroup("mdn", { clear = true })
M.ns = vim.api.nvim_create_namespace("mdn")

setmetatable(M, {
  __index = function(_, key)
    return config[key]
  end,
})

---Extend the defaults options table with the user options
---@param opts? Mdn.Config plugin options
function M.setup(opts)
  config = vim.tbl_deep_extend("force", {}, vim.deepcopy(defaults), opts or {})

  -- Validate config
  vim.validate("auto_continue", config.auto_continue, "boolean")
  vim.validate("keymaps", config.keymaps, "table")

  if config.keymaps.toggle_checkbox then
    vim.validate("keymaps.toggle_checkbox", config.keymaps.toggle_checkbox, "string")
  end
  if config.keymaps.toggle_checkbox_insert then
    vim.validate("keymaps.toggle_checkbox_insert", config.keymaps.toggle_checkbox_insert, "string")
  end
end

return M
