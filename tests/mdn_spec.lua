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
-- Bullet/Checkbox Cycle Tests (buffer-based)
-- ============================================================
describe("bullet/checkbox cycle", function()
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

  describe("state 3: checkbox cycling", function()
    it("cycles [ ] to [~] (unchecked → in-progress)", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [ ] todo" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- [~] todo", line)
    end)

    it("cycles checked to a plain bullet", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [x] done" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- done", line)
    end)

    it("cycles uppercase X to a plain bullet", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [X] done" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- done", line)
    end)

    it("completes in-progress [~] to checked", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [~] in progress" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- [x] in progress", line)
    end)

    it("completes [>] migrated to checked", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [>] migrated" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- [x] migrated", line)
    end)

    it("completes [o] event to checked", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [o] event" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- [x] event", line)
    end)

    it("completes [<] scheduled to checked", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [<] scheduled" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.are.equal("- [x] scheduled", line)
    end)
  end)

  describe("full cycle", function()
    it("cycles blank → bullet → [ ] → [~] → [x] → bullet → [ ]", function()
      -- State 1: blank → bullet
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
      vim.fn.cursor(1, 1)
      Checkbox.cycle()
      assert.are.equal("- ", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])

      -- Add text to the bullet
      vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "- buy milk" })

      -- State 2: bullet → [ ]
      Checkbox.cycle()
      assert.are.equal("- [ ] buy milk", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])

      -- State 3: [ ] → [~]
      Checkbox.cycle()
      assert.are.equal("- [~] buy milk", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])

      -- State 4: [~] → [x]
      Checkbox.cycle()
      assert.are.equal("- [x] buy milk", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])

      -- State 5: [x] → plain bullet
      Checkbox.cycle()
      assert.are.equal("- buy milk", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])

      -- State 2 (again): plain bullet → [ ]
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

    it("checkbox cycle: cursor stays put", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [ ] todo" })
      vim.fn.cursor(1, 7) -- cursor on 't'
      Checkbox.cycle()
      assert.are.equal("- [~] todo", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
      assert.are.equal(7, vim.fn.col(".")) -- same column
    end)

    it("checked → plain bullet: cursor follows the item text", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [x] done" })
      vim.fn.cursor(1, 7) -- cursor on 'd'
      Checkbox.cycle()
      assert.are.equal("- done", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
      assert.are.equal(3, vim.fn.col("."))
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

  it("completes in-progress [~] to checked", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [~] wip" })
    vim.fn.cursor(1, 1)
    local result = Checkbox.toggle()
    assert.is_true(result)
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    assert.are.equal("- [x] wip", line)
  end)

  it("completes [>] migrated to checked", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [>] migrated" })
    vim.fn.cursor(1, 1)
    local result = Checkbox.toggle()
    assert.is_true(result)
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    assert.are.equal("- [x] migrated", line)
  end)

  it("completes [o] event to checked", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [o] event" })
    vim.fn.cursor(1, 1)
    local result = Checkbox.toggle()
    assert.is_true(result)
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    assert.are.equal("- [x] event", line)
  end)

  it("completes [<] scheduled to checked", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [<] scheduled" })
    vim.fn.cursor(1, 1)
    local result = Checkbox.toggle()
    assert.is_true(result)
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    assert.are.equal("- [x] scheduled", line)
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
-- Range Toggle Tests (toggle_range)
-- ============================================================
describe("range toggle", function()
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

  it("checks all when some are unchecked", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "- [ ] first",
      "- [x] second",
      "- [ ] third",
    })
    Checkbox.toggle_range(1, 3)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.equal("- [x] first", lines[1])
    assert.are.equal("- [x] second", lines[2])
    assert.are.equal("- [x] third", lines[3])
  end)

  it("unchecks all when all are checked", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "- [x] first",
      "- [x] second",
    })
    Checkbox.toggle_range(1, 2)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.equal("- [ ] first", lines[1])
    assert.are.equal("- [ ] second", lines[2])
  end)

  it("treats in-progress [~] as not checked", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "- [x] done",
      "- [~] wip",
    })
    Checkbox.toggle_range(1, 2)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.equal("- [x] done", lines[1])
    assert.are.equal("- [x] wip", lines[2])
  end)

  it("skips lines without checkboxes", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "- [ ] task",
      "- plain bullet",
      "# heading",
      "",
      "- [x] done",
    })
    Checkbox.toggle_range(1, 5)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.equal("- [x] task", lines[1])
    assert.are.equal("- plain bullet", lines[2])
    assert.are.equal("# heading", lines[3])
    assert.are.equal("", lines[4])
    assert.are.equal("- [x] done", lines[5])
  end)

  it("does nothing when no checkboxes in range", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "- plain",
      "some text",
    })
    Checkbox.toggle_range(1, 2)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.equal("- plain", lines[1])
    assert.are.equal("some text", lines[2])
  end)

  it("single-line range matches single-line toggle", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [ ] todo" })
    Checkbox.toggle_range(1, 1)
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    assert.are.equal("- [x] todo", line)
  end)

  it("handles partial range within buffer", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "- [x] before",
      "- [ ] first",
      "- [ ] second",
      "- [x] after",
    })
    Checkbox.toggle_range(2, 3)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.equal("- [x] before", lines[1])
    assert.are.equal("- [x] first", lines[2])
    assert.are.equal("- [x] second", lines[3])
    assert.are.equal("- [x] after", lines[4])
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

    it("O on empty list item: clears marker and inserts blank above", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- one", "- ", "- three" })
      vim.fn.cursor(2, 1)
      List.continue("O")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("- one", lines[1])
      assert.are.equal("", lines[2]) -- new blank line above cleared item
      assert.are.equal("", lines[3]) -- cleared item becomes blank
      assert.are.equal("- three", lines[4])
      assert.are.equal(2, vim.fn.line(".")) -- cursor on the new blank line
      assert.are.equal(1, vim.fn.col("."))
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

    it("splits list item at cursor on Enter in middle of text", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- hello world" })
      vim.fn.cursor(1, 7) -- cursor on 'o', after Enter: "- hell" / "- o world"
      List.continue("<CR>")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("- hell", lines[1])
      assert.are.equal("- o world", lines[2])
      assert.are.equal(2, vim.fn.line("."))
      assert.are.equal(3, vim.fn.col(".")) -- past "- "
    end)

    it("splits task list item at cursor on Enter in middle", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [ ] alpha beta" })
      vim.fn.cursor(1, 13) -- cursor on 'b' of "beta", so after Enter: "- [ ] alpha " / "- [ ] beta"
      List.continue("<CR>")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("- [ ] alpha ", lines[1])
      assert.are.equal("- [ ] beta", lines[2])
      assert.are.equal(2, vim.fn.line("."))
      assert.are.equal(7, vim.fn.col(".")) -- past "- [ ] "
    end)

    it("does not split when cursor is within the list prefix", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- [ ] item" })
      vim.fn.cursor(1, 3) -- cursor on space of "- ["
      List.continue("<CR>")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      -- Should create empty continuation, not split
      assert.are.equal("- [ ] item", lines[1])
      assert.are.equal("- [ ] ", lines[2])
      assert.are.equal(2, vim.fn.line("."))
    end)

    it("splits ordered list item at cursor on Enter in middle", function()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "1. hello world" })
      vim.fn.cursor(1, 8) -- cursor on 'o', after Enter: "1. hell" / "2. o world"
      List.continue("<CR>")
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("1. hell", lines[1])
      assert.are.equal("2. o world", lines[2])
      assert.are.equal(2, vim.fn.line("."))
      assert.are.equal(4, vim.fn.col(".")) -- past "2. "
    end)
  end)
end)
