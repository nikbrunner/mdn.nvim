---@module 'luassert'

local Patterns = require("mdn.patterns")
local List = require("mdn.list")
local Checkbox = require("mdn.checkbox")
local Indent = require("mdn.indent")

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
-- Three-State Cycle Tests (buffer-based)
-- ============================================================
describe("three-state cycle", function()
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

  describe("state 1: blank → bullet", function()
    it("creates bullet on blank line", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- ", line)
    end)

    it("creates bullet on whitespace-only line", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "   " })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- ", line)
    end)

    it("prepends bullet to non-list text line", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "some text" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- some text", line)
    end)

    it("cursor is positioned after '- '", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      assert.are.equal(2, vim.fn.col("."))
    end)
  end)

  describe("state 2: bullet → checkbox", function()
    it("adds checkbox to unordered list item", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- plain item" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- [ ] plain item", line)
    end)

    it("adds checkbox to ordered list item", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "1. task" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("1. [ ] task", line)
    end)

    it("adds checkbox to star marker", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "* item" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("* [ ] item", line)
    end)
  end)

  describe("state 3: checkbox toggle", function()
    it("toggles unchecked to checked", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [ ] todo" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- [x] todo", line)
    end)

    it("toggles checked to unchecked", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [x] done" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- [ ] done", line)
    end)

    it("toggles uppercase X to unchecked", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [X] done" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- [ ] done", line)
    end)
  end)

  describe("full three-state cycle", function()
    it("cycles blank → bullet → checkbox → checked", function()
      -- State 1: blank → bullet
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      assert.are.equal("- ", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])

      -- Add text to the bullet
      vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "- buy milk" })

      -- State 2: bullet → checkbox
      Checkbox.cycle()
      assert.are.equal("- [ ] buy milk", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])

      -- State 3: checkbox toggle (unchecked → checked)
      Checkbox.cycle()
      assert.are.equal("- [x] buy milk", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])

      -- State 3 (again): toggle back
      Checkbox.cycle()
      assert.are.equal("- [ ] buy milk", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
    end)
  end)
end)

-- ============================================================
-- Cursor Position Tests
-- ============================================================
describe("cursor position", function()
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

  describe("cycle cursor positions", function()
    it("blank → bullet: col past '- '", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      assert.is_true(vim.fn.col(".") >= 2)
    end)

    it("non-list text → bullet: col past '- '", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      assert.is_true(vim.fn.col(".") >= 2)
    end)

    it("bullet → checkbox: cursor shifts right by 4", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- buy milk" })
      vim.fn.cursor(1, 4) -- cursor on 'b'
      Checkbox.cycle()
      assert.are.equal("- [ ] buy milk", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
      assert.are.equal(8, vim.fn.col(".")) -- still on 'b', shifted by 4
    end)

    it("checkbox toggle: cursor stays put", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [ ] todo" })
      vim.fn.cursor(1, 7) -- cursor on 't'
      Checkbox.cycle()
      assert.are.equal("- [x] todo", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
      assert.are.equal(7, vim.fn.col(".")) -- same column
    end)

    it("check→uncheck: cursor stays put", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [x] done" })
      vim.fn.cursor(1, 7) -- cursor on 'd'
      Checkbox.cycle()
      assert.are.equal("- [ ] done", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
      assert.are.equal(7, vim.fn.col("."))
    end)
  end)

  describe("toggle command cursor positions", function()
    it("checkbox toggle: cursor stays put", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [ ] todo" })
      vim.fn.cursor(1, 7)
      Checkbox.toggle()
      assert.are.equal(7, vim.fn.col("."))
    end)

    it("add checkbox: cursor shifts right by 4", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- plain" })
      vim.fn.cursor(1, 4) -- cursor on 'p'
      Checkbox.toggle()
      assert.are.equal(8, vim.fn.col(".")) -- still on 'p', shifted by 4
    end)
  end)

  describe("continuation cursor positions", function()
    it("o below: cursor on new line after prefix", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- first" })
      vim.fn.cursor(1, 1)
      List.continue("o")
      -- cursor on line 2, col >= 2 (past "- ")
      assert.are.equal(2, vim.fn.line("."))
      assert.is_true(vim.fn.col(".") >= 2)
    end)

    it("o below ordered: cursor on new line after prefix", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "1. first" })
      vim.fn.cursor(1, 1)
      List.continue("o")
      -- cursor on line 2, col >= 3 (past "2. ")
      assert.are.equal(2, vim.fn.line("."))
      assert.is_true(vim.fn.col(".") >= 3)
    end)

    it("o on empty list: clears the line, cursor at col 1", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- " })
      vim.fn.cursor(1, 1)
      List.continue("o")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("", lines[1])
      assert.are.equal(1, vim.fn.line("."))
      assert.are.equal(1, vim.fn.col("."))
    end)

    it("O above: cursor on line 1 after prefix", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- first" })
      vim.fn.cursor(1, 1)
      List.continue("O")
      -- cursor stays on line 1, col >= 2 (past "- ")
      assert.are.equal(1, vim.fn.line("."))
      assert.is_true(vim.fn.col(".") >= 2)
    end)

    it("O above ordered: cursor after prefix", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "5. item" })
      vim.fn.cursor(1, 1)
      List.continue("O")
      -- cursor on line 1, col >= 3 (past "4. ")
      assert.are.equal(1, vim.fn.line("."))
      assert.is_true(vim.fn.col(".") >= 3)
    end)

    it("O above on line 1: cursor after prefix", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "1. item" })
      vim.fn.cursor(1, 1)
      List.continue("O")
      -- prefix is "1. ", cursor past it
      assert.are.equal(1, vim.fn.line("."))
      assert.is_true(vim.fn.col(".") >= 3)
    end)

    it("CR mid-line: splits line, cursor on new line col 1", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "plain text" })
      vim.fn.cursor(1, 7)
      List.continue("<CR>")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("plain ", lines[1])
      assert.are.equal("text", lines[2])
      assert.are.equal(1, vim.fn.col("."))
      assert.are.equal(2, vim.fn.line("."))
    end)

    it("CR on empty line: new blank line, col 1", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
      vim.fn.cursor(1, 1)
      List.continue("<CR>")
      assert.are.equal(1, vim.fn.col("."))
      assert.are.equal(2, vim.fn.line("."))
    end)

    it("CR on list item: cursor on new line after prefix", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- item" })
      vim.fn.cursor(1, 1)
      List.continue("<CR>")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("- item", lines[1])
      assert.are.equal("- ", lines[2])
      assert.are.equal(2, vim.fn.line("."))
      assert.is_true(vim.fn.col(".") >= 2)
    end)

    it("CR on empty list item: clears the line, cursor at col 1", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- " })
      vim.fn.cursor(1, 1)
      List.continue("<CR>")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("", lines[1])
      assert.are.equal(1, vim.fn.col("."))
      assert.are.equal(1, vim.fn.line("."))
    end)
  end)
