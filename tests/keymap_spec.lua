---@module 'luassert'

describe("Markdown buffer keymaps", function()
  local buf

  before_each(function()
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.cmd("runtime! after/ftplugin/markdown.lua")
  end)

  after_each(function()
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end)

  it("restores the Insert cycle map after another plugin replaces it on InsertEnter", function()
    vim.keymap.set("i", "<C-k>", "<Nop>", { buffer = buf, desc = "blink.cmp: show_signature" })

    vim.api.nvim_exec_autocmds("InsertEnter", { buffer = buf })
    vim.wait(100, function()
      return vim.fn.maparg("<C-k>", "i", false, true).desc == "Mdn: Cycle bullet/checkbox"
    end)

    assert.are.equal("Mdn: Cycle bullet/checkbox", vim.fn.maparg("<C-k>", "i", false, true).desc)
  end)

  it("registers a single InsertEnter handler when the ftplugin is sourced again", function()
    vim.cmd("runtime! after/ftplugin/markdown.lua")

    assert.are.equal(1, #vim.api.nvim_get_autocmds({ event = "InsertEnter", buffer = buf }))
  end)
end)
