local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

-- Types
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

-- NPC Tags
local NPCTags = {
	"NPC","Npc","npc","Enemy","enemy","Enemies","enemies","Hostile","hostile",
	"Bad","bad","BadGuy","badguy","Foe","foe","Opponent","opponent","Bot","bot",
	"Bots","bots","Mob","mob","Mobs","mobs","Monster","monster","Monsters","monsters",
	"Zombie","zombie","Zombies","zombies","Creature","creature","Animal","animal",
	"Beast","beast","Villain","villain","Boss","boss","MiniBoss","miniboss",
	"Guard","guard","Guardian","guardian","Soldier","soldier","Warrior","warrior",
	"Fighter","fighter","Target","target","Dummy","dummy","Dummies","dummies",
	"Skeleton","skeleton","Orc","orc","Goblin","goblin","Robot","robot","Drone",
	"drone","Android","android","Cyborg","cyborg","Automaton","automaton",
	"Servant","servant","Minion","minion","Slave","slave","Pawn","pawn",
	"AI","ai","A.I.","Char","char","Character","character","Model","model",
	"Event","event","Special","special","Angel","angel","Archangel","archangel",
	"Crystal","crystal","Demon","demon","Elf","elf","Ghost","ghost","Santa",
	"santa","Slime","slime","Vampire","vampire","Void Slime","void slime",
}

-- Configuration
local ChamsConfig = {
	-- Mode: "Player", "NPC", "Both"
	enabled = false,
	mode = "Both", -- Player, NPC, Both
	maxDistance = 10000,
	updateInterval = 0.05,
	batchSize = 5,
	
	-- Visual Settings
	fillColor = Color3.fromRGB(0, 255, 140),
	outlineColor = Color3.fromRGB(0, 255, 140),
	visibleFillColor = Color3.fromRGB(0, 255, 0),
	visibleOutlineColor = Color3.fromRGB(0, 255, 0),
	hiddenFillColor = Color3.fromRGB(255, 0, 0),
	hiddenOutlineColor = Color3.fromRGB(255, 0, 0),
	fillTransparency = 0.5,
	outlineTransparency = 0,
	
	-- Team Settings
	enableTeamCheck = false,
	showEnemyOnly = false,
	showAlliedOnly = false,
	useTeamColors = false,
	useActualTeamColors = true,
	enemyFillColor = Color3.fromRGB(255, 0, 0),
	enemyOutlineColor = Color3.fromRGB(255, 0, 0),
	alliedFillColor = Color3.fromRGB(0, 255, 0),
	alliedOutlineColor = Color3.fromRGB(0, 255, 0),
	noTeamColor = Color3.fromRGB(255, 255, 255),
	
	-- NPC Settings
	NPCEnabled = false,
	NPCMaxDistance = 10000,
	NPCFillColor = Color3.fromRGB(255, 165, 0),
	NPCOutlineColor = Color3.fromRGB(255, 165, 0),
	StandardNPCColor = Color3.fromRGB(255, 0, 0),
	BossNPCColor = Color3.fromRGB(255, 165, 0),
	UseNPCColors = false,
	EnableTagFilter = true,
	AggressiveNPCDetection = false,
	
	-- Advanced Settings
	depthMode = "AlwaysOnTop", -- "AlwaysOnTop" or "Occluded"
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
	trackedNPCs = {} :: {[Model]: boolean},
	cachedDepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
}

-- Utility Functions
local function SafeCall(func, ...)
	return pcall(func, ...)
end

local function GetDepthMode()
	return ChamsConfig.depthMode == "Occluded"
		and Enum.HighlightDepthMode.Occluded
		or Enum.HighlightDepthMode.AlwaysOnTop
end

-- NPC System
local NPCSystem = {}

function NPCSystem.isPlayer(character)
	if not character or not character:IsA("Model") then return false end
	if character == LocalPlayer.Character then return true end
	return Players:GetPlayerFromCharacter(character) ~= nil
end

function NPCSystem.isNPC(character)
	if not character or not character:IsA("Model") then return false end
	if NPCSystem.isPlayer(character) then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not head or not hrp or humanoid.Health <= 0 then return false end
	if ChamsConfig.AggressiveNPCDetection then return true end
	
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
	local function isBossTag(str)
		local s = string.lower(str)
		return string.find(s, "boss") or string.find(s, "miniboss") or string.find(s, "guardian")
	end
	if isBossTag(npc.Name) then return true end
	
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.MaxHealth > 100 then return true end
	return false
