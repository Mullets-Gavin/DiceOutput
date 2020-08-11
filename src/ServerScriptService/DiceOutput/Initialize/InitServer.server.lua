--// services
local LoadLibrary = require(game:GetService('ReplicatedStorage'):WaitForChild('PlayingCards'))
local Services = setmetatable({}, {__index = function(cache, serviceName)
    cache[serviceName] = game:GetService(serviceName)
    return cache[serviceName]
end})

--// functions
local Initialize = script.Parent
local InitClient = Initialize:FindFirstChild('InitClient')
if InitClient then
	InitClient.Parent = Services['StarterPlayer']['StarterPlayerScripts']
	InitClient.Disabled = false
	Initialize:Destroy()
	LoadLibrary('DiceOutput')
end