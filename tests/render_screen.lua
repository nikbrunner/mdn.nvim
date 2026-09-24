local scenario = assert(vim.env.MDN_SCREEN_SCENARIO, "screen scenario is required")
assert(#vim.api.nvim_list_uis() > 0, "screen scenarios require an attached UI")

vim.opt.runtimepath:prepend(vim.uv.cwd())

local Config = require("mdn.config")
Config.setup()
local Render = require("mdn.render")
Render.setup()
local Conceal = require("mdn.conceal")
Conceal.setup()

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

local function wait_for_screen(check, message)
  local ok = vim.wait(2000, function()
    vim.treesitter.get_parser(buf, "markdown"):parse()
    vim.cmd("redraw!")
    return check()
  end, 10)
  assert(ok, message)
end

if scenario == "link" then
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "before",
    "[label](https://example.com)next",
    "```lua",
    "payload",
    "```",
    "after",
  })
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  Render.render(buf)
  vim.treesitter.start(buf, "markdown")
  wait_for_screen(function()
    return screen_text(win, 2, 9) == "labelnext"
  end, "link never rendered without a trailing gap")

  equal("labelnext", screen_text(win, 2, 9))
  equal("       ", screen_text(win, 3, 7))
  equal("payload", screen_text(win, 4, 7))
  equal("       ", screen_text(win, 5, 7))
  equal("after", screen_text(win, 6, 5))
elseif scenario == "insert" then
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```lua", "payload", "```", "after" })
  vim.api.nvim_win_set_cursor(win, { 3, 0 })
  Render.render(buf)
  vim.treesitter.start(buf, "markdown")
  wait_for_screen(function()
    return screen_text(win, 2, 7) == "payload" and screen_text(win, 3, 10):match("```") ~= nil
  end, "initial fence screen did not stabilize")
  equal("       ", screen_text(win, 1, 7))
  equal("payload", screen_text(win, 2, 7))
  assert(screen_text(win, 3, 10):match("```"))
  equal("after", screen_text(win, 4, 5))

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("Oinserted<Esc>", true, false, true), "x", false)
  equal("inserted", vim.api.nvim_buf_get_lines(buf, 2, 3, false)[1])
  vim.api.nvim_win_set_cursor(win, { 3, 0 })
  local during = {}
  _G.mdn_render_capture_insert = function()
    vim.treesitter.get_parser(buf, "markdown"):parse()
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
  vim.api.nvim_win_set_cursor(win, { 4, 0 })
  wait_for_screen(function()
    return screen_text(win, 4, 10):match("```") ~= nil
  end, "closing fence source did not return on its cursor line")
  equal("       ", screen_text(win, 1, 7))
  equal("payload", screen_text(win, 2, 7))
  equal("inserted!", screen_text(win, 3, 9))
  assert(screen_text(win, 4, 10):match("```"))
elseif scenario == "conceal" then
  vim.g.MDN_SCREEN_ASYNC = true
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "- [ ] first",
    "- [x] second",
    "- [ ] third",
  })
  vim.wo.conceallevel = 2
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  Conceal.render(buf)

  local function contains(row, text)
    return screen_text(win, row, 20):find(text, 1, true) ~= nil
  end
  local function equals(row, text)
    return screen_text(win, row, #text) == text
  end
  local function finish(ok, message)
    if not ok then
      io.stderr:write(message .. "\n")
      vim.cmd("cquit")
      return
    end
    vim.g.MDN_SCREEN_DONE = true
    vim.cmd("qa!")
  end
  local function poll(check, message, next)
    local deadline = vim.uv.hrtime() + 2e9
    local function tick()
      vim.cmd("redraw!")
      if check() then
        next()
      elseif vim.uv.hrtime() < deadline then
        vim.defer_fn(tick, 10)
      else
        finish(false, message)
      end
    end
    vim.schedule(tick)
  end
  local steps = {
    {
      keys = "<C-v>j",
      check = function()
        return vim.fn.mode(1) == "\22"
          and equals(1, "- [ ] first")
          and equals(2, "- [x] second")
          and contains(3, "󰄱")
      end,
      message = "Visual Block selection did not reveal its rows and preserve the unselected row",
    },
    {
      keys = "j",
      check = function()
        return vim.fn.mode(1) == "\22"
          and equals(1, "- [ ] first")
          and equals(2, "- [x] second")
          and equals(3, "- [ ] third")
      end,
      message = "expanding the Visual Block did not reveal the added row",
    },
    {
      keys = "k",
      check = function()
        return vim.fn.mode(1) == "\22"
          and equals(1, "- [ ] first")
          and equals(2, "- [x] second")
          and contains(3, "󰄱")
      end,
      message = "shrinking the Visual Block did not restore conceal outside the selection",
    },
    {
      keys = "<Esc>",
      check = function()
        return vim.fn.mode(1) == "n" and contains(1, "󰄱")
      end,
      message = "conceal did not return after leaving Visual Block mode",
    },
    {
      keys = "j<C-v>k",
      check = function()
        return vim.fn.mode(1) == "\22"
          and contains(1, "󰄱")
          and equals(2, "- [x] second")
          and equals(3, "- [ ] third")
      end,
      message = "upward Visual Block selection did not reveal all selected rows",
    },
    {
      keys = "<Esc>",
      check = function()
        return vim.fn.mode(1) == "n" and contains(1, "󰄱") and contains(3, "󰄱")
      end,
      message = "conceal did not return after upward selection",
    },
  }
  local function run_step(index)
    local step = steps[index]
    if not step then
      finish(true)
      return
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(step.keys, true, false, true), "n", false)
    poll(step.check, step.message, function()
      run_step(index + 1)
    end)
  end

  poll(
    function()
      return contains(2, "󰄲")
    end,
    "checkboxes were not concealed before selection",
    function()
      run_step(1)
    end
  )
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
  wait_for_screen(function()
    return screen_text(first_win, 1, 28):match("```lua") ~= nil
  end, "first window did not reveal fence source")
  assert(screen_text(first_win, 1, 28):match("```lua"))
  equal("label", screen_text(first_win, 4, 5))

  vim.api.nvim_set_current_win(second_win)
  wait_for_screen(function()
    return screen_text(second_win, 4, 28):match("%[label%]") ~= nil
  end, "second window did not reveal link source")
  equal("     ", screen_text(second_win, 1, 5))
  assert(screen_text(second_win, 4, 28):match("%[label%]"))
else
  error("unknown screen scenario: " .. scenario)
end
