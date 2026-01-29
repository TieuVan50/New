--═══════════════════════════════════════════════════════════════════════════════
--  CHAMS SYSTEM - PLAYER & NPC WITH CHAMS RENDERING
--═══════════════════════════════════════════════════════════════════════════════

local Services = {
	Players         = game:GetService("Players"),
	RunService      = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	TweenService    = game:GetService("TweenService")
}

--═══════════════════════════════════════════════════════════════════════════════
--  CACHE & REFERENCES
--═══════════════════════════════════════════════════════════════════════════════

local LocalPlayer = Services.Players.LocalPlayer
local Cache = {
	LocalPlayer = LocalPlayer,
	Mouse       = LocalPlayer:GetMouse(),
	Camera      = workspace.CurrentCamera,
	PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
}

--═══════════════════════════════════════════════════════════════════════════════
--  NPC TAGS LIST
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

--═══════════════════════════════════════════════════════════════════════════════
--  CHAMS CONFIG
--═══════════════════════════════════════════════════════════════════════════════

local CHAMS_CONFIG = {
	-- PLAYER CHAMS
	enabled = false,
	EnableTeamCheck = false,
	ShowEnemyOnly = false,
	ShowAlliedOnly = false,
	useVisibilityColors = false,
	useRaycasting = false,
	depthMode = "AlwaysOnTop",
	fillTransparency = 0.5,
	outlineTransparency = 0,
	UseTeamColors = false,
	UseActualTeamColors = true,
	
	fillColor = Color3.fromRGB(0, 255, 140),
	outlineColor = Color3.fromRGB(0, 255, 140),
	EnemyFillColor = Color3.fromRGB(255, 0, 0),
	EnemyOutlineColor = Color3.fromRGB(255, 0, 0),
	AlliedFillColor = Color3.fromRGB(0, 255, 0),
	AlliedOutlineColor = Color3.fromRGB(0, 255, 0),
	NoTeamColor = Color3.fromRGB(255, 255, 255),
	visibleFillColor = Color3.fromRGB(0, 255, 0),
	visibleOutlineColor = Color3.fromRGB(0, 255, 0),
	hiddenFillColor = Color3.fromRGB(255, 0, 0),
	hiddenOutlineColor = Color3.fromRGB(255, 0, 0),
	
	-- NPC CHAMS (NEW)
	NPCChamsEnabled = false,
	NPCChamsTagFilter = true,
	NPCChamsAggressive = false,
	NPCChamsUseVisibilityColors = false,
	NPCChamsUseRaycasting = false,
	NPCChamsDepthMode = "AlwaysOnTop",
	NPCChamsFillTransparency = 0.5,
	NPCChamsOutlineTransparency = 0,
	
	NPCChamsStandardFillColor = Color3.fromRGB(255, 0, 0),
	NPCChamsStandardOutlineColor = Color3.fromRGB(255, 0, 0),
	NPCChamsBossFillColor = Color3.fromRGB(255, 165, 0),
	NPCChamsBossOutlineColor = Color3.fromRGB(255, 165, 0),
	NPCChamsVisibleFillColor = Color3.fromRGB(0, 255, 0),
	NPCChamsVisibleOutlineColor = Color3.fromRGB(0, 255, 0),
	NPCChamsHiddenFillColor = Color3.fromRGB(255, 0, 0),
	NPCChamsHiddenOutlineColor = Color3.fromRGB(255, 0, 0),
}

--═══════════════════════════════════════════════════════════════════════════════
--  CHAMS STORAGE
--═══════════════════════════════════════════════════════════════════════════════

local ChamsStorage = {
	PlayerChams = {},        -- {Player -> chams data}
	NPCChams = {},           -- {NPC -> chams data}
	TrackedNPCs = {},        -- {NPC -> true}
	ScanConnection = nil,
	UpdateConnection = nil,
	MainScreenGui = nil
}

--═══════════════════════════════════════════════════════════════════════════════
--  INITIALIZE SCREEN GUI
--═══════════════════════════════════════════════════════════════════════════════

local function initializeScreenGui()
	if ChamsStorage.MainScreenGui then return ChamsStorage.MainScreenGui end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ChamsRenderer"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 999
	screenGui.Parent = Cache.PlayerGui
	
	ChamsStorage.MainScreenGui = screenGui
	return screenGui
