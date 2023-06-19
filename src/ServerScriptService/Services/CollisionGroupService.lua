local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local CollisionGroupService = Knit.CreateService({
	Name = "CollisionGroupService",
	Client = {},
})

CollisionGroupService.Groups = {
	Player = "Player",
	Build = "Build",
}

function CollisionGroupService:SetGroup(instance: Instance, groupName: string)
	if instance:IsA("Model") then
		for _, obj in pairs(instance:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.CollisionGroup = groupName
			end
		end
	elseif instance:IsA("BasePart") then
		instance.CollisionGroup = groupName
	end
end

function CollisionGroupService:_setup()
	for _, value in pairs(self.Groups) do
		PhysicsService:RegisterCollisionGroup(value)
	end

	PhysicsService:CollisionGroupSetCollidable(self.Groups.Player, self.Groups.Build, false)
end

function CollisionGroupService:KnitStart()
	self:_setup()
end

function CollisionGroupService:KnitInit()
	local function PlayerAdded(player)
		local function CharacterAdded(character)
			self:SetGroup(character, self.Groups.Player)
		end
		CharacterAdded(player.Character or player.CharacterAdded:wait())
		player.CharacterAppearanceLoaded:Connect(CharacterAdded)
		player.CharacterAdded:Connect(CharacterAdded)
	end
	Players.PlayerAdded:Connect(PlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			PlayerAdded(player)
		end)
	end
end

return CollisionGroupService
