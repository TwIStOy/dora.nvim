---@type dora.core.plugin.PluginOption
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  opts = function()
    ---@type dora.config
    local config = require("dora.config")

    return {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
        },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = config.icon.predefined_icon(
              "DiagnosticError",
              1
            ),
            [vim.diagnostic.severity.WARN] = config.icon.predefined_icon(
              "DiagnosticWarn",
              1
            ),
            [vim.diagnostic.severity.INFO] = config.icon.predefined_icon(
              "DiagnosticInfo",
              1
            ),
            [vim.diagnostic.severity.HINT] = config.icon.predefined_icon(
              "DiagnosticHint",
              1
            ),
          },
        },
      },
      inlay_hints = {
        enabled = false,
      },
      capabilities = {},
      servers = {
        opts = {},
        setup = {},
      },
    }
  end,
  config = function(_, opts)
    ---@type dora.lib
    local lib = require("dora.lib")

    vim.diagnostic.config(vim.deepcopy(opts.diagnostic))

    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      lib.func.require_then("cmp_nvim_lsp", function(cmp_nvim_lsp)
        return cmp_nvim_lsp.default_capabilities()
      end) or {},
      opts.capabilities or {}
    )

    local function get_default_cmd(server)
      local default_config =
        require("lspconfig.server_configurations." .. server).default_config
      return default_config.cmd
    end

    ---@param cmd string[]
    local function try_to_replace_executable_from_nix(cmd)
      local executable = cmd[1]
      ---@type dora.config
      local config = require("dora.config")
      local new_executable = config.nix.resolve_bin(executable)
      return { new_executable, unpack(cmd, 2) }
    end

    ---@param server string
    local function setup_server(server)
      local server_opts = opts.servers.opts[server] or {}
      local server_setup = opts.servers.setup[server]
      local common_setup = opts.servers.setup["*"]

      server_opts = vim.tbl_deep_extend("force", {
        capabilities = vim.deepcopy(capabilities),
      }, server_opts)

      if server_opts.cmd ~= nil then
        server_opts.cmd = try_to_replace_executable_from_nix(server_opts.cmd)
      else
        server_opts.cmd =
          try_to_replace_executable_from_nix(get_default_cmd(server))
      end

      if server_setup ~= nil and server_setup(server, server_opts) then
        return
      elseif common_setup and common_setup(server, server_opts) then
        return
      else
        require("lspconfig")[server].setup(server_opts)
      end
    end

    for server, _ in pairs(opts.servers.opts) do
      setup_server(server)
    end
  end,
}
