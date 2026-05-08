---@class Mdn.Config
---@field auto_continue boolean
---@field cycle_key? string
local M = {}

---@class Mdn.DefaultOptions
---@field auto_continue boolean Automatically continue lists on <CR>/o/O (default: true)
---@field cycle_key string Key for the three-state cycle: blank → bullet → checkbox → toggle (set to "" to disable)

local defaults = {
  auto_continue = true,
  cycle_key = "<C-t>",
}

-- Access config values directly: Config.auto_continue, Config.cycle_key
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
  if config.cycle_key then
    vim.validate("cycle_key", config.cycle_key, "string")
  end
end

return M
