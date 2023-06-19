local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Option = require(ReplicatedStorage.Packages.Option)
local Array2D = require(ReplicatedStorage.Modules.Array2D)

local gridPartTemplate = ReplicatedStorage.Templates:WaitForChild("GridPartTemplate")

local ClientGrid = {}
ClientGrid.__index = ClientGrid

ClientGrid._DEBUG_VISUAL = true
ClientGrid._DEBUG_TEXT = false

function ClientGrid.new(gridPack: table)
	local self = setmetatable({}, ClientGrid)
	self._trove = Trove.new()
	self._folder = workspace:WaitForChild(gridPack.folderName, 30)
	self._width = gridPack.width
	self._height = gridPack.height
	self._cellSize = gridPack.cellSize
	self._originPosition = gridPack.originPosition
	self._gridArray = Array2D.new(self._width, self._height)

	if self._DEBUG_VISUAL then
		self:_visualization()
	end

	return self
end

function ClientGrid:_visualization()
	for x = 1, self._gridArray:GetRowLength() do
		for z = 1, self._gridArray:GetColumnLength() do
			local newGridPart = gridPartTemplate:Clone()
			newGridPart.Size = Vector3.new(self._cellSize, 0.001, self._cellSize)
			if self._DEBUG_TEXT then
				newGridPart.SurfaceGui.Pos.Text = "(" .. x .. ", " .. z .. ")"
			end
			newGridPart.Name = "GridPart" .. x .. "_" .. z
			newGridPart:PivotTo(CFrame.new(self:GetWorldPosition(x, z)))
			newGridPart.Parent = self._folder
		end
	end
end

function ClientGrid:Update(x: number, z: number, msg: string)
	self:GetGridPart(x, z):Match({
		Some = function(gridPart)
			if self._DEBUG_TEXT then
				gridPart.SurfaceGui.Title.Text = msg
			end
		end,
		None = function() end,
	})
end

function ClientGrid:GetGridPart(x: number, z: number): Instance
	return Option.Wrap(self._folder:FindFirstChild("GridPart" .. x .. "_" .. z))
end

function ClientGrid:GetXZ(worldPosition: Vector3): { x: number, z: number }
	local x = math.floor((worldPosition.X - self._originPosition.X) / self._cellSize)
	local z = math.floor((worldPosition.Z - self._originPosition.Z) / self._cellSize)
	return x, z
end

function ClientGrid:GetCellSize(): number
	return self._cellSize
end

function ClientGrid:GetWorldPosition(x: number, z: number): Vector3
	return Vector3.new(
		0 + (x * self._cellSize) + self._originPosition.X,
		self._originPosition.Y,
		0 + (z * self._cellSize) + self._originPosition.Z
	)
end

function ClientGrid:Destroy() end

return ClientGrid
