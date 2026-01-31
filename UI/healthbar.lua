return function(EspPage, HealthBarModule)
	local HealthBarSection = EspPage:Section({
		Name = "HealthBar ESP",
		Description = "Display health bars for players and NPCs",
		Icon = "10734942351",
		Side = 2
	})

	HealthBarSection:Toggle({
		Name = "Enable HealthBar",
		Flag = "HealthBarToggle",
		Default = false,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({Enabled = Value})
			HealthBarModule:Toggle(Value)
		end
	})

	HealthBarSection:Dropdown({
		Name = "HealthBar Mode",
		Flag = "HealthBarMode",
		Default = "Player",
		Items = {"Player", "NPC", "Both"},
		Multi = false,
		Callback = function(Value)
			local selectedMode = type(Value) == "table" and Value[1] or Value
			HealthBarModule:SetMode(selectedMode)
		end
	})

	HealthBarSection:Label("─ General Settings ─")

	HealthBarSection:Slider({
		Name = "Bar Width",
		Flag = "HealthBarWidth",
		Min = 1,
		Max = 10,
		Default = 2.5,
		Decimals = 0.1,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({HealthBarWidth = Value})
		end
	})

	HealthBarSection:Slider({
		Name = "Bar Gap",
		Flag = "HealthBarGap",
		Min = 0,
		Max = 20,
		Default = 2,
		Decimals = 1,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({HealthBarGap = Value})
		end
	})

	HealthBarSection:Dropdown({
		Name = "Bar Side",
		Flag = "HealthBarSide",
		Default = "Left",
		Items = {"Left", "Right"},
		Multi = false,
		Callback = function(Value)
			local selectedSide = type(Value) == "table" and Value[1] or Value
			HealthBarModule:UpdateConfig({Side = selectedSide})
		end
	})

	HealthBarSection:Slider({
		Name = "Offset X",
		Flag = "HealthBarOffsetX",
		Min = -100,
		Max = 100,
		Default = 0,
		Decimals = 1,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({OffsetX = Value})
		end
	})

	HealthBarSection:Slider({
		Name = "Offset Y",
		Flag = "HealthBarOffsetY",
		Min = -100,
		Max = 100,
		Default = 58,
		Decimals = 1,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({OffsetY = Value})
		end
	})

	HealthBarSection:Toggle({
		Name = "Show Self HealthBar",
		Flag = "HealthBarShowSelf",
		Default = false,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({ShowSelfHealthBar = Value})
		end
	})

	HealthBarSection:Label("─ Player Settings ─")

	HealthBarSection:Toggle({
		Name = "Team Check",
		Flag = "HealthBarTeamCheck",
		Default = false,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({EnableTeamCheck = Value})
		end
	})

	HealthBarSection:Toggle({
		Name = "Enemy Only",
		Flag = "HealthBarEnemyOnly",
		Default = false,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({ShowEnemyOnly = Value})
		end
	})

	HealthBarSection:Toggle({
		Name = "Allied Only",
		Flag = "HealthBarAlliedOnly",
		Default = false,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({ShowAlliedOnly = Value})
		end
	})

	HealthBarSection:Toggle({
		Name = "Use Team Colors",
		Flag = "HealthBarUseTeamColors",
		Default = false,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({UseTeamColors = Value})
		end
	})

	HealthBarSection:Toggle({
		Name = "Use Actual Team Colors",
		Flag = "HealthBarUseActualTeamColors",
		Default = true,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({UseActualTeamColors = Value})
		end
	})

	HealthBarSection:Label("─ Player Colors ─")

	HealthBarSection:Label("Default Bar Color"):Colorpicker({
		Name = "Default Bar Color",
		Flag = "HealthBarDefaultColor",
		Default = Color3.fromRGB(180, 0, 255),
		Callback = function(Value)
			HealthBarModule:UpdateConfig({HealthBarColor = Value})
		end
	})

	HealthBarSection:Label("Enemy Bar Color"):Colorpicker({
		Name = "Enemy Bar Color",
		Flag = "HealthBarEnemyColor",
		Default = Color3.fromRGB(180, 0, 255),
		Callback = function(Value)
			HealthBarModule:UpdateConfig({EnemyHealthBarColor = Value})
		end
	})

	HealthBarSection:Label("Allied Bar Color"):Colorpicker({
		Name = "Allied Bar Color",
		Flag = "HealthBarAlliedColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			HealthBarModule:UpdateConfig({AlliedHealthBarColor = Value})
		end
	})

	HealthBarSection:Label("No Team Color"):Colorpicker({
		Name = "No Team Color",
		Flag = "HealthBarNoTeamColor",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(Value)
			HealthBarModule:UpdateConfig({NoTeamColor = Value})
		end
	})

	HealthBarSection:Label("─ Animation Settings ─")

	HealthBarSection:Slider({
		Name = "Animation Speed",
		Flag = "HealthBarAnimSpeed",
		Min = 0,
		Max = 1,
		Default = 0.3,
		Decimals = 0.01,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({AnimationSpeed = Value})
		end
	})

	HealthBarSection:Toggle({
		Name = "Flash Effect",
		Flag = "HealthBarFlashEffect",
		Default = true,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({EnableFlashEffect = Value})
		end
	})

	HealthBarSection:Label("Damage Flash Color"):Colorpicker({
		Name = "Damage Flash Color",
		Flag = "HealthBarDamageFlashColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			HealthBarModule:UpdateConfig({DamageFlashColor = Value})
		end
	})

	HealthBarSection:Label("Heal Flash Color"):Colorpicker({
		Name = "Heal Flash Color",
		Flag = "HealthBarHealFlashColor",
		Default = Color3.fromRGB(0, 255, 100),
		Callback = function(Value)
			HealthBarModule:UpdateConfig({HealFlashColor = Value})
		end
	})

	HealthBarSection:Slider({
		Name = "Flash Duration",
		Flag = "HealthBarFlashDuration",
		Min = 0.05,
		Max = 0.5,
		Default = 0.15,
		Decimals = 0.01,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({FlashDuration = Value})
		end
	})

	HealthBarSection:Label("─ NPC Settings ─")

	HealthBarSection:Toggle({
		Name = "NPC Tag Filter",
		Flag = "HealthBarNPCTagFilter",
		Default = true,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({EnableTagFilter = Value})
		end
	})

	HealthBarSection:Toggle({
		Name = "Aggressive NPC Detection",
		Flag = "HealthBarAggressiveNPC",
		Default = false,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({AggressiveNPCDetection = Value})
		end
	})

	HealthBarSection:Toggle({
		Name = "Use NPC Colors",
		Flag = "HealthBarUseNPCColors",
		Default = false,
		Callback = function(Value)
			HealthBarModule:UpdateConfig({UseNPCColors = Value})
		end
	})

	HealthBarSection:Label("NPC Bar Color"):Colorpicker({
		Name = "NPC Bar Color",
		Flag = "HealthBarNPCColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			HealthBarModule:UpdateConfig({NPCHealthBarColor = Value})
		end
	})

	HealthBarSection:Label("Boss Bar Color"):Colorpicker({
		Name = "Boss Bar Color",
		Flag = "HealthBarBossColor",
		Default = Color3.fromRGB(255, 165, 0),
		Callback = function(Value)
			HealthBarModule:UpdateConfig({BossHealthBarColor = Value})
		end
	})

	HealthBarSection:Label("─ Info ─")

	HealthBarSection:Button({
		Name = "Refresh Info",
		Callback = function()
			local mode = HealthBarModule:GetMode()
			local targets = HealthBarModule:GetTrackedTargets()
			local config = HealthBarModule:GetConfig()
			
			print("📊 HealthBar Mode: " .. mode .. " | Tracking: " .. #targets .. " target(s)")
			print("✓ Enabled: " .. tostring(config.Enabled))
			print("✓ Bar Width: " .. config.HealthBarWidth)
			print("✓ Side: " .. config.Side .. " | Gap: " .. config.HealthBarGap)
		end
	})
end
