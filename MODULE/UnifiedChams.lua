--═══════════════════════════════════════════════════════════════════════════════
--  UNIFIED CHAMS SYSTEM - PLAYER & NPC WITH DROPDOWN
--═══════════════════════════════════════════════════════════════════════════════

local Services = {
	Players         = game:GetService("Players"),
	RunService      = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService")
}

--═══════════════════════════════════════════════════════════════════════════════
--  CACHE DỮ LIỆU CHUNG
--═══════════════════════════════════════════════════════════════════════════════

local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera

--═══════════════════════════════════════════════════════════════════════════════
--  DANH SÁCH TAG NPC
--═══════════════════════════════════════════════════════════════════════════════

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

--═══════════════════════════════════════════════════════════════════════════════
--  GLOBAL CONFIG
--═══════════════════════════════════════════════════════════════════════════════

local GLOBAL_CONFIG = {
	-- Chế độ hoạt động
	Mode = "Player",
	enabled = false,
	
	-- Cấu hình chung
	EnableTeamCheck = false,
	ShowEnemyOnly = false,
	ShowAlliedOnly = false,
	
	-- Visibility & Raycasting
	useVisibilityColors = false,
	useRaycasting = false,
	
	-- Depth mode
	depthMode = "AlwaysOnTop", -- "AlwaysOnTop" hoặc "Occluded"
	
	-- Transparency
	fillTransparency = 0.5,
	outlineTransparency = 0,
	
	-- Team Colors
	UseTeamColors = false,
	UseActualTeamColors = true,
	
	-- Colors - Base
	fillColor = Color3.fromRGB(0, 255, 140),
	outlineColor = Color3.fromRGB(0, 255, 140),
	
	-- Colors - Team (Player)
	EnemyFillColor = Color3.fromRGB(255, 0, 0),
	EnemyOutlineColor = Color3.fromRGB(255, 0, 0),
	AlliedFillColor = Color3.fromRGB(0, 255, 0),
	AlliedOutlineColor = Color3.fromRGB(0, 255, 0),
	NoTeamColor = Color3.fromRGB(255, 255, 255),
	
	-- Colors - Visibility
	visibleFillColor = Color3.fromRGB(0, 255, 0),
	visibleOutlineColor = Color3.fromRGB(0, 255, 0),
	hiddenFillColor = Color3.fromRGB(255, 0, 0),
	hiddenOutlineColor = Color3.fromRGB(255, 0, 0),
	
	-- NPC Specific
	EnableTagFilter = true,
	AggressiveNPCDetection = false,
	UseNPCColors = false,
	StandardNPCFillColor = Color3.fromRGB(255, 0, 0),
	StandardNPCOutlineColor = Color3.fromRGB(255, 0, 0),
	BossNPCFillColor = Color3.fromRGB(255, 165, 0),
	BossNPCOutlineColor = Color3.fromRGB(255, 165, 0),
}

--═══════════════════════════════════════════════════════════════════════════════
--  BỘ NHỚ CHAMS
--═══════════════════════════════════════════════════════════════════════════════

local ChamsStorage = {
	Chams = {},           -- Lưu tất cả chams data
	TrackedNPCs = {},     -- Tracking NPC
	RenderConnection = nil,
	ScanConnection = nil
}

--═══════════════════════════════════════════════════════════════════════════════
--  TEAM SYSTEM
--═══════════════════════════════════════════════════════════════════════════════

local TeamSystem = {}

function TeamSystem.getPlayerTeam(targetPlayer)
	if not targetPlayer then return nil end
	
	if targetPlayer.Team then
		return {
			Name = targetPlayer.Team.Name,
			TeamColor = targetPlayer.Team.TeamColor,
			Instance = targetPlayer.Team
		}
	end
	
	return nil
end

function TeamSystem.isSameTeam(player1, player2)
	if not player1 or not player2 then return false end
	if player1 == player2 then return true end
	
	local team1 = TeamSystem.getPlayerTeam(player1)
	local team2 = TeamSystem.getPlayerTeam(player2)
	
	if not team1 and not team2 then return true end
	if not team1 or not team2 then return false end
	
	if team1.Instance and team2.Instance then
		return team1.Instance == team2.Instance
	end
	
	return team1.Name == team2.Name
end

--═══════════════════════════════════════════════════════════════════════════════
--  NPC SYSTEM
--═══════════════════════════════════════════════════════════════════════════════

local NPCSystem = {}

function NPCSystem.isPlayer(character)
	if not character or not character:IsA("Model") then return false end
	if character == LocalPlayer.Character then return true end
	local player = Services.Players:GetPlayerFromCharacter(character)
	return player ~= nil
end

