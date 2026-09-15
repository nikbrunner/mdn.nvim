---@module 'luassert'

local Config = require("mdn.config")

describe("Markdown rendering configuration", function()
  after_each(function()
    Config.setup()
  end)

  it("defaults to label-only conceal away from the cursor", function()
    Config.setup()

    assert.are.same({ conceallevel = 2, concealcursor = "" }, Config.rendering)
  end)

  it("accepts conceal levels zero through three and valid cursor modes", function()
    for level = 0, 3 do
      Config.setup({ rendering = { conceallevel = level, concealcursor = "nvic" } })
      assert.are.equal(level, Config.rendering.conceallevel)
      assert.are.equal("nvic", Config.rendering.concealcursor)
    end
  end)

  for _, level in ipairs({ -1, 4, 1.5 }) do
    it("rejects conceal level " .. level, function()
      assert.has_error(function()
        Config.setup({ rendering = { conceallevel = level } })
      end)
    end)
  end

  for _, value in ipairs({ "2", true }) do
    it("rejects conceal level type " .. type(value), function()
      assert.has_error(function()
        Config.setup({ rendering = { conceallevel = value } })
      end)
    end)
  end

  for _, value in ipairs({ 2, true }) do
    it("rejects concealcursor type " .. type(value), function()
      assert.has_error(function()
        Config.setup({ rendering = { concealcursor = value } })
      end)
    end)
  end

  for _, value in ipairs({ "x", "nn", "nvv", "n " }) do
    it("rejects concealcursor value " .. vim.inspect(value), function()
      assert.has_error(function()
        Config.setup({ rendering = { concealcursor = value } })
      end)
    end)
  end
end)

local function get_render()
  local ok, render = pcall(require, "mdn.render")
  assert.is_true(ok)
  return render
end

local markdown_query_file = vim.treesitter.query.get_files("markdown", "highlights")[1]
local markdown_query_text = markdown_query_file and table.concat(vim.fn.readfile(markdown_query_file), "\n") or ""

