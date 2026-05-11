---@module 'mdn.patterns'

local M = {}

---@alias MdnPattern string Lua pattern that returns captures for match groups

---@class MdnPatterns
---@field unordered_list string Pattern for unordered list items: captures indent, marker, text
---@field ordered_list string Pattern for ordered list items: captures indent, number, separator, text
---@field task string Pattern for task checkbox markers: captures "[ ]", "[x]", "[X]"

-- Unordered list: "- item", "* item", "+ item"
-- Returns: indent (spaces), marker (-/*/+), text
M.unordered_list = "^([%s]-)([-+*])[%s](.*)"

-- Ordered list: "1. item", "2) item"
-- Returns: indent (spaces), number, separator (./)), text
M.ordered_list = "^([%s]-)([%d]+)([%.%)])[%s](.*)"

-- Task checkbox: matches any single-char checkbox within text
-- e.g. "[ ]", "[x]", "[~]", "[>]", "[o]", "[<]"
-- Used to detect and toggle checkbox state in list items
-- Returns: the checkbox marker
M.task = "[%s]-(%[.%])[%s]+.-"

return M
