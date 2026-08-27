---@module 'luassert'

local Conceal = require("mdn.conceal")
local Config = require("mdn.config")

describe("conceal rendering", function()
  local buf

  before_each(function()
    buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
  end)

  after_each(function()
    Config.setup()
    if buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end)

  it("provides defaults for every list and checkbox state", function()
    assert.are.same({
      listitem = { pattern = "[-+*]%s", replace = " " },
      unchecked = { pattern = "%[%s%]%s", replace = "󰄱 " },
      checked = { pattern = "%[[xX]%]%s", replace = "󰄲 " },
      partial = { pattern = "%[~%]%s", replace = "󰡖 " },
      defer = { pattern = "%[>%]%s", replace = "󰁔 " },
      scheduled = { pattern = "%[<%]%s", replace = "󰃰 " },
      event = { pattern = "%[o%]%s", replace = "󰃭 " },
      canceled = { pattern = "%[%-]%s", replace = "󱋭 " },
    }, Config.conceal)
  end)

  it("renders list and checkbox tokens as concealed virtual text", function()
    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "- [ ] unchecked",
      "- [x] checked",
      "- [~] partial",
      "- [>] defer",
      "- [<] scheduled",
      "- [o] event",
      "- [-] canceled",
      "- plain list item",
      "not a list",
    })
    vim.api.nvim_win_set_cursor(0, { 9, 0 })
    Conceal.render(buf)

    local marks = vim.api.nvim_buf_get_extmarks(buf, Config.conceal_ns, 0, -1, { details = true })
    assert.are.equal(8, #marks)

    local expected = {
      Config.conceal.unchecked.replace,
      Config.conceal.checked.replace,
      Config.conceal.partial.replace,
      Config.conceal.defer.replace,
      Config.conceal.scheduled.replace,
      Config.conceal.event.replace,
      Config.conceal.canceled.replace,
      Config.conceal.listitem.replace,
    }
    for index, mark in ipairs(marks) do
      assert.are.equal("", mark[4].conceal)
      assert.are.same({ { expected[index], "Conceal" } }, mark[4].virt_text)
      assert.are.equal("inline", mark[4].virt_text_pos)
    end
  end)

  it("uses configured symbols", function()
    Config.setup({
      conceal = {
        listitem = { pattern = "%*%s", replace = "L " },
        unchecked = { pattern = "%[%s%]%s", replace = "U " },
      },
    })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "* item", "* [ ] item", "not a list" })
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    Conceal.render(buf)

    local marks = vim.api.nvim_buf_get_extmarks(buf, Config.conceal_ns, 0, -1, { details = true })
    assert.are.equal(2, #marks)
    assert.are.same({ { "L ", "Conceal" } }, marks[1][4].virt_text)
    assert.are.same({ { "U ", "Conceal" } }, marks[2][4].virt_text)
  end)

  it("hides virtual signs on the cursor line", function()
    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "- [ ] current",
      "- [x] other",
    })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    Conceal.render(buf)

    local marks = vim.api.nvim_buf_get_extmarks(buf, Config.conceal_ns, 0, -1, { details = true })
    assert.are.equal(1, #marks)
    assert.are.equal(1, marks[1][2])
  end)
end)
