local SharedInGameExplorer = {
	PropertyChanges = {}
}

local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()

local Signal = require(script.Signal)
local Maid = require(script.Maid)
local ValueToString,StringToValue = unpack(require(script.DataConverter))

local clientBlacklist = {
	"PrivateServerOwnerId",
	"PrivateServerId",
	"VIPServerId",
	"VIPServerOwnerId"
}

local function DeepAssign(root, ...)
	for _,tab in pairs({...}) do
		if type(tab) == "table" then
			for i,v in pairs(tab) do
				if type(v) == "table" then
					if type(root[i]) ~= "table" then
						root[i] = {}
					end

					DeepAssign(root[i], v)
				else
					root[i] = v
				end
			end
		end
	end

	return root
end
local function Clone(tab)
	return DeepAssign({}, tab)
end


function SharedInGameExplorer:FindFromPath(path,root)
	local index = 1
	local searchingFor = path[index]
	local foundChild
	while true do
		local children = root.Children
		if not children then
			break
		end
		local found
		for i,child in root.Children do 
			if child.Name == searchingFor then
				root = child
				found = true
				if index == #path then
					foundChild = child
					break
				end
				index += 1
				searchingFor = path[index]
				break
			end
		end
		if not found then
			break
		end
	end
	return foundChild
end

local DataTypesToChildren = {}


DataTypesToChildren.Vector2 = {
	{Name = "X",ValueType = "float",
		ValueFn = function(parent) 
			return parent.Value.X 
		end,
		SetValueFn = function(value,parent)
			if parent.SetValue then
				parent.SetValue(Vector2.new(value,parent.Value.Y))
			end
		end,
	},
	{Name = "Y",ValueType = "float",
		ValueFn = function(parent) 
			return parent.Value.Y 
		end,
		SetValueFn = function(value,parent)
			if parent.SetValue then
				parent.SetValue(Vector2.new(parent.Value.X,value))
			end
		end,
	}
}

DataTypesToChildren.Vector3 = {
	{Name = "X",ValueType = "float",
		ValueFn = function(parent) 
			return parent.Value.X 
		end,
		SetValueFn = function(value,parent)
			if parent.SetValue then
				parent.SetValue(Vector3.new(value,parent.Value.Y,parent.Value.Z))
			end
		end,
	},
	{Name = "Y",ValueType = "float",
		ValueFn = function(parent) 
			return parent.Value.Y 
		end,
		SetValueFn = function(value,parent)
			if parent.SetValue then
				parent.SetValue(Vector3.new(parent.Value.X,value,parent.Value.Z))
			end
		end,
	},
	{Name = "Z",ValueType = "float",
		ValueFn = function(parent)
			return parent.Value.Z 
		end,
		SetValueFn = function(value,parent)
			if parent.SetValue then
				parent.SetValue(Vector3.new(parent.Value.X,parent.Value.Y,value))
			end
		end,
	}
}

DataTypesToChildren.CFrame = {
	{Name = "Position",
		ValueFn = function(parent) 
			return parent.Value.Position 
		end,
		SetValueFn = function(value,parent)
			local cfAngle = parent.Value - parent.Value.Position
			local cf = CFrame.new(value) * cfAngle
			parent.SetValue(cf)
		end,
		ValueType = "Vector3",
		Children = DataTypesToChildren.Vector3
	},
	{Name = "Orientation",ValueType = "Vector3",
		ValueFn = function(parent) 
			local x,y,z = parent.Value:toEulerAnglesYXZ()
			return Vector3.new(math.deg(x),math.deg(y),math.deg(z))
		end,
		SetValueFn = function(value,parent)
			local cfPos = parent.Value.Position
			local ax,ay,az = value.X,value.Y,value.Z
			ax = math.rad(ax)
			ay = math.rad(ay)
			az = math.rad(az)
			local ang = CFrame.fromOrientation(ax,ay,az)
			local cf = CFrame.new(cfPos) * ang 
			parent.SetValue(cf)
		end,
		Children = DataTypesToChildren.Vector3}
}

