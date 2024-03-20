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

local function guess_name(plugin)
  -- if has '/', use the second part as name
  if plugin.name ~= nil then
    return plugin.name
  elseif string.find(plugin[1], "/") then
    return string.match(plugin[1], ".*/(.*)")
  else
    return plugin[1]
  end
end

---@param plugin dora.core.plugin.PluginOption
---@return dora.core.plugin.PluginOption
function M.fix_gui_cond(plugin, processed)
  local current_gui = require("dora.lib.vim").current_gui()

  local name = guess_name(plugin)
  if processed[name] then
    return plugin
  end
  processed[name] = true

  --- in TUI, always true
  if current_gui == nil then
    return plugin
  end

  local gui = plugin.gui

  if gui == "all" then
    return plugin
  end

  if gui == nil then
    plugin.cond = function()
      return false
    end
    return plugin
  end

  local old_cond = plugin.cond or function()
    return true
  end

  if type(gui) == "string" then
    plugin.cond = function(...)
      return old_cond(...) and current_gui == gui
    end
  elseif type(gui) == "table" and vim.tbl_isarray(gui) then
    plugin.cond = function(...)
      return old_cond(...) and vim.list_contains(gui, current_gui)
    end
  else
    vim.notify(
      "Invalid gui field in "
        .. vim.inspect(plugin)
        .. ", it should be string or table, but got "
        .. vim.inspect(gui),
      vim.log.levels.WARN,
      {
        title = "dora.nvim",
      }
    )
    return plugin
  end
end

function M.setup_on_lazy_plugins(callback)
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyPlugins",
    callback = callback,
  })
end

return M
