local LocalScript = script:FindFirstAncestorWhichIsA("LocalScript")
local Fusion = require(LocalScript:FindFirstChild("Fusion", true))

local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPERTIES = {
	"Name",
}

type ToolbarProperties = {
	Name: string,
	[any]: any,
}

return function(props: ToolbarProperties): LocalScriptToolbar
	local newToolbar = LocalScript:CreateToolbar(props.Name)

	local hydrateProps = table.clone(props)
	for _,propertyName in pairs(COMPONENT_ONLY_PROPERTIES) do
		hydrateProps[propertyName] = nil
	end

	return Hydrate(newToolbar)(hydrateProps)
end
