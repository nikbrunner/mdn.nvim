---@class Mdn.Config
---@field lists? Mdn.ListsOptions
---@field mappings? Mdn.MappingsOptions
local M = {}

---@class Mdn.ListsOptions
---@field auto_continue boolean Automatically continue lists on <CR>/o/O (default: true)
---@field bullet_marker string List marker for new bullets (default: "-")

---@class Mdn.MappingsOptions
---@field cycle_key string Key for three-state cycle: blank → bullet → checkbox → toggle (set to "" to disable)

local defaults = {
  lists = {
    auto_continue = true,
    bullet_marker = "-",
  },
  mappings = {
    cycle_key = "<C-CR>",
  },
}

-- Access nested config values: Config.lists.bullet_marker, Config.mappings.cycle_key, etc.
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
  vim.validate("auto_continue", config.lists.auto_continue, "boolean")
  if config.mappings.cycle_key then
    vim.validate("cycle_key", config.mappings.cycle_key, "string")
  end
  if config.lists.bullet_marker then
    vim.validate("bullet_marker", config.lists.bullet_marker, "string")
  end
end

return M
