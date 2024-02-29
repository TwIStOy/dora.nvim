---@class dora.core.plugin.ExtraPluginOptions
---@field pname? string nix plugin name
---@field gui? "all"|string[] Can be used in which gui environment
---@field actions? dora.core.action.ActionOption[]|fun():dora.core.action.ActionOption[]

---@class dora.core.plugin.PluginOption: dora.core.plugin.ExtraPluginOptions,LazyPluginSpec

---@class dora.core.plugin.Plugin: dora.core.plugin.PluginOption,LazyPlugin
