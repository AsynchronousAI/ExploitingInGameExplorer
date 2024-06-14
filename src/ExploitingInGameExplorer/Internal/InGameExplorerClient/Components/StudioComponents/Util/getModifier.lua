local LocalScript = script:FindFirstAncestorWhichIsA("LocalScript")
local Fusion = require(LocalScript:FindFirstChild("Fusion", true))

local Computed = Fusion.Computed

local unwrap = require(script.Parent.unwrap)
local types = require(script.Parent.types)

type modifierInput = {
	Enabled: types.CanBeState<boolean>?,
	Hovering: types.CanBeState<boolean>?,
	Selected: types.CanBeState<boolean>?,
	Pressed: types.CanBeState<boolean>?,
}

return function(modifierInput: modifierInput): types.Computed<any>
	local isEnabled = modifierInput.Enabled
	local isHovering = modifierInput.Hovering
	local isSelected = modifierInput.Selected
	local isPressed = modifierInput.Pressed

	return Computed(function()
		local isDisabled = not unwrap(isEnabled)
		local isHovering = unwrap(isHovering)
		local isSelected = unwrap(isSelected)
		local isPressed = unwrap(isPressed)
		if isDisabled then
			return "Disabled"
		elseif isSelected then
			return "Selected"
		elseif isPressed then
			return "Pressed"
		elseif isHovering then
			return "Hover"
		end
		return unwrap(modifierInput.Otherwise) or "Default"
	end)
end