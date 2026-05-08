---@module 'mdn.health'

local M = {}

---Health check called by `:checkhealth mdn`
function M.check()
  vim.health.start("mdn.nvim")

  local ok, mdn = pcall(require, "mdn")
  if not ok then
    vim.health.error("Failed to load mdn.nvim: " .. tostring(mdn))
    return
  end

  if mdn.did_setup then
    vim.health.ok("setup() was called")
  else
    vim.health.error("setup() was not called — add require('mdn').setup() to your config")
  end

  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.error("Neovim >= 0.10 is required")
  end

  local Config = require("mdn.config")
  if Config.auto_continue then
    vim.health.ok("auto_continue is enabled")
  else
    vim.health.warn("auto_continue is disabled — list continuation won't work")
  end
end

return M
