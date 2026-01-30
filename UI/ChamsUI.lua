--=== MODE SELECTION ===--

return function(EspPage, ChamsAPI)
local MainSection = EspPage:Section({
Name = "Chams ESP",
Description = "Làm nổi bật người chơi & NPC qua tường",
Icon = "10709782230",
Side = 2
})

-- Toggle chính cho Player ESP
MainSection:Toggle({
    Name = "Enable Player ESP",
    Flag = "ChamsPlayerEnabled",
    Default = false,
    Callback = function(Value)
        ChamsAPI:Toggle(Value)
    end
})

-- Toggle cho NPC ESP
MainSection:Toggle({
    Name = "Enable NPC ESP",
    Flag = "ChamsNPCEnabled",
    Default = false,
    Callback = function(Value)
        ChamsAPI:ToggleNPC(Value)
    end
})

-- Dropdown chọn Mode
MainSection:Dropdown({
    Name = "Chams Mode",
    Flag = "ChamsMode",
    Default = "Both",
    Items = {"Player", "NPC", "Both"},
    Multi = false,
    Callback = function(Value)
        ChamsAPI:SetMode(Value)
    end
})

-- Dropdown Depth Mode
MainSection:Dropdown({
    Name = "Depth Mode",
    Flag = "ChamsDepthMode",
    Default = "AlwaysOnTop",
    Items = {"AlwaysOnTop", "Occluded"},
    Multi = false,
    Callback = function(Value)
        ChamsAPI:UpdateConfig({depthMode = Value})
    end
})

-- Slider khoảng cách tối đa
MainSection:Slider({
    Name = "Max Distance",
    Flag = "ChamsMaxDistance",
    Min = 100,
    Max = 10000,
    Default = 10000,
    Decimals = 0,
    Suffix = " studs",
    Callback = function(Value)
        ChamsAPI:UpdateConfig({maxDistance = Value})
    end
})

-- =============================================
-- SECTION 2: VISUAL SETTINGS
-- =============================================

local VisualSection = EspPage:Section({
    Name = "Visual Settings",
    Description = "Customize chams appearance",
    Icon = "10709818534",
    Side = 1
})

-- Fill Transparency
VisualSection:Slider({
    Name = "Fill Transparency",
    Flag = "ChamsFillTransparency",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Decimals = 2,
    Suffix = "",
    Callback = function(Value)
        ChamsAPI:UpdateConfig({fillTransparency = Value})
    end
})

-- Outline Transparency
VisualSection:Slider({
    Name = "Outline Transparency",
    Flag = "ChamsOutlineTransparency",
    Min = 0,
    Max = 1,
    Default = 0,
    Decimals = 2,
    Suffix = "",
    Callback = function(Value)
        ChamsAPI:UpdateConfig({outlineTransparency = Value})
    end
})

-- Default Fill Color
VisualSection:Label("Fill Color"):Colorpicker({
    Name = "Fill Color",
    Flag = "ChamsFillColor",
    Default = Color3.fromRGB(0, 255, 140),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({fillColor = Value})
    end
})

-- Default Outline Color
VisualSection:Label("Outline Color"):Colorpicker({
    Name = "Outline Color",
    Flag = "ChamsOutlineColor",
    Default = Color3.fromRGB(0, 255, 140),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({outlineColor = Value})
    end
})

-- =============================================
-- SECTION 3: VISIBILITY COLORS
-- =============================================

local VisibilitySection = EspPage:Section({
    Name = "Visibility Colors",
    Description = "Colors based on line of sight",
    Icon = "10709818534",
    Side = 1
})

-- Toggle Raycast/Visibility
VisibilitySection:Toggle({
    Name = "Use Raycasting",
    Flag = "ChamsUseRaycasting",
    Default = false,
    Callback = function(Value)
        ChamsAPI:UpdateConfig({useRaycasting = Value})
    end
})

-- Toggle Visibility Colors
VisibilitySection:Toggle({
    Name = "Use Visibility Colors",
    Flag = "ChamsUseVisibilityColors",
    Default = false,
    Callback = function(Value)
        ChamsAPI:UpdateConfig({useVisibilityColors = Value})
    end
})