end

--═══════════════════════════════════════════════════════════════════════════════
--  UTILITY FUNCTIONS
--═══════════════════════════════════════════════════════════════════════════════

local Utils = {}

function Utils.raycastCheck(character)
	if not character or not character:FindFirstChild("Head") then return false end
	
	local camera = Cache.Camera
	local head = character:FindFirstChild("Head")
	
	local rayOrigin = camera.CFrame.Position
	local rayDirection = (head.Position - rayOrigin).Unit * 2000
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {Cache.LocalPlayer.Character, character}
	
	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	return result == nil
end

function Utils.isNPCBoss(npc)
	if not npc then return false end
	
	local bossKeywords = {"boss", "Boss", "BOSS", "miniboss", "MiniBoss", "MINIBOSS"}
	for _, keyword in pairs(bossKeywords) do
		if string.find(npc.Name, keyword) then
			return true
		end
	end
	
	return false
end

function Utils.isValidNPC(character)
	if not character or not character:IsA("Model") then return false end
	
	-- Bỏ qua player
	if Services.Players:GetPlayerFromCharacter(character) then return false end
	if character == Cache.LocalPlayer.Character then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not head or not hrp or humanoid.Health <= 0 then return false end
	
	if CHAMS_CONFIG.NPCChamsAggressive then return true end
	
	if CHAMS_CONFIG.NPCChamsTagFilter then
		for _, tag in pairs(NPCTags) do
			if string.find(character.Name, tag) then
				return true
			end
		end
		return false
	end
	
	return true
end

function Utils.getTeam(player)
	if not player then return nil end
	
	if player.Team then
		return {
			Name = player.Team.Name,
			Color = player.Team.TeamColor.Color,
		}
	end
	
	if player.TeamColor and player.TeamColor ~= BrickColor.new("White") then
		return {
			Name = player.TeamColor.Name,
			Color = player.TeamColor.Color,
		}
	end
	
	return nil
end

function Utils.isSameTeam(player1, player2)
	if not player1 or not player2 then return false end
	if player1 == player2 then return true end
	
	local team1 = Utils.getTeam(player1)
	local team2 = Utils.getTeam(player2)
	
	if not team1 and not team2 then return true end
	if not team1 or not team2 then return false end
	
	return team1.Name == team2.Name
end

--═══════════════════════════════════════════════════════════════════════════════
--  CHAMS CREATION & MANAGEMENT
--═══════════════════════════════════════════════════════════════════════════════

local ChamsManager = {}

function ChamsManager.createChams(character, isNPC)
	if not character or not character:FindFirstChild("Head") then return nil end
	
	local screenGui = initializeScreenGui()
	
	-- Container frame
	local chamsFrame = Instance.new("Frame")
	chamsFrame.Name = "ChamsFrame_" .. character.Name
	chamsFrame.Size = UDim2.new(0, 50, 0, 100)
	chamsFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	chamsFrame.BorderSizePixel = 0
	chamsFrame.Parent = screenGui
	
	-- Fill
	local fill = Instance.new("Frame")
	fill.Name = "ChamsFill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	fill.BorderSizePixel = 0
	fill.Parent = chamsFrame
	
	-- Stroke (outline)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "ChamsStroke"
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 0, 0)
	stroke.Parent = chamsFrame
	
	-- Gradient (optional)
	local gradient = Instance.new("UIGradient")
	gradient.Name = "ChamsGradient"
	gradient.Transparency = NumberSequence.new(CHAMS_CONFIG.fillTransparency)
	gradient.Rotation = 0
	gradient.Parent = fill
	
	local chamsData = {
		Frame = chamsFrame,
		Fill = fill,
		Stroke = stroke,
		Gradient = gradient,
		Character = character,
		IsNPC = isNPC or false,
	}
	
	return chamsData
end