function NPCSystem.isNPC(character)
	if not character or not character:IsA("Model") then return false end
	if NPCSystem.isPlayer(character) then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not head or not hrp or humanoid.Health <= 0 then return false end
	
	if GLOBAL_CONFIG.AggressiveNPCDetection then 
		return true
	end
	
	if not GLOBAL_CONFIG.EnableTagFilter then
		return true
	end
	
	local charName = character.Name:lower()
	for _, tag in pairs(NPCTags) do
		if charName:find(tag:lower(), 1, true) then return true end
	end
	
	local npcFolders = {"NPCs", "Enemies", "Bots", "Mobs", "Targets", "Enemy", "Hostile",
		"Monsters", "Zombies", "Creatures", "Characters", "Spawns", "EnemySpawns", "NPCSpawns", "Bosses"}
	
	for _, folderName in pairs(npcFolders) do
		local folder = workspace:FindFirstChild(folderName)
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

--═══════════════════════════════════════════════════════════════════════════════
--  UTILS
--═══════════════════════════════════════════════════════════════════════════════

local Utils = {}

function Utils.isTargetVisible(target)
	if not target or not target.Parent then return false end
	
	local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	if not GLOBAL_CONFIG.useRaycasting then
		return true
	end
	
	local rayOrigin = LocalPlayer.Character:FindFirstChild("Head")
	if not rayOrigin then return false end
	
	local rayDirection = (humanoidRootPart.Position - rayOrigin.Position).Unit * 1000
	local raycastResult = workspace:FindPartOnRay(Ray.new(rayOrigin.Position, rayDirection), LocalPlayer.Character)
	
	if raycastResult and (raycastResult:IsDescendantOf(target) or raycastResult.Parent:IsDescendantOf(target)) then
		return true
	end
	
	return raycastResult == nil
end

function Utils.getChamsColor(target, isVisible)
	-- Nếu là player
	if Services.Players:GetPlayerFromCharacter(target) then
		local targetPlayer = Services.Players:GetPlayerFromCharacter(target)
		
		-- Visibility colors
		if GLOBAL_CONFIG.useVisibilityColors then
			if isVisible then
				return GLOBAL_CONFIG.visibleFillColor, GLOBAL_CONFIG.visibleOutlineColor
			else
				return GLOBAL_CONFIG.hiddenFillColor, GLOBAL_CONFIG.hiddenOutlineColor
			end
		end
		
		-- Team colors
		if GLOBAL_CONFIG.UseTeamColors then
			if GLOBAL_CONFIG.UseActualTeamColors then
				local team = TeamSystem.getPlayerTeam(targetPlayer)
				if team and team.TeamColor then
					return team.TeamColor.Color, team.TeamColor.Color
				end
			else
				local isEnemy = not TeamSystem.isSameTeam(LocalPlayer, targetPlayer)
				if isEnemy then
					return GLOBAL_CONFIG.EnemyFillColor, GLOBAL_CONFIG.EnemyOutlineColor
				else
					return GLOBAL_CONFIG.AlliedFillColor, GLOBAL_CONFIG.AlliedOutlineColor
				end
			end
			return GLOBAL_CONFIG.NoTeamColor, GLOBAL_CONFIG.NoTeamColor
		end
	-- Nếu là NPC
	elseif target:IsA("Model") and NPCSystem.isNPC(target) then
		if GLOBAL_CONFIG.UseNPCColors then
			local isBoss = NPCSystem.isBoss(target)
			if isBoss then
				return GLOBAL_CONFIG.BossNPCFillColor, GLOBAL_CONFIG.BossNPCOutlineColor
			else
				return GLOBAL_CONFIG.StandardNPCFillColor, GLOBAL_CONFIG.StandardNPCOutlineColor
			end
		end
	end
	
	return GLOBAL_CONFIG.fillColor, GLOBAL_CONFIG.outlineColor
end

--═══════════════════════════════════════════════════════════════════════════════
--  CHAMS MANAGER
--═══════════════════════════════════════════════════════════════════════════════

local ChamsManager = {}

function ChamsManager.create(target)
	if ChamsStorage.Chams[target] then
		return ChamsStorage.Chams[target]
	end
	
	local character
	if target:IsA("Player") then
		character = target.Character
	elseif target:IsA("Model") then
		character = target
	else
		return nil
	end
	
	if not character then return nil end
	
	local chamsData = {
		Target = target,
		Character = character,
		Parts = {}
	}
	
	-- Tạo chams cho tất cả parts
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			ChamsManager.createPartChams(part, chamsData)
		end
	end
	
	ChamsStorage.Chams[target] = chamsData
	return chamsData
end

