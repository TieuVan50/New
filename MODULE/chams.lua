--=============================================================================
-- CHAMS ESP API MODULE (WITH NPC SUPPORT)
--=============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

type HighlightData = {
	highlight: Highlight?,
	lastUpdateTick: number,
	isNPC: boolean
}

type TargetCache = {
	[any]: HighlightData
}

-- NPC Tags
local NPCTags = {
	"NPC", "Npc", "npc", "Enemy", "enemy", "Enemies", "enemies",
	"Hostile", "hostile", "Bad", "bad", "BadGuy", "badguy",
	"Foe", "foe", "Opponent", "opponent", "Bot", "bot", "Bots", "bots",
	"Mob", "mob", "Mobs", "mobs", "Monster", "monster", "Monsters", "monsters",
	"Zombie", "zombie", "Zombies", "zombies", "Creature", "creature",
	"Animal", "animal", "Beast", "beast", "Villain", "villain",
	"Boss", "boss", "MiniBoss", "miniboss", "Guard", "guard",
	"Guardian", "guardian", "Soldier", "soldier", "Warrior", "warrior",
	"Fighter", "fighter", "Target", "target", "Dummy", "dummy",
}

-- Configuration
local ChamsConfig = {
	enabled = false,
	maxDistance = 10000,
	updateInterval = 0.05,
	batchSize = 5,
	fillColor = Color3.fromRGB(0, 255, 140),
	outlineColor = Color3.fromRGB(0, 255, 140),
	visibleFillColor = Color3.fromRGB(0, 255, 0),
	visibleOutlineColor = Color3.fromRGB(0, 255, 0),
	hiddenFillColor = Color3.fromRGB(255, 0, 0),
	hiddenOutlineColor = Color3.fromRGB(255, 0, 0),
	fillTransparency = 0.5,
	outlineTransparency = 0,
	
	EnableTeamCheck = false,
	ShowEnemyOnly = false,
	ShowAlliedOnly = false,
	UseTeamColors = false,
	UseActualTeamColors = true,
	
	EnemyFillColor = Color3.fromRGB(255, 0, 0),
	EnemyOutlineColor = Color3.fromRGB(255, 0, 0),
	AlliedFillColor = Color3.fromRGB(0, 255, 0),
	AlliedOutlineColor = Color3.fromRGB(0, 255, 0),
	NoTeamColor = Color3.fromRGB(255, 255, 255),
	
	depthMode = "AlwaysOnTop",
	useRaycasting = false,
	useVisibilityColors = false,
	
	-- NPC Settings
	Mode = "Player",
	EnableNPCChams = true,
	UseNPCColors = false,
	NPCFillColor = Color3.fromRGB(255, 0, 0),
	NPCOutlineColor = Color3.fromRGB(255, 0, 0),
	BossFillColor = Color3.fromRGB(255, 165, 0),
	BossOutlineColor = Color3.fromRGB(255, 165, 0),
	EnableTagFilter = true,
	AggressiveNPCDetection = false,
}

-- Runtime Data
local RuntimeData = {
	highlightData = {} :: TargetCache,
	connections = {} :: {[string]: RBXScriptConnection},
	playerConnections = {} :: {[Player]: {[string]: RBXScriptConnection}},
	lastUpdate = 0,
	targetQueue = {} :: {any},
	currentQueueIndex = 1,
	cachedDepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	trackedNPCs = {},
	scanConnection = nil,
}

--=============================================================================
-- NPC SYSTEM
--=============================================================================

local NPCSystem = {}

function NPCSystem.isPlayer(character)
	if not character or not character:IsA("Model") then return false end
	if character == LocalPlayer.Character then return true end
	local targetPlayer = Players:GetPlayerFromCharacter(character)
	return targetPlayer ~= nil
end

