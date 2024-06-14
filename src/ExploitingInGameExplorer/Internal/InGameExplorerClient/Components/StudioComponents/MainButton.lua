-- Roact version by @sircfenner
-- Ported to Fusion by @YasuYoshida

local LocalScript = script:FindFirstAncestorWhichIsA("LocalScript")
local Fusion = require(LocalScript:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local Button = require(StudioComponents.Button)

local Children = Fusion.Children
local Hydrate = Fusion.Hydrate
local New = Fusion.New

local baseProperties = {
	TextColorStyle = "DialogMainButtonText",
	BackgroundColorStyle = "DialogMainButton",
	BorderColorStyle = "ButtonBorder",
	Name = "MainButton",
}

return function(props: Button.ButtonProperties): TextButton
	for index,value in pairs(baseProperties) do
		if props[index]==nil then
			props[index] = value
		end
	end
	return Button(props)
end