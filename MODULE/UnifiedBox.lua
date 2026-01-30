--═══════════════════════════════════════════════════════════════════════════════
--  UNIFIED ESP - WITH PROFESSIONAL BOX SYSTEM (FIXED STROKE RENDERING)
--═══════════════════════════════════════════════════════════════════════════════

local Services = {
	Players         = game:GetService("Players"),
	RunService      = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	TweenService    = game:GetService("TweenService")
}

--═══════════════════════════════════════════════════════════════════════════════
--  CACHE DỮ LIỆU CHUNG
--═══════════════════════════════════════════════════════════════════════════════

local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Cache = {
	LocalPlayer = LocalPlayer,
	Mouse       = LocalPlayer:GetMouse(),
	Camera      = workspace.CurrentCamera,
	PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
}

--═══════════════════════════════════════════════════════════════════════════════
--  DANH SÁCH TAG NPC (EXPANDED - GIỐNG CHAMS)
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
--  GLOBAL CONFIG
--═══════════════════════════════════════════════════════════════════════════════

local GLOBAL_CONFIG = {
	-- Chế độ hoạt động
	Mode = "Player",
	Enabled = false,
	
	-- Cấu hình chung
	BoxColor     = Color3.fromRGB(0, 255, 0),
	BoxThickness = 2,
	MaxDistance = 10000,
	
	-- Team Check
	EnableTeamCheck = false,
	ShowEnemyOnly = false,
	ShowAlliedOnly = false,
	UseTeamColors = false,
	UseActualTeamColors = true,
	EnemyBoxColor = Color3.fromRGB(255, 0, 0),
	AlliedBoxColor = Color3.fromRGB(0, 255, 0),
	NoTeamColor = Color3.fromRGB(255, 255, 255),
	
	-- Gradient
	ShowGradient = false,
	GradientColor1 = Color3.fromRGB(255, 255, 255),
	GradientColor2 = Color3.fromRGB(0, 0, 0),
	GradientTransparency = 0.7,
	GradientRotation = 90,
	EnableGradientAnimation = false,
	GradientAnimationSpeed = 1,
	
	-- NPC Specific (GIỐNG CHAMS)
	NPCEnabled = false,
	NPCMaxDistance = 10000,
	NPCFillColor = Color3.fromRGB(255, 165, 0),
	StandardNPCColor = Color3.fromRGB(255, 0, 0),
	BossNPCColor = Color3.fromRGB(255, 165, 0),
	EnableTagFilter = true,
	AggressiveNPCDetection = false,
	UseNPCColors = false,
	
	-- Text Stroke (FIX)
	TextStrokeSize = 1,
	TextStrokeTransparency = 0,
}

--═══════════════════════════════════════════════════════════════════════════════
--  BỘ NHỚ CHUNG
--═══════════════════════════════════════════════════════════════════════════════

local EspStorage = {
	Boxes           = {},
	TrackedNPCs     = {},
	GradientConnection = nil,
	RenderConnection = nil,
	ScanConnection = nil,
	RotationOffset = 0,
	MainScreenGui = nil
}

--═══════════════════════════════════════════════════════════════════════════════
--  KHỞI TẠO SCREEN GUI
--═══════════════════════════════════════════════════════════════════════════════

local function initializeScreenGui()
	if EspStorage.MainScreenGui then return EspStorage.MainScreenGui end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "UnifiedESP"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 999
	screenGui.Parent = Cache.PlayerGui
	
	EspStorage.MainScreenGui = screenGui
	return screenGui
end

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
	if not GLOBAL_CONFIG.EnableTeamCheck then return true end
	local isEnemyPlayer = isEnemy(targetPlayer)
	if GLOBAL_CONFIG.ShowEnemyOnly and not isEnemyPlayer then return false end
	if GLOBAL_CONFIG.ShowAlliedOnly and isEnemyPlayer then return false end
	return true
end

--═══════════════════════════════════════════════════════════════════════════════
--  NPC SYSTEM (GIỐNG CHAMS - ĐẦY ĐỦ)
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
	
	if GLOBAL_CONFIG.EnableTagFilter then
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

--═══════════════════════════════════════════════════════════════════════════════
--  UTILS
--═══════════════════════════════════════════════════════════════════════════════

local Utils = {}

function Utils.getViewportSize()
	local viewportSize = Camera.ViewportSize
	return {
		X = viewportSize.X,
		Y = viewportSize.Y
	}
end