function ChamsManager.createPartChams(part, chamsData)
	if ChamsStorage.Chams[part] then return end
	
	-- Tạo Surface GUI (fill)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "ChamsGUI"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.ResetOnSpawn = false
	surfaceGui.Parent = part
	
	local fillFrame = Instance.new("Frame")
	fillFrame.Name = "ChamsFill"
	fillFrame.BackgroundColor3 = GLOBAL_CONFIG.fillColor
	fillFrame.BackgroundTransparency = GLOBAL_CONFIG.fillTransparency
	fillFrame.BorderSizePixel = 0
	fillFrame.Size = UDim2.new(1, 0, 1, 0)
	fillFrame.Parent = surfaceGui
	
	-- Outline
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = GLOBAL_CONFIG.outlineColor
	uiStroke.Thickness = 1
	uiStroke.Transparency = GLOBAL_CONFIG.outlineTransparency
	uiStroke.Parent = fillFrame
	
	-- Tambah ke chams data
	table.insert(chamsData.Parts, {
		Part = part,
		SurfaceGui = surfaceGui,
		Frame = fillFrame,
		UIStroke = uiStroke
	})
end

function ChamsManager.update(target, chamsData)
	if not chamsData or not target.Parent then
		ChamsManager.remove(target)
		return
	end
	
	local character
	if target:IsA("Player") then
		character = target.Character
	elseif target:IsA("Model") then
		character = target
	else
		return
	end
	
	if not character then
		ChamsManager.remove(target)
		return
	end
	
	-- Humanoid check
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		ChamsManager.remove(target)
		return
	end
	
	-- Team check (Player only)
	if target:IsA("Player") and GLOBAL_CONFIG.EnableTeamCheck then
		local isEnemy = not TeamSystem.isSameTeam(LocalPlayer, target)
		
		if GLOBAL_CONFIG.ShowEnemyOnly and not isEnemy then
			ChamsManager.setVisible(chamsData, false)
			return
		end
		
		if GLOBAL_CONFIG.ShowAlliedOnly and isEnemy then
			ChamsManager.setVisible(chamsData, false)
			return
		end
	end
	
	-- Check visibility
	local isVisible = Utils.isTargetVisible(character)
	
	-- Update colors
	local fillColor, outlineColor = Utils.getChamsColor(character, isVisible)
	
	for _, partData in pairs(chamsData.Parts) do
		if partData.Part and partData.Part.Parent then
			if partData.Frame then
				partData.Frame.BackgroundColor3 = fillColor
				partData.Frame.BackgroundTransparency = GLOBAL_CONFIG.fillTransparency
			end
			
			if partData.UIStroke then
				partData.UIStroke.Color = outlineColor
				partData.UIStroke.Transparency = GLOBAL_CONFIG.outlineTransparency
			end
		end
	end
	
	ChamsManager.setVisible(chamsData, GLOBAL_CONFIG.enabled)
end

function ChamsManager.setVisible(chamsData, visible)
	if not chamsData then return end
	
	for _, partData in pairs(chamsData.Parts) do
		if partData.SurfaceGui then
			partData.SurfaceGui.Enabled = visible
		end
	end
end

function ChamsManager.updateAll()
	for target, chamsData in pairs(ChamsStorage.Chams) do
		if target and target.Parent and chamsData then
			ChamsManager.update(target, chamsData)
		else
			ChamsManager.remove(target)
		end
	end
end

function ChamsManager.remove(target)
	local chamsData = ChamsStorage.Chams[target]
	if chamsData then
		for _, partData in pairs(chamsData.Parts) do
			if partData.SurfaceGui then
				partData.SurfaceGui:Destroy()
			end
		end
		ChamsStorage.Chams[target] = nil
	end
	ChamsStorage.TrackedNPCs[target] = nil
end

--═══════════════════════════════════════════════════════════════════════════════
--  PLAYER MODE
--═══════════════════════════════════════════════════════════════════════════════

local PlayerMode = {}

function PlayerMode.onPlayerAdded(newPlayer)
	if newPlayer ~= LocalPlayer then
		task.wait(0.5)
		ChamsManager.create(newPlayer)
	end
end

function PlayerMode.onPlayerRemoving(leavingPlayer)
	ChamsManager.remove(leavingPlayer)
end

function PlayerMode.initialize()
	for _, otherPlayer in pairs(Services.Players:GetPlayers()) do
		if otherPlayer ~= LocalPlayer then
			PlayerMode.onPlayerAdded(otherPlayer)
		end
	end
	
	Services.Players.PlayerAdded:Connect(function(player)
		if GLOBAL_CONFIG.Mode == "Player" then
			PlayerMode.onPlayerAdded(player)
		end
	end)
	
	Services.Players.PlayerRemoving:Connect(function(player)
		if GLOBAL_CONFIG.Mode == "Player" then
			PlayerMode.onPlayerRemoving(player)
		end
	end)
