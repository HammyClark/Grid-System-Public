local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Option = require(ReplicatedStorage.Packages.Option)

local Modules = script.Parent.Parent.Modules
local Grid = require(Modules.Grid)
local GridObject = require(Modules.GridObject)
local PlacedOjbect = require(Modules.PlacedObject)

local GridBuildingService = Knit.CreateService({
	Name = "GridBuildingService",
	Client = {
		GridSetup = Knit.CreateSignal(),
		GridChanged = Knit.CreateSignal(),
		BuildOnGrid = Knit.CreateSignal(),
		BuildRemoved = Knit.CreateSignal(),
	},
})

GridBuildingService.Grids = {}
GridBuildingService._DEFAULT_DIRECTION = "Down"

-- Client exposed methods:
function GridBuildingService.Client:CanBuild(
	player: Player,
	worldPosition: Vector3,
	buildName: string,
	dir: string
): boolean
	return self.Server:CanBuild(player, worldPosition, buildName, dir)
end

-- Server methods:
function GridBuildingService:CanBuild(player: Player, worldPosition: Vector3, buildName: string, dir: string): boolean
	local canBuild = true
	self:GetGrid(player):Match({
		Some = function(grid)
			local buildPrefab = ReplicatedStorage.Builds:FindFirstChild(buildName or "Building")
			if not buildPrefab then
				return
			end
			local x, z = grid:GetXZ(worldPosition)

			local gridPositionList =
				self:GetGridPositionList(buildPrefab, Vector2.new(x, z), dir or self._DEFAULT_DIRECTION)
			-- 檢查是否可建築
			for _, gridPosition in ipairs(gridPositionList) do
				grid:GetGridObjectFromIndex(gridPosition.X, gridPosition.Y):Match({
					Some = function(gridObject)
						if not gridObject:CanBuild() then
							canBuild = false
						end
					end,
					None = function()
						canBuild = false
					end,
				})
				if not canBuild then
					break
				end
			end
		end,
		None = function()
			canBuild = false
		end,
	})

	return canBuild
end

function GridBuildingService:GetGrid(player: Player): any
	return Option.Wrap(GridBuildingService.Grids[player.UserId])
end

function GridBuildingService:RemoveGrid(player: Player)
	self:GetGrid(player):Match({
		Some = function(grid: any)
			GridBuildingService.Grids[player.UserId] = nil
			self.Client.GridChanged:Fire(player, grid)
		end,
		None = function() end,
	})
end

function GridBuildingService:CreateGrid(player: Player)
	local playerGrid
	self:GetGrid(player):Match({
		Some = function(grid: any)
			playerGrid = grid
		end,
		None = function()
			playerGrid = Grid.new(player, 10, 5, 4, Vector3.new(4, 0.025, 4), GridObject)
			GridBuildingService.Grids[player.UserId] = playerGrid
			-- 監聽玩家 Grid 的變化，發送給客戶端
			playerGrid.OnGridValueChanged:Connect(function(x: number, z: number, msg: string)
				self.Client.GridChanged:Fire(player, x, z, msg)
			end)
		end,
	})
	self.Client.GridSetup:Fire(player, playerGrid:ClientPack())
end

function GridBuildingService:GetWidthAdnHeightFromBuild(buildInstance: Instance)
	local width = buildInstance:GetAttribute("Width")
	local height = buildInstance:GetAttribute("Height")
	return width, height
end

function GridBuildingService:GetGridPositionList(buildModel: Instance, offset: Vector2, dir: string): table
	local width, height = self:GetWidthAdnHeightFromBuild(buildModel)
	local gridPositionList = {}
	if dir == "Up" or dir == "Down" then
		for x = 0, width - 1 do
			for z = 0, height - 1 do
				table.insert(gridPositionList, offset + Vector2.new(x, z))
			end
		end
	elseif dir == "Left" or dir == "Right" then
		for x = 0, height - 1 do
			for z = 0, width - 1 do
				table.insert(gridPositionList, offset + Vector2.new(x, z))
			end
		end
	end
	return gridPositionList
end

