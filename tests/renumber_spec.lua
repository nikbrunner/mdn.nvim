---@module 'luassert'

local Config = require("mdn.config")
local List = require("mdn.list")

describe("ordered list renumbering", function()
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

  describe("renumber", function()
    it("numbers a list from 1", function()
      set({ "3. a", "3. b", "7. c" })
      assert.is_true(List.renumber(buf, 1))
      assert.are.same({ "1. a", "2. b", "3. c" }, lines())
    end)

    it("reports no change on a numbered list", function()
      set({ "1. a", "2. b" })
      assert.is_false(List.renumber(buf, 0))
    end)

    it("keeps the parenthesis separator", function()
      set({ "1) a", "1) b" })
      List.renumber(buf, 0)
      assert.are.same({ "1) a", "2) b" }, lines())
    end)

    it("counts a nested list on its own and fixes its parent", function()
      set({ "1. a", "1. b", "   5. x", "   5. y", "1. c" })
      List.renumber(buf, 2)
      assert.are.same({ "1. a", "2. b", "   1. x", "   2. y", "3. c" }, lines())
    end)

    it("keeps a nested list nested when a marker grows a digit", function()
      local text = {}
      for i = 1, 9 do
        table.insert(text, i .. ". item")
      end
      table.insert(text, 1, "1. new")
      table.insert(text, "   1. child")
      set(text)
      List.renumber(buf, 0)
      local result = lines()
      assert.are.equal("10. item", result[10])
      assert.are.equal("    1. child", result[11])
    end)

    it("removes the extra indent when a marker loses a digit", function()
      local text = {}
      for i = 1, 11 do
        table.insert(text, i .. ". item")
      end
      table.insert(text, "    1. child")
      table.remove(text, 1)
      set(text)
      List.renumber(buf, 0)
      local result = lines()
      assert.are.equal("9. item", result[9])
      assert.are.equal("10. item", result[10])
      assert.are.equal("    1. child", result[11])
    end)

    it("leaves unordered lists alone", function()
      set({ "- a", "- b" })
      assert.is_false(List.renumber(buf, 0))
    end)

    it("leaves a list inside a fence alone", function()
      set({ "```", "3. a", "3. b", "```" })
      assert.is_false(List.renumber(buf, 1))
      assert.are.same({ "```", "3. a", "3. b", "```" }, lines())
    end)

    it("works on a list inside a blockquote", function()
      set({ "> 1. a", "> 1. b" })
      List.renumber(buf, 1)
      assert.are.same({ "> 1. a", "> 2. b" }, lines())
    end)
  end)

  describe("automatic", function()
    before_each(function()
      require("mdn.autofix").setup()
      vim.bo[buf].filetype = "markdown"
    end)

    local function changed()
      vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
    end

    it("renumbers after deleting the first item", function()
      set({ "1. a", "2. b", "3. c" })
      vim.fn.cursor(1, 1)
      vim.cmd("normal! dd")
      changed()
      assert.are.same({ "1. b", "2. c" }, lines())
    end)

    it("renumbers after inserting in the middle", function()
      set({ "1. a", "2. b" })
      vim.fn.cursor(1, 1)
      List.continue("o")
      vim.cmd("stopinsert")
      changed()
      assert.are.same({ "1. a", "2. ", "3. b" }, lines())
    end)

    it("renumbers after a pasted block", function()
      set({ "1. a", "2. b", "1. x", "2. y" })
      vim.fn.cursor(3, 1)
      vim.cmd("normal! 2dd")
      vim.fn.cursor(1, 1)
      vim.cmd("normal! p")
      changed()
      assert.are.same({ "1. a", "2. x", "3. y", "4. b" }, lines())
    end)

    it("renumbers after moving a line", function()
      set({ "1. a", "2. b", "3. c" })
      vim.cmd("3move 0")
      changed()
      assert.are.same({ "1. c", "2. a", "3. b" }, lines())
    end)

    -- `let &undolevels = &undolevels` closes the undo block, as returning to
    -- the main loop does between real keystrokes.
    local function sync_undo()
      vim.cmd("let &undolevels = &undolevels")
    end

    it("undoes the edit and the renumbering in one step", function()
      set({ "1. a", "2. b", "3. c" })
      sync_undo()
      vim.fn.cursor(1, 1)
      vim.cmd("normal! dd")
      sync_undo()
      changed()
      vim.cmd("undo")
      assert.are.same({ "1. a", "2. b", "3. c" }, lines())
    end)

    it("leaves the buffer alone right after an undo", function()
      set({ "1. a", "1. b" })
      sync_undo()
      vim.fn.cursor(1, 1)
      vim.cmd("normal! x")
      sync_undo()
      vim.cmd("undo")
      changed()
      assert.are.same({ "1. a", "1. b" }, lines())
    end)

    it("stays off when auto_renumber is false", function()
      Config.setup({ lists = { auto_renumber = false } })
      set({ "1. a", "1. b" })
      changed()
      assert.are.same({ "1. a", "1. b" }, lines())
    end)
  end)
end)
