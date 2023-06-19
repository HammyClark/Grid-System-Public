local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)

function Knit.OnComponentsLoaded()
	if Knit.ComponentsLoaded then
		return Promise.resolve()
	end
	return Promise.new(function(resolve, _reject, onCancel)
		local heartbeat
		heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
			if Knit.ComponentsLoaded then
				heartbeat:Disconnect()
				resolve()
			end
		end)
		onCancel(function()
			if heartbeat then
				heartbeat:Disconnect()
			end
		end)
	end)
end

Knit.ComponentsLoaded = false

Knit.AddServices(script.Parent.Services)

Knit.Start()
	:andThen(function()
		for _, component in ipairs(script.Parent.Components:GetChildren()) do
			if component:IsA("ModuleScript") then
				require(component)
			end
		end
		Knit.ComponentsLoaded = true
	end)
	:catch(warn)
