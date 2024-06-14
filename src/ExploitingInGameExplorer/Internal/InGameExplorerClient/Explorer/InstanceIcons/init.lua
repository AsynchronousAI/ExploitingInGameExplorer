local HttpService = game:GetService("HttpService")
local JSON = require(script.JSON)
return function(className,iconImage)
	local info = JSON[className] or JSON["Folder"]
	local x,y = info.x,info.y
	iconImage.Image = "http://www.roblox.com/asset/?id=15288945291"
	iconImage.ImageRectSize = Vector2.new(16,16)
	iconImage.ImageRectOffset = Vector2.new(x,y)
end