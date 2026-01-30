local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--=============================================================================
-- NPC TAGS LIST (EXPANDED - GIỐNG CHAMS)
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

local CONFIG = {
	-- Mode (Player/NPC) - GIỐNG CHAMS
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
	
	-- Distance
	MaxDistance = 10000,
	NPCMaxDistance = 10000,
	
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
	
	-- NPC Specific Config (GIỐNG CHAMS)
	NPCEnabled = false,
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
-- NPC SYSTEM (GIỐNG CHAMS - ĐẦY ĐỦ)
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
	
	if CONFIG.EnableTagFilter then
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

local function getDistance(position)
	return (position - camera.CFrame.p).Magnitude
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
	end
end

local function getBarColor(targetPlayer, healthPercent, isSelf)
	-- NPC Color Selection
	if targetPlayer and not targetPlayer:IsA("Player") then
		-- Nó là NPC
		if CONFIG.UseNPCColors then
			if NPCSystem.isBoss(targetPlayer) then
				return CONFIG.BossNPCColor
			else
				return CONFIG.StandardNPCColor
			end
		end
		return CONFIG.HealthBarColor
	end
	
	-- Player Color Selection
	if not CONFIG.UseTeamColors then
		return CONFIG.HealthBarColor
	end
	
	if CONFIG.UseActualTeamColors then
		local teamColor = getPlayerTeamColor(targetPlayer)
		if teamColor then
			return teamColor
		else
			return CONFIG.NoTeamColor
		end
	else
		if isEnemy(targetPlayer) then
			return CONFIG.EnemyHealthBarColor
		else
			return CONFIG.AlliedHealthBarColor
		end
	end
end

local function createHealthBar(targetPlayer)
	if healthBars[targetPlayer] then return end
	
	local character
	if targetPlayer:IsA("Player") then
		character = targetPlayer.Character
	else
		character = targetPlayer
	end
	
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local outlineBar = Instance.new("Frame")
	outlineBar.Name = "HealthBarOutline"
	outlineBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	outlineBar.BorderSizePixel = 0
	outlineBar.Parent = mainScreenGui
	
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.BackgroundColor3 = CONFIG.HealthBarColor
	healthBar.BorderSizePixel = 0
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.Position = UDim2.new(0, 0, 0, 0)
	healthBar.Parent = outlineBar
	
	local damageTrail = Instance.new("Frame")
	damageTrail.Name = "DamageTrail"
	damageTrail.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	damageTrail.BackgroundTransparency = 0.3
	damageTrail.BorderSizePixel = 0
	damageTrail.Size = UDim2.new(1, 0, 1, 0)
	damageTrail.Position = UDim2.new(0, 0, 0, 0)
	damageTrail.Parent = outlineBar
	
	local flashOverlay = Instance.new("Frame")
	flashOverlay.Name = "FlashOverlay"
	flashOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	flashOverlay.BackgroundTransparency = 1
	flashOverlay.BorderSizePixel = 0
	flashOverlay.Size = UDim2.new(1, 0, 1, 0)
	flashOverlay.Parent = outlineBar
	
	healthBars[targetPlayer] = {
		OutlineBar = outlineBar,
		HealthBar = healthBar,
		DamageTrail = damageTrail,
		FlashOverlay = flashOverlay,
		IsSelf = false,
		LastHealth = 1,
		CurrentTween = nil
	}
end

local function createSelfHealthBar()
	if healthBars[player] then return end
	
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local outlineBar = Instance.new("Frame")
	outlineBar.Name = "SelfHealthBarOutline"
	outlineBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	outlineBar.BorderSizePixel = 0
	outlineBar.Size = UDim2.new(0, CONFIG.HealthBarWidth, 0, 100)
	outlineBar.Position = UDim2.new(1, -CONFIG.HealthBarWidth - 10, 0.5, -50)
	outlineBar.Parent = mainScreenGui
	
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.BackgroundColor3 = CONFIG.HealthBarColor
	healthBar.BorderSizePixel = 0
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.Position = UDim2.new(0, 0, 0, 0)
	healthBar.Parent = outlineBar
	
	local damageTrail = Instance.new("Frame")
	damageTrail.Name = "DamageTrail"
	damageTrail.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	damageTrail.BackgroundTransparency = 0.3
	damageTrail.BorderSizePixel = 0
	damageTrail.Size = UDim2.new(1, 0, 1, 0)
	damageTrail.Position = UDim2.new(0, 0, 0, 0)
	damageTrail.Parent = outlineBar
	
	local flashOverlay = Instance.new("Frame")
	flashOverlay.Name = "FlashOverlay"
	flashOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	flashOverlay.BackgroundTransparency = 1
	flashOverlay.BorderSizePixel = 0
	flashOverlay.Size = UDim2.new(1, 0, 1, 0)
	flashOverlay.Parent = outlineBar
	
	healthBars[player] = {
		OutlineBar = outlineBar,
		HealthBar = healthBar,
		DamageTrail = damageTrail,
		FlashOverlay = flashOverlay,
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
	
	-- Check distance
	if barData.IsSelf then
		-- For self health bar, no team check needed
	elseif targetPlayer:IsA("Player") then
		-- For player targets
		if not shouldShowPlayer(targetPlayer) then
			barData.OutlineBar.Visible = false
			return
		end
		-- Check distance for players
		local distance = getDistance(character.HumanoidRootPart.Position)
		if distance > CONFIG.MaxDistance then
			barData.OutlineBar.Visible = false
			return
		end
	else
		-- For NPC targets
		local distance = getDistance(character.HumanoidRootPart.Position)
		if distance > CONFIG.NPCMaxDistance then
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
-- NPC MODE (GIỐNG CHAMS)
--=============================================================================

local function scanForNPCs()
	if not CONFIG.NPCEnabled then return end
	
	local foundNPCs = NPCSystem.findNPCsRecursive(workspace)
	
	local foundSet = {}
	for _, npc in pairs(foundNPCs) do
		foundSet[npc] = true
	end
	
	-- Remove NPCs that no longer exist
	for npc in pairs(trackedNPCs) do
		if not foundSet[npc] or not npc.Parent then
			removeHealthBar(npc)
		end
	end
	
	-- Add new NPCs
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
				if CONFIG.NPCEnabled then
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

function HealthBarESPAPI:ToggleNPC(state)
	CONFIG.NPCEnabled = state
	if not state then
		-- Clean up NPCs
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
	else
		scanForNPCs()
	end
end

function HealthBarESPAPI:SetMode(mode)
	if mode == "Player" or mode == "NPC" or mode == "Both" then
		switchMode(mode)
	else
		warn("Invalid mode: " .. tostring(mode) .. ". Use 'Player', 'NPC', or 'Both'")
	end
end

function HealthBarESPAPI:GetMode()
	return CONFIG.Mode
end

function HealthBarESPAPI:GetTrackedNPCs()
	local npcList = {}

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
	elseif newMode == "NPC" or newMode == "Both" then
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
				if CONFIG.NPCEnabled then
					scanForNPCs()
				end
			end)
		end
	end
	
	CONFIG.Mode = newMode
end


	for npc in pairs(trackedNPCs) do
		if npc.Parent then
			table.insert(npcList, npc)
		end
	end
	return npcList
end

function HealthBarESPAPI:GetTrackedPlayers()
	local playerList = {}
	for target in pairs(healthBars) do
		if target:IsA("Player") then
			table.insert(playerList, target)
		end
	end
	return playerList
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
