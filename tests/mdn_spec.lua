---@module 'luassert'

local Patterns = require("mdn.patterns")
local List = require("mdn.list")
local Checkbox = require("mdn.checkbox")

-- ============================================================
-- Pattern Tests
-- ============================================================
describe("patterns", function()
  describe("unordered_list", function()
    it("matches dash marker", function()
      local indent, marker, text = ("- item"):match(Patterns.unordered_list)
      assert.are.equal("", indent)
      assert.are.equal("-", marker)
      assert.are.equal("item", text)
    end)

    it("matches star marker", function()
      local indent, marker, text = ("* item"):match(Patterns.unordered_list)
      assert.are.equal("", indent)
      assert.are.equal("*", marker)
      assert.are.equal("item", text)
    end)

    it("matches plus marker", function()
      local indent, marker, text = ("+ item"):match(Patterns.unordered_list)
      assert.are.equal("", indent)
      assert.are.equal("+", marker)
      assert.are.equal("item", text)
    end)

    it("captures indentation", function()
      local indent, marker, text = ("    - item"):match(Patterns.unordered_list)
      assert.are.equal("    ", indent)
      assert.are.equal("-", marker)
      assert.are.equal("item", text)
    end)

    it("captures empty text", function()
      local indent, marker, text = ("- "):match(Patterns.unordered_list)
      assert.are.equal("", indent)
      assert.are.equal("-", marker)
      assert.are.equal("", text)
    end)

    it("does not match without space after marker", function()
      local result = { ("-item"):match(Patterns.unordered_list) }
      -- No match means first capture is nil
      assert.is_nil(result[1])
    end)

    it("does not match non-list lines", function()
      local result = { ("plain text"):match(Patterns.unordered_list) }
      assert.is_nil(result[1])
    end)
  end)

  describe("ordered_list", function()
    it("matches dot separator", function()
      local indent, num, sep, text = ("1. item"):match(Patterns.ordered_list)
      assert.are.equal("", indent)
      assert.are.equal("1", num)
      assert.are.equal(".", sep)
      assert.are.equal("item", text)
    end)

    it("matches paren separator", function()
      local indent, num, sep, text = ("2) item"):match(Patterns.ordered_list)
      assert.are.equal("", indent)
      assert.are.equal("2", num)
      assert.are.equal(")", sep)
      assert.are.equal("item", text)
    end)

    it("captures multi-digit numbers", function()
      local indent, num, sep, text = ("42. item"):match(Patterns.ordered_list)
      assert.are.equal("42", num)
    end)

    it("captures indentation", function()
      local indent, num, sep, text = ("  3. item"):match(Patterns.ordered_list)
      assert.are.equal("  ", indent)
      assert.are.equal("3", num)
    end)

    it("does not match unordered list", function()
      local result = { ("- item"):match(Patterns.ordered_list) }
      assert.is_nil(result[1])
    end)
  end)

  describe("task", function()
    it("matches unchecked checkbox", function()
      local cb = ("- [ ] todo"):match(Patterns.task)
      assert.are.equal("[ ]", cb)
    end)

    it("matches checked checkbox lowercase", function()
      local cb = ("- [x] done"):match(Patterns.task)
      assert.are.equal("[x]", cb)
    end)

    it("matches checked checkbox uppercase", function()
      local cb = ("- [X] done"):match(Patterns.task)
      assert.are.equal("[X]", cb)
    end)
  end)
end)

-- ============================================================
-- List Resolver Tests
-- ============================================================
describe("list resolver", function()
  describe("resolve_list_content", function()
    it("resolves unordered list item", function()
      local result = List.resolve_list_content("- item")
      assert.is_not_nil(result)
      assert.are.equal("", result.indent)
      assert.are.equal("-", result.marker)
      assert.are.equal("", result.separator)
      assert.are.equal("item", result.text)
      assert.are.equal("unordered", result.type)
    end)

    it("resolves ordered list item", function()
      local result = List.resolve_list_content("1. item")
      assert.is_not_nil(result)
      assert.are.equal("", result.indent)
      assert.are.equal("1", result.marker)
      assert.are.equal(".", result.separator)
      assert.are.equal("item", result.text)
      assert.are.equal("ordered", result.type)
    end)

    it("resolves ordered list with parens", function()
      local result = List.resolve_list_content("3) item")
      assert.are.equal("ordered", result.type)
      assert.are.equal(")", result.separator)
    end)

    it("resolves indented list item", function()
      local result = List.resolve_list_content("    - nested")
      assert.are.equal("    ", result.indent)
      assert.are.equal("nested", result.text)
    end)

    it("returns nil for non-list line", function()
      local result = List.resolve_list_content("plain text")
      assert.is_nil(result)
    end)

    it("returns nil for heading", function()
      local result = List.resolve_list_content("# Heading")
      assert.is_nil(result)
    end)

    it("returns nil for empty string", function()
      local result = List.resolve_list_content("")
      assert.is_nil(result)
    end)
  end)

  describe("get_task_state", function()
    it("detects unchecked", function()
      assert.are.equal("unchecked", List.get_task_state("[ ] todo"))
    end)

    it("detects checked lowercase", function()
      assert.are.equal("checked", List.get_task_state("[x] done"))
    end)

    it("detects checked uppercase", function()
      assert.are.equal("checked", List.get_task_state("[X] done"))
    end)

    it("returns nil for no checkbox", function()
      assert.is_nil(List.get_task_state("plain text"))
    end)

    it("returns nil when checkbox is not at start of text", function()
      -- Checkbox is only detected at start of text portion
      -- (this matches real-world usage where checkbox comes right after marker)
      assert.is_nil(List.get_task_state("text [ ] later"))
    end)
  end)

  describe("get_continuation_prefix", function()
    it("continues unordered list with same marker", function()
      local lc = List.resolve_list_content("- item")
      assert.are.equal("- ", List.get_continuation_prefix(lc))
    end)

    it("continues ordered list with incremented number", function()
      local lc = List.resolve_list_content("1. item")
      assert.are.equal("2. ", List.get_continuation_prefix(lc))
    end)

    it("continues ordered list from 5 to 6", function()
      local lc = List.resolve_list_content("5. item")
      assert.are.equal("6. ", List.get_continuation_prefix(lc))
    end)

    it("preserves indentation", function()
      local lc = List.resolve_list_content("    - nested")
      assert.are.equal("    - ", List.get_continuation_prefix(lc))
    end)

    it("continues task list with empty checkbox", function()
      local lc = List.resolve_list_content("- [x] done")
      assert.are.equal("- [ ] ", List.get_continuation_prefix(lc))
    end)

    it("terminates for empty list item", function()
      local lc = List.resolve_list_content("- ")
      assert.is_nil(List.get_continuation_prefix(lc))
    end)

    it("terminates for empty task item", function()
      local lc = List.resolve_list_content("- [ ] ")
      assert.is_nil(List.get_continuation_prefix(lc))
    end)
  end)
end)

