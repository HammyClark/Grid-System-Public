local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Option = require(ReplicatedStorage.Packages.Option)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Array2D = require(ReplicatedStorage.Modules.Array2D)

local Grid = {}
Grid.__index = Grid

function Grid.new(
	owner: Player,
	width: number,
	height: number,
	cellSize: number,
	originPosition: Vector3,
	gridObjectModule: ModuleScript
)
	local self = setmetatable({}, Grid)
	self._trove = Trove.new()
	self._folder = Instance.new("Folder")
	self._owner = owner
	self._width = width
	self._height = height
	self._cellSize = cellSize
	self._originPosition = originPosition
	self._gridArray = Array2D.new(self._width, self._height)
	for x = 1, self._gridArray:GetRowLength() do
		for z = 1, self._gridArray:GetColumnLength() do
			local gridObject = gridObjectModule.new(self, x, z)
			self._gridArray:Set(x, z, gridObject)
		end
	end

	self.OnGridValueChanged = Signal.new()
	self._trove:Add(function()
		self.OnGridValueChanged:Destroy()
	end)

	self:_setup()
	return self
end

function Grid:_setup()
	self._folder.Name = self._owner.Name .. "'s Grid"
	self._folder.Parent = workspace
end

function Grid:GetWorldPosition(x: number, z: number): Vector3
	return Vector3.new(
		0 + (x * self._cellSize) + self._originPosition.X,
		self._originPosition.Y,
		0 + (z * self._cellSize) + self._originPosition.Z
	)
end

function Grid:GetXZ(worldPosition: Vector3): { x: number, z: number }
	local x = math.floor((worldPosition.X - self._originPosition.X) / self._cellSize)
	local z = math.floor((worldPosition.Z - self._originPosition.Z) / self._cellSize)
	return x, z
end

function Grid:GetCellSize(): number
	return self._cellSize
end

function Grid:ClientPack(): table
	local pack = {
		folderName = self._folder.Name,
		width = self._width,
		height = self._height,
		cellSize = self._cellSize,
		originPosition = self._originPosition,
	}
	return pack
end

function Grid:SetGridObjectFromIndex(x: number, z: number, value: any)
	if x >= 1 and z >= 1 and x <= self._width and z <= self._height then
		self._gridArray:Set(x, z, value)
		self.OnGridValueChanged:Fire(x, z)
	end
end

function Grid:TriggerGridObjectChanged(x: number, z: number, msg: string)
	self.OnGridValueChanged:Fire(x, z, msg)
end

function Grid:SetGridObjectFromPosition(worldPosition: Vector3, value: any)
	local x, z = self:GetXZ(worldPosition)
	self:SetGridObjectFromIndex(x, z, value)
end

function Grid:GetGridObjectFromIndex(x: number, z: number): Instance
	if x >= 1 and z >= 1 and x <= self._width and z <= self._height then
		return Option.Wrap(self._gridArray:Get(x, z))
	else
		warn("Not Exist Index")
		return Option.None
	end
end

function Grid:GetGridObjectFromPosition(worldPosition: Vector3): Instance
	local x, z = self:GetXZ(worldPosition)
	if x >= 1 and z >= 1 and x <= self._width and z <= self._height then
		return Option.Wrap(self._gridArray:Get(x, z))
	else
		warn("Not Exist Index")
		return Option.None
	end
end

function Grid:Destroy()
	self._trove:Destroy()
end

return Grid
