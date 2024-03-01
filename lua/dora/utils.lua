---@class dora.utils
local M = {}

---@type dora.lib.CacheManager
local which_cache = require("lib.func").new_cache_manager()

---@param name string
---@return string
function M.which_binary(name)
  return which_cache:ensure(name, function()
    ---@type dora.lib
    local lib = require("dora.lib")
    ---@type dora.config.nix
    local nix = require("dora.config.nix")

    -- resolve binary from nix pkgs config in nixos or nix-darwin
    if lib.nix.has_nix_store() then
      local res = nix.resolve_bin(name)
      if res == name then
        return res
      end
    end

    -- try resolve binary binaries from mason
    if lib.lazy.has("mason.nvim") then
      local mason_root = require("mason.settings").current.install_root_dir
      local path = mason_root .. "/bin/" .. name
      if vim.fn.executable(path) then
        return path
      end
    end

    return name
  end)
end

return M
