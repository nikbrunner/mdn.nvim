---Mdn.nvim Markdown buffer-local keymaps

local function is_enabled()
  local ok, mdn = pcall(require, "mdn")
  if not ok then
    return false
  end
  return mdn.did_setup
end

-- Defer keymap setup to ensure mdn is loaded
vim.schedule(function()
  if not is_enabled() then
    return
  end

  local Config = require("mdn.config")

  -- List continuation (only when auto_continue is enabled)
  if Config.lists.auto_continue then
    vim.keymap.set("i", "<CR>", function()
      require("mdn.list").continue("<CR>")
    end, {
      buffer = true,
      desc = "Mdn: Continue list on Enter",
    })

    vim.keymap.set("n", "o", function()
      require("mdn.list").continue("o")
    end, {
      buffer = true,
      desc = "Mdn: Continue list below",
    })

    vim.keymap.set("n", "O", function()
      require("mdn.list").continue("O")
    end, {
      buffer = true,
      desc = "Mdn: Continue list above",
    })
  end

  -- Three-state cycle: blank → bullet → checkbox → toggle
  -- Same key in both Normal and Insert mode
  if Config.mappings.cycle_key ~= "" then
    vim.keymap.set({ "n", "i" }, Config.mappings.cycle_key, function()
      require("mdn.checkbox").cycle()
    end, {
      buffer = true,
      desc = "Mdn: Cycle bullet/checkbox",
    })
  end

  -- Insert-mode indent / outdent
  if Config.mappings.indent_key ~= "" then
    vim.keymap.set("i", Config.mappings.indent_key, function()
      require("mdn.indent").indent()
    end, {
      buffer = true,
      desc = "Mdn: Indent current line",
    })
  end

  if Config.mappings.outdent_key ~= "" then
    vim.keymap.set("i", Config.mappings.outdent_key, function()
      require("mdn.indent").outdent()
    end, {
      buffer = true,
      desc = "Mdn: Outdent current line",
    })
  end
end)