---@class Mdn.Config
---@field lists? Mdn.ListsOptions
---@field mappings? Mdn.MappingsOptions
---@field conceal? Mdn.ConcealOptions
---@field rendering? Mdn.RenderingOptions
local M = {}

---@class Mdn.ListsOptions
---@field auto_continue boolean Automatically continue lists on <CR>/o/O (default: true)
---@field bullet_marker string List marker for new bullets (default: "-")

---@class Mdn.MappingsOptions
---@field cycle_key string Key for four-state cycle: blank → bullet → checkbox → toggle (set to "" to disable)

---@class Mdn.RenderingOptions
---@field conceallevel integer Markdown window conceal level (default: 2)
---@field concealcursor string Modes which keep conceal active on the cursor line (default: "")

---@class Mdn.ConcealRule
---@field pattern string Lua pattern for the source text to conceal
---@field replace string Text shown in place of the concealed source

---@class Mdn.ConcealOptions
---@field listitem Mdn.ConcealRule Rule for unordered list markers
---@field unchecked Mdn.ConcealRule Rule for unchecked checkboxes
---@field checked Mdn.ConcealRule Rule for checked checkboxes
---@field partial Mdn.ConcealRule Rule for partially checked checkboxes
---@field defer Mdn.ConcealRule Rule for deferred checkboxes
---@field scheduled Mdn.ConcealRule Rule for scheduled checkboxes
---@field event Mdn.ConcealRule Rule for event checkboxes
---@field canceled Mdn.ConcealRule Rule for canceled checkboxes

local defaults = {
  lists = {
    auto_continue = true,
    bullet_marker = "-",
  },
  mappings = {
    cycle_key = "<C-k>",
  },
  rendering = {
    conceallevel = 2,
    concealcursor = "",
  },
  conceal = {
    listitem = { pattern = "[-+*]%s", replace = " " },
    unchecked = { pattern = "%[%s%]%s", replace = "󰄱 " },
    checked = { pattern = "%[[xX]%]%s", replace = "󰄲 " },
    partial = { pattern = "%[~%]%s", replace = "󰡖 " },
    defer = { pattern = "%[>%]%s", replace = "󰁔 " },
    scheduled = { pattern = "%[<%]%s", replace = "󰃰 " },
    event = { pattern = "%[o%]%s", replace = "󰃭 " },
    canceled = { pattern = "%[%-]%s", replace = "󱋭 " },
  },
}

-- Access nested config values: Config.lists.bullet_marker, Config.mappings.cycle_key, etc.
local config = vim.deepcopy(defaults)

-- Created at module load — always available
M.augroup = vim.api.nvim_create_augroup("mdn", { clear = true })
M.ns = vim.api.nvim_create_namespace("mdn")
M.conceal_ns = vim.api.nvim_create_namespace("mdn.conceal")
M.render_ns = vim.api.nvim_create_namespace("mdn.render")

setmetatable(M, {
  __index = function(_, key)
    return config[key]
  end,
})

---Extend the defaults options table with the user options
---@param opts? Mdn.Config plugin options
function M.setup(opts)
  config = vim.tbl_deep_extend("force", {}, vim.deepcopy(defaults), opts or {})

  -- Use the table form for Neovim 0.10 compatibility.
  vim.validate({
    auto_continue = { config.lists.auto_continue, "boolean" },
    cycle_key = { config.mappings.cycle_key, "string", true },
    bullet_marker = { config.lists.bullet_marker, "string", true },
    ["rendering.conceallevel"] = { config.rendering.conceallevel, "number" },
    ["rendering.concealcursor"] = { config.rendering.concealcursor, "string" },
  })
  if
    config.rendering.conceallevel % 1 ~= 0
    or config.rendering.conceallevel < 0
    or config.rendering.conceallevel > 3
  then
    error("rendering.conceallevel must be an integer from 0 through 3")
  end
  local seen_modes = {}
  for mode in config.rendering.concealcursor:gmatch(".") do
    if not mode:match("^[nvic]$") or seen_modes[mode] then
      error("rendering.concealcursor must contain unique mode characters from 'nvic'")
    end
    seen_modes[mode] = true
  end
  for name, rule in pairs(config.conceal) do
    vim.validate({
      ["conceal." .. name] = { rule, "table" },
      ["conceal." .. name .. ".pattern"] = { rule.pattern, "string" },
      ["conceal." .. name .. ".replace"] = { rule.replace, "string" },
    })
  end
end

return M