end

function NPCSystem.findNPCsRecursive(parent)
	local found = {}
	local function scan(obj)
		if obj:IsA("Model") and NPCSystem.isNPC(obj) then
			table.insert(found, obj)
		end
		local ok, children = pcall(function() return obj:GetChildren() end)
		if ok then
			for _, c in pairs(children) do
				scan(c)
			end
		end
	end
	scan(parent)
	return found
end

-- Team Functions
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
	if not ChamsConfig.enableTeamCheck then return true end
	local e = isEnemy(targetPlayer)
	if ChamsConfig.showEnemyOnly and not e then return false end
	if ChamsConfig.showAlliedOnly and e then return false end
	return true
end

-- Raycast Functions
local function CheckLineOfSight(fromPos: Vector3, toPos: Vector3, ignoreChars): boolean
	if not ChamsConfig.useRaycasting then return true end
	local dir = toPos - fromPos
	if dir.Magnitude == 0 then return true end
	
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances = ignoreChars
	p.IgnoreWater = true
	
	local ok, res = SafeCall(function()
		return workspace:Raycast(fromPos, dir, p)
	end)
	
	if ok and res and res.Instance then
		local hitDist = (res.Position - toPos).Magnitude
		if hitDist < 5 then return true end
		local m = res.Instance:FindFirstAncestorOfClass("Model")
		if m and m:FindFirstChild("Humanoid") then return true end
		return false
	end
	
	return true
end

-- Color Functions
local function GetChamsColors(target, isVisible: boolean, isNPC: boolean)
	if isNPC then
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
		if ChamsConfig.useVisibilityColors then
			if isVisible then
				return ChamsConfig.visibleFillColor, ChamsConfig.visibleOutlineColor
			else
				return ChamsConfig.hiddenFillColor, ChamsConfig.hiddenOutlineColor
			end
		end
		
		if not ChamsConfig.useTeamColors then
			return ChamsConfig.fillColor, ChamsConfig.outlineColor
		end
		
		if ChamsConfig.useActualTeamColors then
			local c = getPlayerTeamColor(target)
			if c then
				return c, c
			else
				return ChamsConfig.noTeamColor, ChamsConfig.noTeamColor
			end
		else
			if isEnemy(target) then
				return ChamsConfig.enemyFillColor, ChamsConfig.enemyOutlineColor
			else
				return ChamsConfig.alliedFillColor, ChamsConfig.alliedOutlineColor
			end
		end
	end
end

