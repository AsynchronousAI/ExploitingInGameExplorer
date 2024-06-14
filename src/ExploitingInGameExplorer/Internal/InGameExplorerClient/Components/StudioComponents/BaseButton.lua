-- Roact version by @sircfenner
-- Ported to Fusion by @YasuYoshida

local LocalScript = script:FindFirstAncestorWhichIsA("LocalScript")
local Fusion = require(LocalScript:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local BoxBorder = require(StudioComponents.BoxBorder)

local getMotionState = require(StudioComponentsUtil.getMotionState)
local themeProvider = require(StudioComponentsUtil.themeProvider)
local getModifier = require(StudioComponentsUtil.getModifier)
local stripProps = require(StudioComponentsUtil.stripProps)
local constants = require(StudioComponentsUtil.constants)
local getState = require(StudioComponentsUtil.getState)
local unwrap = require(StudioComponentsUtil.unwrap)
local types = require(StudioComponentsUtil.types)

local New = Fusion.New
local Value = Fusion.Value
local Children = Fusion.Children
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPERTIES = {
	"TextColorStyle",
	"BackgroundColorStyle",
	"BorderColorStyle",
	"Activated",
	"Hover",
	"HoverEnd",
	"Enabled",
}


export type BaseButtonProperties = {
	Activated: (() -> nil)?,
	Hover: (() -> nil)?,
	HoverEnd: (() -> nil)?,
	Enabled: (boolean | types.StateObject<boolean>)?,
	TextColorStyle: styleGuideColorInput,
	BackgroundColorStyle: styleGuideColorInput,
	BorderColorStyle: styleGuideColorInput,
	[any]: any,
}

return function(props: BaseButtonProperties): TextButton
	local isEnabled = getState(props.Enabled, true)
	local isHovering = Value(false)
	local isPressed = Value(false)

	local modifier = getModifier({
		Enabled = isEnabled,
		Selected = props.Selected,
		Pressed = isPressed,
		Hovering = isHovering,
	})

	local newBaseButton = BoxBorder {
		Color = getMotionState(themeProvider:GetColor(props.BorderColorStyle or "CheckedFieldBorder", modifier), "Spring", 40),

		[Children] = New "TextButton" {
			Name = "BaseButton",
			Size = UDim2.fromScale(1, 1),
			Text = "Button",
			Font = themeProvider:GetFont("Default"),
			TextSize = constants.TextSize,
			TextColor3 = getMotionState(themeProvider:GetColor(props.TextColorStyle or "ButtonText", modifier), "Spring", 40),
			BackgroundColor3 = getMotionState(themeProvider:GetColor(props.BackgroundColorStyle or "Button", modifier), "Spring", 40),
			AutoButtonColor = false,

			[OnEvent "InputBegan"] = function(inputObject)
				if not unwrap(isEnabled) then
					return
				elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
					isHovering:set(true)
				elseif inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
					isPressed:set(true)
				end
			end,
			[OnEvent "InputEnded"] = function(inputObject)
				if not unwrap(isEnabled) then
					return
				elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
					isHovering:set(false)
				elseif inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
					isPressed:set(false)
				end
			end,
			[OnEvent "Activated"] = (function()
				if props.Activated then
					return function()
						if unwrap(isEnabled, false) then
							props.Activated()
						end
					end
				end
			end)(),
			[OnEvent "MouseEnter"] = (function()
				if props.Activated then
					return function()
						if props.Hover then props.Hover() end
					end
				end
			end)(),
			[OnEvent "MouseLeave"] = (function()
				if props.HoverEnd then
					return function()
						if props.HoverEnd then props.HoverEnd() end
					end
				end
			end)(),
		}
	}

	local hydrateProps = stripProps(props, COMPONENT_ONLY_PROPERTIES)
	return Hydrate(newBaseButton)(hydrateProps)
end