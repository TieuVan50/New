--═══════════════════════════════════════════════════════════════════════════════
--  UNIFIED BOX SYSTEM - PLAYER & NPC (OPTIMIZED)
--═══════════════════════════════════════════════════════════════════════════════

local Services = {
	Players         = game:GetService("Players"),
	RunService      = game:GetService("RunService"),
	Teams           = game:GetService("Teams"),
	Workspace       = game:GetService("Workspace"),
	CoreGui         = game:GetService("CoreGui")
}

--═══════════════════════════════════════════════════════════════════════════════
--  BIẾN CỤC BỘ & CACHE
--═══════════════════════════════════════════════════════════════════════════════

local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ViewportSize = Camera.ViewportSize

-- Danh sách các Tag để nhận diện NPC
local NPCTags = {
	"NPC", "Npc", "npc", "Enemy", "enemy", "Enemies", "enemies",
	"Hostile", "hostile", "Bad", "bad", "BadGuy", "badguy",
	"Foe", "foe", "Opponent", "opponent", "Bot", "bot", "Bots", "bots",
	"Mob", "mob", "Mobs", "mobs", "Monster", "monster", "Monsters", "monsters",
	"Zombie", "zombie", "Zombies", "zombies", "Creature", "creature",
	"Boss", "boss", "MiniBoss", "miniboss", "Guard", "guard",
	"Soldier", "soldier", "Dummy", "dummy"
}

--═══════════════════════════════════════════════════════════════════════════════
--  CẤU HÌNH (CONFIG TABLE)
--═══════════════════════════════════════════════════════════════════════════════

local CONFIG = {
	-- Trạng thái & Chế độ
	Enabled = false,
	Mode = "Player", -- "Player" hoặc "NPC"
	
	-- Box Style
	BoxColor = Color3.fromRGB(255, 255, 255),
	BoxThickness = 1,
	BoxTransparency = 1, -- Độ trong suốt khung nền (thường là 1 để rỗng)
	
	-- Gradient Settings
	ShowGradient = false,
	GradientColor1 = Color3.fromRGB(255, 86, 0),
	GradientColor2 = Color3.fromRGB(255, 0, 128),
	GradientTransparency = 0.5,
	GradientRotation = 90,
	EnableGradientAnimation = false,
	GradientAnimationSpeed = 1,
	
	-- Team Settings (Player Mode)
	EnableTeamCheck = false,
	ShowEnemyOnly = false,
	ShowAlliedOnly = false,
	UseTeamColors = false,
	UseActualTeamColors = true,
	EnemyBoxColor = Color3.fromRGB(255, 0, 0),
	AlliedBoxColor = Color3.fromRGB(0, 255, 0),
	NoTeamColor = Color3.fromRGB(255, 255, 255),
	
	-- NPC Settings
	EnableNPCTagFilter = true,
	AggressiveNPCDetection = false,
	NPCBoxColor = Color3.fromRGB(255, 50, 50)
}

--═══════════════════════════════════════════════════════════════════════════════
--  QUẢN LÝ DỮ LIỆU (STORAGE)
--═══════════════════════════════════════════════════════════════════════════════

local Storage = {
	ActiveBoxes = {},       -- Lưu trữ GUI Box hiện tại
	TrackedNPCs = {},       -- Lưu danh sách NPC đã tìm thấy
	Connections = {},       -- Lưu các kết nối sự kiện (RenderStepped, PlayerAdded...)
	GradientRotation = 0,   -- Biến đếm cho animation gradient
	ScreenGui = nil         -- GUI chính
}

--═══════════════════════════════════════════════════════════════════════════════
--  HỆ THỐNG TEAM (TEAM LOGIC)
--═══════════════════════════════════════════════════════════════════════════════

local TeamLogic = {}

-- Tìm kiếm dịch vụ Teams hoặc folder Teams
function TeamLogic.getTeamsService()
	if Services.Teams then return Services.Teams end
	return game:FindFirstChild("Teams")
end

-- Lấy Team của Player (Hỗ trợ nhiều kiểu game)
function TeamLogic.getPlayerTeam(targetPlayer)
	if not targetPlayer then return nil end
	
	-- Cách 1: Thuộc tính Team chuẩn
	if targetPlayer.Team then
		return targetPlayer.Team
	end
	
	-- Cách 2: Thuộc tính TeamColor
	if targetPlayer.TeamColor then
		return targetPlayer.TeamColor
	end
	
	-- Cách 3: Kiểm tra tên trong Leaderstats (Một số game cũ)
	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	if leaderstats then
		local teamStat = leaderstats:FindFirstChild("Team")
		if teamStat then return teamStat.Value end
	end
	
	return nil
