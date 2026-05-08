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
  if Config.auto_continue then
    -- Insert mode: <CR> continues the list
    vim.keymap.set("i", "<CR>", function()
      require("mdn.list").continue("<CR>")
    end, {
      buffer = true,
      desc = "Mdn: Continue list on Enter",
    })

    -- Normal mode: o continues the list
    vim.keymap.set("n", "o", function()
      require("mdn.list").continue("o")
    end, {
      buffer = true,
      desc = "Mdn: Continue list below",
    })

    -- Normal mode: O continues the list
    vim.keymap.set("n", "O", function()
      require("mdn.list").continue("O")
    end, {
      buffer = true,
      desc = "Mdn: Continue list above",
    })
  end

  -- Checkbox toggle in Normal mode
  if Config.keymaps.toggle_checkbox ~= "" then
    vim.keymap.set("n", Config.keymaps.toggle_checkbox, function()
      require("mdn.checkbox").toggle()
    end, {
      buffer = true,
      desc = "Mdn: Toggle checkbox",
    })
  end

  -- Checkbox toggle in Insert mode
  if Config.keymaps.toggle_checkbox_insert ~= "" then
    vim.keymap.set("i", Config.keymaps.toggle_checkbox_insert, function()
      require("mdn.checkbox").toggle_expr()
    end, {
      buffer = true,
      desc = "Mdn: Toggle checkbox",
    })
  end
end)
