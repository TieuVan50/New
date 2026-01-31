local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local CONFIG = {
	HealthBarColor = Color3.fromRGB(180, 0, 255),
	HealthBarWidth = 2.5,
	HealthBarGap = 2,
	Side = "Left",
	OffsetX = 0,
	OffsetY = 58,
	ShowSelfHealthBar = false,
	
	Enabled = false,
	ToggleKey = Enum.KeyCode.E,
	
	EnableTeamCheck = false,
	ShowEnemyOnly = false,
	ShowAlliedOnly = false,
	
	UseTeamColors = false,
	UseActualTeamColors = true,
	EnemyHealthBarColor = Color3.fromRGB(180, 0, 255),
	AlliedHealthBarColor = Color3.fromRGB(0, 255, 0),
	NoTeamColor = Color3.fromRGB(255, 255, 255),
	
	AnimationSpeed = 0.3,
	AnimationStyle = Enum.EasingStyle.Quart,
	AnimationDirection = Enum.EasingDirection.Out,
	
	EnableFlashEffect = true,
	DamageFlashColor = Color3.fromRGB(255, 0, 0),
	HealFlashColor = Color3.fromRGB(0, 255, 100),
	FlashDuration = 0.15,
	
	-- NPC Settings
	Mode = "Player",
	EnableNPCHealthBar = true,
	UseNPCColors = false,
	NPCHealthBarColor = Color3.fromRGB(255, 0, 0),
	BossHealthBarColor = Color3.fromRGB(255, 165, 0),
	EnableTagFilter = true,
	AggressiveNPCDetection = false,
}

local playerGui = player:WaitForChild("PlayerGui")
local mainScreenGui = Instance.new("ScreenGui")
mainScreenGui.Name = "HealthBarESP"
mainScreenGui.ResetOnSpawn = false
mainScreenGui.IgnoreGuiInset = true
mainScreenGui.Parent = playerGui

local healthBars = {}
local trackedNPCs = {}
local scanConnection = nil

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

--=============================================================================
-- NPC SYSTEM
--=============================================================================

local NPCSystem = {}

function NPCSystem.isPlayer(character)
	if not character or not character:IsA("Model") then return false end
	if character == player.Character then return true end
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
	
	if CONFIG.AggressiveNPCDetection then 
		return true
	end
	
	if not CONFIG.EnableTagFilter then
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
	
	if not player.Team then
		if not targetPlayer.Team then return false end
		return true
	end
	
	if not targetPlayer.Team then return true end
	
	return player.Team ~= targetPlayer.Team
end

local function shouldShowPlayer(targetPlayer)
	if not CONFIG.EnableTeamCheck then return true end
	local isEnemyPlayer = isEnemy(targetPlayer)
	if CONFIG.ShowEnemyOnly and not isEnemyPlayer then return false end
	if CONFIG.ShowAlliedOnly and isEnemyPlayer then return false end
	return true
end

local function getBoxBounds(character, isNPC)
	if not character then return nil end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return nil end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil end
	
	local charSize = character:GetExtentsSize()
	
	local boxHeight = charSize.Y * 0.8
	local boxWidth = charSize.X * 0.8
	
	local headTop = humanoidRootPart.Position + Vector3.new(0, charSize.Y / 2, 0)
	local feetBottom = humanoidRootPart.Position - Vector3.new(0, charSize.Y / 1.4, 0)
	
	local headScreenPos, headOnScreen = camera:WorldToScreenPoint(headTop)
	local feetScreenPos, feetOnScreen = camera:WorldToScreenPoint(feetBottom)
	
	if headScreenPos.Z <= 0 or not headOnScreen then
		return nil
	end
	
	local screenX = (headScreenPos.X + feetScreenPos.X) / 2
	local screenYTop = headScreenPos.Y
	
	local displayHeight = math.abs(feetScreenPos.Y - headScreenPos.Y)
	local displayWidth = displayHeight * (boxWidth / boxHeight)
	
	if displayHeight <= 0 or displayWidth <= 0 then
		return nil
	end
	
	return {
		X = screenX - displayWidth / 2,
		Y = screenYTop,
		Width = displayWidth,
		Height = displayHeight,
		Visible = true
	}
end

