local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Modules = script.Parent.Parent.Modules
local ClientGrid = require(Modules.ClientGrid)

local GridController = Knit.CreateController({ Name = "GridController" })
GridController.Grid = nil
GridController.GridIndicator = nil
GridController.GridIndicatorColors = {
	Red = Color3.fromRGB(190, 0, 0),
	Green = Color3.fromRGB(0, 255, 127),
}

function GridController:GetWidthAdnHeightFromBuild(buildInstance: Instance)
	local width = buildInstance:GetAttribute("Width")
	local height = buildInstance:GetAttribute("Height")
	return width, height
end

function GridController:GetRotationAngle(dir: string): number
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

function GridController:GetRotationOffset(buildModel: Instance, dir: string): Vector2
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

function GridController:SetIndicator(parent: Instance, cframe: CFrame?, color: Color3?)
	self.GridIndicator:PivotTo(cframe or CFrame.new())
	self.GridIndicator.SurfaceGui.Frame.BackgroundColor3 = color or Color3.fromRGB(0, 255, 127)
	self.GridIndicator.Parent = parent
end

function GridController:_setup()
	-- 生成 Indicator
	self.GridIndicator = ReplicatedStorage.Templates:WaitForChild("GridIndicator"):Clone()
end

function GridController:KnitStart()
	self:_setup()

	local GridBuildingService = Knit.GetService("GridBuildingService")

	GridBuildingService.GridSetup:Connect(function(gridPack: table)
		GridController.Grid = ClientGrid.new(gridPack)
	end)

	GridBuildingService.GridChanged:Connect(function(x: number, z: number, msg: string)
		GridController.Grid:Update(x, z, msg)
	end)
end

function GridController:KnitInit() end

return GridController