-- Visible Fill Color
VisibilitySection:Label("Visible Fill"):Colorpicker({
    Name = "Visible Fill Color",
    Flag = "ChamsVisibleFillColor",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({visibleFillColor = Value})
    end
})

-- Visible Outline Color
VisibilitySection:Label("Visible Outline"):Colorpicker({
    Name = "Visible Outline Color",
    Flag = "ChamsVisibleOutlineColor",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({visibleOutlineColor = Value})
    end
})

-- Hidden Fill Color
VisibilitySection:Label("Hidden Fill"):Colorpicker({
    Name = "Hidden Fill Color",
    Flag = "ChamsHiddenFillColor",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({hiddenFillColor = Value})
    end
})

-- Hidden Outline Color
VisibilitySection:Label("Hidden Outline"):Colorpicker({
    Name = "Hidden Outline Color",
    Flag = "ChamsHiddenOutlineColor",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({hiddenOutlineColor = Value})
    end
})

-- =============================================
-- SECTION 4: TEAM SETTINGS
-- =============================================

local TeamSection = EspPage:Section({
    Name = "Team Settings",
    Description = "Configure team-based colors",
    Icon = "10709818534",
    Side = 2
})

-- Enable Team Check
TeamSection:Toggle({
    Name = "Enable Team Check",
    Flag = "ChamsEnableTeamCheck",
    Default = false,
    Callback = function(Value)
        ChamsAPI:UpdateConfig({enableTeamCheck = Value})
    end
})

-- Show Enemy Only
TeamSection:Toggle({
    Name = "Show Enemy Only",
    Flag = "ChamsShowEnemyOnly",
    Default = false,
    Callback = function(Value)
        ChamsAPI:UpdateConfig({showEnemyOnly = Value})
    end
})

-- Show Allied Only
TeamSection:Toggle({
    Name = "Show Allied Only",
    Flag = "ChamsShowAlliedOnly",
    Default = false,
    Callback = function(Value)
        ChamsAPI:UpdateConfig({showAlliedOnly = Value})
    end
})

-- Use Team Colors
TeamSection:Toggle({
    Name = "Use Team Colors",
    Flag = "ChamsUseTeamColors",
    Default = false,
    Callback = function(Value)
        ChamsAPI:UpdateConfig({useTeamColors = Value})
    end
})

-- Use Actual Team Colors
TeamSection:Toggle({
    Name = "Use Actual Team Colors",
    Flag = "ChamsUseActualTeamColors",
    Default = true,
    Callback = function(Value)
        ChamsAPI:UpdateConfig({useActualTeamColors = Value})
    end
})

-- Enemy Fill Color
TeamSection:Label("Enemy Fill"):Colorpicker({
    Name = "Enemy Fill Color",
    Flag = "ChamsEnemyFillColor",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({enemyFillColor = Value})
    end
})

-- Enemy Outline Color
TeamSection:Label("Enemy Outline"):Colorpicker({
    Name = "Enemy Outline Color",
    Flag = "ChamsEnemyOutlineColor",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({enemyOutlineColor = Value})
    end
})

-- Allied Fill Color
TeamSection:Label("Allied Fill"):Colorpicker({
    Name = "Allied Fill Color",
    Flag = "ChamsAlliedFillColor",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({alliedFillColor = Value})
    end
})

-- Allied Outline Color
TeamSection:Label("Allied Outline"):Colorpicker({
    Name = "Allied Outline Color",
    Flag = "ChamsAlliedOutlineColor",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({alliedOutlineColor = Value})
    end
})

-- No Team Color
TeamSection:Label("No Team Color"):Colorpicker({
    Name = "No Team Color",
    Flag = "ChamsNoTeamColor",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({noTeamColor = Value})
    end
})

-- =============================================
-- SECTION 5: NPC SETTINGS
-- =============================================

local NPCSection = EspPage:Section({
    Name = "NPC Settings",
    Description = "Configure NPC detection and colors",
    Icon = "10709818534",
    Side = 2
})

-- NPC Max Distance
NPCSection:Slider({
    Name = "NPC Max Distance",
    Flag = "ChamsNPCMaxDistance",
    Min = 100,
    Max = 10000,
    Default = 10000,
    Decimals = 0,
    Suffix = " studs",
    Callback = function(Value)
        ChamsAPI:UpdateConfig({NPCMaxDistance = Value})
    end
})

