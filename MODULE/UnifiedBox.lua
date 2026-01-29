--═══════════════════════════════════════════════════════════════════════════════
--  UNIFIED ESP - WITH PROFESSIONAL BOX SYSTEM (From Example File Logic)
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
	Enabled = false,
	
	-- Cấu hình chung
	BoxColor     = Color3.fromRGB(0, 255, 0),
	BoxThickness = 2,
	
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
	
	-- NPC Specific
	EnableTagFilter = true,
	AggressiveNPCDetection = false,
	UseNPCColors = false,
	StandardNPCColor = Color3.fromRGB(255, 0, 0),
	BossNPCColor = Color3.fromRGB(255, 165, 0),
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
				local team = TeamSystem.getPlayerTeam(targetPlayer)
				if team and team.TeamColor then
					return team.TeamColor.Color
				end
			else
				local isEnemy = not TeamSystem.isSameTeam(LocalPlayer, targetPlayer)
				if isEnemy then
					return GLOBAL_CONFIG.EnemyBoxColor
				else
					return GLOBAL_CONFIG.AlliedBoxColor
				end
			end
			return GLOBAL_CONFIG.NoTeamColor
		end
	-- Nếu là NPC
	elseif target:IsA("Model") and NPCSystem.isNPC(target) then
		if GLOBAL_CONFIG.UseNPCColors then
			local isBoss = NPCSystem.isBoss(target)
			if isBoss then
				return GLOBAL_CONFIG.BossNPCColor
			else
				return GLOBAL_CONFIG.StandardNPCColor
			end
		end
	end
	
	return GLOBAL_CONFIG.BoxColor
end

--═══════════════════════════════════════════════════════════════════════════════
--  GRADIENT ANIMATION
--═══════════════════════════════════════════════════════════════════════════════

local GradientManager = {}

function GradientManager.start()
	if EspStorage.GradientConnection then return end
	
	EspStorage.GradientConnection = Services.RunService.RenderStepped:Connect(function()
		if not GLOBAL_CONFIG.EnableGradientAnimation then
			GradientManager.stop()
			return
		end
		
		EspStorage.RotationOffset = (EspStorage.RotationOffset + GLOBAL_CONFIG.GradientAnimationSpeed) % 360
		
		for _, espData in pairs(EspStorage.Boxes) do
			if espData.UIGradient then
				espData.UIGradient.Rotation = EspStorage.RotationOffset
			end
		end
	end)
end

function GradientManager.stop()
	if EspStorage.GradientConnection then
		EspStorage.GradientConnection:Disconnect()
		EspStorage.GradientConnection = nil
	end
end

--═══════════════════════════════════════════════════════════════════════════════
--  BOX MANAGER (Professional Box System from Example)
--═══════════════════════════════════════════════════════════════════════════════

local BoxManager = {}

function BoxManager.create(target)
	if EspStorage.Boxes[target] then
		return EspStorage.Boxes[target]
	end
	
	-- Main holder frame
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Parent = EspStorage.MainScreenGui
	
	-- Box outline (outer stroke - GREEN)
	local boxOutline = Instance.new("UIStroke")
	boxOutline.Thickness = GLOBAL_CONFIG.BoxThickness
	boxOutline.Color = GLOBAL_CONFIG.BoxColor
	boxOutline.LineJoinMode = Enum.LineJoinMode.Miter
	boxOutline.Parent = holder
	
	-- Box handler (inner black border)
	local boxHandler = Instance.new("Frame")
	boxHandler.Name = "BoxHandler"
	boxHandler.BackgroundTransparency = 1
	boxHandler.BorderSizePixel = 0
	boxHandler.Position = UDim2.new(0, 1, 0, 1)
	boxHandler.Size = UDim2.new(1, -2, 1, -2)
	boxHandler.Parent = holder
	
	-- Inner stroke (black outline)
	local innerStroke = Instance.new("UIStroke")
	innerStroke.Thickness = 1
	innerStroke.Color = Color3.fromRGB(0, 0, 0)
	innerStroke.LineJoinMode = Enum.LineJoinMode.Miter
	innerStroke.Parent = boxHandler
	
	-- Gradient frame (optional)
	local gradientFrame = Instance.new("Frame")
	gradientFrame.Name = "BoxGradient"
	gradientFrame.BorderSizePixel = 0
	gradientFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	gradientFrame.Size = UDim2.new(1, 0, 1, 0)
	gradientFrame.BackgroundTransparency = GLOBAL_CONFIG.GradientTransparency
	gradientFrame.Visible = GLOBAL_CONFIG.ShowGradient
	gradientFrame.Parent = holder
	
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Rotation = GLOBAL_CONFIG.GradientRotation
	uiGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0.000, GLOBAL_CONFIG.GradientColor1),
		ColorSequenceKeypoint.new(1.000, GLOBAL_CONFIG.GradientColor2)
	}
	uiGradient.Parent = gradientFrame
	
	EspStorage.Boxes[target] = {
		Holder      = holder,
		BoxOutline  = boxOutline,
		BoxHandler  = boxHandler,
		InnerStroke = innerStroke,
		BoxGradient = gradientFrame,
		UIGradient  = uiGradient
	}
	
	return EspStorage.Boxes[target]
