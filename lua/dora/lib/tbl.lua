---@class dora.lib.tbl
local M = {}

---@param t table
---@param ... string
function M.optional_field(t, ...)
  local keys = { ... }
  local now = t
  for _, key in ipairs(keys) do
    if now[key] == nil then
      return nil
    end
    now = now[key]
  end
  return now
end

---Reverse given list-like table in place.
---NOTE: this mutates the given table.
---@generic T
---@param lst T[]
function M.list_reverse(lst)
  for i = 1, math.floor(#lst / 2) do
    local j = #lst - i + 1
    lst[i], lst[j] = lst[j], lst[i]
  end
end

---@param t table
---@param keys string[]
---@return table
function M.filter_out_keys(t, keys)
  local res = {}
  vim.tbl_add_reverse_lookup(keys)
  for k, v in pairs(t) do
    if keys[k] ~= nil then
      res[k] = v
    end
  end
  return res
end

---@param tbl any
---@return any[]
function M.flatten_array(tbl)
  if type(tbl) ~= "table" then
    return { tbl }
  end

  if vim.tbl_isarray(tbl) then
    local res = {}
    for _, value in ipairs(tbl) do
      local inner_value = M.flatten_array(value)
      res = vim.list_extend(res, inner_value)
    end
    return res
  else
    return { tbl }
  end
end

---@generic T
---@param tbl T[]
---@param fn fun(T, T):T
---@param acc T
function M.foldl(tbl, fn, acc)
  for _, v in ipairs(tbl) do
    acc = fn(acc, v)
  end
  return acc
end

---@generic T
---@param tbl T[]
---@param fn fun(T, T):T
---@param acc T
function M.foldr(tbl, fn, acc)
  for i = #tbl, 1, -1 do
    acc = fn(tbl[i], acc)
  end
  return acc
end

return M