-- ============================================================
-- Checkbox Toggle Tests (buffer-based)
-- ============================================================
describe("checkbox toggle", function()
  local buf

  before_each(function()
    buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
  end)

  after_each(function()
    if buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end)

  it("toggles unchecked to checked", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [ ] todo" })
    vim.fn.cursor(1, 1)
    local result = Checkbox.toggle()
    assert.is_true(result)
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    assert.are.equal("- [x] todo", line)
  end)

  it("toggles checked to unchecked", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [x] done" })
    vim.fn.cursor(1, 1)
    Checkbox.toggle()
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    assert.are.equal("- [ ] done", line)
  end)

  it("adds checkbox to list item without one", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- plain item" })
    vim.fn.cursor(1, 1)
    Checkbox.toggle()
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    assert.are.equal("- [ ] plain item", line)
  end)

  it("returns false for non-list line", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "plain text" })
    vim.fn.cursor(1, 1)
    local result = Checkbox.toggle()
    assert.is_false(result)
    -- Line should be unchanged
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    assert.are.equal("plain text", line)
  end)

  it("toggles checkbox on ordered list item", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "1. [ ] task" })
    vim.fn.cursor(1, 1)
    Checkbox.toggle()
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    assert.are.equal("1. [x] task", line)
  end)
end)

-- ============================================================
-- List Continuation Tests (buffer-based)
-- ============================================================
describe("list continuation", function()
  local buf

  before_each(function()
    buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
  end)

  after_each(function()
    if buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end)

  describe("continue below (o)", function()
    it("inserts next unordered list item", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- first" })
      vim.fn.cursor(1, 1)
      List.continue("o")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("- first", lines[1])
      assert.are.equal("- ", lines[2])
    end)

    it("inserts next ordered list item with incremented number", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "1. first" })
      vim.fn.cursor(1, 1)
      List.continue("o")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("2. ", lines[2])
    end)

    it("terminates for empty list item", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- " })
      vim.fn.cursor(1, 1)
      List.continue("o")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      -- Should insert empty line, not a list continuation
      assert.are.equal("", lines[2])
    end)

    it("continues task list with empty checkbox", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [x] done" })
      vim.fn.cursor(1, 1)
      List.continue("o")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("- [ ] ", lines[2])
    end)
  end)

  describe("continue above (O)", function()
    it("inserts list item above with same marker for unordered", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- first" })
      vim.fn.cursor(1, 1)
      List.continue("O")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("- ", lines[1])
      assert.are.equal("- first", lines[2])
    end)

    it("inserts list item above with decremented number for ordered", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "5. item" })
      vim.fn.cursor(1, 1)
      List.continue("O")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("4. ", lines[1])
    end)

    it("does not go below 1 for ordered lists", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "1. item" })
      vim.fn.cursor(1, 1)
      List.continue("O")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("1. ", lines[1])
    end)
  end)

  describe("continue enter (<CR>)", function()
    it("does not insert a stray 'a' character", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- first" })
      vim.fn.cursor(1, 1)
      List.continue("<CR>")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("- first", lines[1])
      assert.are.equal("- ", lines[2])
    end)

    it("continues unordered list", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- item" })
      vim.fn.cursor(1, 1)
      List.continue("<CR>")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("- ", lines[2])
    end)

    it("terminates for empty list item", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- " })
      vim.fn.cursor(1, 1)
      List.continue("<CR>")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("", lines[2])
    end)
  end)
end)
