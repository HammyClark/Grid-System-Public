local GridObject = {}
GridObject.__index = GridObject

function GridObject.new(grid: any, x: number, z: number)
	local self = setmetatable({}, GridObject)
	self._gird = grid
	self._x = x
	self._z = z
	self._placedObject = nil
	return self
end

function GridObject:SetPlacedObject(placedObject: any)
	self._placedObject = placedObject
	--self._build.Area.Transparency = 1
	--self._build.Anchor.Transparency = 1
	self._gird:TriggerGridObjectChanged(self._x, self._z, self:ToString())
end

function GridObject:GetPlacedObject(): any
	return self._placedObject
end

function GridObject:ClearPlacedObject()
	self._placedObject:Destroy()
	self._placedObject = nil
	self._gird:TriggerGridObjectChanged(self._x, self._z, "None")
end

function GridObject:CanBuild(): boolean
	return self._placedObject == nil
end

function GridObject:ToString(): string
	return self._placedObject._placedBuild.Name
end

function GridObject:Destroy() end

return GridObject
