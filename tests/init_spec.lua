---@module 'luassert'

local Config = require("mdn.config")

describe("automatic initialization", function()
  local original_config
  local original_mdn

  before_each(function()
    original_config = vim.g.mdn_config
    original_mdn = package.loaded["mdn"]
    vim.g.mdn_config = { lists = { bullet_marker = "*" } }
    vim.api.nvim_clear_autocmds({ group = Config.augroup })
    package.loaded["mdn"] = nil
    if vim.fn.exists(":Mdn") == 2 then
      vim.api.nvim_del_user_command("Mdn")
    end
  end)

  after_each(function()
    vim.api.nvim_clear_autocmds({ group = Config.augroup })
    package.loaded["mdn"] = original_mdn
    vim.g.mdn_config = original_config
    Config.setup(original_config)
    if vim.fn.exists(":Mdn") == 2 then
      vim.api.nvim_del_user_command("Mdn")
    end
  end)

  it("loads global config from the plugin entrypoint", function()
    vim.cmd("runtime plugin/mdn.lua")
    local autocmd_count = #vim.api.nvim_get_autocmds({ group = Config.augroup, event = "BufEnter" })

    assert.is_not_nil(package.loaded["mdn"])
    assert.is_true(vim.fn.exists(":Mdn") == 2)
    assert.are.equal("*", Config.lists.bullet_marker)
    assert.is_true(autocmd_count > 0)
  end)
end)