local function createFlashEffect(barData, isDamage)
	if not CONFIG.EnableFlashEffect then return end
	if not barData or not barData.FlashOverlay then return end
	
	local flashColor = isDamage and CONFIG.DamageFlashColor or CONFIG.HealFlashColor
	barData.FlashOverlay.BackgroundColor3 = flashColor
	barData.FlashOverlay.BackgroundTransparency = 0.3
	
	local flashTween = TweenService:Create(
		barData.FlashOverlay,
		TweenInfo.new(CONFIG.FlashDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 1}
	)
	flashTween:Play()
end

local function animateHealthBar(barData, targetPercent, targetColor, isDamage)
	if not barData or not barData.HealthBar then return end
	
	if barData.LastHealth and barData.LastHealth ~= targetPercent then
		createFlashEffect(barData, isDamage)
	end
	barData.LastHealth = targetPercent
	
	if barData.CurrentTween then
		barData.CurrentTween:Cancel()
	end
	
	local tweenInfo = TweenInfo.new(
		CONFIG.AnimationSpeed,
		CONFIG.AnimationStyle,
		CONFIG.AnimationDirection
	)
	
	local sizeTween = TweenService:Create(
		barData.HealthBar,
		tweenInfo,
		{
			Size = UDim2.new(1, 0, targetPercent, 0),
			Position = UDim2.new(0, 0, 1 - targetPercent, 0)
		}
	)
	
	local colorTween = TweenService:Create(
		barData.HealthBar,
		tweenInfo,
		{BackgroundColor3 = targetColor}
	)
	
	sizeTween:Play()
	colorTween:Play()
	
	barData.CurrentTween = sizeTween
	
	if isDamage and barData.DamageTrail then
		task.delay(0.1, function()
			if barData.DamageTrail then
				local trailTween = TweenService:Create(
					barData.DamageTrail,
					TweenInfo.new(CONFIG.AnimationSpeed * 1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Size = UDim2.new(1, 0, targetPercent, 0),
						Position = UDim2.new(0, 0, 1 - targetPercent, 0)
					}
				)
				trailTween:Play()
			end
		end)
	elseif barData.DamageTrail then
		barData.DamageTrail.Size = UDim2.new(1, 0, targetPercent, 0)
		barData.DamageTrail.Position = UDim2.new(0, 0, 1 - targetPercent, 0)
	end
end

local function getHealthGradientColor(healthPercent)
	if healthPercent > 0.5 then
		local t = (healthPercent - 0.5) * 2
		return Color3.fromRGB(
			math.floor(255 * (1 - t)),
			255,
			0
		)
	else
		local t = healthPercent * 2
		return Color3.fromRGB(
			255,
			math.floor(255 * t),
			0
		)
	end
end

local function getBarColor(target, healthPercent, isNPC, isSelf)
	if isNPC then
		if CONFIG.UseNPCColors then
			if NPCSystem.isBoss(target) then
				return CONFIG.BossHealthBarColor
			else
				return CONFIG.NPCHealthBarColor
			end
		end
		return getHealthGradientColor(healthPercent)
	end
	
	if not CONFIG.UseTeamColors then
		return getHealthGradientColor(healthPercent)
	end
	
	if CONFIG.UseActualTeamColors then
		local teamColor = getPlayerTeamColor(target)
		if teamColor then
			return teamColor
		else
			if isSelf then
				return getHealthGradientColor(healthPercent)
			end
			return CONFIG.NoTeamColor
		end
	else
		if isSelf then
			return CONFIG.AlliedHealthBarColor
		end
		
		local isEnemyPlayer = isEnemy(target)
		if isEnemyPlayer then
			return CONFIG.EnemyHealthBarColor
		else
			return CONFIG.AlliedHealthBarColor
		end
	end
end

--=============================================================================
-- HEALTH BAR CREATION & MANAGEMENT
--=============================================================================