end)

-- ============================================================
-- Toggle Command Tests (toggle() only, no bullet creation)
-- ============================================================
describe("toggle command", function()
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
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    assert.are.equal("plain text", line)
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
      -- Should clear the empty list item, not insert continuation
      assert.are.equal("", lines[1])
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
      assert.are.equal("", lines[1])
    end)
  end)
end)

-- ============================================================
-- Indent / Outdent Tests
-- ============================================================
describe("indent / outdent", function()
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

  describe("indent", function()
    it("adds shiftwidth spaces at start of line", function()
      vim.bo.shiftwidth = 2
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "text" })
      vim.fn.cursor(1, 1)
      Indent.indent()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("  text", line)
    end)

    it("preserves cursor column", function()
      vim.bo.shiftwidth = 2
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello" })
      vim.fn.cursor(1, 3) -- cursor on 'l'
      Indent.indent()
      assert.are.equal(5, vim.fn.col(".")) -- shifted right by 2
    end)

    it("works on blank line", function()
      vim.bo.shiftwidth = 2
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
      vim.fn.cursor(1, 1)
      Indent.indent()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("  ", line)
    end)

    it("works on list items", function()
      vim.bo.shiftwidth = 2
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- item" })
      vim.fn.cursor(1, 1)
      Indent.indent()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("  - item", line)
    end)

    it("respects different shiftwidth values", function()
      vim.bo.shiftwidth = 4
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "text" })
      vim.fn.cursor(1, 1)
      Indent.indent()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("    text", line)
    end)
  end)

  describe("outdent", function()
    it("removes shiftwidth leading spaces", function()
      vim.bo.shiftwidth = 2
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "  text" })
      vim.fn.cursor(1, 5)
      Indent.outdent()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("text", line)
    end)

    it("removes only leading spaces, not other chars", function()
      vim.bo.shiftwidth = 2
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "  - item" })
      vim.fn.cursor(1, 5)
      Indent.outdent()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- item", line)
    end)

    it("does nothing on line with no leading spaces", function()
      vim.bo.shiftwidth = 2
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "text" })
      vim.fn.cursor(1, 3)
      Indent.outdent()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("text", line)
    end)

    it("preserves cursor column", function()
      vim.bo.shiftwidth = 2
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "  hello" })
      vim.fn.cursor(1, 5) -- cursor on 'l'
      Indent.outdent()
      assert.are.equal(3, vim.fn.col(".")) -- shifted left by 2
    end)

    it("does not move cursor below col 1", function()
      vim.bo.shiftwidth = 4
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "    text" })
      vim.fn.cursor(1, 2) -- cursor within removed area
      Indent.outdent()
      assert.are.equal(1, vim.fn.col("."))
    end)

    it("removes fewer spaces if less than shiftwidth", function()
      vim.bo.shiftwidth = 4
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "  text" })
      vim.fn.cursor(1, 4)
      Indent.outdent()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("text", line)
    end)

    it("works on blank line with spaces", function()
      vim.bo.shiftwidth = 2
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "    " })
      vim.fn.cursor(1, 3)
      Indent.outdent()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("  ", line)
    end)
  end)
end)
