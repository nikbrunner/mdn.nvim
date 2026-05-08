-- Mdn.nvim user commands.
-- The require() is inside callbacks — the main module is only loaded
-- when the user actually invokes a command (lazy-loading).

local sub_cmds = {
  toggle = function()
    require("mdn").toggle_checkbox()
  end,
}

local sub_cmds_keys = {}
for k, _ in pairs(sub_cmds) do
  table.insert(sub_cmds_keys, k)
end

local function main_cmd(opts)
  local sub_cmd = sub_cmds[opts.args]
  if sub_cmd == nil then
    vim.notify("Mdn: unknown subcommand: " .. tostring(opts.args), vim.log.levels.ERROR, { title = "mdn.nvim" })
  else
    sub_cmd()
  end
end

vim.api.nvim_create_user_command("Mdn", main_cmd, {
  nargs = "?",
  desc = "Mdn: Markdown utility commands",
  complete = function(arg_lead, _, _)
    return vim
      .iter(sub_cmds_keys)
      :filter(function(sub_cmd)
        return sub_cmd:find(arg_lead) ~= nil
      end)
      :totable()
  end,
})