end

-- Kiểm tra xem 2 người chơi có cùng phe không
function TeamLogic.isSameTeam(player1, player2)
	if not player1 or not player2 then return false end
	
	-- Nếu Team Check bị tắt, coi như là kẻ thù (hoặc hiện tất cả tùy logic hiển thị)
	-- Nhưng hàm này chỉ trả về việc CÙNG TEAM hay không.
	
	local team1 = TeamLogic.getPlayerTeam(player1)
	local team2 = TeamLogic.getPlayerTeam(player2)
	
	-- Nếu cả 2 không có team -> Free For All -> Là kẻ thù
	if not team1 and not team2 then return false end
	
	return team1 == team2
end

-- Kiểm tra xem có phải kẻ thù không (Dựa trên config)
function TeamLogic.isEnemy(targetPlayer)
	if not CONFIG.EnableTeamCheck then return true end -- Nếu tắt check team -> Luôn hiển thị
	return not TeamLogic.isSameTeam(LocalPlayer, targetPlayer)
end

--═══════════════════════════════════════════════════════════════════════════════
--  HỆ THỐNG NPC (NPC LOGIC)
--═══════════════════════════════════════════════════════════════════════════════

local NPCLogic = {}

function NPCLogic.isPlayer(model)
	return Services.Players:GetPlayerFromCharacter(model) ~= nil
end

function NPCLogic.isNPC(model)
	if not model or not model:IsA("Model") then return false end
	if NPCLogic.isPlayer(model) then return false end -- Bỏ qua nếu là người chơi
	
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
	
	if not humanoid or not rootPart or humanoid.Health <= 0 then return false end
	
	-- Chế độ quét mạnh (Lấy tất cả Model có Humanoid)
	if CONFIG.AggressiveNPCDetection then return true end
	
	-- Lọc theo Tag tên
	if CONFIG.EnableNPCTagFilter then
		local nameLower = model.Name:lower()
		for _, tag in ipairs(NPCTags) do
			if nameLower:find(tag:lower()) then return true end
		end
		
		-- Kiểm tra Parent folder (Ví dụ: workspace.Enemies)
		local parent = model.Parent
		if parent then
			local parentName = parent.Name:lower()
			for _, tag in ipairs(NPCTags) do
				if parentName:find(tag:lower()) then return true end
			end
		end
		
		-- Kiểm tra BoolValue đánh dấu (IsNPC, Enemy...)
		for _, child in pairs(model:GetChildren()) do
			if child:IsA("BoolValue") and (child.Name == "IsNPC" or child.Name == "Enemy") and child.Value == true then
				return true
			end
		end
		
		-- Kiểm tra Attribute
		if model:GetAttribute("IsNPC") == true or model:GetAttribute("Enemy") == true then
			return true
		end
	end
	
	return false
end

--═══════════════════════════════════════════════════════════════════════════════
--  HỆ THỐNG GUI (BOX RENDER)
--═══════════════════════════════════════════════════════════════════════════════

local BoxLogic = {}

-- Khởi tạo ScreenGui
function BoxLogic.initGui()
	if Storage.ScreenGui then Storage.ScreenGui:Destroy() end
	
	Storage.ScreenGui = Instance.new("ScreenGui")
	Storage.ScreenGui.Name = "UnifiedBoxESP"
	Storage.ScreenGui.ResetOnSpawn = false
	Storage.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Bảo vệ GUI khỏi các script clear (nếu executor hỗ trợ)
	if syn and syn.protect_gui then
		syn.protect_gui(Storage.ScreenGui)
		Storage.ScreenGui.Parent = Services.CoreGui
	elseif gethui then
		Storage.ScreenGui.Parent = gethui()
	else
		Storage.ScreenGui.Parent = Services.CoreGui
	end
end

-- Tạo khung Box mới
function BoxLogic.createBox(id)
	local boxObj = {
		Frame = Instance.new("Frame"),
		Stroke = Instance.new("UIStroke"),
		Gradient = Instance.new("UIGradient")
	}
	
	-- Cấu hình Frame
	boxObj.Frame.Name = "Box_" .. tostring(id)
	boxObj.Frame.BackgroundTransparency = 1 -- Trong suốt, chỉ hiện viền
	boxObj.Frame.BackgroundColor3 = Color3.new(1, 1, 1) -- Màu nền trắng để Gradient hoạt động
	boxObj.Frame.BorderSizePixel = 0
	boxObj.Frame.Parent = Storage.ScreenGui
	
	-- Cấu hình Stroke (Viền)
	boxObj.Stroke.Thickness = CONFIG.BoxThickness
	boxObj.Stroke.Color = CONFIG.BoxColor
	boxObj.Stroke.LineJoinMode = Enum.LineJoinMode.Miter
	boxObj.Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	boxObj.Stroke.Parent = boxObj.Frame
	
	-- Cấu hình Gradient (Ẩn mặc định)
	boxObj.Gradient.Enabled = false
	boxObj.Gradient.Parent = boxObj.Frame
	
	return boxObj
