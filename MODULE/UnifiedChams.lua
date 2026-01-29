--=============================================================================
-- CHAMS ESP API MODULE - WITH NPC SUPPORT
--=============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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

type PlayerCache = {
	[Player]: HighlightData
}

type NPCCache = {
	[Model]: HighlightData
}

-- Danh sách tag NPC (từ ESP dropdown)
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
	"Dummies", "dummies", "Skeleton", "skeleton", "Orc", "orc",
	"Goblin", "goblin", "Robot", "robot", "Drone", "drone",
	"Android", "android", "Cyborg", "cyborg", "Automaton", "automaton",
	"Servant", "servant", "Minion", "minion", "Slave", "slave", "Pawn", "pawn",
	"AI", "ai", "A.I.", "Char", "char", "Character", "character",
	"Model", "model", "Event", "event", "Special", "special",
	"Angel", "angel", "Archangel", "archangel", "Crystal", "crystal",
	"Demon", "demon", "Elf", "elf", "Ghost", "ghost", "Santa", "santa",
	"Slime", "slime", "Vampire", "vampire", "Void Slime", "void slime",
}

-- Configuration
local ChamsConfig = {
	enabled = false,
	maxDistance = 10000,
	updateInterval = 0.05,
	batchSize = 5,
	
	-- Player Chams
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
	
	-- NPC Chams
	NPCEnabled = false,
	NPCMaxDistance = 10000,
	NPCFillColor = Color3.fromRGB(255, 165, 0),
	NPCOutlineColor = Color3.fromRGB(255, 165, 0),
	StandardNPCColor = Color3.fromRGB(255, 0, 0),
	BossNPCColor = Color3.fromRGB(255, 165, 0),
	UseNPCColors = false,
	EnableTagFilter = true,
	AggressiveNPCDetection = false,
	
	depthMode = "AlwaysOnTop",
	useRaycasting = false,
	useVisibilityColors = false,
}

-- Runtime Data
local RuntimeData = {
	highlightData = {} :: PlayerCache,
	npcHighlightData = {} :: NPCCache,
	connections = {} :: {[string]: RBXScriptConnection},
	playerConnections = {} :: {[Player]: {[string]: RBXScriptConnection}},
	npcConnections = {} :: {[Model]: {[string]: RBXScriptConnection}},
	lastUpdate = 0,
	playerQueue = {} :: {Player},
	npcQueue = {} :: {Model},
	currentQueueIndex = 1,
	npcQueueIndex = 1,
	cachedDepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	trackedNPCs = {} :: {[Model]: boolean},
}

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

--=============================================================================
-- NPC DETECTION SYSTEM (từ ESP)
--=============================================================================

local NPCSystem = {}

function NPCSystem.isPlayer(character)
	if not character or not character:IsA("Model") then return false end
	if character == LocalPlayer.Character then return true end
	local player = Players:GetPlayerFromCharacter(character)
	return player ~= nil
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
	
	if ChamsConfig.EnableTagFilter then
		for _, tag in ipairs(NPCTags) do
			if string.find(character.Name, tag) then
				return true
			end
		end
		return false
	end
	
	return true
end

function NPCSystem.isBoss(npc)
	if not npc then return false end
	
	local isBossTag = function(str)
		local str_lower = string.lower(str)
		return string.find(str_lower, "boss") or string.find(str_lower, "miniboss") or string.find(str_lower, "guardian")
	end
	
	if isBossTag(npc.Name) then return true end
	
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.MaxHealth > 100 then return true end
	
	return false
end

function NPCSystem.findNPCsRecursive(parent)
	local foundNPCs = {}
	
	local function scan(obj)
		if obj:IsA("Model") and NPCSystem.isNPC(obj) then
			table.insert(foundNPCs, obj)
		end
		
		local success, children = pcall(function() return obj:GetChildren() end)
		if success then
			for _, child in pairs(children) do
				scan(child)
			end
		end
	end
	
	scan(parent)
	return foundNPCs
end

--=============================================================================
-- CHAMS COLORS
--=============================================================================