local query_generation = 0
local function reset_markdown_query()
  query_generation = query_generation + 1
  vim.treesitter.query.set(
    "markdown",
    "highlights",
    ([[
; generation %d
(fenced_code_block
  (fenced_code_block_delimiter) @markup.raw.block
  (#set! conceal "")
  (#set! conceal_lines ""))

(fenced_code_block
  (info_string
    (language) @label
    (#set! conceal "")
    (#set! conceal_lines "")))

(atx_heading
  (atx_h1_marker) @punctuation.special
  (#set! conceal ""))
]]):format(query_generation)
  )
end

local function restore_markdown_query()
  vim.treesitter.query.set("markdown", "highlights", markdown_query_text)
end

local function has_markdown_parser()
  return pcall(vim.treesitter.get_parser, 0, "markdown")
end

local function can_disable_query_patterns()
  local query = vim.treesitter.query.get("markdown", "highlights")
  return query and query.query and type(query.query.disable_pattern) == "function"
end

local function screen_text(win, buffer_row, width)
  local pos = vim.fn.win_screenpos(win)
  local topline = vim.api.nvim_win_call(win, function()
    return vim.fn.line("w0")
  end)
  local screen_row = pos[1] + buffer_row - topline
  local chars = {}
  for col = pos[2], pos[2] + width - 1 do
    chars[#chars + 1] = vim.fn.screenstring(screen_row, col)
  end
  return table.concat(chars)
end

local function has_screen()
  vim.cmd("redraw!")
  return vim.fn.screenchar(1, 1) >= 0
end

local function run_screen_scenario(scenario)
  local result = vim
    .system({ "nvim", "--clean", "--headless", "-l", "tests/render_screen.lua", scenario }, { text = true })
    :wait()
  if result.code ~= 0 then
    error(result.stderr)
  end
end

local function conceal_line_match_count(query, buf)
  local parser = vim.treesitter.get_parser(buf, "markdown")
  local tree = parser:parse()[1]
  local count = 0
  for _, _, metadata in query:iter_matches(tree:root(), buf, 0, -1, { all = true }) do
    if metadata.conceal_lines ~= nil then
      count = count + 1
    end
  end
  return count
end

describe("hybrid Markdown rendering", function()
  local Render
  local buf
  local original_buf
  local original_win
  local extra_wins

  before_each(function()
    Render = get_render()
    vim.cmd("silent! only")
    original_buf = vim.api.nvim_get_current_buf()
    original_win = vim.api.nvim_get_current_win()
    extra_wins = {}
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(original_win, buf)
    vim.api.nvim_set_current_win(original_win)
    vim.bo[buf].filetype = "markdown"
    Config.setup()
  end)

  after_each(function()
    for _, win in ipairs(extra_wins) do
      if vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
    if buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.treesitter.stop, buf)
      if vim.api.nvim_win_is_valid(original_win) then
        pcall(vim.api.nvim_set_current_win, original_win)
      end
      if vim.api.nvim_buf_is_valid(original_buf) and vim.api.nvim_win_is_valid(original_win) then
        pcall(vim.api.nvim_win_set_buf, original_win, original_buf)
      end
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
    Config.setup()
    restore_markdown_query()
    Render.setup()
  end)

  it("applies default options from the Markdown after-ftplugin", function()
    vim.wo[original_win].conceallevel = 0
    vim.wo[original_win].concealcursor = "n"

    vim.cmd("runtime! after/ftplugin/markdown.lua")

    assert.are.equal(2, vim.wo[original_win].conceallevel)
    assert.are.equal("", vim.wo[original_win].concealcursor)
  end)

  it("applies each configured conceal level and cursor modes to every window", function()
    vim.cmd("vsplit")
    local second_win = vim.api.nvim_get_current_win()
    extra_wins[#extra_wins + 1] = second_win

    for level = 0, 3 do
      Config.setup({ rendering = { conceallevel = level, concealcursor = "iv" } })
      vim.wo[original_win].conceallevel = (level + 1) % 4
      vim.wo[second_win].conceallevel = (level + 2) % 4
      vim.wo[original_win].concealcursor = "n"
      vim.wo[second_win].concealcursor = "c"

      vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = buf })

      assert.are.equal(level, vim.wo[original_win].conceallevel)
      assert.are.equal(level, vim.wo[second_win].conceallevel)
      assert.are.equal("iv", vim.wo[original_win].concealcursor)
      assert.are.equal("iv", vim.wo[second_win].concealcursor)
    end
  end)

  it("disables every highlight pattern carrying conceal_lines before attachment", function()
    if not has_markdown_parser() or not can_disable_query_patterns() then
      return
    end
    reset_markdown_query()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "# heading", "```lua", "payload", "```" })
    local query = vim.treesitter.query.get("markdown", "highlights")
    assert.is_true(conceal_line_match_count(query, buf) > 0)

    Render.setup()

    assert.are.equal(query, vim.treesitter.query.get("markdown", "highlights"))
    assert.are.equal(0, conceal_line_match_count(query, buf))
    local remaining_conceal = 0
    local tree = vim.treesitter.get_parser(buf, "markdown"):parse()[1]
    for _, _, metadata in query:iter_matches(tree:root(), buf, 0, -1, { all = true }) do
      if metadata.conceal ~= nil then
        remaining_conceal = remaining_conceal + 1
      end
    end
    assert.are.equal(1, remaining_conceal)
  end)

  it("removes emitted vertical conceal marks when preparing an attached highlighter", function()
    if not has_markdown_parser() or not can_disable_query_patterns() then
      return
    end
    reset_markdown_query()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```lua", "payload", "```", "after" })
    vim.wo[original_win].conceallevel = 2
    vim.wo[original_win].concealcursor = ""
    vim.api.nvim_win_set_cursor(original_win, { 4, 0 })
    vim.treesitter.start(buf, "markdown")
    local old_highlighter = require("vim.treesitter.highlighter").active[buf]
    vim.cmd("redraw!")
    assert.are.equal("payload", screen_text(original_win, 1, 7))
    local before_marks = vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })
    assert.is_true(#before_marks > 0)

    Render.setup()

    assert.are_not.equal(old_highlighter, require("vim.treesitter.highlighter").active[buf])
    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
      assert.are.equal(Config.render_ns, mark[4].ns_id)
    end
    assert.is_not_nil(require("vim.treesitter.highlighter").active[buf])
  end)

  it("leaves an inactive Markdown highlighter inactive", function()
    assert.is_nil(require("vim.treesitter.highlighter").active[buf])

    Render.setup()

    assert.is_nil(require("vim.treesitter.highlighter").active[buf])
  end)

  it("uses one prepared highlight query for two attached Markdown buffers", function()
    if not has_markdown_parser() or not can_disable_query_patterns() then
      return
    end
    reset_markdown_query()
    local second_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[second_buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```", "one", "```" })
    vim.api.nvim_buf_set_lines(second_buf, 0, -1, false, { "```", "two", "```" })
    vim.treesitter.start(buf, "markdown")
    vim.treesitter.start(second_buf, "markdown")

    Render.setup()

    local query = vim.treesitter.query.get("markdown", "highlights")
    assert.are.equal(0, conceal_line_match_count(query, buf))
    assert.are.equal(0, conceal_line_match_count(query, second_buf))
    assert.is_not_nil(require("vim.treesitter.highlighter").active[buf])
    assert.is_not_nil(require("vim.treesitter.highlighter").active[second_buf])
    vim.treesitter.stop(second_buf)
    vim.api.nvim_buf_delete(second_buf, { force = true })
  end)

  it("leaves readable source when conceal_lines patterns cannot be disabled", function()
    if not has_markdown_parser() then
      return
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```lua", "payload", "```" })
    local original_get = vim.treesitter.query.get
    vim.treesitter.query.get = function()
      return {
        info = { patterns = { { { "set!", "conceal_lines", "" } } } },
        query = {},
      }
    end

    local ok = pcall(function()
      Render.setup()
      Render.render(buf)
    end)

    vim.treesitter.query.get = original_get
    assert.is_true(ok)
    assert.are.same({ "```lua", "payload", "```" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    assert.are.equal(0, #vim.api.nvim_buf_get_extmarks(buf, Config.render_ns, 0, -1, {}))
  end)

  it("leaves readable source when the Markdown highlight query is missing", function()
    if not has_markdown_parser() then
      return
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```lua", "payload", "```" })
    local original_get = vim.treesitter.query.get
    vim.treesitter.query.get = function()
      return nil
    end

    local ok = pcall(function()
      Render.setup()
      Render.render(buf)
    end)

    vim.treesitter.query.get = original_get
    assert.is_true(ok)
    assert.are.same({ "```lua", "payload", "```" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    assert.are.equal(0, #vim.api.nvim_buf_get_extmarks(buf, Config.render_ns, 0, -1, {}))
  end)

  it("leaves readable source without errors when parser and query support are missing", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```lua", "payload", "```" })
    local original_get = vim.treesitter.query.get
    local original_get_parser = vim.treesitter.get_parser
    vim.treesitter.query.get = function()
      return nil
    end
    vim.treesitter.get_parser = function()
      error("no parser")
    end

    local ok = pcall(function()
      Render.setup()
      Render.render(buf)
    end)

    vim.treesitter.query.get = original_get
    vim.treesitter.get_parser = original_get_parser
    assert.is_true(ok)
    assert.are.same({ "```lua", "payload", "```" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    assert.are.equal(0, #vim.api.nvim_buf_get_extmarks(buf, Config.render_ns, 0, -1, {}))
  end)

  it("conceals fence delimiters and language character-wise on every source row", function()
    if not has_markdown_parser() then
      return
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```lua", "payload", "```" })
    vim.api.nvim_win_set_cursor(original_win, { 1, 0 })

    Render.render(buf)

    local marks = vim.api.nvim_buf_get_extmarks(buf, Config.render_ns, 0, -1, { details = true })
    assert.are.equal(3, #marks)
    assert.are.same({ 0, 0, 0, 3 }, { marks[1][2], marks[1][3], marks[1][4].end_row, marks[1][4].end_col })
    assert.are.same({ 0, 3, 0, 6 }, { marks[2][2], marks[2][3], marks[2][4].end_row, marks[2][4].end_col })
    assert.are.same({ 2, 0, 2, 3 }, { marks[3][2], marks[3][3], marks[3][4].end_row, marks[3][4].end_col })
    for _, mark in ipairs(marks) do
      assert.are.equal("", mark[4].conceal)
    end
  end)

  it("renders links without a trailing cell and preserves fence and payload rows", function()
    if not has_markdown_parser() then
      return
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "before",
      "[label](https://example.com)next",
      "```lua",
      "payload",
      "```",
      "after",
    })
    vim.api.nvim_win_set_cursor(original_win, { 1, 0 })
    Render.setup()
    Render.render(buf)
    vim.treesitter.start(buf, "markdown")
    vim.cmd("redraw!")
    if not has_screen() then
      return
    end

    assert.are.equal("labelnext", screen_text(original_win, 2, 9))
    assert.are.equal("       ", screen_text(original_win, 3, 7))
    assert.are.equal("payload", screen_text(original_win, 4, 7))
    assert.are.equal("       ", screen_text(original_win, 5, 7))
    assert.are.equal("after", screen_text(original_win, 6, 5))
  end)

  it("keeps payload and both fence rows through an Insert-mode edit beside the closing fence", function()
    if not has_screen() then
      return
    end
    run_screen_scenario("insert")
  end)

  it("reveals fence and link source independently in two windows", function()
    if not has_screen() then
      return
    end
    run_screen_scenario("windows")
  end)
end)
