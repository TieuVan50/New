return function(EspPage, TracerModule)
	local TracerSection = EspPage:Section({
		Name = "Tracer ESP",
		Description = "Draw lines to targets from screen origin",
		Icon = "10734942351",
		Side = 2
	})

	TracerSection:Toggle({
		Name = "Enable Tracer",
		Flag = "TracerToggle",
		Default = false,
		Callback = function(Value)
			TracerModule:UpdateConfig({Enabled = Value})
			TracerModule:Toggle(Value)
		end
	})

	TracerSection:Dropdown({
		Name = "Tracer Mode",
		Flag = "TracerMode",
		Default = "Player",
		Items = {"Player", "NPC", "Both"},
		Multi = false,
		Callback = function(Value)
			local selectedMode = type(Value) == "table" and Value[1] or Value
			TracerModule:SetMode(selectedMode)
		end
	})

	TracerSection:Label("─ General Settings ─")

	TracerSection:Slider({
		Name = "Tracer Thickness",
		Flag = "TracerThickness",
		Min = 0.1,
		Max = 5,
		Default = 1,
		Decimals = 0.1,
		Callback = function(Value)
			TracerModule:UpdateConfig({TracerThickness = Value})
		end
	})

	TracerSection:Slider({
		Name = "Tracer Transparency",
		Flag = "TracerTransparency",
		Min = 0,
		Max = 1,
		Default = 1,
		Decimals = 0.01,
		Callback = function(Value)
			TracerModule:UpdateConfig({TracerTransparency = Value})
		end
	})

	TracerSection:Dropdown({
		Name = "Origin Point",
		Flag = "TracerOrigin",
		Default = "Top",
		Items = {"Top", "Center", "Bottom", "Mouse"},
		Multi = false,
		Callback = function(Value)
			local selectedOrigin = type(Value) == "table" and Value[1] or Value
			TracerModule:UpdateConfig({Origin = selectedOrigin})
		end
	})

	TracerSection:Dropdown({
		Name = "Target Point",
		Flag = "TracerTarget",
		Default = "Head",
		Items = {"Head", "Torso", "Feet", "Root"},
		Multi = false,
		Callback = function(Value)
			local selectedTarget = type(Value) == "table" and Value[1] or Value
			TracerModule:UpdateConfig({Target = selectedTarget})
		end
	})

	TracerSection:Slider({
		Name = "Offset X",
		Flag = "TracerOffsetX",
		Min = -500,
		Max = 500,
		Default = 0,
		Decimals = 1,
		Callback = function(Value)
			TracerModule:UpdateConfig({OffsetX = Value})
		end
	})

	TracerSection:Slider({
		Name = "Offset Y",
		Flag = "TracerOffsetY",
		Min = -500,
		Max = 500,
		Default = 0,
		Decimals = 1,
		Callback = function(Value)
			TracerModule:UpdateConfig({OffsetY = Value})
		end
	})

	TracerSection:Toggle({
		Name = "Alive Only",
		Flag = "TracerAliveOnly",
		Default = true,
		Callback = function(Value)
			TracerModule:UpdateConfig({AliveOnly = Value})
		end
	})

	TracerSection:Toggle({
		Name = "Draw Offscreen",
		Flag = "TracerDrawOffscreen",
		Default = true,
		Callback = function(Value)
			TracerModule:UpdateConfig({DrawOffscreen = Value})
		end
	})

	TracerSection:Label("─ Player Settings ─")

	TracerSection:Toggle({
		Name = "Team Check",
		Flag = "TracerTeamCheck",
		Default = false,
		Callback = function(Value)
			TracerModule:UpdateConfig({EnableTeamCheck = Value})
		end
	})

	TracerSection:Toggle({
		Name = "Enemy Only",
		Flag = "TracerEnemyOnly",
		Default = false,
		Callback = function(Value)
			TracerModule:UpdateConfig({ShowEnemyOnly = Value})
		end
	})

	TracerSection:Toggle({
		Name = "Allied Only",
		Flag = "TracerAlliedOnly",
		Default = false,
		Callback = function(Value)
			TracerModule:UpdateConfig({ShowAlliedOnly = Value})
		end
	})

	TracerSection:Toggle({
		Name = "Use Team Colors",
		Flag = "TracerUseTeamColors",
		Default = false,
		Callback = function(Value)
			TracerModule:UpdateConfig({UseTeamColors = Value})
		end
	})

	TracerSection:Toggle({
		Name = "Use Actual Team Colors",
		Flag = "TracerUseActualTeamColors",
		Default = true,
		Callback = function(Value)
			TracerModule:UpdateConfig({UseActualTeamColors = Value})
		end
	})

	TracerSection:Label("─ Player Colors ─")

	TracerSection:Label("Tracer Color"):Colorpicker({
		Name = "Tracer Color",
		Flag = "TracerTracerColor",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(Value)
			TracerModule:UpdateConfig({TracerColor = Value})
		end
	})

	TracerSection:Label("Enemy Tracer Color"):Colorpicker({
		Name = "Enemy Tracer Color",
		Flag = "TracerEnemyTracerColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			TracerModule:UpdateConfig({EnemyTracerColor = Value})
		end
	})

	TracerSection:Label("Allied Tracer Color"):Colorpicker({
		Name = "Allied Tracer Color",
		Flag = "TracerAlliedTracerColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			TracerModule:UpdateConfig({AlliedTracerColor = Value})
		end
	})

	TracerSection:Label("No Team Color"):Colorpicker({
		Name = "No Team Color",
		Flag = "TracerNoTeamColor",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(Value)
			TracerModule:UpdateConfig({NoTeamColor = Value})
		end
	})

	TracerSection:Label("─ NPC Settings ─")

	TracerSection:Toggle({
		Name = "NPC Tag Filter",
		Flag = "TracerNPCTagFilter",
		Default = true,
		Callback = function(Value)
			TracerModule:UpdateConfig({EnableTagFilter = Value})
		end
	})

	TracerSection:Toggle({
		Name = "Aggressive NPC Detection",
		Flag = "TracerAggressiveNPC",
		Default = false,
		Callback = function(Value)
			TracerModule:UpdateConfig({AggressiveNPCDetection = Value})
		end
	})

	TracerSection:Toggle({
		Name = "Use NPC Colors",
		Flag = "TracerUseNPCColors",
		Default = false,
		Callback = function(Value)
			TracerModule:UpdateConfig({UseNPCColors = Value})
		end
	})

	TracerSection:Label("NPC Tracer Color"):Colorpicker({
		Name = "NPC Tracer Color",
		Flag = "TracerNPCTracerColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			TracerModule:UpdateConfig({NPCTracerColor = Value})
		end
	})

	TracerSection:Label("Boss Tracer Color"):Colorpicker({
		Name = "Boss Tracer Color",
		Flag = "TracerBossTracerColor",
		Default = Color3.fromRGB(255, 165, 0),
		Callback = function(Value)
			TracerModule:UpdateConfig({BossTracerColor = Value})
		end
	})

	TracerSection:Label("─ Info ─")

	TracerSection:Button({
		Name = "Refresh Info",
		Callback = function()
			local mode = TracerModule:GetMode()
			local targets = TracerModule:GetTrackedTargets()
			local config = TracerModule:GetConfig()
			
			print("📊 Tracer Mode: " .. mode .. " | Tracking: " .. #targets .. " target(s)")
			print("✓ Enabled: " .. tostring(config.Enabled))
			print("✓ Tracer Thickness: " .. config.TracerThickness)
			print("✓ Origin: " .. config.Origin .. " | Target: " .. config.Target)
		end
	})
end