-- Enable Tag Filter
NPCSection:Toggle({
    Name = "Enable Tag Filter",
    Flag = "ChamsEnableTagFilter",
    Default = true,
    Callback = function(Value)
        ChamsAPI:UpdateConfig({EnableTagFilter = Value})
    end
})

-- Aggressive NPC Detection
NPCSection:Toggle({
    Name = "Aggressive Detection",
    Flag = "ChamsAggressiveNPCDetection",
    Default = false,
    Callback = function(Value)
        ChamsAPI:UpdateConfig({AggressiveNPCDetection = Value})
    end
})

-- Use NPC Colors (Boss vs Standard)
NPCSection:Toggle({
    Name = "Use NPC Type Colors",
    Flag = "ChamsUseNPCColors",
    Default = false,
    Callback = function(Value)
        ChamsAPI:UpdateConfig({UseNPCColors = Value})
    end
})

-- NPC Fill Color
NPCSection:Label("NPC Fill"):Colorpicker({
    Name = "NPC Fill Color",
    Flag = "ChamsNPCFillColor",
    Default = Color3.fromRGB(255, 165, 0),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({NPCFillColor = Value})
    end
})

-- NPC Outline Color
NPCSection:Label("NPC Outline"):Colorpicker({
    Name = "NPC Outline Color",
    Flag = "ChamsNPCOutlineColor",
    Default = Color3.fromRGB(255, 165, 0),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({NPCOutlineColor = Value})
    end
})

-- Standard NPC Color
NPCSection:Label("Standard NPC"):Colorpicker({
    Name = "Standard NPC Color",
    Flag = "ChamsStandardNPCColor",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({StandardNPCColor = Value})
    end
})

-- Boss NPC Color
NPCSection:Label("Boss NPC"):Colorpicker({
    Name = "Boss NPC Color",
    Flag = "ChamsBossNPCColor",
    Default = Color3.fromRGB(255, 165, 0),
    Callback = function(Value)
        ChamsAPI:UpdateConfig({BossNPCColor = Value})
    end
})

-- =============================================
-- SECTION 6: PERFORMANCE SETTINGS
-- =============================================

local PerformanceSection = EspPage:Section({
    Name = "Performance",
    Description = "Optimize ESP performance",
    Icon = "10709818534",
    Side = 2
})

-- Update Interval
PerformanceSection:Slider({
    Name = "Update Interval",
    Flag = "ChamsUpdateInterval",
    Min = 0.01,
    Max = 0.5,
    Default = 0.05,
    Decimals = 2,
    Suffix = "s",
    Callback = function(Value)
        ChamsAPI:UpdateConfig({updateInterval = Value})
    end
})

-- Batch Size
PerformanceSection:Slider({
    Name = "Batch Size",
    Flag = "ChamsBatchSize",
    Min = 1,
    Max = 20,
    Default = 5,
    Decimals = 0,
    Suffix = "",
    Callback = function(Value)
        ChamsAPI:UpdateConfig({batchSize = Value})
    end
})

-- =============================================
-- SECTION 7: INFO & ACTIONS
-- =============================================

local InfoSection = EspPage:Section({
    Name = "Info & Actions",
    Description = "View stats and perform actions",
    Icon = "10709818534",
    Side = 2
})

-- Refresh NPCs Button
InfoSection:Button({
    Name = "Refresh NPCs",
    Callback = function()
        -- Trigger NPC rescan
        ChamsAPI:ToggleNPC(false)
        task.wait(0.1)
        ChamsAPI:ToggleNPC(true)
        print("NPCs Refreshed!")
    end
})

-- Destroy All Chams Button
InfoSection:Button({
    Name = "Destroy All Chams",
    Callback = function()
        ChamsAPI:Destroy()
        print("All Chams Destroyed!")
    end
})

-- Get Tracked Count Button
InfoSection:Button({
    Name = "Print Tracked Count",
    Callback = function()
        local players = ChamsAPI:GetTrackedPlayers()
        local npcs = ChamsAPI:GetTrackedNPCs()
        print("Tracked Players: " .. #players)
        print("Tracked NPCs: " .. #npcs)
    end
})