local function GetChamsColors(target, isVisible: boolean)
	local isNPC = RuntimeData.npcHighlightData[target] and RuntimeData.npcHighlightData[target].isNPC
	
	if isNPC then
		-- NPC Colors
		if ChamsConfig.useVisibilityColors then
			if isVisible then
				return ChamsConfig.visibleFillColor, ChamsConfig.visibleOutlineColor
			else
				return ChamsConfig.hiddenFillColor, ChamsConfig.hiddenOutlineColor
			end
		end
		
		if ChamsConfig.UseNPCColors then
			if NPCSystem.isBoss(target) then
				return ChamsConfig.BossNPCColor, ChamsConfig.BossNPCColor
			else
				return ChamsConfig.StandardNPCColor, ChamsConfig.StandardNPCColor
			end
		end
		
		return ChamsConfig.NPCFillColor, ChamsConfig.NPCOutlineColor
	else
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
end

--=============================================================================
-- LINE OF SIGHT CHECK
--=============================================================================

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

--=============================================================================
-- STATUS CHECKERS
--=============================================================================

local function GetPlayerStatus(player: Player): (boolean, boolean, number)
	if not ChamsConfig.enabled or player == LocalPlayer then 
		return false, false, 0
	end
	
	local success, result = SafeCall(function()
		local character = player.Character
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
		
		if not shouldShowPlayer(player) then
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

local function GetNPCStatus(npc: Model): (boolean, boolean, number)
	if not ChamsConfig.NPCEnabled or not npc then 
		return false, false, 0
	end
	
	local success, result = SafeCall(function()
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		
		if not humanoid or not hrp or humanoid.Health <= 0 then 
			return {false, false, 0}
		end
		
		local myChar = LocalPlayer.Character
		if not myChar then return {false, false, 0} end
		
		local myHrp = myChar:FindFirstChild("HumanoidRootPart")
		if not myHrp then return {false, false, 0} end
		
		local distance = (hrp.Position - myHrp.Position).Magnitude
		if distance > ChamsConfig.NPCMaxDistance then 
			return {false, false, distance}
		end
		
		local isVisible = CheckLineOfSight(myHrp.Position, hrp.Position, {myChar, npc})
		
		return {true, isVisible, distance}
	end)
	
	if success and result then
		return result[1], result[2], result[3]
	end
	return false, false, 0
end

--=============================================================================
-- HIGHLIGHT MANAGEMENT
--=============================================================================

local function IsHighlightValid(highlightData: HighlightData?): boolean
	if not highlightData or not highlightData.highlight then return false end
	
	local success, isValid = SafeCall(function()
		return highlightData.highlight.Parent ~= nil
	end)
	
	return success and isValid or false
end

local function CreateHighlight(target, character: Model, isNPC: boolean): boolean
	local success = SafeCall(function()
		local cacheData = isNPC and RuntimeData.npcHighlightData or RuntimeData.highlightData
		
		if cacheData[target] then
			local oldData = cacheData[target]
			if oldData.highlight then
				oldData.highlight:Destroy()
			end
		end
		
		local highlight = Instance.new("Highlight")
		highlight.Name = (isNPC and "Chams_NPC_" or "Chams_Player_") .. (isNPC and target.Name or target.UserId)
		highlight.Adornee = character
		highlight.DepthMode = GetDepthMode()
		highlight.Enabled = true
		highlight.Parent = character
		
		cacheData[target] = {
			highlight = highlight,
			lastUpdateTick = tick(),
			isNPC = isNPC
		}
		
		return true
	end)
	
	return success
end

local function RemoveHighlight(target, isNPC: boolean)
	local cacheData = isNPC and RuntimeData.npcHighlightData or RuntimeData.highlightData
	
	SafeCall(function()
		local data = cacheData[target]
		if data and data.highlight then
			data.highlight:Destroy()
		end
		cacheData[target] = nil
	end)
	
	if isNPC then
		local npcConns = RuntimeData.npcConnections[target]
		if npcConns then
			for _, conn in pairs(npcConns) do
				SafeCall(function() conn:Disconnect() end)
			end
			RuntimeData.npcConnections[target] = nil
		end
		RuntimeData.trackedNPCs[target] = nil
	else
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
	local shouldShow, isVisible, distance
	
	if isNPC then
		shouldShow, isVisible, distance = GetNPCStatus(target)
	else
		shouldShow, isVisible, distance = GetPlayerStatus(target)
	end
	
	if not shouldShow then
		RemoveHighlight(target, isNPC)
		return
	end
	
	local character = isNPC and target or target.Character
	if not character then
		RemoveHighlight(target, isNPC)
		return
	end
	
	local cacheData = isNPC and RuntimeData.npcHighlightData or RuntimeData.highlightData
	local data = cacheData[target]
	
	if not IsHighlightValid(data) then
		if not CreateHighlight(target, character, isNPC) then
			return
		end
		data = cacheData[target]
	end
	
	if not data then return end
	
	local fillColor, outlineColor = GetChamsColors(target, isVisible)
	
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

--=============================================================================
-- QUEUE & BATCH UPDATE SYSTEM
--=============================================================================

local function RebuildPlayerQueue()
	RuntimeData.playerQueue = {}
	for _, player in Players:GetPlayers() do
		if player ~= LocalPlayer then
			table.insert(RuntimeData.playerQueue, player)
		end
	end
	RuntimeData.currentQueueIndex = 1
end

local function RebuildNPCQueue()
	RuntimeData.npcQueue = {}
	local npcs = NPCSystem.findNPCsRecursive(workspace)
	for _, npc in pairs(npcs) do
		table.insert(RuntimeData.npcQueue, npc)
	end
	RuntimeData.npcQueueIndex = 1
end

local function UpdateBatchChams()
	if not ChamsConfig.enabled and not ChamsConfig.NPCEnabled then return end
	
	local currentTime = tick()
	local deltaTime = currentTime - RuntimeData.lastUpdate
	
	if deltaTime < ChamsConfig.updateInterval then return end
	RuntimeData.lastUpdate = currentTime
	
	-- Update Players
	if ChamsConfig.enabled then
		local queueLength = #RuntimeData.playerQueue
		if queueLength == 0 then
			RebuildPlayerQueue()
			queueLength = #RuntimeData.playerQueue
		end
		
		local batchCount = math.min(ChamsConfig.batchSize, queueLength)
		
		for i = 1, batchCount do
			local index = RuntimeData.currentQueueIndex
			local player = RuntimeData.playerQueue[index]
			
			if player and player.Parent then
				UpdateHighlight(player, false)
			else
				table.remove(RuntimeData.playerQueue, index)
				queueLength = #RuntimeData.playerQueue
				if queueLength == 0 then break end
				if RuntimeData.currentQueueIndex > queueLength then
					RuntimeData.currentQueueIndex = 1
				end
			end
			
			RuntimeData.currentQueueIndex = RuntimeData.currentQueueIndex + 1
			if RuntimeData.currentQueueIndex > #RuntimeData.playerQueue then
				RuntimeData.currentQueueIndex = 1
			end
		end
	end
	
	-- Update NPCs
	if ChamsConfig.NPCEnabled then
		local queueLength = #RuntimeData.npcQueue
		if queueLength == 0 then
			RebuildNPCQueue()
			queueLength = #RuntimeData.npcQueue
		end
		
		local batchCount = math.min(ChamsConfig.batchSize, queueLength)
		
		for i = 1, batchCount do
			local index = RuntimeData.npcQueueIndex
			local npc = RuntimeData.npcQueue[index]
			
			if npc and npc.Parent then
				UpdateHighlight(npc, true)
			else
				table.remove(RuntimeData.npcQueue, index)
				queueLength = #RuntimeData.npcQueue
				if queueLength == 0 then break end
				if RuntimeData.npcQueueIndex > queueLength then
					RuntimeData.npcQueueIndex = 1
				end
			end
			
			RuntimeData.npcQueueIndex = RuntimeData.npcQueueIndex + 1
			if RuntimeData.npcQueueIndex > #RuntimeData.npcQueue then
				RuntimeData.npcQueueIndex = 1
			end
		end
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
		RemoveHighlight(player, false)
	end)
	
	if not table.find(RuntimeData.playerQueue, player) then
		table.insert(RuntimeData.playerQueue, player)
	end
