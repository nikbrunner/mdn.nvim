---@module 'mdn.conceal'

local Config = require("mdn.config")
local List = require("mdn.list")
local M = {}

local checkbox_symbols = {
  [" "] = "unchecked",
  x = "checked",
  X = "checked",
  ["~"] = "partial",
  [">"] = "defer",
  ["<"] = "scheduled",
  o = "event",
  ["-"] = "canceled",
}

local function add_mark(buf, row, start_col, end_col, symbol)
  local opts = {
    end_col = end_col,
    conceal = "",
    priority = 200,
  }
  if symbol ~= "" then
    opts.virt_text = { { symbol, "Conceal" } }
    opts.virt_text_pos = "inline"
  end
  vim.api.nvim_buf_set_extmark(buf, Config.conceal_ns, row, start_col, opts)
end

local function find_rule_end(line, start_col, rule)
  local match_start, match_end = line:find(rule.pattern, start_col + 1)
  if match_start == start_col + 1 then
    return match_end
  end
end

---Render list markers and supported checkbox states in a buffer.
---@param buf integer Buffer id
function M.render(buf)
  vim.validate("buf", buf, "number")

  vim.api.nvim_buf_clear_namespace(buf, Config.conceal_ns, 0, -1)
  if vim.wo.conceallevel == 0 then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local cursor_row
  if vim.api.nvim_get_current_buf() == buf then
    cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
  end

  for row, line in ipairs(lines) do
    local row_index = row - 1
    if row_index ~= cursor_row then
      local lcontent = List.resolve_list_content(line)
      if lcontent then
        local list_start = #lcontent.indent
        local checkbox_char = lcontent.text:match("^%[(.)%]")
        local symbol_name = checkbox_symbols[checkbox_char]
        if symbol_name then
          local checkbox_start = list_start + #lcontent.marker + #lcontent.separator + 1
          local prefix_start = checkbox_start
          if lcontent.type == "unordered" then
            prefix_start = list_start
          end
          local rule = Config.conceal[symbol_name]
          local prefix_end = find_rule_end(line, checkbox_start, rule)
          if prefix_end then
            add_mark(buf, row_index, prefix_start, prefix_end, rule.replace)
          end
        elseif lcontent.type == "unordered" then
          local rule = Config.conceal.listitem
          local list_end = find_rule_end(line, list_start, rule)
          if list_end then
            add_mark(buf, row_index, list_start, list_end, rule.replace)
          end
        end
      end
    end
  end
end

local function refresh(args)
  if vim.bo[args.buf].filetype == "markdown" then
    M.render(args.buf)
  end
end

local function refresh_conceallevel()
  if vim.bo.filetype == "markdown" then
    M.render(0)
  end
end

---Enable automatic conceal rendering for Markdown buffers.
function M.setup()
  vim.api.nvim_create_autocmd(
    { "BufEnter", "TextChanged", "TextChangedI", "CursorMoved", "CursorMovedI", "FileType" },
    {
      group = Config.augroup,
      pattern = "*",
      callback = refresh,
    }
  )
  vim.api.nvim_create_autocmd("OptionSet", {
    group = Config.augroup,
    pattern = "conceallevel",
    callback = refresh_conceallevel,
  })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "markdown" then
      M.render(buf)
    end
  end
end

return M