function NPCSystem.isNPC(character)
	if not character or not character:IsA("Model") then return false end
	if NPCSystem.isPlayer(character) then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not head or not hrp or humanoid.Health <= 0 then return false end
	
	if ChamsConfig.AggressiveNPCDetection then 
		return true
	end
	
	if not ChamsConfig.EnableTagFilter then
		return true
	end
	
	local charName = character.Name:lower()
	for _, tag in pairs(NPCTags) do
		if charName:find(tag:lower(), 1, true) then return true end
	end
	
	local npcFolders = {"NPCs", "Enemies", "Bots", "Mobs", "Targets", "Enemy", "Hostile",
		"Monsters", "Zombies", "Creatures", "Characters", "Spawns", "EnemySpawns", "NPCSpawns", "Bosses"}
	
	for _, folderName in pairs(npcFolders) do
		local folder = Workspace:FindFirstChild(folderName)
		if folder and character:IsDescendantOf(folder) then return true end
	end
	
	local npcIndicators = {"NPC", "IsNPC", "IsEnemy", "Hostile"}
	for _, indicator in pairs(npcIndicators) do
		local val = character:FindFirstChild(indicator)
		if val and val:IsA("BoolValue") and val.Value == true then return true end
	end
	
	return false
end

function NPCSystem.isBoss(character)
	if not character then return false end
	
	local charName = character.Name:lower()
	if charName:find("boss") or charName:find("miniboss") or charName:find("leader") then
		return true
	end
	
	if character:GetAttribute("IsBoss") == true then
		return true
	end
	
	return false
end

function NPCSystem.findNPCsRecursive(parent)
	local foundNPCs = {}
	for _, instance in pairs(parent:GetDescendants()) do
		if NPCSystem.isNPC(instance) then
			table.insert(foundNPCs, instance)
		end
	end
	return foundNPCs
end

--=============================================================================
-- UTILITY FUNCTIONS
--=============================================================================

local function SafeCall(func, ...)
	return pcall(func, ...)
end

local function GetDepthMode()
	return ChamsConfig.depthMode == "Occluded" 
		and Enum.HighlightDepthMode.Occluded 
		or Enum.HighlightDepthMode.AlwaysOnTop
end

local function gameHasTeams()
	local teams = game:GetService("Teams")
	if not teams then return false end
	return #teams:GetTeams() > 0
end

local function getPlayerTeamColor(targetPlayer)
	if not targetPlayer then return nil end
	if not targetPlayer.Team then return nil end
	return targetPlayer.Team.TeamColor.Color
end

local function isEnemy(targetPlayer)
	if not targetPlayer then return true end
	if not targetPlayer.Character then return true end
	
	if not gameHasTeams() then return true end
	
	if not LocalPlayer.Team then
		if not targetPlayer.Team then return false end
		return true
	end
	
	if not targetPlayer.Team then return true end
	
	return LocalPlayer.Team ~= targetPlayer.Team
end

local function shouldShowPlayer(targetPlayer)
	if not ChamsConfig.EnableTeamCheck then return true end
	local isEnemyPlayer = isEnemy(targetPlayer)
	if ChamsConfig.ShowEnemyOnly and not isEnemyPlayer then return false end
	if ChamsConfig.ShowAlliedOnly and isEnemyPlayer then return false end
	return true
end

local function GetChamsColors(target, isVisible: boolean, isNPC: boolean)
	-- NPC Colors
	if isNPC then
		if ChamsConfig.UseNPCColors then
			if NPCSystem.isBoss(target) then
				return ChamsConfig.BossFillColor, ChamsConfig.BossOutlineColor
			else
				return ChamsConfig.NPCFillColor, ChamsConfig.NPCOutlineColor
			end
		end
		-- Default gradient based on visibility
		if ChamsConfig.useVisibilityColors then
			if isVisible then
				return ChamsConfig.visibleFillColor, ChamsConfig.visibleOutlineColor
			else
				return ChamsConfig.hiddenFillColor, ChamsConfig.hiddenOutlineColor
			end
		end
		return ChamsConfig.fillColor, ChamsConfig.outlineColor
	end
	
	-- Player Colors
	if ChamsConfig.useVisibilityColors then
		if isVisible then
			return ChamsConfig.visibleFillColor, ChamsConfig.visibleOutlineColor
		else
			return ChamsConfig.hiddenFillColor, ChamsConfig.hiddenOutlineColor
		end
	end
	
	if not ChamsConfig.UseTeamColors then
		return ChamsConfig.fillColor, ChamsConfig.outlineColor
	end
	
	if ChamsConfig.UseActualTeamColors then
		local teamColor = getPlayerTeamColor(target)
		if teamColor then
			return teamColor, teamColor
		else
			return ChamsConfig.NoTeamColor, ChamsConfig.NoTeamColor
		end
	else
		local isEnemyPlayer = isEnemy(target)
		if isEnemyPlayer then
			return ChamsConfig.EnemyFillColor, ChamsConfig.EnemyOutlineColor
		else
			return ChamsConfig.AlliedFillColor, ChamsConfig.AlliedOutlineColor
		end
	end