end

--=============================================================================
-- NPC SCANNING & TRACKING
--=============================================================================

local function ScanForNPCs()
	if not ChamsConfig.NPCEnabled then return end
	
	local foundNPCs = NPCSystem.findNPCsRecursive(workspace)
	
	local foundSet = {}
	for _, npc in pairs(foundNPCs) do
		foundSet[npc] = true
	end
	
	-- Xóa NPC không còn tồn tại
	for npc in pairs(RuntimeData.trackedNPCs) do
		if not foundSet[npc] or not npc.Parent then
			RemoveHighlight(npc, true)
		end
	end
	
	-- Thêm NPC mới
	for _, npc in pairs(foundNPCs) do
		if not RuntimeData.trackedNPCs[npc] then
			RuntimeData.trackedNPCs[npc] = true
			if not table.find(RuntimeData.npcQueue, npc) then
				table.insert(RuntimeData.npcQueue, npc)
			end
		end
	end
end

--=============================================================================
-- EVENT INITIALIZATION
--=============================================================================

local function InitializeEvents()
	RuntimeData.connections.heartbeat = RunService.Heartbeat:Connect(UpdateBatchChams)
	
	-- Player events
	RuntimeData.connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
		RemoveHighlight(player, false)
		
		local index = table.find(RuntimeData.playerQueue, player)
		if index then
			table.remove(RuntimeData.playerQueue, index)
			if RuntimeData.currentQueueIndex > #RuntimeData.playerQueue and #RuntimeData.playerQueue > 0 then
				RuntimeData.currentQueueIndex = 1
			end
		end
	end)
	
	RuntimeData.connections.playerAdded = Players.PlayerAdded:Connect(SetupPlayerConnections)
	
	RuntimeData.connections.localCharAdded = LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.5)
		for player in pairs(RuntimeData.highlightData) do
			RemoveHighlight(player, false)
		end
		task.wait(0.2)
		RebuildPlayerQueue()
	end)
	
	-- NPC scanning
	RuntimeData.connections.npcScan = RunService.Heartbeat:Connect(ScanForNPCs)
	
	for _, player in Players:GetPlayers() do
		SetupPlayerConnections(player)
	end
	
	RebuildPlayerQueue()
