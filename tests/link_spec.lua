---@module 'luassert'

local Link = require("mdn.link")

describe("link.at", function()
  local line = "See [docs](https://example.com/a) and https://neovim.io/doc."

  it("returns the full Markdown link from the label", function()
    assert.are.equal("[docs](https://example.com/a)", Link.at(line, 5))
  end)

  it("returns the full Markdown link from the destination", function()
    assert.are.equal("[docs](https://example.com/a)", Link.at(line, 20))
  end)

  it("returns the bare URL without trailing punctuation", function()
    assert.are.equal("https://neovim.io/doc", Link.at(line, 45))
  end)

  it("returns nil on trailing punctuation after a bare URL", function()
    assert.is_nil(Link.at(line, #line - 1))
  end)

  it("returns nil outside links", function()
    assert.is_nil(Link.at(line, 0))
  end)

  it("includes the image marker", function()
    assert.are.equal("![alt](img.png)", Link.at("x ![alt](img.png)", 2))
  end)

  it("skips a checkbox before a Markdown link", function()
    assert.are.equal("[a](b)", Link.at("- [ ] [a](b)", 7))
    assert.is_nil(Link.at("- [ ] [a](b)", 3))
  end)

  it("returns the URL inside an autolink", function()
    assert.are.equal("https://x.dev", Link.at("<https://x.dev>", 3))
  end)

  it("keeps balanced parentheses in bare URLs", function()
    local url = "https://en.wikipedia.org/wiki/Lua_(programming_language)"
    assert.are.equal(url, Link.at("(" .. url .. ")", 5))
    assert.are.equal("https://x.dev", Link.at("(https://x.dev)", 5))
  end)
end)

describe("link.yank", function()
  local buf

  before_each(function()
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "a [b](c) https://d.dev" })
    vim.fn.setreg('"', "")
  end)

  after_each(function()
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end)

  it("yanks a Markdown link", function()
    vim.api.nvim_win_set_cursor(0, { 1, 3 })
    Link.yank()
    assert.are.equal("[b](c)", vim.fn.getreg('"'))
  end)

  it("yanks a bare URL", function()
    vim.api.nvim_win_set_cursor(0, { 1, 12 })
    Link.yank()
    assert.are.equal("https://d.dev", vim.fn.getreg('"'))
  end)

  it("falls back to native yl outside links", function()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    Link.yank()
    assert.are.equal("a", vim.fn.getreg('"'))
  end)
end)