end

local function CheckLineOfSight(fromPos: Vector3, toPos: Vector3, ignoreChars): boolean
	if not ChamsConfig.useRaycasting then return true end
	
	local direction = toPos - fromPos
	if direction.Magnitude == 0 then return true end
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignoreChars
	rayParams.IgnoreWater = true
	
	local success, result = SafeCall(function()
		return workspace:Raycast(fromPos, direction, rayParams)
	end)
	
	if success and result then
		if result.Instance then
			local hitDistance = (result.Position - toPos).Magnitude
			if hitDistance < 5 then return true end
			
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			if model and model:FindFirstChild("Humanoid") then return true end
			return false
		end
	end
	return true
end

local function GetTargetStatus(target, isNPC: boolean): (boolean, boolean, number)
	if not ChamsConfig.enabled then 
		return false, false, 0
	end
	
	local success, result = SafeCall(function()
		local character
		if isNPC then
			character = target
			if character == LocalPlayer.Character then return {false, false, 0} end
		else
			if target == LocalPlayer then return {false, false, 0} end
			character = target.Character
		end
		
		if not character then return {false, false, 0} end
		
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChild("Humanoid")
		
		if not hrp or not humanoid or humanoid.Health <= 0 then 
			return {false, false, 0}
		end
		
		local myChar = LocalPlayer.Character
		if not myChar then return {false, false, 0} end
		
		local myHrp = myChar:FindFirstChild("HumanoidRootPart")
		if not myHrp then return {false, false, 0} end
		
		local distance = (hrp.Position - myHrp.Position).Magnitude
		if distance > ChamsConfig.maxDistance then 
			return {false, false, distance}
		end
		
		if not isNPC and not shouldShowPlayer(target) then
			return {false, false, distance}
		end
		
		local isVisible = CheckLineOfSight(myHrp.Position, hrp.Position, {myChar, character})
		
		return {true, isVisible, distance}
	end)
	
	if success and result then
		return result[1], result[2], result[3]
	end
	return false, false, 0
end

local function IsHighlightValid(highlightData: HighlightData?): boolean
	if not highlightData or not highlightData.highlight then return false end
	
	local success, isValid = SafeCall(function()
		return highlightData.highlight.Parent ~= nil
	end)
	
	return success and isValid or false
end

local function CreateHighlight(target, character: Model, isNPC: boolean): boolean
	local success = SafeCall(function()
		if RuntimeData.highlightData[target] then
			local oldData = RuntimeData.highlightData[target]
			if oldData.highlight then
				oldData.highlight:Destroy()
			end
		end
		
		local targetName = isNPC and character.Name or target.UserId
		
		local highlight = Instance.new("Highlight")
		highlight.Name = "Chams_" .. tostring(targetName)
		highlight.Adornee = character
		highlight.DepthMode = GetDepthMode()
		highlight.Enabled = true
		highlight.Parent = character
		
		RuntimeData.highlightData[target] = {
			highlight = highlight,
			lastUpdateTick = tick(),
			isNPC = isNPC
		}
		
		return true
	end)
	
	return success
end

local function RemoveHighlight(target)
	SafeCall(function()
		local data = RuntimeData.highlightData[target]
		if data and data.highlight then
			data.highlight:Destroy()
		end
		RuntimeData.highlightData[target] = nil
	end)
	
	if not data or not data.isNPC then
		local playerConns = RuntimeData.playerConnections[target]
		if playerConns then
			for _, conn in pairs(playerConns) do
				SafeCall(function() conn:Disconnect() end)
			end
			RuntimeData.playerConnections[target] = nil
		end
	end
end

local function UpdateHighlightProperties(highlight: Highlight, fillColor: Color3, outlineColor: Color3)
	highlight.FillColor = fillColor
	highlight.OutlineColor = outlineColor
	highlight.FillTransparency = ChamsConfig.fillTransparency
	highlight.OutlineTransparency = ChamsConfig.outlineTransparency
	highlight.DepthMode = GetDepthMode()
end