local function createHealthBar(target, isNPC)
	if healthBars[target] then return end
	
	local targetName = isNPC and target.Name or target.Name
	
	local OutlineBar = Instance.new("Frame")
	OutlineBar.Name = "HealthBar_" .. targetName
	OutlineBar.Size = UDim2.new(0, CONFIG.HealthBarWidth, 0, 100)
	OutlineBar.Position = UDim2.new(0, 0, 0, 0)
	OutlineBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	OutlineBar.BackgroundTransparency = 0.3
	OutlineBar.BorderSizePixel = 0
	OutlineBar.AnchorPoint = Vector2.new(0, 0)
	OutlineBar.Visible = false
	OutlineBar.Parent = mainScreenGui
	
	local OutlineStroke = Instance.new("UIStroke")
	OutlineStroke.Thickness = 1
	OutlineStroke.Color = Color3.fromRGB(0, 0, 0)
	OutlineStroke.LineJoinMode = Enum.LineJoinMode.Miter
	OutlineStroke.Parent = OutlineBar
	
	local DamageTrail = Instance.new("Frame")
	DamageTrail.Name = "DamageTrail"
	DamageTrail.Size = UDim2.new(1, 0, 1, 0)
	DamageTrail.Position = UDim2.new(0, 0, 0, 0)
	DamageTrail.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	DamageTrail.BackgroundTransparency = 0.3
	DamageTrail.BorderSizePixel = 0
	DamageTrail.ZIndex = 1
	DamageTrail.Parent = OutlineBar
	
	local HealthBar = Instance.new("Frame")
	HealthBar.Name = "HealthBar"
	HealthBar.Size = UDim2.new(1, 0, 1, 0)
	HealthBar.Position = UDim2.new(0, 0, 0, 0)
	HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	HealthBar.BorderSizePixel = 0
	HealthBar.ZIndex = 2
	HealthBar.Parent = OutlineBar
	
	local FlashOverlay = Instance.new("Frame")
	FlashOverlay.Name = "FlashOverlay"
	FlashOverlay.Size = UDim2.new(1, 0, 1, 0)
	FlashOverlay.Position = UDim2.new(0, 0, 0, 0)
	FlashOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	FlashOverlay.BackgroundTransparency = 1
	FlashOverlay.BorderSizePixel = 0
	FlashOverlay.ZIndex = 3
	FlashOverlay.Parent = OutlineBar
	
	healthBars[target] = {
		OutlineBar = OutlineBar,
		HealthBar = HealthBar,
		DamageTrail = DamageTrail,
		FlashOverlay = FlashOverlay,
		IsNPC = isNPC or false,
		IsSelf = false,
		LastHealth = 1,
		CurrentTween = nil
	}
end

local function createSelfHealthBar()
	if not player.Character then return end
	if healthBars[player] then return end
	
	local OutlineBar = Instance.new("Frame")
	OutlineBar.Name = "SelfHealthBar"
	OutlineBar.Size = UDim2.new(0, CONFIG.HealthBarWidth, 0, 100)
	OutlineBar.Position = UDim2.new(0, 0, 0, 0)
	OutlineBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	OutlineBar.BackgroundTransparency = 0.3
	OutlineBar.BorderSizePixel = 0
	OutlineBar.AnchorPoint = Vector2.new(0, 0)
	OutlineBar.Visible = false
	OutlineBar.Parent = mainScreenGui
	
	local OutlineStroke = Instance.new("UIStroke")
	OutlineStroke.Thickness = 1
	OutlineStroke.Color = Color3.fromRGB(0, 0, 0)
	OutlineStroke.LineJoinMode = Enum.LineJoinMode.Miter
	OutlineStroke.Parent = OutlineBar
	
	local DamageTrail = Instance.new("Frame")
	DamageTrail.Name = "DamageTrail"
	DamageTrail.Size = UDim2.new(1, 0, 1, 0)
	DamageTrail.Position = UDim2.new(0, 0, 0, 0)
	DamageTrail.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	DamageTrail.BackgroundTransparency = 0.3
	DamageTrail.BorderSizePixel = 0
	DamageTrail.ZIndex = 1
	DamageTrail.Parent = OutlineBar
	
	local HealthBar = Instance.new("Frame")
	HealthBar.Name = "HealthBar"
	HealthBar.Size = UDim2.new(1, 0, 1, 0)
	HealthBar.Position = UDim2.new(0, 0, 0, 0)
	HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	HealthBar.BorderSizePixel = 0
	HealthBar.ZIndex = 2
	HealthBar.Parent = OutlineBar
	
	local FlashOverlay = Instance.new("Frame")
	FlashOverlay.Name = "FlashOverlay"
	FlashOverlay.Size = UDim2.new(1, 0, 1, 0)
	FlashOverlay.Position = UDim2.new(0, 0, 0, 0)
	FlashOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	FlashOverlay.BackgroundTransparency = 1
	FlashOverlay.BorderSizePixel = 0
	FlashOverlay.ZIndex = 3
	FlashOverlay.Parent = OutlineBar
	
	healthBars[player] = {
		OutlineBar = OutlineBar,
		HealthBar = HealthBar,
		DamageTrail = DamageTrail,
		FlashOverlay = FlashOverlay,
		IsNPC = false,
		IsSelf = true,
		LastHealth = 1,
		CurrentTween = nil
	}
