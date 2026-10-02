#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = ".tests"
vim.env.LAZY_PATH = vim.fs.normalize("~/projects/lazy.nvim")

local lazy_cache = vim.fs.normalize(vim.env.LAZY_STDPATH .. "/data/nvim/lazy/lazy.nvim")

if vim.fn.isdirectory(vim.env.LAZY_PATH) == 1 then
  loadfile(vim.env.LAZY_PATH .. "/bootstrap.lua")()
elseif vim.fn.isdirectory(lazy_cache) == 1 then
  vim.env.LAZY_PATH = lazy_cache
  loadfile(lazy_cache .. "/bootstrap.lua")()
else
  load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"), "bootstrap.lua")()
end

require("lazy.minit").setup({
  spec = {
    { dir = vim.uv.cwd() },
  },
})
