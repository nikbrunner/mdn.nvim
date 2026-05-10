---@class Mdn.Config
---@field auto_continue boolean
---@field cycle_key? string
---@field bullet_marker? string
---@field indent_key? string
---@field outdent_key? string
local M = {}

---@class Mdn.DefaultOptions
---@field auto_continue boolean Automatically continue lists on <CR>/o/O (default: true)
---@field cycle_key string Key for the three-state cycle: blank → bullet → checkbox → toggle (set to "" to disable)
---@field bullet_marker string List marker used when creating new bullets via cycle (default: "-")
---@field indent_key string Insert-mode key for indenting current line (default: "<Tab>")
---@field outdent_key string Insert-mode key for outdenting current line (default: "<S-Tab>")

local defaults = {
  auto_continue = true,
  cycle_key = "<C-t>",
  bullet_marker = "-",
  indent_key = "<Tab>",
  outdent_key = "<S-Tab>",
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
  if config.bullet_marker then
    vim.validate("bullet_marker", config.bullet_marker, "string")
  end
  if config.indent_key then
    vim.validate("indent_key", config.indent_key, "string")
  end
  if config.outdent_key then
    vim.validate("outdent_key", config.outdent_key, "string")
  end
end

return M
