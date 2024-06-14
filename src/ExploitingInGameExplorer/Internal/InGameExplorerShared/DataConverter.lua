local function CFrameToString(cframe)
	local ax, ay, az = cframe:ToOrientation()
	return string.format("CFrame(%s,%s,%s,%s,%s,%s)",cframe.X, cframe.Y, cframe.Z, ax, ay, az)
end
local function Vector3ToString(vec)
	local x, y, z = vec.x,vec.y,vec.z
	return string.format("Vector3(%s,%s,%s)",x,y,z)
end
local function Vector2ToString(vec)
	local x, y = vec.x,vec.y
	return string.format("Vector2(%s,%s)",x,y)
end
local function ColorToString(color)
	local r,g,b = color.r,color.g,color.b
	return string.format("Color(%s,%s,%s)",r * 255,g * 255,b * 255)
end

local function StringToCFrame(cframe)
	local x,y,z,ax,ay,az = cframe:match("CFrame%((.-),(.-),(.-),(.-),(.-),(.-)%)")
	return CFrame.new(x,y,z) * CFrame.Angles(ax,ay,az)
end
local function StringToVector3(vector3)
	local x,y,z = vector3:match("Vector3%((.-),(.-),(.-)%)")
	return Vector3.new(x,y,z)
end
local function StringToVector2(vector2)
	local x,y = vector2:match("Vector2%((.-),(.-)%)")
	return Vector2.new(x,y)
end
local function StringToColor(color)
	local r,g,b = color:match("Color%((.-),(.-),(.-)%)")
	return Color3.fromRGB(r,g,b)
end
local function StringToBool(bool)
	local val = bool:match("Bool%((.+)%)")
	if val == "true" then
		return true
	else
		return false
	end
end

local function StringToValue(str)
	if str:match("CFrame") then
		return StringToCFrame(str)
	elseif str:match("Vector3") then
		return StringToVector3(str)
	elseif str:match("Vector2") then
		return StringToVector2(str)
	elseif str:match("Color") then 
		return StringToColor(str)
	elseif str:match("Bool") then
		return StringToBool(str)
	else
		return str
	end
end
local function ValueToString(value)
	
	local typeOf = typeof(value)

	if typeOf == "Instance" then 
		return
	end
		
	if typeOf == "CFrame" then
		return CFrameToString(value)
	elseif typeOf == "Vector3" then
		return Vector3ToString(value)
	elseif typeOf == "Vector2" then
		return Vector2ToString(value)
	elseif typeOf == "Color3" then
		return ColorToString(value)
	elseif typeOf == "EnumItem" then
		return value.Name
	elseif typeOf == "boolean" then
		return string.format("Bool(%s)",tostring(value))
	elseif tostring(value) then
		return tostring(value)
	end
end

return {ValueToString,StringToValue}