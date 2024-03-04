---@class dora.utils
local M = {}

---@type dora.lib.CacheManager
local which_cache = require("dora.lib.func").new_cache_manager()

---@param name string
---@return string
function M.which_binary(name)
  return which_cache:ensure(name, function()
    if type(name) ~= "string" then
      return name
    end

    ---@type dora.lib
    local lib = require("dora.lib")
    ---@type dora.config.nix
    local nix = require("dora.config.nix")

    -- resolve binary from nix pkgs config in nixos or nix-darwin
    if lib.nix.has_nix_store() then
      local res = nix.resolve_bin(name)
      if res ~= name then
        return res
      end
    end

    -- try resolve binary binaries from mason
    if lib.lazy.has("mason.nvim") then
      local mason_root = require("mason.settings").current.install_root_dir
      local path = mason_root .. "/bin/" .. name
      if vim.fn.executable(path) == 1 then
        return path
      end
    end

    return name
  end)
end

---NOTE: opts will be modified in place
---@param opts table
---@param default_value string
---@param ... string
function M.fix_opts_cmd(opts, default_value, ...)
  local cmd = vim.F.if_nil(vim.tbl_get(opts, ...), default_value)
  cmd = M.which_binary(cmd)
  require("dora.lib.tbl").tbl_set(opts, cmd, ...)
  return opts
end

return M
