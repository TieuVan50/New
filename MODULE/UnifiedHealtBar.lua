local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--=============================================================================
-- NPC TAGS LIST
--=============================================================================

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

local CONFIG = {
	-- Mode (Player/NPC)
	Mode = "Player",
	
	HealthBarColor = Color3.fromRGB(180, 0, 255),
	HealthBarWidth = 3,
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
	
	-- NPC Specific Config
	EnableTagFilter = true,
	AggressiveNPCDetection = false,
	UseNPCColors = false,
	StandardNPCColor = Color3.fromRGB(255, 0, 0),
	BossNPCColor = Color3.fromRGB(255, 165, 0),
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

--=============================================================================
-- NPC SYSTEM
--=============================================================================

local function isPlayer(character)
	if not character or not character:IsA("Model") then return false end
	if character == player.Character then return true end
	local targetPlayer = Players:GetPlayerFromCharacter(character)
	return targetPlayer ~= nil
end

local function isNPC(character)
	if not character or not character:IsA("Model") then return false end
	if isPlayer(character) then return false end
	
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

local function isBoss(character)
	if not character then return false end
	
	local charName = character.Name:lower()
	if charName:find("boss") or charName:find("miniboss") or charName:find("leader") then
		return true
	end
	
	return false
end

local function findNPCsRecursive(parent)
	local foundNPCs = {}
	for _, instance in pairs(parent:GetDescendants()) do
		if isNPC(instance) then
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

local function getBoxBounds(target)
	-- Handle both Player and NPC
	local character
	if target:IsA("Player") then
		character = target.Character
	else
		character = target
	end
	
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

local function getBarColor(targetPlayer, healthPercent, isSelf)
	-- Nếu là NPC
	if not targetPlayer:IsA("Player") then
		if CONFIG.UseNPCColors then
			if isBoss(targetPlayer) then
				return CONFIG.BossNPCColor
			else
				return CONFIG.StandardNPCColor
			end
		else
			return getHealthGradientColor(healthPercent)
		end
	end
	
	if not CONFIG.UseTeamColors then
		return getHealthGradientColor(healthPercent)
	end
	
	if CONFIG.UseActualTeamColors then
		local teamColor = getPlayerTeamColor(targetPlayer)
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
		
		local isEnemyPlayer = isEnemy(targetPlayer)
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

local function createHealthBar(targetPlayer)
	if healthBars[targetPlayer] then return end
	
	local OutlineBar = Instance.new("Frame")
	OutlineBar.Name = "HealthBar_" .. targetPlayer.Name
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
	
	healthBars[targetPlayer] = {
		OutlineBar = OutlineBar,
		HealthBar = HealthBar,
		DamageTrail = DamageTrail,
		FlashOverlay = FlashOverlay,
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
		IsSelf = true,
		LastHealth = 1,
		CurrentTween = nil
	}
end

local function updateHealthBar(targetPlayer, barData)
	if not barData then return end
	if not barData.OutlineBar then return end
	if not barData.OutlineBar.Parent then return end
	
	if not CONFIG.Enabled then
		barData.OutlineBar.Visible = false
		return
	end
	
	if not targetPlayer then
		barData.OutlineBar.Visible = false
		return
	end
	
	if not targetPlayer.Parent then
		barData.OutlineBar.Visible = false
		return
	end
	
	-- Handle both Player and NPC characters
	local character
	if targetPlayer:IsA("Player") then
		character = targetPlayer.Character
	else
		character = targetPlayer
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
	
	if barData.IsSelf then
		-- For self health bar
	elseif targetPlayer:IsA("Player") then
		-- For player targets
		if not shouldShowPlayer(targetPlayer) then
			barData.OutlineBar.Visible = false
			return
		end
	end
	
	local boxBounds = getBoxBounds(targetPlayer)
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
	
	local barColor = getBarColor(targetPlayer, healthPercent, barData.IsSelf)
	
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

local function removeHealthBar(targetPlayer)
	if healthBars[targetPlayer] then
		if healthBars[targetPlayer].CurrentTween then
			healthBars[targetPlayer].CurrentTween:Cancel()
		end
		if healthBars[targetPlayer].OutlineBar then
			healthBars[targetPlayer].OutlineBar:Destroy()
		end
		healthBars[targetPlayer] = nil
	end
end

local function updateAllHealthBars()
	for targetPlayer, barData in pairs(healthBars) do
		if targetPlayer and targetPlayer.Parent and barData then
			if targetPlayer == player then
				if CONFIG.ShowSelfHealthBar then
					updateHealthBar(targetPlayer, barData)
				else
					if barData.OutlineBar then
						barData.OutlineBar.Visible = false
					end
				end
			else
				updateHealthBar(targetPlayer, barData)
			end
		else
			removeHealthBar(targetPlayer)
		end
	end
end

--=============================================================================
-- NPC MODE
--=============================================================================

local function scanForNPCs()
	local foundNPCs = findNPCsRecursive(workspace)
	
	local foundSet = {}
	for _, npc in pairs(foundNPCs) do
		foundSet[npc] = true
	end
	
	for npc in pairs(trackedNPCs) do
		if not foundSet[npc] or not npc.Parent then
			removeHealthBar(npc)
		end
	end
	
	for _, npc in pairs(foundNPCs) do
		if not trackedNPCs[npc] then
			trackedNPCs[npc] = true
			createHealthBar(npc)
		end
	end
end

local function switchMode(newMode)
	if newMode == CONFIG.Mode then return end
	
	if newMode == "Player" then
		-- Clean up NPC bars
		local npcsToRemove = {}
		for target in pairs(healthBars) do
			if not target:IsA("Player") then
				table.insert(npcsToRemove, target)
			end
		end
		for _, npc in pairs(npcsToRemove) do
			removeHealthBar(npc)
		end
		trackedNPCs = {}
		
		if scanConnection then
			scanConnection:Disconnect()
			scanConnection = nil
		end
	else
		-- Clean up player bars (except self)
		local playersToRemove = {}
		for target in pairs(healthBars) do
			if target:IsA("Player") and target ~= player then
				table.insert(playersToRemove, target)
			end
		end
		for _, playerTarget in pairs(playersToRemove) do
			removeHealthBar(playerTarget)
		end
		
		-- Start NPC scanning
		scanForNPCs()
		if not scanConnection then
			scanConnection = RunService.Heartbeat:Connect(function()
				if CONFIG.Mode == "NPC" then
					scanForNPCs()
				end
			end)
		end
	end
	
	CONFIG.Mode = newMode
end

--=============================================================================
-- EVENT HANDLERS
--=============================================================================

local function onPlayerAdded(newPlayer)
	if newPlayer ~= player then
		task.wait(0.5)
		createHealthBar(newPlayer)
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
	if mode == "Player" or mode == "NPC" then
		switchMode(mode)
	else
		warn("Invalid mode: " .. tostring(mode) .. ". Use 'Player' or 'NPC'")
	end
end

function HealthBarESPAPI:GetMode()
	return CONFIG.Mode
end

function HealthBarESPAPI:Destroy()
	if scanConnection then
		scanConnection:Disconnect()
	end
	for targetPlayer in pairs(healthBars) do
		removeHealthBar(targetPlayer)
	end
	mainScreenGui:Destroy()
end

return HealthBarESPAPI
