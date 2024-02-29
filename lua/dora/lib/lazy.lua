---@class dora.lib.lazy
local M = {}

---@param plugin string
function M.has(plugin)
  return require("lazy.core.config").spec.plugins[plugin] ~= nil
end

---@param name string
function M.opts(name)
  local plugin = require("lazy.core.config").plugins[name]
  if not plugin then
    return {}
  end
  local Plugin = require("lazy.core.plugin")
  return Plugin.values(plugin, "opts", false)
end

-- event: LazyPlugins

M.fix_valid_fields = require("dora.lib.func").call_once(function()
  local health = require("lazy.health")
  --- pname: package name
  health.valid[#health.valid + 1] = "pname"
  --- actions: exported actions
  health.valid[#health.valid + 1] = "actions"
  --- gui: can be used in which kind of GUI
  health.valid[#health.valid + 1] = "gui"
end)

---@param plugin dora.core.plugin.PluginOption
function M.fix_gui_cond(plugin)
  local current_gui = require("lazy.lib.vim").current_gui()
  --- in TUI, always true
  if current_gui == nil then
    return true
  end

  local gui = plugin.gui
  if gui == nil then
    return false
  end

  if gui == "all" then
    return true
  end

  if type(gui) == "string" then
    return current_gui == plugin.gui
  elseif type(gui) == "table" and vim.tbl_isarray(gui) then
    return vim.list_contains(gui, current_gui)
  else
    vim.notify(
      "Invalid gui field in "
        .. plugin.name
        .. ", it should be string or table, but got "
        .. vim.inspect(gui),
      vim.log.levels.WARN,
      {
        title = "dora.nvim",
      }
    )
  end

  return false
end

function M.setup_on_lazy_plugins()
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyPlugins",
    callback = function()
      for _, _plugin in pairs(require("lazy.core.config").spec.plugins) do
        local plugin = _plugin --[[@as LazyPlugin]]
        if
          (plugin._.kind ~= "disabled" or plugin._.kind ~= "clean")
          and plugin.actions ~= nil
        then
          -- inject keys defined in actions
          local all_keys
          if plugin.keys == nil then
            all_keys = {}
          elseif vim.tbl_isarray(plugin.keys) then
            all_keys = plugin.keys
          else
            all_keys = { plugin.keys }
          end
          local actions
          if type(plugin.actions) == "function" then
            actions = plugin.actions()
          elseif vim.tbl_isarray(plugin.actions) then
            actions = plugin.actions
          else
            actions = { plugin.actions }
          end
          for _, action_spec in ipairs(actions) do
            local action = require("dora.core.action").new_action(action_spec)
            vim.list_extend(all_keys, action:into_lazy_keys())
          end
          plugin.keys = all_keys
        end
      end
    end,
  })
end

return M