function ChamsManager.updateChams(chamsData)
	if not chamsData or not chamsData.Character or not chamsData.Character.Parent then return end
	
	local character = chamsData.Character
	local head = character:FindFirstChild("Head")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	if not head or not humanoid or humanoid.Health <= 0 then
		ChamsManager.removeChams(chamsData)
		return
	end
	
	local config = CHAMS_CONFIG
	
	-- Determine visibility
	local isVisible = true
	if config.useRaycasting or (chamsData.IsNPC and config.NPCChamsUseRaycasting) then
		isVisible = Utils.raycastCheck(character)
	end
	
	-- Determine colors
	local fillColor, strokeColor
	
	if chamsData.IsNPC then
		if config.NPCChamsUseVisibilityColors then
			fillColor = isVisible and config.NPCChamsVisibleFillColor or config.NPCChamsHiddenFillColor
			strokeColor = isVisible and config.NPCChamsVisibleOutlineColor or config.NPCChamsHiddenOutlineColor
		else
			local isBoss = Utils.isNPCBoss(character)
			fillColor = isBoss and config.NPCChamsBossFillColor or config.NPCChamsStandardFillColor
			strokeColor = isBoss and config.NPCChamsBossOutlineColor or config.NPCChamsStandardOutlineColor
		end
	else
		-- Player chams
		if config.useVisibilityColors then
			fillColor = isVisible and config.visibleFillColor or config.hiddenFillColor
			strokeColor = isVisible and config.visibleOutlineColor or config.hiddenOutlineColor
		elseif config.UseTeamColors then
			local isAlly = Utils.isSameTeam(Cache.LocalPlayer, character)
			fillColor = isAlly and config.AlliedFillColor or config.EnemyFillColor
			strokeColor = isAlly and config.AlliedOutlineColor or config.EnemyOutlineColor
		else
			fillColor = config.fillColor
			strokeColor = config.outlineColor
		end
	end
	
	-- Update colors
	chamsData.Fill.BackgroundColor3 = fillColor
	chamsData.Stroke.Color = strokeColor
	
	-- Update transparency
	local transparency = chamsData.IsNPC and config.NPCChamsFillTransparency or config.fillTransparency
	chamsData.Gradient.Transparency = NumberSequence.new(transparency)
	
	local outlineTransparency = chamsData.IsNPC and config.NPCChamsOutlineTransparency or config.outlineTransparency
	chamsData.Stroke.Transparency = outlineTransparency
	
	-- World to screen
	local headScreenPos, onScreen = Cache.Camera:WorldToScreenPoint(head.Position)
	
	if onScreen then
		chamsData.Frame.Visible = true
		
		-- Size estimation
		local topScreenPos = Cache.Camera:WorldToScreenPoint(head.Position + Vector3.new(0, head.Size.Y/2, 0))
		local bottomScreenPos = Cache.Camera:WorldToScreenPoint(head.Position - Vector3.new(0, head.Size.Y/2, 0))
		
		local height = math.abs(bottomScreenPos.Y - topScreenPos.Y)
		local width = height * 0.5
		
		chamsData.Frame.Size = UDim2.new(0, width, 0, height * 2)
		chamsData.Frame.Position = UDim2.new(0, headScreenPos.X - width/2, 0, topScreenPos.Y - height)
	else
		chamsData.Frame.Visible = false
	end
end

function ChamsManager.removeChams(chamsData)
	if chamsData and chamsData.Frame then
		chamsData.Frame:Destroy()
	end
end

--═══════════════════════════════════════════════════════════════════════════════
--  PLAYER CHAMS HANDLER
--═══════════════════════════════════════════════════════════════════════════════

local PlayerChamsHandler = {}

function PlayerChamsHandler.addPlayer(player)
	if player == Cache.LocalPlayer then return end
	
	task.wait(0.3)
	
	if not player.Character then return end
	
	local chamsData = ChamsManager.createChams(player.Character, false)
	if chamsData then
		ChamsStorage.PlayerChams[player] = chamsData
	end
end

function PlayerChamsHandler.removePlayer(player)
	local chamsData = ChamsStorage.PlayerChams[player]
	if chamsData then
		ChamsManager.removeChams(chamsData)
		ChamsStorage.PlayerChams[player] = nil
	end
end

function PlayerChamsHandler.initialize()
	for _, player in pairs(Services.Players:GetPlayers()) do
		if player ~= Cache.LocalPlayer then
			PlayerChamsHandler.addPlayer(player)
		end
	end
	
	Services.Players.PlayerAdded:Connect(function(player)
		if CHAMS_CONFIG.enabled then
			PlayerChamsHandler.addPlayer(player)
		end
	end)
	
	Services.Players.PlayerRemoving:Connect(function(player)
		PlayerChamsHandler.removePlayer(player)
	end)
