return function(EspPage, UnifiedChams)
	local ChamsSection = EspPage:Section({
		Name = "Chams ESP",
		Description = "Highlight targets through walls - Player & NPC",
		Icon = "10709782230",
		Side = 2
	})

	--=============================================================================
	-- BẬT/TẮT CHÍNH
	--=============================================================================

	ChamsSection:Toggle({
		Name = "Enable Chams",
		Flag = "ChamsToggle",
		Default = false,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({enabled = Value})
			UnifiedChams:Toggle(Value)
		end
	})

	--=============================================================================
	-- DROPDOWN CHỌN MODE (PLAYER HOẶC NPC)
	--=============================================================================

	ChamsSection:Dropdown({
		Name = "Chams Mode",
		Flag = "ChamsMode",
		Default = "Player",
		Items = {"Player", "NPC"},
		Multi = false,
		Callback = function(Value)
			local selectedMode = type(Value) == "table" and Value[1] or Value
			UnifiedChams:SetMode(selectedMode)
			print("✓ Chams mode changed to: " .. selectedMode)
		end
	})

	--=============================================================================
	-- CẤU HÌNH CHUNG
	--=============================================================================

	ChamsSection:Label("─ Cấu Hình Chung ─")

	ChamsSection:Toggle({
		Name = "Use Visibility Colors",
		Flag = "ChamsVisibilityColors",
		Default = false,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({useVisibilityColors = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Use Raycasting",
		Flag = "ChamsRaycasting",
		Default = false,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({useRaycasting = Value})
		end
	})

	ChamsSection:Dropdown({
		Name = "Depth Mode",
		Flag = "ChamsDepthMode",
		Default = "AlwaysOnTop",
		Items = {"AlwaysOnTop", "Occluded"},
		Multi = false,
		Callback = function(Value)
			local selectedMode = type(Value) == "table" and Value[1] or Value
			UnifiedChams:UpdateConfig({depthMode = selectedMode})
		end
	})

	ChamsSection:Slider({
		Name = "Fill Transparency",
		Flag = "ChamsFillTransparency",
		Min = 0,
		Max = 1,
		Default = 0.5,
		Decimals = 0.01,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({fillTransparency = Value})
		end
	})

	ChamsSection:Slider({
		Name = "Outline Transparency",
		Flag = "ChamsOutlineTransparency",
		Min = 0,
		Max = 1,
		Default = 0,
		Decimals = 0.01,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({outlineTransparency = Value})
		end
	})

	--=============================================================================
	-- CẤU HÌNH PLAYER MODE
	--=============================================================================

	ChamsSection:Label("─ Player Settings ─")

	ChamsSection:Toggle({
		Name = "Team Check",
		Flag = "ChamsTeamCheck",
		Default = false,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({EnableTeamCheck = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Enemy Only",
		Flag = "ChamsEnemyOnly",
		Default = false,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({ShowEnemyOnly = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Allied Only",
		Flag = "ChamsAlliedOnly",
		Default = false,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({ShowAlliedOnly = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Use Team Colors",
		Flag = "ChamsUseTeamColors",
		Default = false,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({UseTeamColors = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Use Actual Team Colors",
		Flag = "ChamsUseActualTeamColors",
		Default = true,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({UseActualTeamColors = Value})
		end
	})

	--=============================================================================
	-- MÀUG BASE (CHO CẢ PLAYER & NPC)
	--=============================================================================

	ChamsSection:Label("─ Base Colors ─")

	ChamsSection:Label("Fill Color"):Colorpicker({
		Name = "Fill Color",
		Flag = "ChamsFillColor",
		Default = Color3.fromRGB(0, 255, 140),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({fillColor = Value})
		end
	})

	ChamsSection:Label("Outline Color"):Colorpicker({
		Name = "Outline Color",
		Flag = "ChamsOutlineColor",
		Default = Color3.fromRGB(0, 255, 140),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({outlineColor = Value})
		end
	})

	--=============================================================================
	-- MÀUG PLAYER TEAM
	--=============================================================================

	ChamsSection:Label("─ Player Team Colors ─")

	ChamsSection:Label("Enemy Fill Color"):Colorpicker({
		Name = "Enemy Fill Color",
		Flag = "ChamsEnemyFillColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({EnemyFillColor = Value})
		end
	})

	ChamsSection:Label("Enemy Outline Color"):Colorpicker({
		Name = "Enemy Outline Color",
		Flag = "ChamsEnemyOutlineColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({EnemyOutlineColor = Value})
		end
	})

	ChamsSection:Label("Allied Fill Color"):Colorpicker({
		Name = "Allied Fill Color",
		Flag = "ChamsAlliedFillColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({AlliedFillColor = Value})
		end
	})

	ChamsSection:Label("Allied Outline Color"):Colorpicker({
		Name = "Allied Outline Color",
		Flag = "ChamsAlliedOutlineColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({AlliedOutlineColor = Value})
		end
	})

	ChamsSection:Label("No Team Color"):Colorpicker({
		Name = "No Team Color",
		Flag = "ChamsNoTeamColor",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({NoTeamColor = Value})
		end
	})

	--=============================================================================
	-- MÀUG VISIBILITY
	--=============================================================================

	ChamsSection:Label("─ Visibility Colors ─")

	ChamsSection:Label("Visible Fill Color"):Colorpicker({
		Name = "Visible Fill Color",
		Flag = "ChamsVisibleFillColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({visibleFillColor = Value})
		end
	})

	ChamsSection:Label("Visible Outline Color"):Colorpicker({
		Name = "Visible Outline Color",
		Flag = "ChamsVisibleOutlineColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({visibleOutlineColor = Value})
		end
	})

	ChamsSection:Label("Hidden Fill Color"):Colorpicker({
		Name = "Hidden Fill Color",
		Flag = "ChamsHiddenFillColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({hiddenFillColor = Value})
		end
	})

	ChamsSection:Label("Hidden Outline Color"):Colorpicker({
		Name = "Hidden Outline Color",
		Flag = "ChamsHiddenOutlineColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({hiddenOutlineColor = Value})
		end
	})

	--=============================================================================
	-- CẤU HÌNH NPC MODE
	--=============================================================================

	ChamsSection:Label("─ NPC Settings ─")

	ChamsSection:Toggle({
		Name = "NPC Tag Filter",
		Flag = "ChamsNPCTagFilter",
		Default = true,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({EnableTagFilter = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Aggressive NPC Detection",
		Flag = "ChamsAggressiveNPC",
		Default = false,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({AggressiveNPCDetection = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Use NPC Colors",
		Flag = "ChamsUseNPCColors",
		Default = false,
		Callback = function(Value)
			UnifiedChams:UpdateConfig({UseNPCColors = Value})
		end
	})

	ChamsSection:Label("Standard NPC Fill"):Colorpicker({
		Name = "Standard NPC Fill",
		Flag = "ChamsStandardNPCFill",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({StandardNPCFillColor = Value})
		end
	})

	ChamsSection:Label("Standard NPC Outline"):Colorpicker({
		Name = "Standard NPC Outline",
		Flag = "ChamsStandardNPCOutline",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({StandardNPCOutlineColor = Value})
		end
	})

	ChamsSection:Label("Boss NPC Fill"):Colorpicker({
		Name = "Boss NPC Fill",
		Flag = "ChamsBossNPCFill",
		Default = Color3.fromRGB(255, 165, 0),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({BossNPCFillColor = Value})
		end
	})

	ChamsSection:Label("Boss NPC Outline"):Colorpicker({
		Name = "Boss NPC Outline",
		Flag = "ChamsBossNPCOutline",
		Default = Color3.fromRGB(255, 165, 0),
		Callback = function(Value)
			UnifiedChams:UpdateConfig({BossNPCOutlineColor = Value})
		end
	})

	--=============================================================================
	-- THÔNG TIN TRACKING
	--=============================================================================

	ChamsSection:Label("─ Info ─")

	ChamsSection:Button({
		Name = "Refresh Info",
		Callback = function()
			local mode = UnifiedChams:GetMode()
			local targets = UnifiedChams:GetTrackedTargets()
			local config = UnifiedChams:GetConfig()
			
			print("📊 Chams Mode: " .. mode .. " | Tracking: " .. #targets .. " target(s)")
			print("✓ Enabled: " .. tostring(config.enabled))
			print("✓ Fill Transparency: " .. config.fillTransparency)
		end
	})
end
