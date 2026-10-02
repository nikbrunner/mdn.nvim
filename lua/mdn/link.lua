---@module 'mdn.link'

local M = {}

---@param line string
---@param pattern string
---@param pos integer 1-based byte position
---@return integer? start
---@return integer? finish
local function find_at(line, pattern, pos)
  local init = 1
  while true do
    local s, e = line:find(pattern, init)
    if not s or s > pos then
      return nil
    end
    if pos <= e then
      return s, e
    end
    init = e + 1
  end
end

---Return the link at a 0-based byte column: the full source of a Markdown
---link, or the URL of a bare link.
---@param line string
---@param col integer 0-based byte column
---@return string?
function M.at(line, col)
  local pos = col + 1

  local s, e = find_at(line, "!?%b[]%b()", pos)
  if s then
    return line:sub(s, e)
  end

  s, e = find_at(line, "%a[%w+.-]*://[^%s<>]+", pos)
  if not s then
    return nil
  end
  local url = line:sub(s, e):gsub("[.,;:!?'\"]+$", "")
  -- Keep closing parens the URL opens itself, e.g. Wikipedia links.
  local _, opened = url:gsub("%(", "")
  local _, closed = url:gsub("%)", "")
  while closed > opened and url:sub(-1) == ")" do
    url, closed = url:sub(1, -2), closed - 1
  end
  if pos > s + #url - 1 then
    return nil
  end
  return url
end

---Yank the link under the cursor into v:register. Falls back to a native
---`yl` when the cursor is not on a link.
function M.yank()
  local register, count = vim.v.register, vim.v.count1
  local link = M.at(vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[2])
  if link then
    vim.fn.setreg(register, link, "v")
    vim.notify("Mdn: Yanked " .. link, vim.log.levels.INFO, { title = "mdn.nvim" })
  else
    vim.cmd.normal({ ('"%s%dyl'):format(register, count), bang = true })
  end
end

return M