end

--=============================================================================
-- PUBLIC API
--=============================================================================

local ChamsAPI = {}

function ChamsAPI:Toggle(state: boolean)
	ChamsConfig.enabled = state
	if not state then
		for player in pairs(RuntimeData.highlightData) do
			RemoveHighlight(player, false)
		end
	else
		RebuildPlayerQueue()
	end
end

function ChamsAPI:ToggleNPC(state: boolean)
	ChamsConfig.NPCEnabled = state
	if not state then
		for npc in pairs(RuntimeData.npcHighlightData) do
			RemoveHighlight(npc, true)
		end
		RuntimeData.trackedNPCs = {}
	else
		RebuildNPCQueue()
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

function ChamsAPI:GetTrackedNPCs()
	local npcList = {}
	for npc in pairs(RuntimeData.trackedNPCs) do
		if npc.Parent then
			table.insert(npcList, npc)
		end
	end
	return npcList
end

function ChamsAPI:GetTrackedPlayers()
	local playerList = {}
	for player in pairs(RuntimeData.highlightData) do
		if player.Parent then
			table.insert(playerList, player)
		end
	end
	return playerList
end

function ChamsAPI:Destroy()
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
	
	for npc, conns in pairs(RuntimeData.npcConnections) do
		for _, conn in pairs(conns) do
			SafeCall(function() conn:Disconnect() end)
		end
	end
	RuntimeData.npcConnections = {}
	
	for player in pairs(RuntimeData.highlightData) do
		RemoveHighlight(player, false)
	end
	RuntimeData.highlightData = {}
	
	for npc in pairs(RuntimeData.npcHighlightData) do
		RemoveHighlight(npc, true)
	end
	RuntimeData.npcHighlightData = {}
	
	RuntimeData.trackedNPCs = {}
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

InitializeEvents()

return ChamsAPI
