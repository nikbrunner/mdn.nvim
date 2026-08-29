---@module 'mdn.health'

local M = {}

---Health check called by `:checkhealth mdn`
function M.check()
  vim.health.start("mdn.nvim")

  local ok, err = pcall(require, "mdn")
  if not ok then
    vim.health.error("Failed to load mdn.nvim: " .. tostring(err))
    return
  end

  vim.health.ok("plugin is loaded")

  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.error("Neovim >= 0.10 is required")
  end

  local Config = require("mdn.config")
  if Config.lists.auto_continue then
    vim.health.ok("auto_continue is enabled")
  else
    vim.health.warn("auto_continue is disabled — list continuation won't work")
  end

  if Config.mappings.cycle_key ~= "" then
    vim.health.ok(("cycle key is set to '%s'"):format(Config.mappings.cycle_key))
  else
    vim.health.warn("cycle_key is empty — bullet/checkbox cycle is disabled")
  end

  if Config.lists.bullet_marker then
    vim.health.ok(("bullet marker is '%s'"):format(Config.lists.bullet_marker))
  end
end

return M
