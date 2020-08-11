--[[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Print the output in the chat! Set the PlaceId to use it
--]]

--// logic
local Output = {}
Output.PlaceId = game.PlaceId -- or an ID of a specific place. this is to make grabbing the place ID easier than a game ID
Output.Logs = {}
Output.Settings = {
	['Font'] = Enum.Font.SourceSansBold;
	['Size'] = 19;
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
function Output:PostChat(message,enum)
	if game.PlaceId ~= Output.PlaceId and not Services['RunService']:IsStudio() then return end
	if Services['RunService']:IsClient() then
		repeat
			Services['RunService'].RenderStepped:Wait()
			local Success = pcall(function()
				Services['StarterGui']:SetCore('ChatMakeSystemMessage', {
					Text = message;
					Color = Output.Enums[enum];
					Font = Output.Settings.Font;
					TextSize = Output.Settings.Size;
				})
			end)
		until Success
	end
end

local function CreateMessage(message,enum,extra)
	if Services['RunService']:IsStudio() then
		if Output.Enums[enum] then
			Output:PostChat('[STUDIO]: '..message,enum)
		end
	else
		if Output.Enums[enum] then
			Output:PostChat('['..extra..']: '..message,enum)
		end
	end
end

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
		CreateMessage(message,enum,'SERVER')
	end)
	-- CLIENT OUTPUT
	Services['LogService'].MessageOut:Connect(function(message,enum)
		CreateMessage(message,enum,'CLIENT')
	end)
end

return Output