end

local function updateHealthBar(target, barData)
	if not barData then return end
	if not barData.OutlineBar then return end
	if not barData.OutlineBar.Parent then return end
	
	if not CONFIG.Enabled then
		barData.OutlineBar.Visible = false
		return
	end
	
	if not target then
		barData.OutlineBar.Visible = false
		return
	end
	
	if not target.Parent then
		barData.OutlineBar.Visible = false
		return
	end
	
	local character
	if barData.IsNPC then
		character = target
	else
		character = target.Character
	end
	
	if not character then
		barData.OutlineBar.Visible = false
		return
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		barData.OutlineBar.Visible = false
		return
	end
	
	if humanoid.Health <= 0 then
		barData.OutlineBar.Visible = false
		return
	end
	
	if not barData.IsSelf and not barData.IsNPC and not shouldShowPlayer(target) then
		barData.OutlineBar.Visible = false
		return
	end
	
	local boxBounds = getBoxBounds(character, barData.IsNPC)
	if not boxBounds then
		barData.OutlineBar.Visible = false
		return
	end
	
	local healthBarX
	if CONFIG.Side == "Left" then
		healthBarX = boxBounds.X - CONFIG.HealthBarWidth - CONFIG.HealthBarGap
	else
		healthBarX = boxBounds.X + boxBounds.Width + CONFIG.HealthBarGap
	end
	
	healthBarX = healthBarX + CONFIG.OffsetX
	local healthBarY = boxBounds.Y + CONFIG.OffsetY
	
	barData.OutlineBar.Size = UDim2.new(0, CONFIG.HealthBarWidth, 0, boxBounds.Height)
	barData.OutlineBar.Position = UDim2.new(0, healthBarX, 0, healthBarY)
	
	local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	
	local barColor = getBarColor(target, healthPercent, barData.IsNPC, barData.IsSelf)
	
	local isDamage = barData.LastHealth and healthPercent < barData.LastHealth
	
	if barData.LastHealth ~= healthPercent then
		animateHealthBar(barData, healthPercent, barColor, isDamage)
	else
		barData.HealthBar.BackgroundColor3 = barColor
	end
	
	local screenSize = mainScreenGui.AbsoluteSize
	local isOnScreen = healthBarX > -50 and healthBarX < screenSize.X + 50 and healthBarY > -50 and healthBarY < screenSize.Y + 50
	
	barData.OutlineBar.Visible = isOnScreen
end

local function removeHealthBar(target)
	if healthBars[target] then
		if healthBars[target].CurrentTween then
			healthBars[target].CurrentTween:Cancel()
		end
		if healthBars[target].OutlineBar then
			healthBars[target].OutlineBar:Destroy()
		end
		healthBars[target] = nil
	end
end

local function updateAllHealthBars()
	for target, barData in pairs(healthBars) do
		if target and target.Parent and barData then
			if target == player then
				if CONFIG.ShowSelfHealthBar then
					updateHealthBar(target, barData)
				else
					if barData.OutlineBar then
						barData.OutlineBar.Visible = false
					end
				end
			else
				-- Logic tương tự Tracer
				if barData.IsNPC then
					if CONFIG.Enabled and (CONFIG.Mode == "NPC" or CONFIG.Mode == "Both") then
						updateHealthBar(target, barData)
					else
						barData.OutlineBar.Visible = false
					end
				else
					if CONFIG.Enabled and (CONFIG.Mode == "Player" or CONFIG.Mode == "Both") and shouldShowPlayer(target) then
						updateHealthBar(target, barData)
					else
						barData.OutlineBar.Visible = false
					end
				end
			end
		else
			removeHealthBar(target)
		end
	end
end

--=============================================================================
-- NPC MODE FUNCTIONS
--=============================================================================

