return function(EspPage, BoxAPIModule)
	local BoxSection = EspPage:Section({
		Name = "Box ESP",
		Description = "Vẽ khung bao quanh mục tiêu",
		Icon = "rbxassetid://10709782230", -- Icon ví dụ
		Side = 1
	})

	--=============================================================================
	-- BẬT/TẮT & CHẾ ĐỘ
	--=============================================================================

	BoxSection:Toggle({
		Name = "Bật Box ESP",
		Flag = "BoxEspToggle",
		Default = false,
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({Enabled = Value})
			BoxAPIModule:Toggle(Value)
		end
	})

	BoxSection:Dropdown({
		Name = "Chế độ (Target)",
		Flag = "BoxMode",
		Default = "Player",
		Items = {"Player", "NPC"},
		Callback = function(Value)
			local mode = type(Value) == "table" and Value[1] or Value
			BoxAPIModule:UpdateConfig({Mode = mode})
		end
	})

	--=============================================================================
	-- CẤU HÌNH GIAO DIỆN BOX
	--=============================================================================
	
	BoxSection:Label("─ Giao Diện Box ─")

	BoxSection:Slider({
		Name = "Độ dày nét (Thickness)",
		Flag = "BoxThickness",
		Min = 1,
		Max = 5,
		Default = 1,
		Decimals = 0.5,
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({BoxThickness = Value})
		end
	})

	BoxSection:Label("Màu Box Mặc Định"):Colorpicker({
		Name = "Box Color",
		Flag = "BoxDefaultColor",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({BoxColor = Value})
		end
	})
	
	--=============================================================================
	-- GRADIENT SETTINGS
	--=============================================================================
	
	BoxSection:Label("─ Hiệu Ứng Gradient ─")
	
	BoxSection:Toggle({
		Name = "Bật Gradient",
		Flag = "BoxShowGradient",
		Default = false,
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({ShowGradient = Value})
		end
	})
	
	BoxSection:Toggle({
		Name = "Animation Xoay",
		Flag = "BoxAnimGradient",
		Default = false,
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({EnableGradientAnimation = Value})
		end
	})
	
	BoxSection:Slider({
		Name = "Tốc độ xoay",
		Flag = "BoxAnimSpeed",
		Min = 1,
		Max = 10,
		Default = 1,
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({GradientAnimationSpeed = Value})
		end
	})
	
	BoxSection:Label("Màu Gradient 1"):Colorpicker({
		Name = "G Color 1",
		Flag = "BoxGColor1",
		Default = Color3.fromRGB(255, 86, 0),
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({GradientColor1 = Value})
		end
	})
	
	BoxSection:Label("Màu Gradient 2"):Colorpicker({
		Name = "G Color 2",
		Flag = "BoxGColor2",
		Default = Color3.fromRGB(255, 0, 128),
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({GradientColor2 = Value})
		end
	})

	--=============================================================================
	-- CẤU HÌNH TEAM CHECK (PLAYER)
	--=============================================================================

	BoxSection:Label("─ Cài Đặt Player/Team ─")

	BoxSection:Toggle({
		Name = "Kiểm tra Team (Team Check)",
		Flag = "BoxTeamCheck",
		Default = false,
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({EnableTeamCheck = Value})
		end
	})

	BoxSection:Toggle({
		Name = "Chỉ hiện Kẻ Thù (Enemy Only)",
		Flag = "BoxEnemyOnly",
		Default = false,
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({ShowEnemyOnly = Value})
		end
	})
	
	BoxSection:Toggle({
		Name = "Dùng màu Team (Team Colors)",
		Flag = "BoxUseTeamColors",
		Default = false,
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({UseTeamColors = Value})
		end
	})
	
	BoxSection:Label("Màu Kẻ Thù"):Colorpicker({
		Name = "Enemy Color",
		Flag = "BoxEnemyColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({EnemyBoxColor = Value})
		end
	})
	
	BoxSection:Label("Màu Đồng Đội"):Colorpicker({
		Name = "Ally Color",
		Flag = "BoxAllyColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({AlliedBoxColor = Value})
		end
	})

	--=============================================================================
	-- CẤU HÌNH NPC
	--=============================================================================

	BoxSection:Label("─ Cài Đặt NPC ─")

	BoxSection:Toggle({
		Name = "Lọc tên NPC (Tag Filter)",
		Flag = "BoxNPCTagFilter",
		Default = true,
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({EnableNPCTagFilter = Value})
		end
	})
	
	BoxSection:Label("Màu NPC"):Colorpicker({
		Name = "NPC Color",
		Flag = "BoxNPCColor",
		Default = Color3.fromRGB(255, 50, 50),
		Callback = function(Value)
			BoxAPIModule:UpdateConfig({NPCBoxColor = Value})
		end
	})
end
