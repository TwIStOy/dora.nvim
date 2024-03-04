---@type dora.core.plugin.PluginOption
return {
  "ibhagwan/fzf-lua",
  dependencies = {
    "nvim-web-devicons",
  },
  opts = {},
  config = function(_, opts)
    ---@type dora.utils
    local utils = require("dora.utils")
    opts = opts or {}

    local bins = {
      { "fzf", { "fzf_bin" } },
      { "cat", { "previewers", "cat", "cmd" } },
      { "bat", { "previewers", "bat", "cmd" } },
      { "head", { "previewers", "head", "cmd" } },
    }

    for _, bin in ipairs(bins) do
      utils.fix_opts_cmd(opts, bin[1], unpack(bin[2]))
    end

    require("fzf-lua").setup(opts)
  end,
}
