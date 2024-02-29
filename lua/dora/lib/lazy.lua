---@class dora.lib.lazy
local M = {}

---@param plugin string
function M.has(plugin)
  return require("lazy.core.config").spec.plugins[plugin] ~= nil
end

---@param plugin string
---@return boolean
function M.loaded(plugin)
  local p = require("lazy.core.config").spec.plugins[plugin]
  if p == nil then
    return false
  end
  return not not p._.loaded
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

function M.setup_on_lazy_plugins(callback)
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyPlugins",
    callback = callback,
  })
end

return M
