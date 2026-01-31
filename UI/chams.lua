return function(EspPage, ChamsModule)
	local ChamsSection = EspPage:Section({
		Name = "Chams ESP",
		Description = "Highlight targets through walls",
		Icon = "10734942351",
		Side = 2
	})

	ChamsSection:Toggle({
		Name = "Enable Chams",
		Flag = "ChamsToggle",
		Default = false,
		Callback = function(Value)
			ChamsModule:UpdateConfig({enabled = Value})
			ChamsModule:Toggle(Value)
		end
	})

	ChamsSection:Dropdown({
		Name = "Chams Mode",
		Flag = "ChamsMode",
		Default = "Player",
		Items = {"Player", "NPC", "Both"},
		Multi = false,
		Callback = function(Value)
			local selectedMode = type(Value) == "table" and Value[1] or Value
			ChamsModule:SetMode(selectedMode)
		end
	})

	ChamsSection:Label("─ General Settings ─")

	ChamsSection:Slider({
		Name = "Max Distance",
		Flag = "ChamsMaxDistance",
		Min = 100,
		Max = 10000,
		Default = 10000,
		Decimals = 1,
		Callback = function(Value)
			ChamsModule:UpdateConfig({maxDistance = Value})
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
			ChamsModule:UpdateConfig({fillTransparency = Value})
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
			ChamsModule:UpdateConfig({outlineTransparency = Value})
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
			ChamsModule:UpdateConfig({depthMode = selectedMode})
		end
	})

	ChamsSection:Label("─ Player Settings ─")

	ChamsSection:Toggle({
		Name = "Team Check",
		Flag = "ChamsTeamCheck",
		Default = false,
		Callback = function(Value)
			ChamsModule:UpdateConfig({EnableTeamCheck = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Enemy Only",
		Flag = "ChamsEnemyOnly",
		Default = false,
		Callback = function(Value)
			ChamsModule:UpdateConfig({ShowEnemyOnly = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Allied Only",
		Flag = "ChamsAlliedOnly",
		Default = false,
		Callback = function(Value)
			ChamsModule:UpdateConfig({ShowAlliedOnly = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Use Team Colors",
		Flag = "ChamsUseTeamColors",
		Default = false,
		Callback = function(Value)
			ChamsModule:UpdateConfig({UseTeamColors = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Use Actual Team Colors",
		Flag = "ChamsUseActualTeamColors",
		Default = true,
		Callback = function(Value)
			ChamsModule:UpdateConfig({UseActualTeamColors = Value})
		end
	})

	ChamsSection:Label("─ Default Colors ─")

	ChamsSection:Label("Fill Color"):Colorpicker({
		Name = "Fill Color",
		Flag = "ChamsFillColor",
		Default = Color3.fromRGB(0, 255, 140),
		Callback = function(Value)
			ChamsModule:UpdateConfig({fillColor = Value})
		end
	})

	ChamsSection:Label("Outline Color"):Colorpicker({
		Name = "Outline Color",
		Flag = "ChamsOutlineColor",
		Default = Color3.fromRGB(0, 255, 140),
		Callback = function(Value)
			ChamsModule:UpdateConfig({outlineColor = Value})
		end
	})

	ChamsSection:Label("─ Team Colors ─")

	ChamsSection:Label("Enemy Fill Color"):Colorpicker({
		Name = "Enemy Fill Color",
		Flag = "ChamsEnemyFillColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			ChamsModule:UpdateConfig({EnemyFillColor = Value})
		end
	})

	ChamsSection:Label("Enemy Outline Color"):Colorpicker({
		Name = "Enemy Outline Color",
		Flag = "ChamsEnemyOutlineColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			ChamsModule:UpdateConfig({EnemyOutlineColor = Value})
		end
	})

	ChamsSection:Label("Allied Fill Color"):Colorpicker({
		Name = "Allied Fill Color",
		Flag = "ChamsAlliedFillColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			ChamsModule:UpdateConfig({AlliedFillColor = Value})
		end
	})

	ChamsSection:Label("Allied Outline Color"):Colorpicker({
		Name = "Allied Outline Color",
		Flag = "ChamsAlliedOutlineColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			ChamsModule:UpdateConfig({AlliedOutlineColor = Value})
		end
	})

	ChamsSection:Label("No Team Color"):Colorpicker({
		Name = "No Team Color",
		Flag = "ChamsNoTeamColor",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(Value)
			ChamsModule:UpdateConfig({NoTeamColor = Value})
		end
	})

	ChamsSection:Label("─ Visibility Colors ─")

	ChamsSection:Toggle({
		Name = "Use Visibility Colors",
		Flag = "ChamsUseVisibilityColors",
		Default = false,
		Callback = function(Value)
			ChamsModule:UpdateConfig({useVisibilityColors = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Use Raycasting",
		Flag = "ChamsUseRaycasting",
		Default = false,
		Callback = function(Value)
			ChamsModule:UpdateConfig({useRaycasting = Value})
		end
	})

	ChamsSection:Label("Visible Fill Color"):Colorpicker({
		Name = "Visible Fill Color",
		Flag = "ChamsVisibleFillColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			ChamsModule:UpdateConfig({visibleFillColor = Value})
		end
	})

	ChamsSection:Label("Visible Outline Color"):Colorpicker({
		Name = "Visible Outline Color",
		Flag = "ChamsVisibleOutlineColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			ChamsModule:UpdateConfig({visibleOutlineColor = Value})
		end
	})

	ChamsSection:Label("Hidden Fill Color"):Colorpicker({
		Name = "Hidden Fill Color",
		Flag = "ChamsHiddenFillColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			ChamsModule:UpdateConfig({hiddenFillColor = Value})
		end
	})

	ChamsSection:Label("Hidden Outline Color"):Colorpicker({
		Name = "Hidden Outline Color",
		Flag = "ChamsHiddenOutlineColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			ChamsModule:UpdateConfig({hiddenOutlineColor = Value})
		end
	})

	ChamsSection:Label("─ NPC Settings ─")

	ChamsSection:Toggle({
		Name = "NPC Tag Filter",
		Flag = "ChamsNPCTagFilter",
		Default = true,
		Callback = function(Value)
			ChamsModule:UpdateConfig({EnableTagFilter = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Aggressive NPC Detection",
		Flag = "ChamsAggressiveNPC",
		Default = false,
		Callback = function(Value)
			ChamsModule:UpdateConfig({AggressiveNPCDetection = Value})
		end
	})

	ChamsSection:Toggle({
		Name = "Use NPC Colors",
		Flag = "ChamsUseNPCColors",
		Default = false,
		Callback = function(Value)
			ChamsModule:UpdateConfig({UseNPCColors = Value})
		end
	})

	ChamsSection:Label("NPC Fill Color"):Colorpicker({
		Name = "NPC Fill Color",
		Flag = "ChamsNPCFillColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			ChamsModule:UpdateConfig({NPCFillColor = Value})
		end
	})

	ChamsSection:Label("NPC Outline Color"):Colorpicker({
		Name = "NPC Outline Color",
		Flag = "ChamsNPCOutlineColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			ChamsModule:UpdateConfig({NPCOutlineColor = Value})
		end
	})

	ChamsSection:Label("Boss Fill Color"):Colorpicker({
		Name = "Boss Fill Color",
		Flag = "ChamsBossFillColor",
		Default = Color3.fromRGB(255, 165, 0),
		Callback = function(Value)
			ChamsModule:UpdateConfig({BossFillColor = Value})
		end
	})

	ChamsSection:Label("Boss Outline Color"):Colorpicker({
		Name = "Boss Outline Color",
		Flag = "ChamsBossOutlineColor",
		Default = Color3.fromRGB(255, 165, 0),
		Callback = function(Value)
			ChamsModule:UpdateConfig({BossOutlineColor = Value})
		end
	})

	ChamsSection:Label("─ Performance ─")

	ChamsSection:Slider({
		Name = "Update Interval",
		Flag = "ChamsUpdateInterval",
		Min = 0.01,
		Max = 0.5,
		Default = 0.05,
		Decimals = 0.01,
		Callback = function(Value)
			ChamsModule:UpdateConfig({updateInterval = Value})
		end
	})

	ChamsSection:Slider({
		Name = "Batch Size",
		Flag = "ChamsBatchSize",
		Min = 1,
		Max = 20,
		Default = 5,
		Decimals = 1,
		Callback = function(Value)
			ChamsModule:UpdateConfig({batchSize = Value})
		end
	})

	ChamsSection:Label("─ Info ─")

	ChamsSection:Button({
		Name = "Refresh Info",
		Callback = function()
			local mode = ChamsModule:GetMode()
			local targets = ChamsModule:GetTrackedTargets()
			local config = ChamsModule:GetConfig()
			
			print("📊 Chams Mode: " .. mode .. " | Tracking: " .. #targets .. " target(s)")
			print("✓ Enabled: " .. tostring(config.enabled))
			print("✓ Max Distance: " .. config.maxDistance)
			print("✓ Depth Mode: " .. config.depthMode)
			print("✓ Fill Transparency: " .. config.fillTransparency)
		end
	})
end
