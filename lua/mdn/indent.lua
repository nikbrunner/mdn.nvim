---@module 'mdn.indent'

local M = {}

---Find and parse a .prettierrc file to get the tabWidth.
---Searches up from the current buffer's directory.
---Caches result in buffer-local variables.
---@return integer|nil tabWidth if found, nil otherwise
local function find_prettier_tabwidth()
  -- Check per-buffer cache
  if vim.b.mdn_prettier_lookup_done then
    return vim.b.mdn_prettier_tabwidth
  end

  local buf_dir = vim.fn.expand("%:p:h")
  if buf_dir == "" then
    vim.b.mdn_prettier_lookup_done = true
    return nil
  end

  -- Try to read and parse a file as JSON, return tabWidth if found
  local function try_parse(filepath)
    local ok, data = pcall(vim.fn.readfile, filepath)
    if not ok or not data then
      return nil
    end
    local content = table.concat(data, "\n")
    local ok, decoded = pcall(vim.json.decode, content)
    if ok and type(decoded) == "table" then
      -- .prettierrc / .prettierrc.json: top-level tabWidth
      if decoded.tabWidth then
        return tonumber(decoded.tabWidth)
      end
      -- package.json: "prettier" key
      if decoded.prettier and type(decoded.prettier) == "table" and decoded.prettier.tabWidth then
        return tonumber(decoded.prettier.tabWidth)
      end
    end
    return nil
  end

  local candidates = { ".prettierrc", ".prettierrc.json", "package.json" }
  local dir = buf_dir

  -- Walk up directory tree (max 20 levels to avoid runaway)
  for _ = 1, 20 do
    for _, candidate in ipairs(candidates) do
      local filepath = dir .. "/" .. candidate
      if vim.fn.filereadable(filepath) == 1 then
        local tw = try_parse(filepath)
        if tw then
          vim.b.mdn_prettier_lookup_done = true
          vim.b.mdn_prettier_tabwidth = tw
          return tw
        end
      end
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  vim.b.mdn_prettier_lookup_done = true
  return nil
end

---Get the indent width for the current buffer.
---Priority:
---  1. .prettierrc / .prettierrc.json tabWidth (walk up from buffer dir)
---  2. vim.bo.shiftwidth (buffer-local, respects EditorConfig)
---  3. vim.fn.shiftwidth()
---  4. Hardcoded 2 as last resort
---@return integer
local function get_indent_width()
  -- Try Prettier config first
  local tw = find_prettier_tabwidth()
  if tw then
    return tw
  end

  -- Fallback: vim.bo.shiftwidth (respects EditorConfig if enabled)
  local sw = vim.bo.shiftwidth
  if sw and sw > 0 then
    return sw
  end

  -- Final fallback
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
  local sw = get_indent_width()
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
  local sw = get_indent_width()

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
