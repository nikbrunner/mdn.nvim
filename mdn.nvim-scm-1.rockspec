package = "mdn.nvim"
version = "scm-1"
source = {
  url = "git+https://github.com/nikbrunner/mdn.nvim.git",
}
description = {
  summary = "Minimal Markdown utilities for Neovim: smart list continuation and checkbox toggling",
  detailed = [[
    mdn.nvim provides two focused features for Markdown editing:
    - Smart list continuation on Enter/o/O (ordered, unordered, task lists)
    - Checkbox toggling in both Normal and Insert mode
  ]],
  homepage = "https://github.com/nikbrunner/mdn.nvim",
  license = "MIT",
}
dependencies = {
  "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
    ["mdn"] = "lua/mdn/init.lua",
    ["mdn.config"] = "lua/mdn/config.lua",
    ["mdn.patterns"] = "lua/mdn/patterns.lua",
    ["mdn.list"] = "lua/mdn/list.lua",
    ["mdn.checkbox"] = "lua/mdn/checkbox.lua",
    ["mdn.health"] = "lua/mdn/health.lua",
  },
}