end

-- Lấy màu sắc phù hợp cho mục tiêu
function BoxLogic.getColor(target, isPlayer)
	if isPlayer then
		if CONFIG.UseTeamColors then
			if CONFIG.UseActualTeamColors then
				if target.TeamColor then return target.TeamColor.Color end
				return CONFIG.NoTeamColor
			else
				return TeamLogic.isEnemy(target) and CONFIG.EnemyBoxColor or CONFIG.AlliedBoxColor
			end
		else
			return CONFIG.BoxColor
		end
	else
		-- Logic màu cho NPC
		return CONFIG.NPCBoxColor
	end
end

-- Tính toán vị trí Box (Hỗ trợ PC & Mobile chuẩn xác)
function BoxLogic.calculateBox(model)
	local cf, size = model:GetBoundingBox()
	local corners = {
		cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
		cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
		cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
		cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
		cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
		cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
		cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
		cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)
	}
	
	local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
	local onScreen = false
	
	for _, corner in ipairs(corners) do
		local screenPos, visible = Camera:WorldToViewportPoint(corner.Position)
		if visible then onScreen = true end
		
		if screenPos.X < minX then minX = screenPos.X end
		if screenPos.X > maxX then maxX = screenPos.X end
		if screenPos.Y < minY then minY = screenPos.Y end
		if screenPos.Y > maxY then maxY = screenPos.Y end
	end
	
	-- Nếu đối tượng ở sau lưng hoặc quá xa
	if not onScreen then return nil end
	
	return {
		Position = UDim2.new(0, minX, 0, minY),
		Size = UDim2.new(0, maxX - minX, 0, maxY - minY)
	}
end

-- Cập nhật một Box cụ thể
function BoxLogic.updateBox(id, model, isPlayer)
	local boxData = Storage.ActiveBoxes[id]
	if not boxData then
		boxData = BoxLogic.createBox(id)
		Storage.ActiveBoxes[id] = boxData
	end
	
	-- Kiểm tra model tồn tại
	if not model or not model.Parent then
		BoxLogic.removeBox(id)
		return
	end
	
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		boxData.Frame.Visible = false
		return
	end
	
	-- Logic hiển thị theo config
	local shouldShow = CONFIG.Enabled
	
	if isPlayer then
		if CONFIG.EnableTeamCheck then
			local isEnemy = TeamLogic.isEnemy(Services.Players:GetPlayerFromCharacter(model))
			if CONFIG.ShowEnemyOnly and not isEnemy then shouldShow = false end
			if CONFIG.ShowAlliedOnly and isEnemy then shouldShow = false end
		end
	end
	
	if not shouldShow then
		boxData.Frame.Visible = false
		return
	end
	
	-- Tính toán vị trí
	local boxMetrics = BoxLogic.calculateBox(model)
	if not boxMetrics then
		boxData.Frame.Visible = false
		return
	end
	
	-- Cập nhật thuộc tính Visual
	local color
	if isPlayer then
		local player = Services.Players:GetPlayerFromCharacter(model)
		color = BoxLogic.getColor(player, true)
	else
		color = BoxLogic.getColor(model, false)
	end
	
	-- Apply thông số vào Frame
	boxData.Frame.Position = boxMetrics.Position
	boxData.Frame.Size = boxMetrics.Size
	boxData.Frame.Visible = true
	
	-- Apply Stroke
	boxData.Stroke.Thickness = CONFIG.BoxThickness
	
	-- Gradient Handling
	if CONFIG.ShowGradient then
		boxData.Stroke.Enabled = false -- Tắt stroke thường
		boxData.Frame.BorderSizePixel = CONFIG.BoxThickness -- Dùng border của frame để hiện gradient (Workaround)
		-- Lưu ý: UIStroke không hỗ trợ UIGradient trực tiếp tốt trên viền rỗng, 
		-- nên ta dùng BackgroundTransparency kết hợp hoặc logic khác.
		-- Cách tốt nhất cho Box Gradient: Frame nền mỏng + UIGradient
		
		boxData.Frame.BackgroundTransparency = 0 -- Hiện nền để áp dụng Gradient vào viền giả
		-- Logic Box Gradient phức tạp hơn với UIStroke, ở đây dùng màu Stroke cơ bản nếu tắt Gradient
		-- Nếu bật Gradient, ta chuyển màu Stroke:
		boxData.Stroke.Enabled = true
		boxData.Stroke.Color = Color3.new(1,1,1) -- Trắng để ăn màu Gradient
		boxData.Gradient.Enabled = true
		boxData.Gradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0.0, CONFIG.GradientColor1),
			ColorSequenceKeypoint.new(1.0, CONFIG.GradientColor2)
		}
		boxData.Gradient.Rotation = CONFIG.GradientRotation + Storage.GradientRotation
	else
		boxData.Stroke.Enabled = true
		boxData.Stroke.Color = color
		boxData.Gradient.Enabled = false
		boxData.Frame.BackgroundTransparency = 1
	end
