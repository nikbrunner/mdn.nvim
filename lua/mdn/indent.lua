---@module 'mdn.indent'

local M = {}

---Get the shiftwidth for the current buffer.
---Uses vim.bo.shiftwidth (buffer-local), falls back to 2 for edge cases.
---@return integer
local function shiftwidth()
  local sw = vim.bo.shiftwidth
  if sw and sw > 0 then
    return sw
  end
  -- Fallback: vim.fn.shiftwidth() returns a default
  local fn_sw = vim.fn.shiftwidth()
  return fn_sw > 0 and fn_sw or 2
end

---Indent the current line by prepending shiftwidth spaces.
---Preserves cursor column position relative to the indent change.
---Works on any line type in Insert mode.
function M.indent()
  local lnum = vim.fn.line(".")
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local sw = shiftwidth()
  local indent_spaces = string.rep(" ", sw)

  vim.api.nvim_set_current_line(indent_spaces .. line)
  vim.fn.cursor(lnum, col + sw)
end

---Outdent the current line by removing up to shiftwidth leading spaces.
---Removes only leading whitespace, not other characters.
---If there are fewer than shiftwidth leading spaces, removes all of them.
---Preserves cursor column position relative to the outdent change.
---Works on any line type in Insert mode.
function M.outdent()
  local lnum = vim.fn.line(".")
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local sw = shiftwidth()

  -- Count leading spaces
  local leading = line:match("^(%s*)")
  local leading_len = #leading

  if leading_len == 0 then
    return -- Nothing to outdent
  end

  local remove = math.min(sw, leading_len)
  local new_line = line:sub(remove + 1)
  vim.api.nvim_set_current_line(new_line)

  -- Adjust cursor: move left by the number of spaces removed, but not past col 1
  local new_col = math.max(1, col - remove)
  vim.fn.cursor(lnum, new_col)
end

return M
