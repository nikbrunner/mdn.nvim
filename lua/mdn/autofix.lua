---@module 'mdn.autofix'

local Config = require("mdn.config")
local M = {}

---@type integer[]
local autocmds = {}

---Whether the buffer sits on an undone state. Fixing it would turn the
---next redo into a branch, so undo and redo stay untouched.
---@param buf integer
---@return boolean
local function after_undo(buf)
  local tree = vim.api.nvim_buf_call(buf, vim.fn.undotree)
  return tree.seq_cur < tree.seq_last
end

---Run a fix that edits the buffer.
---@param buf integer
---@param fix fun()
---@param join boolean Join the fix's edits to the user's last change
local function run(buf, fix, join)
  if after_undo(buf) then
    return
  end
  local tick = vim.b[buf].changedtick
  vim.api.nvim_buf_call(buf, function()
    if join then
      pcall(vim.cmd.undojoin)
    end
    pcall(fix)
  end)
  -- Edits made inside a TextChanged handler don't fire it again, so the
  -- extmarks drawn for the old text need a redraw here.
  if vim.b[buf].changedtick ~= tick then
    require("mdn.render").render(buf)
    require("mdn.conceal").render(buf)
  end
end

---Rows to fix after a change: the cursor row and the start of the change.
---@param buf integer
---@return integer[] 0-indexed rows
local function changed_rows(buf)
  local rows = { vim.api.nvim_win_get_cursor(0)[1] - 1 }
  local change_start = vim.api.nvim_buf_get_mark(buf, "[")[1] - 1
  if change_start >= 0 and change_start ~= rows[1] then
    table.insert(rows, change_start)
  end
  return rows
end

local function renumber(args)
  if vim.bo[args.buf].filetype ~= "markdown" or not Config.lists.auto_renumber then
    return
  end
  run(args.buf, function()
    for _, row in ipairs(changed_rows(args.buf)) do
      require("mdn.list").renumber(args.buf, row)
    end
  end, true)
end

local function fit(args)
  if vim.bo[args.buf].filetype ~= "markdown" or not Config.tables.auto_fit then
    return
  end
  -- Leaving Insert mode without typing has no change of its own to join.
  local join = args.event ~= "InsertLeave" or vim.b[args.buf].changedtick ~= vim.b[args.buf].mdn_insert_tick
  run(args.buf, function()
    for _, row in ipairs(changed_rows(args.buf)) do
      require("mdn.table").fit(args.buf, row)
    end
  end, join)
end

---Enable automatic fixes for Markdown buffers.
function M.setup()
  for _, autocmd in ipairs(autocmds) do
    pcall(vim.api.nvim_del_autocmd, autocmd)
  end
  autocmds = {
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = Config.augroup,
      pattern = "*",
      callback = renumber,
    }),
    vim.api.nvim_create_autocmd("InsertEnter", {
      group = Config.augroup,
      pattern = "*",
      callback = function(args)
        vim.b[args.buf].mdn_insert_tick = vim.b[args.buf].changedtick
      end,
    }),
    vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
      group = Config.augroup,
      pattern = "*",
      callback = fit,
    }),
  }
end

return M
