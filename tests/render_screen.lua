local scenario = assert(arg[1], "screen scenario is required")

vim.o.lines = 20
vim.o.columns = 100
vim.opt.runtimepath:prepend(vim.uv.cwd())

local Config = require("mdn.config")
Config.setup()
local Render = require("mdn.render")
Render.setup()

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buf)
vim.bo[buf].filetype = "markdown"

local function screen_text(win, row, width)
  local pos = vim.fn.win_screenpos(win)
  local chars = {}
  for col = pos[2], pos[2] + width - 1 do
    chars[#chars + 1] = vim.fn.screenstring(pos[1] + row - 1, col)
  end
  return table.concat(chars)
end

local function equal(expected, actual)
  assert(expected == actual, ("expected %q, got %q"):format(expected, actual))
end

if scenario == "insert" then
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```lua", "payload", "```", "after" })
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  Render.render(buf)
  vim.treesitter.start(buf, "markdown")
  vim.cmd("redraw!")
  equal("       ", screen_text(win, 1, 7))
  equal("payload", screen_text(win, 2, 7))
  assert(screen_text(win, 3, 10):match("```"))
  equal("after", screen_text(win, 4, 5))

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("Oinserted<Esc>", true, false, true), "x", false)
  equal("inserted", vim.api.nvim_buf_get_lines(buf, 2, 3, false)[1])
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  local during = {}
  _G.mdn_render_capture_insert = function()
    vim.cmd("redraw!")
    during.mode = vim.api.nvim_get_mode().mode
    during.payload = screen_text(win, 3, 9)
    during.opening = screen_text(win, 1, 7)
    during.closing = screen_text(win, 4, 7)
  end
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("A!<Cmd>lua _G.mdn_render_capture_insert()<CR><Esc>", true, false, true),
    "x",
    false
  )
  equal("i", during.mode)
  equal("inserted!", during.payload)
  equal("       ", during.opening)
  equal("       ", during.closing)

  equal("inserted!", vim.api.nvim_buf_get_lines(buf, 2, 3, false)[1])
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  vim.cmd("redraw!")
  equal("       ", screen_text(win, 1, 7))
  equal("payload", screen_text(win, 2, 7))
  equal("inserted!", screen_text(win, 3, 9))
  assert(screen_text(win, 4, 10):match("```"))
elseif scenario == "windows" then
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "```lua",
    "payload",
    "```",
    "[label](https://example.com)",
    "after",
  })
  Render.render(buf)
  vim.treesitter.start(buf, "markdown")
  local first_win = vim.api.nvim_get_current_win()
  vim.cmd("vsplit")
  local second_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_cursor(first_win, { 1, 0 })
  vim.api.nvim_win_set_cursor(second_win, { 4, 0 })

  vim.api.nvim_set_current_win(first_win)
  vim.cmd("redraw!")
  assert(screen_text(first_win, 1, 28):match("```lua"))
  equal("label", screen_text(first_win, 4, 5))

  vim.api.nvim_set_current_win(second_win)
  vim.cmd("redraw!")
  equal("     ", screen_text(second_win, 1, 5))
  assert(screen_text(second_win, 4, 28):match("%[label%]"))
else
  error("unknown screen scenario: " .. scenario)
end
