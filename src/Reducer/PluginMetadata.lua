local Plugin = script.Parent.Parent
local Llama = require(Plugin.Packages.Llama)

local INIT_STATE = {
	isDevMode = false,
	build = "STABLE",
}

return function(state, action)
	state = state or INIT_STATE

	if action.type == "SET_PLUGIN_METADATA" then
		return Llama.Dictionary.merge(state, action.payload)
	end

	return state
end