local function UpdateHighlight(target, isNPC: boolean)
	local shouldShow, isVisible, distance = GetTargetStatus(target, isNPC)
	
	if not shouldShow then
		RemoveHighlight(target)
		return
	end
	
	local character
	if isNPC then
		character = target
	else
		character = target.Character
	end
	
	if not character then
		RemoveHighlight(target)
		return
	end
	
	local data = RuntimeData.highlightData[target]
	
	if not IsHighlightValid(data) then
		if not CreateHighlight(target, character, isNPC) then
			return
		end
		data = RuntimeData.highlightData[target]
	end
	
	if not data then return end
	
	local fillColor, outlineColor = GetChamsColors(target, isVisible, isNPC)
	
	SafeCall(function()
		if data.highlight then
			local adornee = data.highlight.Adornee
			if adornee ~= character then
				data.highlight.Adornee = character
			end
			UpdateHighlightProperties(data.highlight, fillColor, outlineColor)
		end
	end)
end

local function RebuildTargetQueue()
	RuntimeData.targetQueue = {}
	
	-- Add Players
	if ChamsConfig.Mode == "Player" or ChamsConfig.Mode == "Both" then
		for _, player in Players:GetPlayers() do
			if player ~= LocalPlayer then
				table.insert(RuntimeData.targetQueue, {target = player, isNPC = false})
			end
		end
	end
	
	-- Add NPCs
	if ChamsConfig.Mode == "NPC" or ChamsConfig.Mode == "Both" then
		for npc in pairs(RuntimeData.trackedNPCs) do
			if npc and npc.Parent then
				table.insert(RuntimeData.targetQueue, {target = npc, isNPC = true})
			end
		end
	end
	
	RuntimeData.currentQueueIndex = 1
end

local function UpdateBatchChams()
	if not ChamsConfig.enabled then return end
	
	local currentTime = tick()
	local deltaTime = currentTime - RuntimeData.lastUpdate
	
	if deltaTime < ChamsConfig.updateInterval then return end
	RuntimeData.lastUpdate = currentTime
	
	local queueLength = #RuntimeData.targetQueue
	if queueLength == 0 then
		RebuildTargetQueue()
		queueLength = #RuntimeData.targetQueue
		if queueLength == 0 then return end
	end
	
	local batchCount = math.min(ChamsConfig.batchSize, queueLength)
	
	for i = 1, batchCount do
		local index = RuntimeData.currentQueueIndex
		local entry = RuntimeData.targetQueue[index]
		
		if entry and entry.target and entry.target.Parent then
			UpdateHighlight(entry.target, entry.isNPC)
		else
			table.remove(RuntimeData.targetQueue, index)
			queueLength = #RuntimeData.targetQueue
			if queueLength == 0 then break end
			if RuntimeData.currentQueueIndex > queueLength then
				RuntimeData.currentQueueIndex = 1
			end
		end
		
		RuntimeData.currentQueueIndex = RuntimeData.currentQueueIndex + 1
		if RuntimeData.currentQueueIndex > #RuntimeData.targetQueue then
			RuntimeData.currentQueueIndex = 1
		end
	end
end

--=============================================================================
-- NPC FUNCTIONS
--=============================================================================

local function scanForNPCs()
	local foundNPCs = NPCSystem.findNPCsRecursive(Workspace)
	
	local foundSet = {}
	for _, npc in pairs(foundNPCs) do
		foundSet[npc] = true
	end
	
	-- Remove dead NPCs
	for npc in pairs(RuntimeData.trackedNPCs) do
		if not foundSet[npc] or not npc.Parent then
			RemoveHighlight(npc)
			RuntimeData.trackedNPCs[npc] = nil
		end
	end
	
	-- Add new NPCs
	for _, npc in pairs(foundNPCs) do
		if not RuntimeData.trackedNPCs[npc] then
			RuntimeData.trackedNPCs[npc] = true
		end
	end
	
	RebuildTargetQueue()
end

local function initializeNPCScanning()
	scanForNPCs()
	
	if not RuntimeData.scanConnection then
		RuntimeData.scanConnection = RunService.Heartbeat:Connect(function()
			if ChamsConfig.enabled and (ChamsConfig.Mode == "NPC" or ChamsConfig.Mode == "Both") then
				scanForNPCs()
			end
		end)
	end
end

