---@class dora.lib.nix
local M = {}

---@type fun():string[]
local get_all_packages = require("dora.lib.func").call_once(function()
  local obj = vim
    .system(
      { "nix-store", "--query", "--requisites", "/run/current-system" },
      { text = true }
    )
    :wait()
  if obj.code == 0 then
    ---@type string[]
    local lines = vim.split(obj.stdout or "", "\n", { trimempty = true })
    local res = {}
    for _, value in ipairs(lines) do
      if value:find("vimplugin-") then
        res[#res + 1] = value
      end
    end
    return res
  else
    return {}
  end
end)

---@type dora.lib.CacheManager
local search_cache = require("dora.lib.func").new_cache_manager()

---@param query string
---@return string[]
function M.search_nix_store(query)
  local packages = get_all_packages()
  return search_cache:ensure(query, function()
    local results = {}
    for _, package in ipairs(packages) do
      if package:find(query, 1, true) then
        table.insert(results, package)
      end
    end
    return results
  end)
end

---@param plugin dora.core.plugin.PluginOption
---@return string
function M.normalize_plugin_pname(plugin)
  if plugin.pname == nil then
    return plugin.name
  else
    if type(plugin.pname) == "function" then
      return plugin.pname(plugin)
    elseif type(plugin.pname) == "string" then
      return plugin.pname
    else
      error("invalid pname type")
    end
  end
end

---@return boolean
M.has_nix_store = require("dora.lib.func").call_once(function()
  return vim.fn.executable("nix-store") == 1
end)

---@return boolean
M.is_nixos = require("dora.lib.func").call_once(function()
  local version = vim.uv.os_uname().version
  return version:find("NixOs", 1, true) ~= nil
end)

return M
