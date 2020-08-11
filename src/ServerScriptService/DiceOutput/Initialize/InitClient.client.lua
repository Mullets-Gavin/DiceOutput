--// services
local LoadLibrary = require(game:GetService('ReplicatedStorage'):WaitForChild('PlayingCards'))
local Services = setmetatable({}, {__index = function(cache, serviceName)
    cache[serviceName] = game:GetService(serviceName)
    return cache[serviceName]
end})

--// functions
local Player = Services['Players'].LocalPlayer
if script:IsDescendantOf(Player) then
	LoadLibrary('DiceOutput')
	Services['RunService'].Heartbeat:Wait()
	script:Destroy()
end