end

function PlayerMode.cleanup()
	local playersToRemove = {}
	for target in pairs(ChamsStorage.Chams) do
		if target:IsA("Player") then
			table.insert(playersToRemove, target)
		end
	end
	
	for _, player in pairs(playersToRemove) do
		ChamsManager.remove(player)
	end
end

--═══════════════════════════════════════════════════════════════════════════════
--  NPC MODE
--═══════════════════════════════════════════════════════════════════════════════

local NPCMode = {}

function NPCMode.scanForNPCs()
	local foundNPCs = NPCSystem.findNPCsRecursive(workspace)
	
	local foundSet = {}
	for _, npc in pairs(foundNPCs) do
		foundSet[npc] = true
	end
	
	for npc in pairs(ChamsStorage.TrackedNPCs) do
		if not foundSet[npc] or not npc.Parent then
			ChamsManager.remove(npc)
		end
	end
	
	for _, npc in pairs(foundNPCs) do
		if not ChamsStorage.TrackedNPCs[npc] then
			ChamsStorage.TrackedNPCs[npc] = true
			ChamsManager.create(npc)
		end
	end
end

function NPCMode.initialize()
	NPCMode.scanForNPCs()
	
	if not ChamsStorage.ScanConnection then
		ChamsStorage.ScanConnection = Services.RunService.Heartbeat:Connect(function()
			if GLOBAL_CONFIG.Mode == "NPC" then
				NPCMode.scanForNPCs()
			end
		end)
	end
end

function NPCMode.cleanup()
	local npcsToRemove = {}
	for target in pairs(ChamsStorage.Chams) do
		if target:IsA("Model") and NPCSystem.isNPC(target) then
			table.insert(npcsToRemove, target)
		end
	end
	
	for _, npc in pairs(npcsToRemove) do
		ChamsManager.remove(npc)
	end
	
	ChamsStorage.TrackedNPCs = {}
end

--═══════════════════════════════════════════════════════════════════════════════
--  MODE SWITCHING
--═══════════════════════════════════════════════════════════════════════════════

local function switchMode(newMode)
	if newMode == GLOBAL_CONFIG.Mode then return end
	
	for target in pairs(ChamsStorage.Chams) do
		ChamsManager.remove(target)
	end
	
	GLOBAL_CONFIG.Mode = newMode
	
	if newMode == "Player" then
		PlayerMode.cleanup()
		NPCMode.cleanup()
		PlayerMode.initialize()
	else
		PlayerMode.cleanup()
		NPCMode.cleanup()
		NPCMode.initialize()
	end
end

--═══════════════════════════════════════════════════════════════════════════════
--  INITIALIZATION
--═══════════════════════════════════════════════════════════════════════════════

local function initialize()
	-- Initialize Player mode
	PlayerMode.initialize()
	
	-- Main render loop
	ChamsStorage.RenderConnection = Services.RunService.RenderStepped:Connect(function()
		ChamsManager.updateAll()
	end)
end

initialize()

--═══════════════════════════════════════════════════════════════════════════════
--  PUBLIC API
--═══════════════════════════════════════════════════════════════════════════════

local UnifiedChamsModule = {}

function UnifiedChamsModule:UpdateConfig(newConfig)
	for key, value in pairs(newConfig) do
		if GLOBAL_CONFIG[key] ~= nil then
			GLOBAL_CONFIG[key] = value
		end
	end
end

function UnifiedChamsModule:GetConfig()
	return GLOBAL_CONFIG
end

function UnifiedChamsModule:Toggle(state)
	GLOBAL_CONFIG.enabled = state
end

function UnifiedChamsModule:SetMode(mode)
	if mode == "Player" or mode == "NPC" then
		switchMode(mode)
	else
		warn("Invalid mode: " .. tostring(mode) .. ". Use 'Player' or 'NPC'")
	end
end

function UnifiedChamsModule:GetMode()
	return GLOBAL_CONFIG.Mode
end

function UnifiedChamsModule:Destroy()
	if ChamsStorage.RenderConnection then
		ChamsStorage.RenderConnection:Disconnect()
	end
	
	if ChamsStorage.ScanConnection then
		ChamsStorage.ScanConnection:Disconnect()
	end
	
	for target in pairs(ChamsStorage.Chams) do
		ChamsManager.remove(target)
	end
end

function UnifiedChamsModule:GetTrackedTargets()
	local targets = {}
	for target in pairs(ChamsStorage.Chams) do
		table.insert(targets, target)
	end
	return targets
end

return UnifiedChamsModule
