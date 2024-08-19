--[[
	License: Licensed under the MIT License
	Version: 1.0.0
	Github: https://github.com/OssieNomae/FastClusterPatcher
	Authors:
		OssieNomae - 2024

	FastClusterPatcher: A Workaround for a FastCluster induced slow downs, moving attached parts outside of the humanoid models
	
	--------------------------------
	
	Members:
		Module.Patchers -> List of all created Patcher objects with keys as the attached humanoid model
	
	Functions:
		Module.new(HumanoidModel: Model) -> [Patcher] -- Creates a Patcher object
		
		Module.WaitForAccessoryWeld(Accessory: Accessory) -> Returns an AccessoryWeld, yields for maximum a second
	
	Members [Patcher]:
		Patcher.Model -> [Model] -- Attached humanoid model
		Patcher.Entities -> {BasePart} -- List of tracked entities
		
		Patcher._ParentConnection -> [RBXScriptConnection]
	
	Methods [Patcher]:
		Patcher:Add(Entity: BasePart) -> Adds an entity to the Patcher object
		
		Patcher:Destroy() -> Cleans up the Patcher object
	
	--------------------------------
	< Example Usage >
	
	local TestRig = workspace.TestRig
	local Patcher = Module.new(TestRig)
	
	local TestPart = Instance.new("Part")
	local Weld = Instance.new("Weld")
	Weld.Part0 = TestPart
	Weld.Part1 = TestRig.Head
	Weld.Parent = TestRig.Head

	Patcher:Add(TestPart)
	
	Note: FastClusterPatcher should only be used on the client, it is not necessary to use it for the local character
--]]
--!strict

----- Module Settings -----
local PATCH_FOLDER = Instance.new("Folder")
PATCH_FOLDER.Name = "_FastClusterPatchFolder"
PATCH_FOLDER.Parent = workspace

local ACCESSORY_MAX_YIELD = 1

----- Module / Class / Object Table -----
local Module = {}
local Object = {}
Object.__index = Object

----- Types -----
export type Patcher = typeof(setmetatable({} :: {
	Humanoid: Humanoid,
	Model: Model,
	Entities: {BasePart},
	_ParentConnection: RBXScriptConnection,
}, Object))

----- Public Methods -----
Module.Patchers = setmetatable({} :: {[Model]: Patcher}, {
	__mode = "kv"
})

function Module.new(HumanoidModel: Model): Patcher
	local self = setmetatable({}, Object) :: Patcher
	
	self.Model = HumanoidModel
	self.Entities = {}
	
	self._ParentConnection = HumanoidModel:GetPropertyChangedSignal("Parent"):Connect(function() -- Instance.Destroying isn't fully released
		if self.Model.Parent ~= nil then return end
		
		self:Destroy()
	end)
	
	Module.Patchers[self.Model] = self
	
	return self
end

function Module.WaitForAccessoryWeld(Accessory: Accessory): Weld?
	local Handle = Accessory:FindFirstChild("Handle")
	if not Handle then return end

	local AccessoryWeld = Handle:WaitForChild("AccessoryWeld", ACCESSORY_MAX_YIELD) :: Weld
	if not AccessoryWeld then return end

	return AccessoryWeld
end

----- Public Object Methods -----
function Object.Add(self: Patcher, Entity: BasePart)
	Entity.Parent = PATCH_FOLDER
	
	table.insert(self.Entities, Entity)
end

function Object.Destroy(self: Patcher)
	self._ParentConnection:Disconnect()
	
	for _,Entity in pairs(self.Entities) do
		Entity:Destroy()
	end
	
	self.Entities = {}
end

return Module