end

function BoxManager.update(target, espData)
	if not espData or not espData.Holder then return end
	
	local character
	
	if target:IsA("Player") then
		character = target.Character
	elseif target:IsA("Model") then
		character = target
	else
		espData.Holder.Visible = false
		return
	end
	
	if not character then
		espData.Holder.Visible = false
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		espData.Holder.Visible = false
		return
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		espData.Holder.Visible = false
		return
	end
	
	-- Team check (for players only)
	if target:IsA("Player") and GLOBAL_CONFIG.EnableTeamCheck then
		local isEnemyPlayer = not TeamSystem.isSameTeam(LocalPlayer, target)
		
		if GLOBAL_CONFIG.ShowEnemyOnly and not isEnemyPlayer then
			espData.Holder.Visible = false
			return
		end
		
		if GLOBAL_CONFIG.ShowAlliedOnly and isEnemyPlayer then
			espData.Holder.Visible = false
			return
		end
	end
	
	-- Box solving (same logic as example file)
	local boxSize, boxPos, onScreen, distance = Utils.boxSolve(humanoidRootPart)
	
	if not boxSize or not boxPos then
		espData.Holder.Visible = false
		return
	end
	
	-- Update position and size
	espData.Holder.Position = UDim2.fromOffset(boxPos.X, boxPos.Y)
	espData.Holder.Size = UDim2.fromOffset(boxSize.X, boxSize.Y)
	
	-- Update colors
	local boxColor = Utils.getBoxColor(character)
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
--  NPC MODE
--═══════════════════════════════════════════════════════════════════════════════

local NPCMode = {}

function NPCMode.scanForNPCs()
	local foundNPCs = NPCSystem.findNPCsRecursive(workspace)
	
	local foundSet = {}
	for _, npc in pairs(foundNPCs) do
		foundSet[npc] = true
	end
	
	for npc in pairs(EspStorage.TrackedNPCs) do
		if not foundSet[npc] or not npc.Parent then
			BoxManager.remove(npc)
		end
	end
	
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
			if GLOBAL_CONFIG.Mode == "NPC" then
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
	
	for target in pairs(EspStorage.Boxes) do
		BoxManager.remove(target)
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
	
	if newConfig.EnableGradientAnimation ~= nil then
		if newConfig.EnableGradientAnimation then
			GradientManager.start()
		else
			GradientManager.stop()
		end
	end
end

function UnifiedESPModule:GetConfig()
	return GLOBAL_CONFIG
end

function UnifiedESPModule:Toggle(state)
	GLOBAL_CONFIG.Enabled = state
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

function UnifiedESPModule:Destroy()
	GradientManager.stop()
	
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

function UnifiedESPModule:GetTrackedPlayers()
	local playerList = {}
	for target in pairs(EspStorage.Boxes) do
		if target:IsA("Player") then
			table.insert(playerList, target)
		end
	end
	return playerList
end

function UnifiedESPModule:GetTrackedNPCs()
	local npcList = {}
	for npc in pairs(EspStorage.TrackedNPCs) do
		table.insert(npcList, npc)
	end
	return npcList
end

return UnifiedESPModule