end

function PlayerChamsHandler.cleanup()
	for player in pairs(ChamsStorage.PlayerChams) do
		PlayerChamsHandler.removePlayer(player)
	end
end

--═══════════════════════════════════════════════════════════════════════════════
--  NPC CHAMS HANDLER
--═══════════════════════════════════════════════════════════════════════════════

local NPCChamsHandler = {}

function NPCChamsHandler.scanNPCs()
	local function scanRecursive(parent)
		local npcs = {}
		for _, child in pairs(parent:GetChildren()) do
			if Utils.isValidNPC(child) then
				table.insert(npcs, child)
			end
			for _, foundNPC in pairs(scanRecursive(child)) do
				table.insert(npcs, foundNPC)
			end
		end
		return npcs
	end
	
	return scanRecursive(workspace)
end

function NPCChamsHandler.update()
	local foundNPCs = NPCChamsHandler.scanNPCs()
	local foundSet = {}
	
	for _, npc in pairs(foundNPCs) do
		foundSet[npc] = true
	end
	
	-- Remove dead NPCs
	for npc in pairs(ChamsStorage.NPCChams) do
		if not foundSet[npc] or not npc.Parent then
			ChamsManager.removeChams(ChamsStorage.NPCChams[npc])
			ChamsStorage.NPCChams[npc] = nil
		end
	end
	
	-- Add new NPCs
	for _, npc in pairs(foundNPCs) do
		if not ChamsStorage.NPCChams[npc] then
			local chamsData = ChamsManager.createChams(npc, true)
			if chamsData then
				ChamsStorage.NPCChams[npc] = chamsData
			end
		end
	end
end

function NPCChamsHandler.cleanup()
	for npc in pairs(ChamsStorage.NPCChams) do
		ChamsManager.removeChams(ChamsStorage.NPCChams[npc])
	end
	ChamsStorage.NPCChams = {}
end

--═══════════════════════════════════════════════════════════════════════════════
--  MAIN CHAMS API
--═══════════════════════════════════════════════════════════════════════════════

local ChamsAPI = {}

function ChamsAPI:UpdateConfig(newConfig)
	for key, value in pairs(newConfig) do
		if CHAMS_CONFIG[key] ~= nil then
			CHAMS_CONFIG[key] = value
		end
	end
end

function ChamsAPI:GetConfig()
	return CHAMS_CONFIG
end

function ChamsAPI:Toggle(state)
	CHAMS_CONFIG.enabled = state
	
	if state then
		PlayerChamsHandler.initialize()
	else
		PlayerChamsHandler.cleanup()
	end
end

function ChamsAPI:ToggleNPC(state)
	CHAMS_CONFIG.NPCChamsEnabled = state
	
	if state then
		NPCChamsHandler.update()
	else
		NPCChamsHandler.cleanup()
	end
end

function ChamsAPI:Destroy()
	PlayerChamsHandler.cleanup()
	NPCChamsHandler.cleanup()
	
	if ChamsStorage.UpdateConnection then
		ChamsStorage.UpdateConnection:Disconnect()
	end
	
	if ChamsStorage.ScanConnection then
		ChamsStorage.ScanConnection:Disconnect()
	end
	
	if ChamsStorage.MainScreenGui then
		ChamsStorage.MainScreenGui:Destroy()
	end
end

--═══════════════════════════════════════════════════════════════════════════════
--  INITIALIZATION
--═══════════════════════════════════════════════════════════════════════════════

local function initialize()
	initializeScreenGui()
	
	-- Main update loop
	ChamsStorage.UpdateConnection = Services.RunService.RenderStepped:Connect(function()
		if CHAMS_CONFIG.enabled then
			for player, chamsData in pairs(ChamsStorage.PlayerChams) do
				ChamsManager.updateChams(chamsData)
			end
		end
		
		if CHAMS_CONFIG.NPCChamsEnabled then
			for npc, chamsData in pairs(ChamsStorage.NPCChams) do
				ChamsManager.updateChams(chamsData)
			end
		end
	end)
	
	-- NPC scan loop
	ChamsStorage.ScanConnection = Services.RunService.Heartbeat:Connect(function()
		if CHAMS_CONFIG.NPCChamsEnabled then
			NPCChamsHandler.update()
		end
	end)
end

initialize()

return ChamsAPI