local function scanForNPCs()
	local foundNPCs = NPCSystem.findNPCsRecursive(Workspace)
	
	local foundSet = {}
	for _, npc in pairs(foundNPCs) do
		foundSet[npc] = true
	end
	
	-- Remove dead NPCs
	for npc in pairs(trackedNPCs) do
		if not foundSet[npc] or not npc.Parent then
			removeHealthBar(npc)
			trackedNPCs[npc] = nil
		end
	end
	
	-- Add new NPCs
	for _, npc in pairs(foundNPCs) do
		if not trackedNPCs[npc] then
			trackedNPCs[npc] = true
			createHealthBar(npc, true)
		end
	end
end

local function initializeNPCScanning()
	scanForNPCs()
	
	if not scanConnection then
		scanConnection = RunService.Heartbeat:Connect(function()
			if CONFIG.Enabled and (CONFIG.Mode == "NPC" or CONFIG.Mode == "Both") then
				scanForNPCs()
			end
		end)
	end
end

local function cleanupNPCs()
	local npcsToRemove = {}
	for target in pairs(healthBars) do
		if target:IsA("Model") and NPCSystem.isNPC(target) then
			table.insert(npcsToRemove, target)
		end
	end
	
	for _, npc in pairs(npcsToRemove) do
		removeHealthBar(npc)
	end
	
	trackedNPCs = {}
end

local function cleanupPlayers()
	local playersToRemove = {}
	for target in pairs(healthBars) do
		if target:IsA("Player") then
			table.insert(playersToRemove, target)
		end
	end
	
	for _, playerTarget in pairs(playersToRemove) do
		removeHealthBar(playerTarget)
	end
end

--=============================================================================
-- EVENT HANDLERS
--=============================================================================

local function onPlayerAdded(newPlayer)
	if newPlayer ~= player then
		task.wait(0.5)
		createHealthBar(newPlayer, false)
	end
end

local function onPlayerRemoving(leavingPlayer)
	removeHealthBar(leavingPlayer)
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

createSelfHealthBar()
player.CharacterAdded:Connect(function()
	task.wait(0.5)
	if healthBars[player] then
		if healthBars[player].CurrentTween then
			healthBars[player].CurrentTween:Cancel()
		end
		if healthBars[player].OutlineBar then
			healthBars[player].OutlineBar:Destroy()
		end
	end
	healthBars[player] = nil
	createSelfHealthBar()
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, otherPlayer in pairs(Players:GetPlayers()) do
	if otherPlayer ~= player then
		onPlayerAdded(otherPlayer)
	end
end

initializeNPCScanning()

RunService.RenderStepped:Connect(function()
	updateAllHealthBars()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == CONFIG.ToggleKey then
		CONFIG.Enabled = not CONFIG.Enabled
	end
end)

--=============================================================================
-- PUBLIC API
--=============================================================================

local HealthBarESPAPI = {}

function HealthBarESPAPI:UpdateConfig(newConfig)
	for key, value in pairs(newConfig) do
		if CONFIG[key] ~= nil then
			CONFIG[key] = value
		end
	end
end

function HealthBarESPAPI:GetConfig()
	return CONFIG
end

function HealthBarESPAPI:Toggle(state)
	CONFIG.Enabled = state
end

function HealthBarESPAPI:SetMode(mode)
	if mode == "Player" or mode == "NPC" or mode == "Both" then
		local oldMode = CONFIG.Mode
		CONFIG.Mode = mode
		
		if oldMode ~= mode then
			if mode == "Player" then
				cleanupNPCs()
				
				for _, otherPlayer in ipairs(Players:GetPlayers()) do
					if otherPlayer ~= player and not healthBars[otherPlayer] then
						createHealthBar(otherPlayer, false)
					end
				end
			elseif mode == "NPC" then
				cleanupPlayers()
				
				scanForNPCs()
			elseif mode == "Both" then
				for _, otherPlayer in ipairs(Players:GetPlayers()) do
					if otherPlayer ~= player and not healthBars[otherPlayer] then
						createHealthBar(otherPlayer, false)
					end
				end
				
				scanForNPCs()
			end
		end
	end
end

function HealthBarESPAPI:GetMode()
	return CONFIG.Mode
end

function HealthBarESPAPI:GetTrackedTargets()
	local targets = {}
	for target in pairs(healthBars) do
		table.insert(targets, target)
	end
	return targets
end

function HealthBarESPAPI:Destroy()
	if scanConnection then
		scanConnection:Disconnect()
		scanConnection = nil
	end
	
	for target in pairs(healthBars) do
		removeHealthBar(target)
	end
	mainScreenGui:Destroy()
end

return HealthBarESPAPI