function GridBuildingService:GetRotationAngle(dir: string): number
	if dir == "Down" then
		return math.rad(0)
	elseif dir == "Left" then
		return math.rad(90)
	elseif dir == "Up" then
		return math.rad(180)
	elseif dir == "Right" then
		return math.rad(270)
	end
end

function GridBuildingService:GetRotationOffset(buildModel: Instance, dir: string): Vector2
	local width, height = self:GetWidthAdnHeightFromBuild(buildModel)
	if dir == "Down" then
		return Vector2.new(0, 0)
	elseif dir == "Left" then
		return Vector2.new(0, width)
	elseif dir == "Up" then
		return Vector2.new(width, height)
	elseif dir == "Right" then
		return Vector2.new(height, 0)
	end
end

function GridBuildingService:_setup()
	-- 設定所有建築的 CollisionGroup
	local CollisionGroupService = Knit.GetService("CollisionGroupService")
	for _, build in ipairs(ReplicatedStorage.Builds:GetChildren()) do
		CollisionGroupService:SetGroup(build, CollisionGroupService.Groups.Build)
	end
end

-- Knit lifecycle
function GridBuildingService:KnitStart()
	self:_setup()
end

function GridBuildingService:KnitInit()
	local function PlayerAdded(player)
		local function CharacterAdded(character) end
		CharacterAdded(player.Character or player.CharacterAdded:wait())
		player.CharacterAdded:Connect(CharacterAdded)

		self:CreateGrid(player)
	end
	Players.PlayerAdded:Connect(PlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			PlayerAdded(player)
		end)
	end

	-- 玩家拆除
	self.Client.BuildRemoved:Connect(function(player: Player, worldPosition: Vector3)
		local function ClearOtherPlacedObject(placedObject: any, grid: any)
			local gridPositionList = placedObject:GetGridPositionList()
			for _, gridPosition in ipairs(gridPositionList) do
				grid:GetGridObjectFromIndex(gridPosition.X, gridPosition.Y):Match({
					Some = function(gridObject)
						gridObject:ClearPlacedObject()
					end,
					None = function() end,
				})
			end
		end

		self:GetGrid(player):Match({
			Some = function(grid)
				local x, z = grid:GetXZ(worldPosition)
				grid:GetGridObjectFromIndex(x, z):Match({
					Some = function(gridObject)
						local placedObject = gridObject:GetPlacedObject()
						if placedObject then
							ClearOtherPlacedObject(placedObject, grid)
						end
					end,
					None = function() end,
				})
			end,
			None = function() end,
		})
	end)

	-- 玩家建築
	self.Client.BuildOnGrid:Connect(function(player: Player, worldPosition: Vector3, buildName: string, dir: string)
		self:GetGrid(player):Match({
			Some = function(grid)
				local buildPrefab = ReplicatedStorage.Builds:FindFirstChild(buildName or "Building")
				if not buildPrefab then
					return
				end

				local x, z = grid:GetXZ(worldPosition)
				local gridPositionList =
					self:GetGridPositionList(buildPrefab, Vector2.new(x, z), dir or self._DEFAULT_DIRECTION)
				-- 檢查是否可建築
				local canBuild = self:CanBuild(player, worldPosition, buildName, dir)

				if canBuild then
					local rotationOffset = self:GetRotationOffset(buildPrefab, dir)
					local placedBuildCFrame = CFrame.new(
						grid:GetWorldPosition(x, z)
							+ Vector3.new(rotationOffset.X, 0, rotationOffset.Y) * grid:GetCellSize()
					) * CFrame.Angles(0, self:GetRotationAngle(dir), 0)

					local newPlacedObject = PlacedOjbect.new(placedBuildCFrame, Vector2.new(x, z), dir, buildPrefab)

					for _, gridPosition: Vector2 in ipairs(gridPositionList) do
						grid:GetGridObjectFromIndex(gridPosition.X, gridPosition.Y):Match({
							Some = function(gridObject)
								gridObject:SetPlacedObject(newPlacedObject)
							end,
							None = function() end,
						})
					end
				else
					print("Already builded.")
				end
			end,
			None = function() end,
		})
	end)
end

return GridBuildingService
