return function(EspPage, BoxModule)
	local BoxSection = EspPage:Section({
		Name = "Box ESP",
		Description = "Highlight targets with boxes",
		Icon = "10709782230",
		Side = 2
	})

	BoxSection:Toggle({
		Name = "Enable Box",
		Flag = "BoxToggle",
		Default = false,
		Callback = function(Value)
			BoxModule:UpdateConfig({Enabled = Value})
			BoxModule:Toggle(Value)
		end
	})

	BoxSection:Dropdown({
		Name = "Box Mode",
		Flag = "BoxMode",
		Default = "Player",
		Items = {"Player", "NPC", "Both"},
		Multi = false,
		Callback = function(Value)
			local selectedMode = type(Value) == "table" and Value[1] or Value
			BoxModule:SetMode(selectedMode)
		end
	})

	BoxSection:Label("─ General Settings ─")

	BoxSection:Slider({
		Name = "Box Thickness",
		Flag = "BoxThickness",
		Min = 0.1,
		Max = 3,
		Default = 0.5,
		Decimals = 0.1,
		Callback = function(Value)
			BoxModule:UpdateConfig({BoxThickness = Value})
			BoxModule.updateAllThickness()
		end
	})

	BoxSection:Toggle({
		Name = "Show Gradient",
		Flag = "BoxShowGradient",
		Default = false,
		Callback = function(Value)
			BoxModule:UpdateConfig({ShowGradient = Value})
		end
	})

	BoxSection:Slider({
		Name = "Gradient Transparency",
		Flag = "BoxGradientTransparency",
		Min = 0,
		Max = 1,
		Default = 0.7,
		Decimals = 0.01,
		Callback = function(Value)
			BoxModule:UpdateConfig({GradientTransparency = Value})
		end
	})

	BoxSection:Slider({
		Name = "Gradient Rotation",
		Flag = "BoxGradientRotation",
		Min = 0,
		Max = 360,
		Default = 90,
		Decimals = 1,
		Callback = function(Value)
			BoxModule:UpdateConfig({GradientRotation = Value})
		end
	})

	BoxSection:Toggle({
		Name = "Enable Gradient Animation",
		Flag = "BoxEnableGradientAnimation",
		Default = false,
		Callback = function(Value)
			BoxModule:UpdateConfig({EnableGradientAnimation = Value})
		end
	})

	BoxSection:Slider({
		Name = "Gradient Animation Speed",
		Flag = "BoxGradientAnimationSpeed",
		Min = 0.1,
		Max = 5,
		Default = 1,
		Decimals = 0.1,
		Callback = function(Value)
			BoxModule:UpdateConfig({GradientAnimationSpeed = Value})
		end
	})

	BoxSection:Label("Gradient Color 1"):Colorpicker({
		Name = "Gradient Color 1",
		Flag = "BoxGradientColor1",
		Default = Color3.fromRGB(255, 86, 0),
		Callback = function(Value)
			BoxModule:UpdateConfig({GradientColor1 = Value})
		end
	})

	BoxSection:Label("Gradient Color 2"):Colorpicker({
		Name = "Gradient Color 2",
		Flag = "BoxGradientColor2",
		Default = Color3.fromRGB(255, 0, 128),
		Callback = function(Value)
			BoxModule:UpdateConfig({GradientColor2 = Value})
		end
	})

	BoxSection:Label("─ Player Settings ─")

	BoxSection:Toggle({
		Name = "Team Check",
		Flag = "BoxTeamCheck",
		Default = false,
		Callback = function(Value)
			BoxModule:UpdateConfig({EnableTeamCheck = Value})
		end
	})

	BoxSection:Toggle({
		Name = "Enemy Only",
		Flag = "BoxEnemyOnly",
		Default = false,
		Callback = function(Value)
			BoxModule:UpdateConfig({ShowEnemyOnly = Value})
		end
	})

	BoxSection:Toggle({
		Name = "Allied Only",
		Flag = "BoxAlliedOnly",
		Default = false,
		Callback = function(Value)
			BoxModule:UpdateConfig({ShowAlliedOnly = Value})
		end
	})

	BoxSection:Toggle({
		Name = "Use Team Colors",
		Flag = "BoxUseTeamColors",
		Default = false,
		Callback = function(Value)
			BoxModule:UpdateConfig({UseTeamColors = Value})
		end
	})

	BoxSection:Toggle({
		Name = "Use Actual Team Colors",
		Flag = "BoxUseActualTeamColors",
		Default = true,
		Callback = function(Value)
			BoxModule:UpdateConfig({UseActualTeamColors = Value})
		end
	})

	BoxSection:Label("─ Player Colors ─")

	BoxSection:Label("Box Color"):Colorpicker({
		Name = "Box Color",
		Flag = "BoxBoxColor",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(Value)
			BoxModule:UpdateConfig({BoxColor = Value})
		end
	})

	BoxSection:Label("Enemy Box Color"):Colorpicker({
		Name = "Enemy Box Color",
		Flag = "BoxEnemyBoxColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			BoxModule:UpdateConfig({EnemyBoxColor = Value})
		end
	})

	BoxSection:Label("Allied Box Color"):Colorpicker({
		Name = "Allied Box Color",
		Flag = "BoxAlliedBoxColor",
		Default = Color3.fromRGB(0, 255, 0),
		Callback = function(Value)
			BoxModule:UpdateConfig({AlliedBoxColor = Value})
		end
	})

	BoxSection:Label("No Team Color"):Colorpicker({
		Name = "No Team Color",
		Flag = "BoxNoTeamColor",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(Value)
			BoxModule:UpdateConfig({NoTeamColor = Value})
		end
	})

	BoxSection:Label("─ NPC Settings ─")

	BoxSection:Toggle({
		Name = "NPC Tag Filter",
		Flag = "BoxNPCTagFilter",
		Default = true,
		Callback = function(Value)
			BoxModule:UpdateConfig({EnableTagFilter = Value})
		end
	})

	BoxSection:Toggle({
		Name = "Aggressive NPC Detection",
		Flag = "BoxAggressiveNPC",
		Default = false,
		Callback = function(Value)
			BoxModule:UpdateConfig({AggressiveNPCDetection = Value})
		end
	})

	BoxSection:Toggle({
		Name = "Use NPC Colors",
		Flag = "BoxUseNPCColors",
		Default = false,
		Callback = function(Value)
			BoxModule:UpdateConfig({UseNPCColors = Value})
		end
	})

	BoxSection:Label("NPC Box Color"):Colorpicker({
		Name = "NPC Box Color",
		Flag = "BoxNPCBoxColor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(Value)
			BoxModule:UpdateConfig({NPCBoxColor = Value})
		end
	})

	BoxSection:Label("Boss Box Color"):Colorpicker({
		Name = "Boss Box Color",
		Flag = "BoxBossBoxColor",
		Default = Color3.fromRGB(255, 165, 0),
		Callback = function(Value)
			BoxModule:UpdateConfig({BossBoxColor = Value})
		end
	})

	BoxSection:Label("─ Info ─")

	BoxSection:Button({
		Name = "Refresh Info",
		Callback = function()
			local mode = BoxModule:GetMode()
			local targets = BoxModule:GetTrackedTargets()
			local config = BoxModule:GetConfig()
			
			print("📊 Box Mode: " .. mode .. " | Tracking: " .. #targets .. " target(s)")
			print("✓ Enabled: " .. tostring(config.Enabled))
			print("✓ Box Thickness: " .. config.BoxThickness)
		end
	})
end