local function cleanupNPCs()
	local npcsToRemove = {}
	for target, data in pairs(RuntimeData.highlightData) do
		if data.isNPC then
			table.insert(npcsToRemove, target)
		end
	end
	
	for _, npc in pairs(npcsToRemove) do
		RemoveHighlight(npc)
	end
	
	RuntimeData.trackedNPCs = {}
end

local function cleanupPlayers()
	local playersToRemove = {}
	for target, data in pairs(RuntimeData.highlightData) do
		if not data.isNPC then
			table.insert(playersToRemove, target)
		end
	end
	
	for _, player in pairs(playersToRemove) do
		RemoveHighlight(player)
	end
end

--=============================================================================
-- PLAYER CONNECTION SETUP
--=============================================================================

local function SetupPlayerConnections(player: Player)
	if player == LocalPlayer then return end
	
	RuntimeData.playerConnections[player] = {}
	
	RuntimeData.playerConnections[player]["charAdded"] = player.CharacterAdded:Connect(function(character)
		task.wait(0.1)
		if player.Parent and ChamsConfig.enabled then
			SafeCall(function()
				UpdateHighlight(player, false)
			end)
		end
	end)
	
	RuntimeData.playerConnections[player]["charRemoving"] = player.CharacterRemoving:Connect(function()
		RemoveHighlight(player)
	end)
end

local function InitializeEvents()
	RuntimeData.connections.heartbeat = RunService.Heartbeat:Connect(UpdateBatchChams)
	
	RuntimeData.connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
		RemoveHighlight(player)
		RebuildTargetQueue()
	end)
	
	RuntimeData.connections.playerAdded = Players.PlayerAdded:Connect(SetupPlayerConnections)
	
	RuntimeData.connections.localCharAdded = LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.5)
		for target in pairs(RuntimeData.highlightData) do
			RemoveHighlight(target)
		end
		task.wait(0.2)
		RebuildTargetQueue()
	end)
	
	for _, player in Players:GetPlayers() do
		SetupPlayerConnections(player)
	end
	
	initializeNPCScanning()
	RebuildTargetQueue()
end

--=============================================================================
-- PUBLIC API
--=============================================================================

local ChamsAPI = {}

function ChamsAPI:Toggle(state: boolean)
	ChamsConfig.enabled = state
	if not state then
		for target in pairs(RuntimeData.highlightData) do
			RemoveHighlight(target)
		end
	else
		RebuildTargetQueue()
	end
end

function ChamsAPI:UpdateConfig(newConfig: {[string]: any})
	for key, value in pairs(newConfig) do
		if ChamsConfig[key] ~= nil then
			ChamsConfig[key] = value
		end
	end
end

function ChamsAPI:GetConfig()
	return ChamsConfig
end

function ChamsAPI:SetMode(mode: string)
	if mode == "Player" or mode == "NPC" or mode == "Both" then
		local oldMode = ChamsConfig.Mode
		ChamsConfig.Mode = mode
		
		if oldMode ~= mode then
			if mode == "Player" then
				cleanupNPCs()
				RebuildTargetQueue()
			elseif mode == "NPC" then
				cleanupPlayers()
				scanForNPCs()
			elseif mode == "Both" then
				RebuildTargetQueue()
				scanForNPCs()
			end
		end
	end
end

function ChamsAPI:GetMode()
	return ChamsConfig.Mode
end

function ChamsAPI:GetTrackedTargets()
	local targets = {}
	for target in pairs(RuntimeData.highlightData) do
		table.insert(targets, target)
	end
	return targets
end

function ChamsAPI:Destroy()
	if RuntimeData.scanConnection then
		RuntimeData.scanConnection:Disconnect()
		RuntimeData.scanConnection = nil
	end
	
	for name, conn in pairs(RuntimeData.connections) do
		SafeCall(function() conn:Disconnect() end)
	end
	RuntimeData.connections = {}
	
	for player, conns in pairs(RuntimeData.playerConnections) do
		for _, conn in pairs(conns) do
			SafeCall(function() conn:Disconnect() end)
		end
	end
	RuntimeData.playerConnections = {}
	
	for target in pairs(RuntimeData.highlightData) do
		RemoveHighlight(target)
	end
	RuntimeData.highlightData = {}
	RuntimeData.trackedNPCs = {}
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

InitializeEvents()

return ChamsAPI