function SharedInGameExplorer:Open(player,instance,classInfo,remote,clientServerView)
	
	local client = not IsServer
	
	local EventMaid = Maid.new()
	
	if not classInfo then
		warn("Error - No Class Info - ",instance)
		return
	end
	classInfo = Clone(classInfo)
	
	local changeListeners = {}

	local explorer = {}
	local function resolve(list)
		local tab = {}

		--[[ Iterate through each property ]]
		for i,propertyInfo in list do

			local propertyName = propertyInfo.propertyName
			
			
			local success,currentValue
			
			local tags = propertyInfo.tags

			if not propertyInfo.isAttribute then
				--[[ Filter out bad properties and get current value ]]
					
				success,currentValue = pcall(function()
					return instance[propertyName]
				end)
							
				if not success then
					continue
				end
				if client and not clientServerView then
					if table.find(clientBlacklist,propertyName) then
						continue
					end
				end

				if tags and tags.Deprecated then
					continue
				end
			else
				currentValue = propertyInfo.currentValue
			end
		
			
			local valueType = propertyInfo.valueType
			
			
			local success,writeWarning
			if not propertyInfo.isAttribute then
				--[[ Detect if write ]]
				success,writeWarning = pcall(function()
					--local clone = instance:Clone()
					--clone.Parent = game:GetService("CoreGui")
					--clone[propertyName] = currentValue
					--clone:Destroy()
				end)
				
				if clientServerView then
					writeWarning = false
				end
			end
			
			
			local property = {}
			property.isAttribute = propertyInfo.isAttribute
			property.Name = propertyName
			property.ValueType = valueType
			
			if writeWarning or (tags and (tags.NotScriptable or tags.Hidden)) then
				property.ReadOnly = true
			end
			if tags and tags.ReadOnly then
				property.ReadOnly = true
			end

			--[[ Set value to current value ]]
			property.Value = currentValue
			--


			--[[ Get children properties template for a given valueType ]]
			local template = DataTypesToChildren[valueType]
			--

			if template then
				template = Clone(template)

				local function rec(p)
					if not p.Children then 
						return
					end
					for i,child in p.Children do
						child.NotInstanceProp = true
						rec(child)
					end
				end
				for i,child in template do
					child.NotInstanceProp = true
					rec(child)
				end
				property.Children = template
			end

			property.ValueChanged = Signal.new()
			EventMaid:Add(function()
				property.ValueChanged:Destroy()
			end)

			table.insert(tab,property)
			table.insert(changeListeners,{instance,property,propertyName,currentValue,property.ValueChanged})
		end
		return tab
	end
	
	
	local attributes	
	if typeof(instance) == "table" then 
		attributes = instance.AttributesList
		function instance:GetAttribute(i)
			return attributes[i]
		end
		function instance:GetFullName()
			return instance.FullName
		end
	else
		attributes = instance:GetAttributes()
	end
	local attributesInfo = {
		name = "Attributes",
		list = {}
	}
	for i,v in attributes do 
		local property = {propertyName = i,valueType = typeof(v),isAttribute = true,currentValue = v}	
		table.insert(attributesInfo.list,property)
	end
	table.insert(classInfo.Categorized_Properties,attributesInfo)
	
	for i,info in classInfo.Categorized_Properties do
		--[[ For each category list ]]

		local categoryType = info.name
		local properties = info.list
		table.sort(properties,function(a,b)
			return a.propertyName < b.propertyName
		end)
		
		--[[ Set root property to category type with children of property tree ]]
		local property = {Name = categoryType,Children = resolve(properties),IsRoot = true}
		property.IsCollapsed = false
		if property.Children and #property.Children > 0 then
			--[[ If has children, valid ]]
			table.insert(explorer,property)
		end
	end
	
	local function getFullName(child)
		local strPath = {child.Name}
		local parent = child
		while true do
			local nextParent = parent.Parent			
			if parent and not parent.Name then
				break
			end
			if not parent then
				break
			end	
			parent = nextParent
			table.insert(strPath,parent.Name)
		end
		local newPath = {}
		for i = #strPath,1,-1 do 
			table.insert(newPath,strPath[i])
		end
		strPath = newPath
		return strPath
	end
	
	local function recurse(parent)
		--[[ Set value function ]]
		parent.SetValue = function(newValue,refresh)
			if not parent.NotInstanceProp then
				
				local strValue = ValueToString(newValue)
				if strValue then
				
					local instanceFullName = instance:GetFullName()
					local changeList = SharedInGameExplorer.PropertyChanges[instanceFullName]
					if not changeList then
						changeList = {properties = {},attributes = {}}
						SharedInGameExplorer.PropertyChanges[instanceFullName] = changeList
					end
					local list = changeList.properties
					if parent.isAttribute then
						list = changeList.attributes
					end
					list[parent.Name] = strValue
				end
			end
			
			local isAttribute = parent.isAttribute
			if clientServerView then
				local fullName = getFullName(parent)
				if isAttribute then
					remote:FireServer("RequestAttributeChange",fullName,newValue)
				else
					remote:FireServer("RequestPropertyChange",fullName,newValue)
				end
				return
			end
			if not parent.NotInstanceProp then
				--[[ Attempt to set instance property directly ]]
				local success,err = pcall(function()
					if isAttribute then
						instance:SetAttribute(parent.Name,newValue)
					else
						instance[parent.Name] = newValue
					end
					parent.Value = newValue
				end)
				if not success then
					warn(err)
				end
			else
				--[[ Set Value function ]]
				if parent.SetValueFn then
					parent.SetValueFn(newValue,parent.Parent)
				end
			end

			if refresh then
				self:Open(instance)
			end
		end

		--[[ Set current value to valuefunctions result ]]
		if parent.ValueFn and parent.Parent and parent.Parent.Value then
			parent.ValueChanged = Signal.new()
			EventMaid:Add(function()
				parent.ValueChanged:Destroy()
			end)
			parent.Value = parent.ValueFn(parent.Parent)
		end
		--

		if not parent.Children then
			return
		end
		for i,v in parent.Children do 
			if parent.ReadOnly == true then
				v.ReadOnly = true
			end
			v.Parent = parent
			recurse(v)
		end
	end

	EventMaid:Add(RunService.Heartbeat:Connect(function()
		for i,info in changeListeners do
			local instance,property,propertyName,lastValue,valueChanged = unpack(info)
			local isAttribute = property.isAttribute
			
			local currentValue
			if isAttribute then
				currentValue = instance:GetAttribute(propertyName)
			else
				currentValue = instance[propertyName]
			end
			
			if currentValue ~= lastValue then
				property.Value = currentValue
				valueChanged:Fire(currentValue)
				self:updateChildren(property)
				if IsServer then
					remote:FireClient(player,"TreeChangedValue",getFullName(property),currentValue)
				end
			end
			info[4] = currentValue
		end
	end))
	--


	local Tree = {IsCollapsed = false,Children = explorer}

	recurse(Tree)

	return Tree,EventMaid	
end
function SharedInGameExplorer:updateChildren(property)
	--[[ Propagate changes to children ]]
	if not property.Children then
		return
	end
	for i,child in property.Children do
		if child.ValueFn then
			local newValue = child.ValueFn(property)
			child.Value = newValue
			if child.ValueChanged then
				child.ValueChanged:Fire(newValue)
			end
			self:updateChildren(child)
		end
	end
	--
end
return SharedInGameExplorer