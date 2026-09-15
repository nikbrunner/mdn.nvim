---@module 'mdn.render'

local Config = require("mdn.config")
local M = {}

local fence_query_text = [[
(fenced_code_block
  (fenced_code_block_delimiter) @conceal)

(fenced_code_block
  (info_string
    (language) @conceal))
]]

---@type vim.treesitter.Query?
local fence_query
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
  for _, buf in ipairs(active) do
    pcall(vim.treesitter.stop, buf)
  end
  for _, buf in ipairs(active) do
    pcall(vim.treesitter.start, buf, "markdown")
  end
  return true
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
  vim.validate({ buf = { buf, "number" } })
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
    for _, node in query:iter_captures(trees[1]:root(), buf, 0, -1) do
      local start_row, start_col, end_row, end_col = node:range()
      vim.api.nvim_buf_set_extmark(buf, Config.render_ns, start_row, start_col, {
        end_row = end_row,
        end_col = end_col,
        conceal = "",
        priority = 200,
      })
    end
  end)
  if not ok then
    vim.api.nvim_buf_clear_namespace(buf, Config.render_ns, 0, -1)
  end
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
