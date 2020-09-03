--[[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Print the output in the chat! Set the PlaceId to use it
--]]

--// logic
local Output = {}
Output.Enabled = true
Output.PlaceId = game.PlaceId -- or an ID of a specific place. this is to make grabbing the place ID easier than a game ID
Output.Timeout = 3
Output.Logs = {}
Output.Cache = {}
Output.Connections = {}
Output.Filter = {
	['Server'] = '[SERVER]: ';
	['Client'] = '[CLIENT]: ';
	['Studio'] = '[STUDIO]: ';
}
Output.Settings = {
	['Font'] = Enum.Font.SourceSansBold;
	['Size'] = 18;
}
Output.Enums = {
	[Enum.MessageType.MessageError] = Color3.fromRGB(255, 56, 59);
	[Enum.MessageType.MessageOutput] = Color3.fromRGB(78, 187, 255);
	[Enum.MessageType.MessageWarning] = Color3.fromRGB(255, 182, 34);
}

--// services
local Services = setmetatable({}, {__index = function(cache, serviceName)
    cache[serviceName] = game:GetService(serviceName)
    return cache[serviceName]
end})

--// remotes
local Network = script.Network
local rFunc = Network.rFunc
local rEvent = Network.rEvent

--// functions
local function LoadHistory()
	coroutine.wrap(function()
		if Services['RunService']:IsServer() then
			for index,contents in pairs(Services['LogService']:GetLogHistory()) do
				rEvent:FireAllClients(contents['message'],contents['messageType'])
			end
		elseif Services['RunService']:IsClient() then
			for index,contents in pairs(Services['LogService']:GetLogHistory()) do
				Output.CreateMessage(contents['message'],contents['messageType'],'Client')
			end
		end
	end)()
end

function Output.FilterMessage(message)
	if table.find(Output.Cache,string.lower(message)) then return false end
	if string.find(string.lower(message), "failed to load") then return false end
	if string.find(string.lower(message), "unable to download") then return false end
	table.insert(Output.Cache,string.lower(message))
	coroutine.wrap(function()
		wait(Output.Timeout)
		table.remove(Output.Cache,table.find(Output.Cache,string.lower(message)))
	end)()
	return true
end

function Output.CreateMessage(message,enum,extra)
	if not Output.FilterMessage(message) then return end
	if Services['RunService']:IsStudio() then
		if Output.Enums[enum] then
			Output:PostChat(Output.Filter['Studio']..message,enum)
		end
	else
		if Output.Enums[enum] then
			Output:PostChat(Output.Filter[extra]..message,enum)
		end
	end
end

function Output.Hook(func) -- returns dictionary to create text
	if typeof(func) == 'function' then
		table.insert(Output.Connections,func)
	end
	repeat Services['RunService'].Heartbeat:Wait() until #Output.Logs > 1
	for index,contents in pairs(Output.Logs) do
		func(contents)
		Services['RunService'].Heartbeat:Wait()
	end
end

function Output:PostChat(message,enum)
	local contents = {
		['Text'] = message;
		['Color'] = Output.Enums[enum];
		['Font'] = Output.Settings.Font;
		['TextSize'] = Output.Settings.Size;
	}
	for index,func in pairs(Output.Connections) do
		func(contents)
	end
	table.insert(Output.Logs,contents)
	if game.PlaceId ~= Output.PlaceId or not Services['RunService']:IsStudio() or not Output.Enabled then return end
	if Services['RunService']:IsClient() then
		repeat
			Services['RunService'].Heartbeat:Wait()
			local Success = pcall(function()
				Services['StarterGui']:SetCore('ChatMakeSystemMessage', contents)
			end)
		until Success
	end
end

LoadHistory()
if Services['RunService']:IsServer() then
	-- SERVER OUTPUT
	Services['LogService'].MessageOut:Connect(function(message,enum)
		if Output.Enums[enum] and not Services['RunService']:IsStudio() then
			rEvent:FireAllClients(message,enum)
		end
	end)
elseif Services['RunService']:IsClient() then
	-- CLIENT REMOTE EVENT
	rEvent.OnClientEvent:Connect(function(message,enum)
		Output.CreateMessage(message,enum,'Server')
	end)
	-- CLIENT OUTPUT
	Services['LogService'].MessageOut:Connect(function(message,enum)
		Output.CreateMessage(message,enum,'Client')
	end)
end

return Output