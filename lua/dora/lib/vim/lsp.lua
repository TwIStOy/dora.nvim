---@class dora.lib.vim.lsp
local M = {}

---Try to get the root of the current LSP client
---@param bufnr? number
---@return string?, string?
function M.get_lsp_root(bufnr)
  bufnr = vim.F.if_nil(bufnr, 0)
  local buf_ft = vim.api.nvim_get_option_value("filetype", {
    buf = bufnr,
  })
  ---@type lsp.Client[]
  local clients = vim.lsp.get_clients {
    bufnr = bufnr,
  }
  if #clients == 0 then
    return nil
  end

  for _, value in ipairs(clients) do
    local filetypes = vim.F.if_nil(value.config.filetypes, {})
    if vim.tbl_contains(filetypes, buf_ft) then
      return value.config.root_dir, value.name
    end
  end

  return nil
end

return M