function Utils.getScreenPos(worldPosition)
	local viewport = Camera.ViewportSize
	local localPos = Camera.CFrame:PointToObjectSpace(worldPosition)
	
	local aspectRatio = viewport.X / viewport.Y
	local halfHeight = -localPos.Z * math.tan(math.rad(Camera.FieldOfView / 2))
	local halfWidth = aspectRatio * halfHeight
	
	local farPlaneCorner = Vector3.new(-halfWidth, halfHeight, localPos.Z)
	local relativePos = localPos - farPlaneCorner
	
	local screenX = relativePos.X / (halfWidth * 2)
	local screenY = -relativePos.Y / (halfHeight * 2)
	
	local isOnScreen = -localPos.Z > 0 and screenX >= 0 and screenX <= 1 and screenY >= 0 and screenY <= 1
	
	return Vector3.new(screenX * viewport.X, screenY * viewport.Y, -localPos.Z), isOnScreen
end

function Utils.boxSolve(torso)
	if not torso then
		return nil, nil, nil
	end
	
	local viewportTop = torso.Position + (torso.CFrame.UpVector * 1.8) + Camera.CFrame.UpVector
	local viewportBottom = torso.Position - (torso.CFrame.UpVector * 2.5) - Camera.CFrame.UpVector
	local distance = (torso.Position - Camera.CFrame.p).Magnitude

	local top, topIsRendered = Utils.getScreenPos(viewportTop)
	local bottom, bottomIsRendered = Utils.getScreenPos(viewportBottom)

	local width = math.max(math.floor(math.abs(top.X - bottom.X)), 3)
	local height = math.max(math.floor(math.max(math.abs(bottom.Y - top.Y), width / 2)), 3)
	local boxSize = Vector2.new(math.floor(math.max(height / 1.5, width)), height)
	local boxPos = Vector2.new(math.floor(top.X * 0.5 + bottom.X * 0.5 - boxSize.X * 0.5), math.floor(math.min(top.Y, bottom.Y)))
	
	return boxSize, boxPos, topIsRendered, distance
end

function Utils.getBoxColor(target)
	-- Nếu là player
	if Services.Players:GetPlayerFromCharacter(target) then
		local targetPlayer = Services.Players:GetPlayerFromCharacter(target)
		if GLOBAL_CONFIG.UseTeamColors then
			if GLOBAL_CONFIG.UseActualTeamColors then
				local teamColor = getPlayerTeamColor(targetPlayer)
				if teamColor then
					return teamColor
				else
					return GLOBAL_CONFIG.NoTeamColor
				end
			else
				if isEnemy(targetPlayer) then
					return GLOBAL_CONFIG.EnemyBoxColor
				else
					return GLOBAL_CONFIG.AlliedBoxColor
				end
			end
		end
		return GLOBAL_CONFIG.BoxColor
	end
	
	-- Nếu là NPC
	if GLOBAL_CONFIG.UseNPCColors then
		if NPCSystem.isBoss(target) then
			return GLOBAL_CONFIG.BossNPCColor
		else
			return GLOBAL_CONFIG.StandardNPCColor
		end
	end
	
	return GLOBAL_CONFIG.NPCFillColor
end

function Utils.getDistance(position)
	return (position - Camera.CFrame.p).Magnitude
end

function Utils.shouldShowTarget(target)
	if Services.Players:GetPlayerFromCharacter(target) then
		local targetPlayer = Services.Players:GetPlayerFromCharacter(target)
		return shouldShowPlayer(targetPlayer) and Utils.getDistance(target.HumanoidRootPart.Position) <= GLOBAL_CONFIG.MaxDistance
	else
		-- NPC
		return Utils.getDistance(target.HumanoidRootPart.Position) <= GLOBAL_CONFIG.NPCMaxDistance
	end
end

--═══════════════════════════════════════════════════════════════════════════════
--  BOX MANAGER
--═══════════════════════════════════════════════════════════════════════════════

local BoxManager = {}

function BoxManager.create(target)
	if EspStorage.Boxes[target] then
		return
	end
	
	if not target or not target.Parent then
		return
	end
	
	-- Kiểm tra xem có Humanoid không
	local character
	if target:IsA("Player") then
		character = target.Character
	else
		character = target
	end
	
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not hrp then return end
	
	local screenGui = initializeScreenGui()
	
	-- Create Holder
	local holder = Instance.new("Frame")
	holder.Name = "BoxHolder"
	holder.BackgroundTransparency = 1
	holder.Parent = screenGui
	
	-- Create UIStroke for box outline
	local boxOutline = Instance.new("UIStroke")
	boxOutline.Thickness = GLOBAL_CONFIG.BoxThickness
	boxOutline.LineJoinMode = Enum.LineJoinMode.Round
	boxOutline.Color = Utils.getBoxColor(target)
	boxOutline.Parent = holder
	
	-- Create BoxGradient (optional)
	local boxGradient = Instance.new("Frame")
	boxGradient.Name = "BoxGradient"
	boxGradient.BackgroundColor3 = GLOBAL_CONFIG.GradientColor1
	boxGradient.BackgroundTransparency = GLOBAL_CONFIG.GradientTransparency
	boxGradient.BorderSizePixel = 0
	boxGradient.Visible = GLOBAL_CONFIG.ShowGradient
	boxGradient.Parent = holder
	
	-- Create UIGradient inside gradient frame
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0.000, GLOBAL_CONFIG.GradientColor1),
		ColorSequenceKeypoint.new(1.000, GLOBAL_CONFIG.GradientColor2)
	}
	uiGradient.Rotation = GLOBAL_CONFIG.GradientRotation
	uiGradient.Parent = boxGradient
	
	EspStorage.Boxes[target] = {
		Holder = holder,
		BoxOutline = boxOutline,
		BoxGradient = boxGradient,
		UIGradient = uiGradient
	}
