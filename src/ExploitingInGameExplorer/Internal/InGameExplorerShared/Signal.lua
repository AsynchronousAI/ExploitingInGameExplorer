local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

--

local ConnectionToListItem = setmetatable({}, { __mode = "kv" })

function AddListItem(signal, callback)
	local listItem = { Signal = signal, Callback = callback, Last = signal.Last }
	
	if listItem.Last then listItem.Last.Next = listItem end
	signal.Last = listItem
	
	return listItem
end

function DisconnectListItem(listItem)
	if listItem.Signal.Last == listItem then listItem.Signal.Last = listItem.Last end
	if listItem.Last then listItem.Last.Next = listItem.Next end
	if listItem.Next then listItem.Next.Last = listItem.Last end
	listItem.Callback = nil
end

--

function Signal.new()
	return setmetatable({ Last = nil }, Signal)
end

function Signal:Connect(fn)
	if self.Killed then return end
	
	local con = setmetatable({ Connected = true }, Connection)
	ConnectionToListItem[con] = AddListItem(self, fn)
	
	return con
end

function Signal:Wait()
	if self.Killed then return coroutine.yield() end
	
	AddListItem(self, coroutine.running())
	
	return coroutine.yield()
end

function Signal:Fire(...)
	if self.Killed then return end
	
	local listItem = self.Last
	
	while listItem do
		local callback = listItem.Callback
		local callbackType = typeof(callback)
		
		if callbackType == "thread" then
			DisconnectListItem(listItem)
			task.spawn(callback, ...)
		elseif callbackType == "function" then
			task.spawn(callback, ...)
		end
		
		listItem = listItem.Last
	end
end

function Signal:FireDeferred(...)
	task.defer(self.Fire, self, ...) -- yay?
end

function Signal:Destroy()
	if self.Killed then return end
	
	self.Killed = true
	self.Last = nil
end

Signal.connect = Signal.Connect
Signal.wait = Signal.Wait

--

function Connection:GetOnDisconnectSignal()
	if not self.DisconnectSignal then
		self.DisconnectSignal = Signal.new()
	end
	
	return self.DisconnectSignal
end

function Connection:Disconnect()
	if self.Connected then
		self.Connected = false
		
		local listItem = ConnectionToListItem[self]
		if listItem then
			ConnectionToListItem[self] = nil
			DisconnectListItem(listItem)
		end
		
		if self.DisconnectSignal then
			self.DisconnectSignal:Fire()
			self.DisconnectSignal:Destroy()
		end
	end
end

Connection.disconnect = Connection.Disconnect
Connection.Destroy = Connection.Disconnect

--

return Signal