end

function BoxLogic.removeBox(id)
	if Storage.ActiveBoxes[id] then
		if Storage.ActiveBoxes[id].Frame then
			Storage.ActiveBoxes[id].Frame:Destroy()
		end
		Storage.ActiveBoxes[id] = nil
	end
end

function BoxLogic.clearAll()
	for id, _ in pairs(Storage.ActiveBoxes) do
		BoxLogic.removeBox(id)
	end
	Storage.TrackedNPCs = {}
end

--═══════════════════════════════════════════════════════════════════════════════
--  VÒNG LẶP CHÍNH (MAIN LOOP)
--═══════════════════════════════════════════════════════════════════════════════

local Core = {}

function Core.updateAll()
	-- Xoay gradient nếu bật animation
	if CONFIG.EnableGradientAnimation and CONFIG.ShowGradient then
		Storage.GradientRotation = (Storage.GradientRotation + CONFIG.GradientAnimationSpeed * 2) % 360
	end

	if CONFIG.Mode == "Player" then
		for _, player in ipairs(Services.Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				BoxLogic.updateBox(player.UserId, player.Character, true)
			end
		end
	elseif CONFIG.Mode == "NPC" then
		for npcModel, _ in pairs(Storage.TrackedNPCs) do
			if npcModel.Parent then
				BoxLogic.updateBox(npcModel, npcModel, false)
			else
				Storage.TrackedNPCs[npcModel] = nil
				BoxLogic.removeBox(npcModel)
			end
		end
	end
end

-- Quét NPC định kỳ (Không chạy mỗi frame để đỡ lag)
function Core.scanNPCs()
	if CONFIG.Mode ~= "NPC" then return end
	
	-- Quét workspace
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and not Storage.TrackedNPCs[obj] then
			if NPCLogic.isNPC(obj) then
				Storage.TrackedNPCs[obj] = true
			end
		end
	end
end

function Core.start()
	BoxLogic.initGui()
	
	-- Render Loop
	Storage.Connections.Render = Services.RunService.RenderStepped:Connect(Core.updateAll)
	
	-- NPC Scan Loop (1 giây 1 lần)
	task.spawn(function()
		while task.wait(1) do
			if CONFIG.Enabled and CONFIG.Mode == "NPC" then
				Core.scanNPCs()
			end
		end
	end)
	
	-- Player Removal
	Services.Players.PlayerRemoving:Connect(function(player)
		BoxLogic.removeBox(player.UserId)
	end)
end

--═══════════════════════════════════════════════════════════════════════════════
--  PUBLIC API MODULE
--═══════════════════════════════════════════════════════════════════════════════

local BoxAPIModule = {}

function BoxAPIModule:UpdateConfig(newConfig)
	for key, value in pairs(newConfig) do
		if CONFIG[key] ~= nil then
			CONFIG[key] = value
		end
	end
	
	-- Nếu đổi chế độ -> Xóa sạch box cũ để vẽ lại
	if newConfig.Mode then
		BoxLogic.clearAll()
	end
end

function BoxAPIModule:GetConfig()
	return CONFIG
end

function BoxAPIModule:Toggle(state)
	CONFIG.Enabled = state
	if not state then
		BoxLogic.clearAll()
	end
end

function BoxAPIModule:Destroy()
	for _, conn in pairs(Storage.Connections) do
		conn:Disconnect()
	end
	if Storage.ScreenGui then
		Storage.ScreenGui:Destroy()
	end
	BoxLogic.clearAll()
end

-- Khởi động hệ thống
Core.start()

return BoxAPIModule