-- Status Check Functions
local function GetPlayerStatus(player: Player): (boolean, boolean, number)
	if not ChamsConfig.enabled or player == LocalPlayer then
		return false, false, 0
	end
	
	local ok, r = SafeCall(function()
		local ch = player.Character
		if not ch then return {false, false, 0} end
		local hrp = ch:FindFirstChild("HumanoidRootPart")
		local hum = ch:FindFirstChild("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then
			return {false, false, 0}
		end
		
		local my = LocalPlayer.Character
		if not my then return {false, false, 0} end
		local myHrp = my:FindFirstChild("HumanoidRootPart")
		if not myHrp then return {false, false, 0} end
		
		local d = (hrp.Position - myHrp.Position).Magnitude
		if d > ChamsConfig.maxDistance then
			return {false, false, d}
		end
		
		if not shouldShowPlayer(player) then
			return {false, false, d}
		end
		
		local vis = CheckLineOfSight(myHrp.Position, hrp.Position, {my, ch})
		return {true, vis, d}
	end)
	
	if ok and r then return r[1], r[2], r[3] end
	return false, false, 0
end

local function GetNPCStatus(npc: Model): (boolean, boolean, number)
	if not ChamsConfig.NPCEnabled or not npc then
		return false, false, 0
	end
	
	local ok, r = SafeCall(function()
		local hum = npc:FindFirstChildOfClass("Humanoid")
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp or hum.Health <= 0 then
			return {false, false, 0}
		end
		
		local my = LocalPlayer.Character
		if not my then return {false, false, 0} end
		local myHrp = my:FindFirstChild("HumanoidRootPart")
		if not myHrp then return {false, false, 0} end
		
		local d = (hrp.Position - myHrp.Position).Magnitude
		if d > ChamsConfig.NPCMaxDistance then
			return {false, false, d}
		end
		
		local vis = CheckLineOfSight(myHrp.Position, hrp.Position, {my, npc})
		return {true, vis, d}
	end)
	
	if ok and r then return r[1], r[2], r[3] end
	return false, false, 0
end

-- Highlight Management
local function IsHighlightValid(data: HighlightData?): boolean
	if not data or not data.highlight then return false end
	local ok, v = SafeCall(function()
		return data.highlight.Parent ~= nil
	end)
	return ok and v or false
end

local function CreateHighlight(target, character: Model, isNPC: boolean): boolean
	local ok = SafeCall(function()
		local cache = isNPC and RuntimeData.npcHighlightData or RuntimeData.highlightData
		if cache[target] and cache[target].highlight then
			cache[target].highlight:Destroy()
		end
		
		local h = Instance.new("Highlight")
		h.Name = (isNPC and "Chams_NPC_" or "Chams_Player_") .. (isNPC and target.Name or target.UserId)
		h.Adornee = character
		h.DepthMode = GetDepthMode()
		h.Enabled = true
		h.Parent = character
		
		cache[target] = {
			highlight = h,
			lastUpdateTick = tick(),
			isNPC = isNPC
		}
	end)
	return ok
end

local function RemoveHighlight(target, isNPC: boolean)
	local cache = isNPC and RuntimeData.npcHighlightData or RuntimeData.highlightData
	SafeCall(function()
		local d = cache[target]
		if d and d.highlight then d.highlight:Destroy() end
		cache[target] = nil
	end)
end

local function UpdateHighlightProperties(h: Highlight, fc: Color3, oc: Color3)
	h.FillColor = fc
	h.OutlineColor = oc
	h.FillTransparency = ChamsConfig.fillTransparency
	h.OutlineTransparency = ChamsConfig.outlineTransparency
	h.DepthMode = GetDepthMode()
end

local function UpdateHighlight(target, isNPC: boolean)
	local show, vis = (isNPC and GetNPCStatus(target) or GetPlayerStatus(target))
	if not show then
		RemoveHighlight(target, isNPC)
		return
	end
	
	local character = isNPC and target or target.Character
	if not character then
		RemoveHighlight(target, isNPC)
		return
	end
	
	local cache = isNPC and RuntimeData.npcHighlightData or RuntimeData.highlightData
	local data = cache[target]
	
	if not IsHighlightValid(data) then
		if not CreateHighlight(target, character, isNPC) then return end
		data = cache[target]
	end
	if not data then return end
	
	local fc, oc = GetChamsColors(target, vis, isNPC)
	SafeCall(function()
		if data.highlight then
			if data.highlight.Adornee ~= character then
				data.highlight.Adornee = character
			end
			UpdateHighlightProperties(data.highlight, fc, oc)
		end
	end)
end

-- Queue Management
local function RebuildPlayerQueue()
	RuntimeData.playerQueue = {}
	for _, p in Players:GetPlayers() do
		if p ~= LocalPlayer then table.insert(RuntimeData.playerQueue, p) end
	end
	RuntimeData.currentQueueIndex = 1
end

local function RebuildNPCQueue()
	RuntimeData.npcQueue = {}
	for npc in pairs(RuntimeData.trackedNPCs) do
		if npc.Parent then
			table.insert(RuntimeData.npcQueue, npc)
		end
	end
	RuntimeData.npcQueueIndex = 1
end

local function ScanForNPCs()
	if not ChamsConfig.NPCEnabled then return end
	
	local foundNPCs = NPCSystem.findNPCsRecursive(workspace)
	
	local foundSet = {}
	for _, npc in pairs(foundNPCs) do
		foundSet[npc] = true
	end
	
	-- Remove NPCs that no longer exist
	for npc in pairs(RuntimeData.trackedNPCs) do
		if not foundSet[npc] or not npc.Parent then
			RuntimeData.trackedNPCs[npc] = nil
			RemoveHighlight(npc, true)
		end
	end
	
	-- Add new NPCs
	for _, npc in pairs(foundNPCs) do
		if not RuntimeData.trackedNPCs[npc] then
			RuntimeData.trackedNPCs[npc] = true
		end
	end
	
	RebuildNPCQueue()
end

-- Batch Update
local function UpdateBatchChams()
	if not ChamsConfig.enabled and not ChamsConfig.NPCEnabled then return end
	if tick() - RuntimeData.lastUpdate < ChamsConfig.updateInterval then return end
	RuntimeData.lastUpdate = tick()
	
	local mode = ChamsConfig.mode
	
	-- Update Players
	if (mode == "Player" or mode == "Both") and ChamsConfig.enabled then
		if #RuntimeData.playerQueue == 0 then RebuildPlayerQueue() end
		for i = 1, math.min(ChamsConfig.batchSize, #RuntimeData.playerQueue) do
			local idx = RuntimeData.currentQueueIndex
			local p = RuntimeData.playerQueue[idx]
			if p and p.Parent then UpdateHighlight(p, false) end
			RuntimeData.currentQueueIndex += 1
			if RuntimeData.currentQueueIndex > #RuntimeData.playerQueue then
				RuntimeData.currentQueueIndex = 1
			end
		end
	end
	
	-- Update NPCs
	if (mode == "NPC" or mode == "Both") and ChamsConfig.NPCEnabled then
		if #RuntimeData.npcQueue == 0 then RebuildNPCQueue() end
		for i = 1, math.min(ChamsConfig.batchSize, #RuntimeData.npcQueue) do
			local idx = RuntimeData.npcQueueIndex
			local npc = RuntimeData.npcQueue[idx]
			if npc and npc.Parent then UpdateHighlight(npc, true) end
			RuntimeData.npcQueueIndex += 1
			if RuntimeData.npcQueueIndex > #RuntimeData.npcQueue then
				RuntimeData.npcQueueIndex = 1
			end
		end
	end
end

-- Initialize
RebuildPlayerQueue()

-- NPC Scanning Loop
task.spawn(function()
	while true do
		task.wait(2)
		if ChamsConfig.mode == "NPC" or ChamsConfig.mode == "Both" then
			ScanForNPCs()
		end
	end
end)

-- Main Update Loop
RunService.RenderStepped:Connect(UpdateBatchChams)

-- API
local ChamsAPI = {}

function ChamsAPI:Toggle(state: boolean)
	ChamsConfig.enabled = state
	if not state then
		for p in pairs(RuntimeData.highlightData) do
			RemoveHighlight(p, false)
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
		ScanForNPCs()
	end
end

function ChamsAPI:SetMode(mode: string)
	if mode ~= "Player" and mode ~= "NPC" and mode ~= "Both" then
		warn("Invalid mode. Use 'Player', 'NPC', or 'Both'")
		return
	end
	
	ChamsConfig.mode = mode
	
	-- Clear inappropriate highlights based on mode
	if mode == "Player" then
		for npc in pairs(RuntimeData.npcHighlightData) do
			RemoveHighlight(npc, true)
		end
		RuntimeData.trackedNPCs = {}
	elseif mode == "NPC" then
		for p in pairs(RuntimeData.highlightData) do
			RemoveHighlight(p, false)
		end
	end
	
	-- Rebuild queues
	if mode == "Player" or mode == "Both" then
		RebuildPlayerQueue()
	end
	if mode == "NPC" or mode == "Both" then
		ScanForNPCs()
	end
end

function ChamsAPI:GetMode()
	return ChamsConfig.mode
end

function ChamsAPI:GetConfig()
	return ChamsConfig
end

function ChamsAPI:UpdateConfig(newConfig)
	for key, value in pairs(newConfig) do
		if ChamsConfig[key] ~= nil then
			ChamsConfig[key] = value
		end
	end
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
	for p in pairs(RuntimeData.highlightData) do
		table.insert(playerList, p)
	end
	return playerList
end

function ChamsAPI:Destroy()
	for p in pairs(RuntimeData.highlightData) do
		RemoveHighlight(p, false)
	end
	for npc in pairs(RuntimeData.npcHighlightData) do
		RemoveHighlight(npc, true)
	end
end

return ChamsAPI
