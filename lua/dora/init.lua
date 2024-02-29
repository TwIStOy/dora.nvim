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
  ---@type dora.config
  local config = require("dora.config")
  ---@type dora.core
  local core = require("dora.core")
  ---@type dora.lib
  local lib = require("dora.lib")

  -- set mapleader at very beginning of profile
  vim.api.nvim_set_var("mapleader", " ")

  config.setup(opts or {})

  local specs = {}
  local packages = config.package.sorted_package()
  for _, pkg in ipairs(packages) do
    for _, plug_opts in ipairs(pkg:plugins()) do
      specs[#specs + 1] = plug_opts
    end
  end

  install_missing_lazy()

  lib.lazy.setup_on_lazy_plugins()

  require("lazy").setup {
    spec = specs,
    change_detection = { enabled = false },
    install = {
      missing = true,
    },
    dev = {
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

  lib.lazy.fix_valid_fields()

  for _, pkg in ipairs(packages) do
    pkg:setup()
  end
end

return M
