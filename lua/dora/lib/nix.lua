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
    return vim.split(obj.stdout or "", "\n", { trimempty = true })
  else
    return {}
  end
end)

---@type dora.lib.CacheManager
local search_cache = require("dora.lib.func").new_cache_manager()

---@param query string
---@return string[]
function M.search_nix_store(query)
  return search_cache:ensure(query, function()
    local packages = get_all_packages()
    local results = {}
    for _, package in ipairs(packages) do
      if package:find(query) then
        table.insert(results, package)
      end
    end
    return results
  end)
end

return M
