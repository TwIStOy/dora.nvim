local function install_missing_lazy()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.uv.fs_stat(lazypath) then
    vim.fn.system {
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
    }
  end
  vim.opt.rtp:prepend(lazypath)
end

---@class dora
local M = {}

---@param opts? dora.config.SetupOptions
function M.setup(opts)
  opts = opts or {}

  ---@type dora.config
  local config = require("dora.config")
  ---@type dora.lib
  local lib = require("dora.lib")

  -- set mapleader at very beginning of profile
  vim.api.nvim_set_var("mapleader", " ")

  config.setup(opts)

  local specs = {}
  local packages = config.package.sorted_package()
  local processed = {}
  for _, pkg in ipairs(packages) do
    for _, plug_opts in ipairs(pkg:plugins()) do
      specs[#specs + 1] = lib.lazy.fix_gui_cond(plug_opts, processed)
    end
  end

  install_missing_lazy()

  lib.lazy.setup_on_lazy_plugins(function()
    for _, _plugin in pairs(require("lazy.core.config").spec.plugins) do
      local plugin = _plugin --[[@as dora.core.plugin.Plugin]]
      if
        (plugin._.kind ~= "disabled" or plugin._.kind ~= "clean")
        and plugin.actions ~= nil
      then
        -- inject keys defined in actions
        ---@type LazyKeysSpec[]
        local all_keys
        if plugin.keys == nil then
          all_keys = {}
        elseif vim.tbl_isarray(plugin.keys) then
          all_keys = plugin.keys --[[ @as LazyKeysSpec[] ]]
        else
          all_keys = { plugin.keys }
        end
        ---@type dora.core.action.ActionOption[]
        local actions
        if type(plugin.actions) == "function" then
          actions = plugin.actions()
        elseif vim.tbl_isarray(plugin.actions) then
          actions = plugin.actions --[[ @as dora.core.action.ActionOption[] ]]
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
  end)

  local lazy_opts = {
    spec = specs,
    change_detection = { enabled = false },
    install = {
      missing = true,
    },
    performance = {
      cache = { enabled = true },
      install = { colorscheme = { "tokyonight", "habamax" } },
      rtp = {
        paths = {
          -- dora.nvim default install path
          vim.fn.stdpath("data") .. "/dora.nvim",
        },
        disabled_plugins = {
          "gzip",
          "matchit",
          "matchparen",
          "netrwPlugin",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
          "spellfile",
        },
      },
    },
  }

  if lib.nix.has_nix_store() then
    lazy_opts.dev = {
      path = function(plugin)
        local pname = lib.nix.normalize_plugin_pname(plugin)
        local resolved_path = config.nix.resolve_pkg(pname)
        if resolved_path ~= nil then
          return resolved_path
        end
        local paths = lib.nix.search_nix_store(pname)
        if #paths > 1 then
          vim.notify(
            "Found multiple paths matches "
              .. pname
              .. " in nix store. "
              .. "Use the first match now, you can specify the package's version later.",
            vim.log.levels.WARN,
            {
              title = "dora.nvim",
            }
          )
        end
        if #paths > 0 then
          return paths[1]
        end
        return "/dev/null/must_not_exists"
      end,
      patterns = { "/" }, -- hack to make sure all plugins are `dev`
      fallback = true,
    }
  end

  if opts.lazy ~= nil then
    if type(opts.lazy) == "function" then
      opts.lazy = opts.lazy(lazy_opts)
    else
      lazy_opts = vim.tbl_deep_extend("force", lazy_opts, opts.lazy)
    end
  end

  require("lazy").setup(lazy_opts)

  lib.lazy.fix_valid_fields()

  for _, pkg in ipairs(packages) do
    pkg:setup()
  end
end

return M
