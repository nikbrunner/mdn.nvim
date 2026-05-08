---@class Base.Health
local M = {}

---Validate that config values have expected types
local function validate_opts_table()
  local opts = require("mdn.config")

  local ok, err = pcall(function()
    vim.validate({
      name = { opts.name, "string" },
      --- validate other options here...
    })
  end)

  if not ok then
    vim.health.error("Invalid setup options: " .. err)
  else
    vim.health.ok("opts are correctly set")
  end
end

---Health check called by `:checkhealth mdn`
function M.check()
  vim.health.start("mdn.nvim")

  if require("mdn").did_setup then
    vim.health.ok("setup() was called")
  else
    vim.health.error("setup() was not called. Call require('mdn').setup({}) in your config.")
  end

  validate_opts_table()
end

return M