end

function BoxManager.update(target, espData)
	if not target or not target.Parent or not espData then
		return
	end
	
	-- Get character
	local character
	if target:IsA("Player") then
		character = target.Character
	else
		character = target
	end
	
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not hrp or humanoid.Health <= 0 then return end
	
	-- Check distance
	local distance = Utils.getDistance(hrp.Position)
	local maxDist = Services.Players:GetPlayerFromCharacter(target) and GLOBAL_CONFIG.MaxDistance or GLOBAL_CONFIG.NPCMaxDistance
	
	if distance > maxDist then
		espData.Holder.Visible = false
		return
	end
	
	-- Check team filters for players
	if Services.Players:GetPlayerFromCharacter(target) then
		if not shouldShowPlayer(Services.Players:GetPlayerFromCharacter(target)) then
			espData.Holder.Visible = false
			return
		end
	end
	
	local boxSize, boxPos, onScreen = Utils.boxSolve(hrp)
	
	if not boxSize or not boxPos then
		return
	end
	
	-- Update position and size
	espData.Holder.Position = UDim2.fromOffset(boxPos.X, boxPos.Y)
	espData.Holder.Size = UDim2.fromOffset(boxSize.X, boxSize.Y)
	
	-- Update colors
	local boxColor = Utils.getBoxColor(target)
	if espData.BoxOutline then
		espData.BoxOutline.Color = boxColor
		espData.BoxOutline.Thickness = GLOBAL_CONFIG.BoxThickness
	end
	
	-- Update gradient
	if espData.BoxGradient then
		espData.BoxGradient.Visible = GLOBAL_CONFIG.ShowGradient
		espData.BoxGradient.BackgroundTransparency = GLOBAL_CONFIG.GradientTransparency
	end
	
	if espData.UIGradient then
		espData.UIGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0.000, GLOBAL_CONFIG.GradientColor1),
			ColorSequenceKeypoint.new(1.000, GLOBAL_CONFIG.GradientColor2)
		}
		if not GLOBAL_CONFIG.EnableGradientAnimation then
			espData.UIGradient.Rotation = GLOBAL_CONFIG.GradientRotation
		end
	end
	
	-- Visibility check
	espData.Holder.Visible = GLOBAL_CONFIG.Enabled and onScreen
end

function BoxManager.remove(target)
	local espData = EspStorage.Boxes[target]
	if espData then
		if espData.Holder then
			espData.Holder:Destroy()
		end
		EspStorage.Boxes[target] = nil
	end
	EspStorage.TrackedNPCs[target] = nil
end

function BoxManager.updateAll()
	for target, espData in pairs(EspStorage.Boxes) do
		if target and target.Parent and espData then
			BoxManager.update(target, espData)
		else
			BoxManager.remove(target)
		end
	end
end

--═══════════════════════════════════════════════════════════════════════════════
--  PLAYER MODE
--═══════════════════════════════════════════════════════════════════════════════

local PlayerMode = {}

function PlayerMode.onPlayerAdded(newPlayer)
	if newPlayer ~= LocalPlayer then
		task.wait(0.5)
		BoxManager.create(newPlayer)
	end
end

function PlayerMode.onPlayerRemoving(leavingPlayer)
	BoxManager.remove(leavingPlayer)
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
	for target in pairs(EspStorage.Boxes) do
		if target:IsA("Player") then
			table.insert(playersToRemove, target)
		end
	end
	
	for _, player in pairs(playersToRemove) do
		BoxManager.remove(player)
	end
end

--═══════════════════════════════════════════════════════════════════════════════
--  NPC MODE (GIỐNG CHAMS)
--═══════════════════════════════════════════════════════════════════════════════

local NPCMode = {}

