local types = require(script.Parent.types)

type computedOrValue = types.Computed<Color3> | types.Value<Color3>

local LocalScript = script:FindFirstAncestorWhichIsA("LocalScript")
local Fusion = require(LocalScript:FindFirstChild("Fusion", true))

local unwrap = require(script.Parent.unwrap)

local Computed = Fusion.Computed
local Value = Fusion.Value

local currentTheme = {}
local themeProvider = {
	Theme = Value("Dark"),
	Fonts = {
		Default = Enum.Font.SourceSans,
		SemiBold = Enum.Font.SourceSansSemibold,
		Bold = Enum.Font.SourceSansBold,
		Black = Enum.Font.GothamBlack,
		Mono = Enum.Font.Code,
	},
	IsDark = Value(true),
}

local getColor = require(script.themeGetColor)



function themeProvider:GetColor(studioStyleGuideColor: styleStyleGuideColor, studioStyleGuideModifier: styleGuideModifier?): computedOrValue
		
	local hasState = (unwrap(studioStyleGuideModifier, false) ~= studioStyleGuideModifier) or (unwrap(studioStyleGuideColor, false) ~= studioStyleGuideColor)

	local function isCorrectType(value, enumType)
		local unwrapped = unwrap(value, false)
		local isState = unwrapped ~= value and unwrapped~=nil
		assert((value==nil or isState) or (typeof(value)=="EnumItem" and value.EnumType==enumType), "Incorrect type")
	end


	local unwrappedColor = unwrap(studioStyleGuideColor, false)
	local unwrappedModifier = unwrap(studioStyleGuideModifier, false)

	if not currentTheme[unwrappedColor] then
		currentTheme[unwrappedColor] = {}
	end

	local themeValue = (function()
		local styleGuideModifier = if unwrappedModifier~=nil then unwrappedModifier else "Default"

		local existingValue = currentTheme[unwrappedColor][styleGuideModifier]
		if existingValue then
			return existingValue
		end

		local newThemeValue = Value(getColor(unwrappedColor, styleGuideModifier))
		currentTheme[unwrappedColor][styleGuideModifier] = newThemeValue

		return newThemeValue
	end)()

	return if not hasState then themeValue else Computed(function()
		local currentColor = unwrap(studioStyleGuideColor)
		local currentModifier = unwrap(studioStyleGuideModifier)
		local currentValueState = self:GetColor(currentColor, currentModifier)
		return currentValueState:get()
	end)
end

function themeProvider:GetFont(fontName: (string | types.StateObject<string>)?): types.Computed<Enum.Font>
	return Computed(function()
		local givenFontName = unwrap(fontName)
		local fontToGet = self.Fonts.Default
		if givenFontName~=nil and self.Fonts[givenFontName] then
			fontToGet = self.Fonts[givenFontName]
		end
		return unwrap(fontToGet)
	end)
end

local function updateTheme()
	--for studioStyleGuideColor, styleGuideModifiers: {Enum.StudioStyleGuideModifier} in pairs(currentTheme) do
	--	for studioStyleGuideModifier, valueState in pairs(styleGuideModifiers) do
	--		valueState:set(getColor(studioStyleGuideColor, studioStyleGuideModifier))
	--	end
	--end
	themeProvider.Theme:set("Dark")

	local _,_,v = getColor("MainBackground"):ToHSV()
	themeProvider.IsDark:set(v<=0.6)
end

do
	updateTheme()
end

return themeProvider
