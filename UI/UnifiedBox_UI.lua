return function(EspPage, UnifiedESP)
	local EspSection = EspPage:Section({
		Name = "Box ESP",
		Description = "Hệ thống Box ESP nâng cao với Dropdown Player/NPC + Corner Boxes",
		Icon = "10734965702",
		Side = 1
	})

	--=============================================================================
	-- BẬT/TẮT CHÍNH
	--=============================================================================

	EspSection:Toggle({
		Name = "Bật",
		Flag = "BoxESPEnable",
		Default = false,
		Callback = function(Value)
			UnifiedESP:UpdateConfig({Enabled = Value})
			UnifiedESP:Toggle(Value)
		end
	})

	--=============================================================================
	-- DROPDOWN CHỌN MODE (PLAYER HOẶC NPC)
	--=============================================================================


EspSection:Dropdown({
	Name = "Chế độ ESP",
	Flag = "ESPMode",
	Default = "Player",
	Items = {"Player", "NPC", "Both"},
	Multi = false,
	Callback = function(Value)
		local selectedMode = type(Value) == "table" and Value[1] or Value

		UnifiedESP:Toggle(true)
		UnifiedESP:SetMode(selectedMode)

		print("✓ Đổi sang chế độ ESP: " .. selectedMode)
	end
})

	--=============================================================================
	-- CẤU HÌNH BOX (CHUNG CHO CẢ 2 MODE)
	--=============================================================================

	EspSection:Label("─ Cấu Hình Box ─")

	EspSection:Slider({
		Name = "Độ dày Box",
		Flag = "BoxThickness",
		Min = 0.5,
		Max = 5,
		Default = 0.5,
		Decimals = 0.1,
		Suffix = "px",
		Callback = function(Value)
			UnifiedESP:UpdateConfig({BoxThickness = Value})
		end
	})

	EspSection:Label("Màu Box"):Colorpicker({
		Name = "Màu Box",
		Flag = "BoxColor",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(Value)
			UnifiedESP:UpdateConfig({BoxColor = Value})
		end
	})

	--=============================================================================
	-- CẤU HÌNH PLAYER MODE
	--=============================================================================

	EspSection:Label("─ Cấu Hình Player ─")

	EspSection:Toggle({
		Name = "Kiểm tra Team",
		Flag = "EnableTeamCheck",
		Default = false,
		Callback = function(Value)
			UnifiedESP:UpdateConfig({EnableTeamCheck = Value})
		end
	})

	EspSection:Toggle({
		Name = "Chỉ hiện Enemy",
		Flag = "ShowEnemyOnly",
		Default = false,
		Callback = function(Value)
			UnifiedESP:UpdateConfig({ShowEnemyOnly = Value})
		end
	})

	EspSection:Toggle({
		Name = "Chỉ hiện Đồng Đội",
		Flag = "ShowAlliedOnly",
		Default = false,
		Callback = function(Value)
			UnifiedESP:UpdateConfig({ShowAlliedOnly = Value})
		end
	})

	--=============================================================================
	-- MÀUG TEAM (CHỈ CHO PLAYER)
	--=============================================================================

	EspSection:Toggle({
		Name = "Dùng Màu Team",
		Flag = "UseTeamColors",
		Default = false,
		Callback = function(Value)
			UnifiedESP:UpdateConfig({UseTeamColors = Value})
		end
	})

	EspSection:Toggle({
		Name = "Dùng Màu Thực Tế",
		Flag = "UseActualTeamColors",
		Default = true,
		Callback = function(Value)
			UnifiedESP:UpdateConfig({UseActualTeamColors = Value})
		end
	})

	EspSection:Label("Màu Enemy"):Colorpicker({
		Name = "Màu Box Enemy",
		Flag = "EnemyBoxColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			UnifiedESP:UpdateConfig({EnemyBoxColor = Value})
		end
	})

	EspSection:Label("Màu Đồng Đội"):Colorpicker({
		Name = "Màu Box Đồng Đội",
		Flag = "AlliedBoxColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			UnifiedESP:UpdateConfig({AlliedBoxColor = Value})
		end
	})

	EspSection:Label("Màu Không Team"):Colorpicker({
		Name = "Màu Không Team",
		Flag = "NoTeamColor",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(Value)
			UnifiedESP:UpdateConfig({NoTeamColor = Value})
		end
	})

	--=============================================================================
	-- CẤU HÌNH NPC MODE
	--=============================================================================

	EspSection:Label("─ Cấu Hình NPC ─")

	EspSection:Toggle({
		Name = "Lọc Tag NPC",
		Flag = "EnableTagFilter",
		Default = true,
		Callback = function(Value)
			UnifiedESP:UpdateConfig({EnableTagFilter = Value})
		end
	})

	EspSection:Toggle({
		Name = "Phát Hiện NPC Tích Cực",
		Flag = "AggressiveNPCDetection",
		Default = false,
		Callback = function(Value)
			UnifiedESP:UpdateConfig({AggressiveNPCDetection = Value})
		end
	})

	EspSection:Toggle({
		Name = "Dùng Màu NPC",
		Flag = "UseNPCColors",
		Default = false,
		Callback = function(Value)
			UnifiedESP:UpdateConfig({UseNPCColors = Value})
		end
	})

	EspSection:Label("Màu NPC Thường"):Colorpicker({
		Name = "Màu NPC Thường",
		Flag = "StandardNPCColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			UnifiedESP:UpdateConfig({StandardNPCColor = Value})
		end
	})

	EspSection:Label("Màu Boss NPC"):Colorpicker({
		Name = "Màu Boss NPC",
		Flag = "BossNPCColor",
		Default = Color3.fromRGB(255, 165, 0),
		Callback = function(Value)
			UnifiedESP:UpdateConfig({BossNPCColor = Value})
		end
	})

	--=============================================================================
	-- CẤU HÌNH GRADIENT (CHUNG CHO CẢ 2 MODE)
	--=============================================================================

	EspSection:Label("─ Cấu Hình Gradient ─")

	EspSection:Toggle({
		Name = "Hiển thị Gradient",
		Flag = "ShowGradient",
		Default = false,
		Callback = function(Value)
			UnifiedESP:UpdateConfig({ShowGradient = Value})
		end
	})

	EspSection:Label("Màu Gradient 1"):Colorpicker({
		Name = "Màu Gradient 1",
		Flag = "GradientColor1",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(Value)
			UnifiedESP:UpdateConfig({GradientColor1 = Value})
		end
	})

	EspSection:Label("Màu Gradient 2"):Colorpicker({
		Name = "Màu Gradient 2",
		Flag = "GradientColor2",
		Default = Color3.fromRGB(0, 0, 0),
		Callback = function(Value)
			UnifiedESP:UpdateConfig({GradientColor2 = Value})
		end
	})

	EspSection:Slider({
		Name = "Độ Trong Suốt Gradient",
		Flag = "GradientTransparency",
		Min = 0,
		Max = 1,
		Default = 0.7,
		Decimals = 0.1,
		Callback = function(Value)
			UnifiedESP:UpdateConfig({GradientTransparency = Value})
		end
	})

	EspSection:Slider({
		Name = "Góc Xoay Gradient",
		Flag = "GradientRotation",
		Min = 0,
		Max = 360,
		Default = 90,
		Decimals = 1,
		Suffix = "°",
		Callback = function(Value)
			UnifiedESP:UpdateConfig({GradientRotation = Value})
		end
	})

	--=============================================================================
	-- ANIMATION GRADIENT
	--=============================================================================

	EspSection:Label("─ Animation ─")

	EspSection:Toggle({
		Name = "Bật Animation Gradient",
		Flag = "EnableGradientAnimation",
		Default = false,
		Callback = function(Value)
			UnifiedESP:UpdateConfig({EnableGradientAnimation = Value})
		end
	})

	EspSection:Slider({
		Name = "Tốc độ Animation",
		Flag = "GradientAnimationSpeed",
		Min = 0.1,
		Max = 5,
		Default = 1,
		Decimals = 0.1,
		Suffix = "x",
		Callback = function(Value)
			UnifiedESP:UpdateConfig({GradientAnimationSpeed = Value})
		end
	})

	--=============================================================================
	-- THÔNG TIN TRACKING
	--=============================================================================

	EspSection:Label("─ Thông Tin ─")

	-- Button để refresh info
	EspSection:Button({
		Name = "Làm mới thông tin",
		Callback = function()
			local mode = UnifiedESP:GetMode()
			local config = UnifiedESP:GetConfig()
			
			if mode == "Player" then
				local players = UnifiedESP:GetTrackedPlayers()
				print("📊 Mode: " .. mode .. " | Tracking: " .. #players .. " player(s)")
			else
				local npcs = UnifiedESP:GetTrackedNPCs()
				print("📊 Mode: " .. mode .. " | Tracking: " .. #npcs .. " NPC(s)")
			end
			
			print("✓ Enabled: " .. tostring(config.Enabled))
			print("✓ Box Color: " .. tostring(config.BoxColor))
			print("✓ Box Thickness: " .. config.BoxThickness)
		end
	})
end
