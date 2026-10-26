---@module 'mdn.render'

local Config = require("mdn.config")
local M = {}

local fence_query_text = [[
(fenced_code_block
  (fenced_code_block_delimiter) @conceal)

(fenced_code_block
  (info_string
    (language) @conceal))

(pipe_table_header
  "|" @table.pipe)

(pipe_table_row
  "|" @table.pipe)

(pipe_table_delimiter_row) @table.delimiter
]]

local link_query_text = [[
(inline_link
  [
    "("
    (link_destination)
    ")"
  ] @link.destination)

(image
  [
    "("
    (link_destination)
    ")"
  ] @link.destination)
]]

---@type vim.treesitter.Query?
local fence_query
---@type vim.treesitter.Query?
local link_query
---@type integer[]
local autocmds = {}
local highlight_query_ready = false

local function get_fence_query()
  if fence_query then
    return fence_query
  end

  local ok, query = pcall(vim.treesitter.query.parse, "markdown", fence_query_text)
  if ok then
    fence_query = query
  end
  return fence_query
end

local function get_link_query()
  if link_query then
    return link_query
  end

  local ok, query = pcall(vim.treesitter.query.parse, "markdown_inline", link_query_text)
  if ok then
    link_query = query
  end
  return link_query
end

local function loaded_markdown_highlighters()
  local ok, highlighter = pcall(require, "vim.treesitter.highlighter")
  if not ok then
    return {}
  end

  local active = {}
  for buf in pairs(highlighter.active) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "markdown" then
      active[#active + 1] = buf
    end
  end
  return active
end

local function restart_highlighters(bufs)
  for _, buf in ipairs(bufs) do
    pcall(vim.treesitter.stop, buf)
  end
  for _, buf in ipairs(bufs) do
    pcall(vim.treesitter.start, buf, "markdown")
  end
end

local function prepare_highlight_query()
  local ok, query = pcall(vim.treesitter.query.get, "markdown", "highlights")
  if not ok or not query or not query.info or not query.info.patterns or not query.query then
    return false
  end

  local active = loaded_markdown_highlighters()
  local prepared = false
  for pattern, directives in pairs(query.info.patterns) do
    for _, directive in ipairs(directives) do
      if directive[1] == "set!" and directive[2] == "conceal_lines" then
        if type(query.query.disable_pattern) ~= "function" then
          return false
        end
        local disabled = pcall(query.query.disable_pattern, query.query, pattern)
        if not disabled then
          return false
        end
        prepared = true
        break
      end
    end
  end

  if not prepared then
    return true
  end

  query.has_conceal_line = false
  restart_highlighters(active)
  return true
end

-- Concealing a link destination leaves its width in the wrapped row, so
-- inline links and images keep their source visible.
local function prepare_inline_query()
  local query = vim.treesitter.query.get("markdown_inline", "highlights")
  if not query or not query.query or type(query.query.disable_pattern) ~= "function" then
    return
  end

  local sample = "[a](b) ![c](d)"
  local root = vim.treesitter.get_string_parser(sample, "markdown_inline"):parse()[1]:root()
  local link_patterns = {}
  for pattern, match, metadata in query:iter_matches(root, sample, 0, -1) do
    if metadata.conceal ~= nil then
      for id in pairs(match) do
        if query.captures[id] == "markup.link" then
          link_patterns[pattern] = true
        end
      end
    end
  end

  if next(link_patterns) == nil then
    return
  end
  for pattern in pairs(link_patterns) do
    query.query:disable_pattern(pattern)
  end
  restart_highlighters(loaded_markdown_highlighters())
end

local function set_conceal(buf, row, start_col, end_col, char)
  vim.api.nvim_buf_set_extmark(buf, Config.render_ns, row, start_col, {
    end_col = end_col,
    conceal = char,
    priority = 200,
  })
end

local function render_delimiter_row(buf, row)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  local first, last = line:find("%S"), line:find("%S%s*$")
  for col = first, last do
    local char = line:sub(col, col)
    local symbol = "━"
    if char == "|" then
      symbol = col == first and "┝" or col == last and "┥" or "┿"
    end
    set_conceal(buf, row, col - 1, col, symbol)
  end
end

local function render_link_destinations(buf, parser)
  local query = get_link_query()
  if not query then
    return
  end

  pcall(function()
    parser:parse(true)
    local inline = parser:children().markdown_inline
    if not inline then
      return
    end
    for _, tree in ipairs(inline:trees()) do
      for _, node in query:iter_captures(tree:root(), buf, 0, -1) do
        local start_row, start_col, end_row, end_col = node:range()
        vim.api.nvim_buf_set_extmark(buf, Config.render_ns, start_row, start_col, {
          end_row = end_row,
          end_col = end_col,
          hl_group = "Conceal",
          priority = 200,
        })
      end
    end
  end)
end

---Apply configured rendering options to every window displaying a buffer.
---@param buf integer Buffer id
function M.apply_windows(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "markdown" then
    return
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.wo[win].conceallevel = Config.rendering.conceallevel
    vim.wo[win].concealcursor = Config.rendering.concealcursor
  end
end

---Render fenced-code delimiters and language markers in a Markdown buffer.
---@param buf integer Buffer id
function M.render(buf)
  vim.validate("buf", buf, "number")
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, Config.render_ns, 0, -1)
  if vim.bo[buf].filetype ~= "markdown" or not highlight_query_ready then
    return
  end

  local query = get_fence_query()
  local parser_ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
  if not query or not parser_ok or not parser then
    return
  end

  local parse_ok, trees = pcall(parser.parse, parser)
  if not parse_ok or not trees or not trees[1] then
    return
  end

  local ok = pcall(function()
    for id, node in query:iter_captures(trees[1]:root(), buf, 0, -1) do
      local capture = query.captures[id]
      local start_row, start_col, end_row, end_col = node:range()
      if capture == "table.pipe" then
        set_conceal(buf, start_row, start_col, start_col + 1, "│")
      elseif capture == "table.delimiter" then
        render_delimiter_row(buf, start_row)
      else
        vim.api.nvim_buf_set_extmark(buf, Config.render_ns, start_row, start_col, {
          end_row = end_row,
          end_col = end_col,
          conceal = "",
          priority = 200,
        })
      end
    end
  end)
  if not ok then
    vim.api.nvim_buf_clear_namespace(buf, Config.render_ns, 0, -1)
    return
  end

  render_link_destinations(buf, parser)
end

---Apply window options and render a Markdown buffer.
---@param buf integer Buffer id
function M.attach(buf)
  M.apply_windows(buf)
  M.render(buf)
end

local function refresh(args)
  if vim.bo[args.buf].filetype == "markdown" then
    M.attach(args.buf)
  end
end

---Enable hybrid Markdown rendering.
function M.setup()
  highlight_query_ready = prepare_highlight_query()
  pcall(prepare_inline_query)

  for _, autocmd in ipairs(autocmds) do
    pcall(vim.api.nvim_del_autocmd, autocmd)
  end
  autocmds = {
    vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
      group = Config.augroup,
      pattern = "*",
      callback = refresh,
    }),
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = Config.augroup,
      pattern = "*",
      callback = function(args)
        if vim.bo[args.buf].filetype == "markdown" then
          M.render(args.buf)
        end
      end,
    }),
  }

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "markdown" then
      M.attach(buf)
    end
  end
end

return M
