local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local builds = ReplicatedStorage:WaitForChild("Builds")
local camera = workspace.CurrentCamera

local RaycastController = Knit.CreateController({ Name = "RaycastController" })

RaycastController.BuildDirection = "Down"
RaycastController.BuildToSpawn = nil
RaycastController.BuildAngle = 0
RaycastController.BuildOffset = Vector2.new(0, 0)
RaycastController.CanBuild = false

local MAX_PLACED_RANGE = 30
local MOVE_DURATION = 0.2

function RaycastController:MouseRayCast(excludeModel: Model): RaycastResult
	local mousePosition = UserInputService:GetMouseLocation()
	local mouseRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local raycastParams = RaycastParams.new()

	local excludeList = camera:GetChildren()
	table.insert(excludeList, excludeModel)
	table.insert(excludeList, Knit.Player.Character)
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = excludeList

	local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * MAX_PLACED_RANGE, raycastParams)

	return raycastResult
end

function RaycastController:RemovePlaceholder()
	if self.BuildToSpawn then
		self.BuildToSpawn:Destroy()
		self.BuildDirection = "Down"
		self.BuildToSpawn = nil
		self.BuildAngle = 0
		self.BuildOffset = Vector2.new(0, 0)
	end
end

function RaycastController:AddPlaceholder(buildName: string, spawnPosition: Vector3)
	local buildExists = builds:FindFirstChild(buildName)
	if buildExists then
		self:RemovePlaceholder()
		self.BuildToSpawn = buildExists:Clone()
		self.BuildToSpawn.Area.Transparency = 1 -- 應刪除物件
		self.BuildToSpawn.Anchor.Transparency = 1 -- 應刪除物件
		self.BuildToSpawn.Parent = workspace
		self.BuildToSpawn:MoveTo(spawnPosition)

		for _, object in ipairs(self.BuildToSpawn:GetDescendants()) do
			if object:IsA("BasePart") then
				object.CollisionGroup = "Build"
				--object.Material = Enum.Material.ForceField
			end
		end
	end
end

function RaycastController:KnitStart()
	local GridBuildingService = Knit.GetService("GridBuildingService")
	local GridController = Knit.GetController("GridController")

	local function SetAngleAndOffset()
		self.BuildAngle = GridController:GetRotationAngle(self.BuildDirection)
		self.BuildOffset = GridController:GetRotationOffset(self.BuildToSpawn, self.BuildDirection)
	end

	local function TriggerCanBuild(result)
		-- 只在每一次位置變化時偵測 CanBuild
		GridBuildingService:CanBuild(result.Position, self.BuildToSpawn.Name, self.BuildDirection)
			:andThen(function(canBuild)
				self.CanBuild = canBuild
			end)
	end

	local function SetGridIndicator(cframe)
		if self.CanBuild then
			GridController:SetIndicator(camera, cframe, GridController.GridIndicatorColors.Green)
		else
			GridController:SetIndicator(camera, cframe, GridController.GridIndicatorColors.Red)
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent or not GridController.Grid then
			return
		end

		if self.BuildToSpawn then
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local result = self:MouseRayCast(self.BuildToSpawn)
				if result and result.Instance and result.Instance.Parent:IsA("Folder") then
					GridBuildingService.BuildOnGrid:Fire(result.Position, self.BuildToSpawn.Name, self.BuildDirection)
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				local result = self:MouseRayCast(self.BuildToSpawn)
				if result and result.Instance and result.Instance.Parent:IsA("Folder") then
					GridBuildingService.BuildRemoved:Fire(result.Position)
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.R then
			if self.BuildDirection == "Down" then
				self.BuildDirection = "Left"
				SetAngleAndOffset()
			elseif self.BuildDirection == "Left" then
				self.BuildDirection = "Up"
				SetAngleAndOffset()
			elseif self.BuildDirection == "Up" then
				self.BuildDirection = "Right"
				SetAngleAndOffset()
			elseif self.BuildDirection == "Right" then
				self.BuildDirection = "Down"
				SetAngleAndOffset()
			end
		elseif input.KeyCode == Enum.KeyCode.One then
			local result = self:MouseRayCast(self.BuildToSpawn)
			if result and result.Instance then
				self:AddPlaceholder("Building", result.Position)
				SetAngleAndOffset()
			end
		elseif input.KeyCode == Enum.KeyCode.Two then
			local result = self:MouseRayCast(self.BuildToSpawn)
			if result and result.Instance then
				self:AddPlaceholder("FireStation", result.Position)
				SetAngleAndOffset()
			end
		elseif input.KeyCode == Enum.KeyCode.Three then
			local result = self:MouseRayCast(self.BuildToSpawn)
			if result and result.Instance then
				self:AddPlaceholder("TownHall", result.Position)
				SetAngleAndOffset()
			end
		end
	end)

	-- 節流機制
	local isThrottled = false
	local throttleDealy = 0.15
	local lastplacedBuildCFrame
	local tweenInfo = TweenInfo.new(MOVE_DURATION)
	RunService.RenderStepped:Connect(function()
		-- 確認玩家已生成 ClientGrid
		local grid = GridController.Grid
		if not grid then
			return
		end

		local result = self:MouseRayCast(self.BuildToSpawn)
		if result and result.Instance then
			if self.BuildToSpawn then
				local x, z = grid:GetXZ(result.Position)
				local placedBuildCFrame = CFrame.new(
					grid:GetWorldPosition(x, z)
						+ Vector3.new(self.BuildOffset.X, 0, self.BuildOffset.Y) * grid:GetCellSize()
				) * CFrame.Angles(0, self.BuildAngle, 0)

				if not lastplacedBuildCFrame then
					self.BuildToSpawn:PivotTo(placedBuildCFrame)
					lastplacedBuildCFrame = placedBuildCFrame

					-- 節流
					if not isThrottled then
						TriggerCanBuild(result)
						SetGridIndicator(placedBuildCFrame)
						isThrottled = true
						coroutine.wrap(function()
							task.wait(throttleDealy)
							isThrottled = false
						end)()
					end
				elseif placedBuildCFrame ~= lastplacedBuildCFrame then
					local tween = TweenService:Create(self.BuildToSpawn.PrimaryPart, tweenInfo, {
						CFrame = placedBuildCFrame * self.BuildToSpawn.PrimaryPart.PivotOffset:Inverse(),
					})
					local tweenConn
					tweenConn = tween.Completed:Connect(function()
						lastplacedBuildCFrame = placedBuildCFrame
						tweenConn:Disconnect()
					end)
					tween:Play()

					-- 節流
					if not isThrottled then
						TriggerCanBuild(result)
						SetGridIndicator(placedBuildCFrame)
						isThrottled = true
						coroutine.wrap(function()
							task.wait(throttleDealy)
							isThrottled = false
						end)()
					end
				end
			end
		end
	end)
end

function RaycastController:KnitInit() end

return RaycastController
