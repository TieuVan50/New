local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local ChamsConfig = {
	enabled = false,
	NPCEnabled = false,
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
	useVisibilityColors = false,
	NPCFillColor = Color3.fromRGB(255, 255, 0),
	NPCOutlineColor = Color3.fromRGB(255, 255, 0)
}

local NPCTags = {
	"NPC","Npc","npc","Enemy","enemy","Enemies","enemies","Hostile","hostile",
	"Bad","bad","BadGuy","badguy","Foe","foe","Opponent","opponent","Bot","bot",
	"Bots","bots","Mob","mob","Mobs","mobs","Monster","monster","Monsters","monsters",
	"Zombie","zombie","Zombies","zombies","Creature","creature","Animal","animal",
	"Beast","beast","Villain","villain","Boss","boss","MiniBoss","miniboss"
}

local RuntimeData = {
	highlightData = {},
	npcData = {},
	connections = {},
	playerConnections = {},
	playerQueue = {},
	npcQueue = {},
	currentQueueIndex = 1,
	currentNPCQueueIndex = 1,
	lastUpdate = 0
}

local function SafeCall(fn)
	local success, err = pcall(fn)
	return success, err
end

local function IsNPC(model)
	if model:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(model) then
		for _, tag in ipairs(NPCTags) do
			if model.Name:find(tag) then return true end
		end
		for _, tag in ipairs(NPCTags) do
			if CollectionService:HasTag(model, tag) then return true end
		end
	end
	return false
end

local function GetChamsColors(target, isVisible)
	if typeof(target) == "Instance" and target:IsA("Model") then
		return ChamsConfig.NPCFillColor, ChamsConfig.NPCOutlineColor
	end
	
	if ChamsConfig.useVisibilityColors then
		if isVisible then
			return ChamsConfig.visibleFillColor, ChamsConfig.visibleOutlineColor
		else
			return ChamsConfig.hiddenFillColor, ChamsConfig.hiddenOutlineColor
		end
	end

	if ChamsConfig.EnableTeamCheck then
		if target.Team == LocalPlayer.Team then
			return ChamsConfig.AlliedFillColor, ChamsConfig.AlliedOutlineColor
		else
			return ChamsConfig.EnemyFillColor, ChamsConfig.EnemyOutlineColor
		end
	end

	if ChamsConfig.UseTeamColors then
		local color = ChamsConfig.UseActualTeamColors and target.TeamColor.Color or target.Team.TeamColor.Color
		return color, color
	end

	return ChamsConfig.fillColor, ChamsConfig.outlineColor
end

local function CreateHighlight(parent)
	local hl = Instance.new("Highlight")
	hl.FillTransparency = ChamsConfig.fillTransparency
	hl.OutlineTransparency = ChamsConfig.outlineTransparency
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = parent
	return hl
end

local function UpdateHighlightProperties(hl, fc, oc)
	hl.FillColor = fc
	hl.OutlineColor = oc
	hl.FillTransparency = ChamsConfig.fillTransparency
	hl.OutlineTransparency = ChamsConfig.outlineTransparency
	hl.Enabled = true
end

local function RemoveHighlight(target)
	local data = RuntimeData.highlightData[target] or RuntimeData.npcData[target]
	if data and data.highlight then
		data.highlight:Destroy()
	end
	RuntimeData.highlightData[target] = nil
	RuntimeData.npcData[target] = nil
end

local function UpdateHighlight(target, isNPC)
	if not ChamsConfig.enabled and not isNPC then return end
	if isNPC and not ChamsConfig.NPCEnabled then return end

	local character = isNPC and target or target.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) 
		and (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude or 0
	
	if dist > ChamsConfig.maxDistance then
		RemoveHighlight(target)
		return
	end

	if not isNPC and ChamsConfig.EnableTeamCheck then
		local isEnemy = target.Team ~= LocalPlayer.Team
		if ChamsConfig.ShowEnemyOnly and not isEnemy then RemoveHighlight(target) return end
		if ChamsConfig.ShowAlliedOnly and isEnemy then RemoveHighlight(target) return end
	end

	local cache = isNPC and RuntimeData.npcData or RuntimeData.highlightData
	local data = cache[target]
	if not data then
		data = {highlight = CreateHighlight(character), lastUpdateTick = 0}
		cache[target] = data
	end

	local fc, oc = GetChamsColors(target, false)
	UpdateHighlightProperties(data.highlight, fc, oc)
end

local function RebuildQueues()
	RuntimeData.playerQueue = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then table.insert(RuntimeData.playerQueue, p) end
	end
	
	RuntimeData.npcQueue = {}
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("Model") and IsNPC(v) then
			table.insert(RuntimeData.npcQueue, v)
		end
	end
end

local function UpdateBatch()
	if not ChamsConfig.enabled and not ChamsConfig.NPCEnabled then return end
	if tick() - RuntimeData.lastUpdate < ChamsConfig.updateInterval then return end
	RuntimeData.lastUpdate = tick()

	if ChamsConfig.enabled and #RuntimeData.playerQueue > 0 then
		for i = 1, math.min(ChamsConfig.batchSize, #RuntimeData.playerQueue) do
			local p = RuntimeData.playerQueue[RuntimeData.currentQueueIndex]
			if p and p.Parent then UpdateHighlight(p, false) end
			RuntimeData.currentQueueIndex = (RuntimeData.currentQueueIndex % #RuntimeData.playerQueue) + 1
		end
	end

	if ChamsConfig.NPCEnabled and #RuntimeData.npcQueue > 0 then
		for i = 1, math.min(ChamsConfig.batchSize, #RuntimeData.npcQueue) do
			local npc = RuntimeData.npcQueue[RuntimeData.currentNPCQueueIndex]
			if npc and npc.Parent then UpdateHighlight(npc, true) end
			RuntimeData.currentNPCQueueIndex = (RuntimeData.currentNPCQueueIndex % #RuntimeData.npcQueue) + 1
		end
	end
end

local function SetupConnections()
	RuntimeData.connections.render = RunService.Heartbeat:Connect(UpdateBatch)
	RuntimeData.connections.pAdded = Players.PlayerAdded:Connect(RebuildQueues)
	RuntimeData.connections.pRemoving = Players.PlayerRemoving:Connect(function(p)
		RemoveHighlight(p)
		RebuildQueues()
	end)
	
	task.spawn(function()
		while task.wait(5) do
			if ChamsConfig.enabled or ChamsConfig.NPCEnabled then
				RebuildQueues()
			end
		end
	end)
end

local ChamsAPI = {}

function ChamsAPI:Toggle(state)
	ChamsConfig.enabled = state
	if not state then
		for p in pairs(RuntimeData.highlightData) do RemoveHighlight(p) end
	else
		RebuildQueues()
	end
end

function ChamsAPI:ToggleNPC(state)
	ChamsConfig.NPCEnabled = state
	if not state then
		for n in pairs(RuntimeData.npcData) do RemoveHighlight(n) end
	else
		RebuildQueues()
	end
end

function ChamsAPI:UpdateConfig(newConfig)
	for k, v in pairs(newConfig) do
		if ChamsConfig[k] ~= nil then ChamsConfig[k] = v end
	end
end

function ChamsAPI:GetConfig() return ChamsConfig end

function ChamsAPI:Destroy()
	for _, c in pairs(RuntimeData.connections) do c:Disconnect() end
	for p in pairs(RuntimeData.highlightData) do RemoveHighlight(p) end
	for n in pairs(RuntimeData.npcData) do RemoveHighlight(n) end
	RuntimeData.highlightData = {}
	RuntimeData.npcData = {}
end

SetupConnections()
return ChamsAPI
