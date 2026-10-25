---@module 'luassert'

local Config = require("mdn.config")
local Table = require("mdn.table")

describe("table fit", function()
  local buf

  local function lines()
    return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  end

  local function set(text)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)
  end

  before_each(function()
    buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    require("mdn")
  end)

  after_each(function()
    Config.setup()
    if buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end)

  describe("fit", function()
    it("pads cells to the widest cell of each column", function()
      set({ "| a | long header |", "|---|---|", "| longer cell | b |" })
      assert.is_true(Table.fit(buf, 0))
      assert.are.same({
        "| a           | long header |",
        "| ----------- | ----------- |",
        "| longer cell | b           |",
      }, lines())
    end)

    it("reports no change on a fitted table", function()
      set({ "| a   | b   |", "| --- | --- |", "| c   | d   |" })
      assert.is_false(Table.fit(buf, 2))
    end)

    it("keeps alignment colons", function()
      set({ "| left | right | center |", "|:-|-:|:-:|", "| a | b | c |" })
      Table.fit(buf, 0)
      assert.are.same({
        "| left | right | center |",
        "| :--- | ----: | :----: |",
        "| a    | b     | c      |",
      }, lines())
    end)

    it("measures umlauts and icons by display width", function()
      set({ "| name | x |", "|---|---|", "| Müller | 󰄲 |", "| 漢字 | y |" })
      Table.fit(buf, 0)
      assert.are.same({
        "| name   | x   |",
        "| ------ | --- |",
        "| Müller | 󰄲   |",
        "| 漢字   | y   |",
      }, lines())
    end)

    it("keeps escaped pipes inside a cell", function()
      set({ "| a | b |", "|---|---|", "| x \\| y | z |" })
      Table.fit(buf, 0)
      assert.are.same({ "| a      | b   |", "| ------ | --- |", "| x \\| y | z   |" }, lines())
    end)

    it("keeps an empty cell", function()
      set({ "| a | b | c |", "|---|---|---|", "| 1 || 3 |" })
      Table.fit(buf, 0)
      assert.are.equal("| 1   |     | 3   |", lines()[3])
    end)

    it("pads a short row with empty cells", function()
      set({ "| a | b |", "|---|---|", "| 1 |" })
      Table.fit(buf, 0)
      assert.are.equal("| 1   |     |", lines()[3])
    end)

    it("keeps extra cells", function()
      set({ "| a | b |", "|---|---|", "| 1 | 2 | extra |" })
      Table.fit(buf, 0)
      assert.are.equal("| 1   | 2   | extra |", lines()[3])
    end)

    it("reads rows without outer pipes", function()
      set({ "a | b", "--|--", "1 | 2" })
      Table.fit(buf, 2)
      assert.are.same({ "| a   | b   |", "| --- | --- |", "| 1   | 2   |" }, lines())
    end)

    it("keeps the blockquote prefix", function()
      set({ "> | a | b |", "> |---|---|", "> | long | c |" })
      Table.fit(buf, 2)
      assert.are.same({ "> | a    | b   |", "> | ---- | --- |", "> | long | c   |" }, lines())
    end)

    it("keeps the indent of a table inside a list item", function()
      set({ "- item", "", "  | a | b |", "  |---|---|", "  | long | c |" })
      Table.fit(buf, 4)
      assert.are.same({ "  | a    | b   |", "  | ---- | --- |", "  | long | c   |" }, { unpack(lines(), 3) })
    end)

    it("leaves a table inside a fence alone", function()
      local text = { "```", "| a | b |", "|---|---|", "| long | c |", "```" }
      set(text)
      assert.is_false(Table.fit(buf, 1))
      assert.are.same(text, lines())
    end)

    it("leaves an incomplete table alone", function()
      set({ "| a | b |", "|---|" })
      assert.is_false(Table.fit(buf, 0))
    end)

    it("keeps the cursor in its cell", function()
      set({ "| a | b |", "|---|---|", "| long | xy |" })
      vim.api.nvim_win_set_cursor(0, { 1, 6 })
      Table.fit(buf, 0)
      assert.are.equal("| a    | b   |", lines()[1])
      assert.are.same({ 1, 9 }, vim.api.nvim_win_get_cursor(0))
    end)
  end)

  describe("automatic", function()
    local function sync_undo()
      vim.cmd("let &undolevels = &undolevels")
    end

    before_each(function()
      require("mdn.autofix").setup()
      vim.bo[buf].filetype = "markdown"
    end)

    it("fits after a Normal-mode edit and undoes in one step", function()
      set({ "| a   | b   |", "| --- | --- |", "| c   | d   |" })
      sync_undo()
      vim.api.nvim_win_set_cursor(0, { 3, 2 })
      vim.cmd("normal! ilonger ")
      sync_undo()
      vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
      assert.are.equal("| longer c | d   |", lines()[3])
      vim.cmd("undo")
      assert.are.same({ "| a   | b   |", "| --- | --- |", "| c   | d   |" }, lines())
    end)

    it("redraws the table lines after fitting", function()
      set({ "| a | b |", "|---|---|", "| long | d |" })
      require("mdn.render").render(buf)
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
      local line = lines()[3]
      local marks = vim.api.nvim_buf_get_extmarks(buf, Config.render_ns, { 2, 0 }, { 2, -1 }, {})
      assert.is_true(#marks > 0)
      for _, mark in ipairs(marks) do
        assert.are.equal("|", line:sub(mark[3] + 1, mark[3] + 1))
      end
    end)

    it("stays off when auto_fit is false", function()
      Config.setup({ tables = { auto_fit = false } })
      local text = { "| a | b |", "|---|---|", "| long | c |" }
      set(text)
      vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
      assert.are.same(text, lines())
    end)
  end)
end)
