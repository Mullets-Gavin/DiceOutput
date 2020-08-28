--[[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Print the output in the chat! Set the PlaceId to use it
--]]

--// logic
local Output = {}
Output.Enabled = true
Output.PlaceId = game.PlaceId -- or an ID of a specific place. this is to make grabbing the place ID easier than a game ID
Output.Logs = {}
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
local function CreateMessage(message,enum,extra)
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

if Services['RunService']:IsServer() then
	-- SERVER OUTPUT
	Services['LogService'].MessageOut:Connect(function(message,enum)
		if Output.Enums[enum] and not Services['RunService']:IsStudio() then
			-- filters
			if string.find(string.lower(message), "failed to load") then return end
			-- post
			rEvent:FireAllClients(message,enum)
		end
	end)
elseif Services['RunService']:IsClient() then
	-- CLIENT REMOTE EVENT
	rEvent.OnClientEvent:Connect(function(message,enum)
		CreateMessage(message,enum,'Server')
	end)
	-- CLIENT OUTPUT
	Services['LogService'].MessageOut:Connect(function(message,enum)
		-- filters
		if string.find(string.lower(message), "failed to load") then return end
		-- post
		CreateMessage(message,enum,'Client')
	end)
end

return Output