function NPCMode.scanForNPCs()
	if not GLOBAL_CONFIG.NPCEnabled then return end
	
	local foundNPCs = NPCSystem.findNPCsRecursive(workspace)
	
	local foundSet = {}
	for _, npc in pairs(foundNPCs) do
		foundSet[npc] = true
	end
	
	-- Remove NPCs that no longer exist
	for npc in pairs(EspStorage.TrackedNPCs) do
		if not foundSet[npc] or not npc.Parent then
			BoxManager.remove(npc)
		end
	end
	
	-- Add new NPCs
	for _, npc in pairs(foundNPCs) do
		if not EspStorage.TrackedNPCs[npc] then
			EspStorage.TrackedNPCs[npc] = true
			BoxManager.create(npc)
		end
	end
end

function NPCMode.initialize()
	NPCMode.scanForNPCs()
	
	if not EspStorage.ScanConnection then
		EspStorage.ScanConnection = Services.RunService.Heartbeat:Connect(function()
			if GLOBAL_CONFIG.NPCEnabled then
				NPCMode.scanForNPCs()
			end
		end)
	end
end

function NPCMode.cleanup()
	local npcsToRemove = {}
	for target in pairs(EspStorage.Boxes) do
		if target:IsA("Model") and NPCSystem.isNPC(target) then
			table.insert(npcsToRemove, target)
		end
	end
	
	for _, npc in pairs(npcsToRemove) do
		BoxManager.remove(npc)
	end
	
	EspStorage.TrackedNPCs = {}
end

--═══════════════════════════════════════════════════════════════════════════════
--  MODE SWITCHING
--═══════════════════════════════════════════════════════════════════════════════

local function switchMode(newMode)
	if newMode == GLOBAL_CONFIG.Mode then return end

	-- Clear all ESP boxes
	for target in pairs(EspStorage.Boxes) do
		BoxManager.remove(target)
	end

	-- Cleanup trước cho chắc
	PlayerMode.cleanup()
	NPCMode.cleanup()

	GLOBAL_CONFIG.Mode = newMode

	if newMode == "Player" then
		PlayerMode.initialize()

	elseif newMode == "NPC" then
		NPCMode.initialize()

	elseif newMode == "Both" then
		PlayerMode.initialize()
		NPCMode.initialize()
	end
end

--═══════════════════════════════════════════════════════════════════════════════
--  INITIALIZATION
--═══════════════════════════════════════════════════════════════════════════════

local function initialize()
	initializeScreenGui()
	PlayerMode.initialize()
	
	EspStorage.RenderConnection = Services.RunService.RenderStepped:Connect(function()
		BoxManager.updateAll()
	end)
	
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		Cache.Camera = workspace.CurrentCamera
	end)
end

initialize()

--═══════════════════════════════════════════════════════════════════════════════
--  PUBLIC API
--═══════════════════════════════════════════════════════════════════════════════

local UnifiedESPModule = {}

function UnifiedESPModule:UpdateConfig(newConfig)
	for key, value in pairs(newConfig) do
		if GLOBAL_CONFIG[key] ~= nil then
			GLOBAL_CONFIG[key] = value
		end
	end
end

function UnifiedESPModule:GetConfig()
	return GLOBAL_CONFIG
end

function UnifiedESPModule:Toggle(state)
	GLOBAL_CONFIG.Enabled = state
end

function UnifiedESPModule:ToggleNPC(state)
	GLOBAL_CONFIG.NPCEnabled = state
	if not state then
		NPCMode.cleanup()
	else
		NPCMode.initialize()
	end
end

function UnifiedESPModule:SetMode(mode)
	if mode == "Player" or mode == "NPC" then
		switchMode(mode)
	else
		warn("Invalid mode: " .. tostring(mode) .. ". Use 'Player' or 'NPC'")
	end
end

function UnifiedESPModule:GetMode()
	return GLOBAL_CONFIG.Mode
end

function UnifiedESPModule:GetTrackedNPCs()
	local npcList = {}
	for npc in pairs(EspStorage.TrackedNPCs) do
		if npc.Parent then
			table.insert(npcList, npc)
		end
	end
	return npcList
end

function UnifiedESPModule:GetTrackedPlayers()
	local playerList = {}
	for target in pairs(EspStorage.Boxes) do
		if target:IsA("Player") then
			table.insert(playerList, target)
		end
	end
	return playerList
end

function UnifiedESPModule:Destroy()
	if EspStorage.RenderConnection then
		EspStorage.RenderConnection:Disconnect()
	end
	
	if EspStorage.ScanConnection then
		EspStorage.ScanConnection:Disconnect()
	end
	
	for target in pairs(EspStorage.Boxes) do
		BoxManager.remove(target)
	end
	
	if EspStorage.MainScreenGui then
		EspStorage.MainScreenGui:Destroy()
	end
end

return UnifiedESPModule
