local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PlacedObject = {}
PlacedObject.__index = PlacedObject

function PlacedObject.new(worldPosition: Vector3, origin: Vector2, dir: string, buildPrefab: Instance)
	local self = setmetatable({}, PlacedObject)

	local newBuild = buildPrefab:Clone()
	newBuild.Area.Transparency = 1 -- 應刪除物件
	newBuild.Anchor.Transparency = 1 -- 應刪除物件
	newBuild:PivotTo(worldPosition)
	newBuild.Parent = workspace

	self._torve = Trove.new()
	self._placedBuild = newBuild
	self._torve:Add(self._placedBuild)
	self._origin = origin
	self._dir = dir
	return self
end

function PlacedObject:GetGridPositionList(): table
	return Knit.GetService("GridBuildingService"):GetGridPositionList(self._placedBuild, self._origin, self._dir)
end

function PlacedObject:Destroy()
	self._torve:Destroy()
end

return PlacedObject
