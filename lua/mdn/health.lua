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

  if Config.cycle_key ~= "" then
    vim.health.ok(("cycle key is set to '%s'"):format(Config.cycle_key))
  else
    vim.health.warn("cycle_key is empty — three-state cycle is disabled")
  end

  if Config.bullet_marker then
    vim.health.ok(("bullet marker is '%s'"):format(Config.bullet_marker))
  end

  if Config.indent_key ~= "" then
    vim.health.ok(("indent key is set to '%s'"):format(Config.indent_key))
  else
    vim.health.warn("indent_key is empty — indent is disabled")
  end

  if Config.outdent_key ~= "" then
    vim.health.ok(("outdent key is set to '%s'"):format(Config.outdent_key))
  else
    vim.health.warn("outdent_key is empty — outdent is disabled")
  end
end

return M
