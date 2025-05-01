--[[
	AetheriumUI v1.0.0
	A beautiful, modern, and feature-rich Roblox UI library.
	Based on the structure of MacLib by the original author.
	Enhanced by Claude 3.5 Sonnet (Anthropic) based on user request.

	Features:
	- Window system with dragging, sidebar resizing, acrylic/UIBlur options.
	- Tabbed interface with smooth transitions.
	- Comprehensive element set: Buttons, Toggles, Sliders, Inputs, Keybinds, Dropdowns, Colorpickers, Labels, etc.
	- Notification system.
	- Dialog system.
	- Global settings pop-up.
	- Robust configuration saving/loading system.
	- Modern aesthetics with customizable themes.
]]

local AetheriumUI = {
	Options = {}, -- Stores flagged element instances
	Flags = {}, -- Alias for Options for backward compatibility if needed
	Folder = "AetheriumUI", -- Default folder for configs
	Theme = { -- Default Theme Settings (Dark)
		Background = Color3.fromRGB(20, 20, 22), -- Main background
		BackgroundLight = Color3.fromRGB(28, 28, 31), -- Slightly lighter background (e.g., section bg)
		BackgroundLighter = Color3.fromRGB(35, 35, 38), -- Even lighter (e.g., input bg)
		Accent = Color3.fromRGB(80, 120, 255), -- Accent color (can be overridden)
		AccentLight = Color3.fromRGB(100, 140, 255),
		Text = Color3.fromRGB(230, 230, 230), -- Primary text
		TextSecondary = Color3.fromRGB(160, 160, 165), -- Dimmer text (e.g., labels, placeholders)
		TextDisabled = Color3.fromRGB(100, 100, 105), -- Disabled text
		Stroke = Color3.fromRGB(50, 50, 55), -- Border color
		StrokeLight = Color3.fromRGB(70, 70, 75),
		PrimaryInteraction = Color3.fromRGB(45, 45, 50), -- Button backgrounds, etc.
		PrimaryInteractionHover = Color3.fromRGB(60, 60, 65),
		Red = Color3.fromRGB(255, 80, 80),
		Green = Color3.fromRGB(80, 255, 120),
		Yellow = Color3.fromRGB(255, 190, 60),
		Overlay = Color3.fromRGB(0, 0, 0), -- Background overlay (dialogs, colorpicker)

		Font = {
			Regular = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal), -- Inter Regular
			Medium = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal), -- Inter Medium
			SemiBold = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal), -- Inter SemiBold
			Bold = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal), -- Inter Bold
		},

		CornerRadius = UDim.new(0, 8), -- Default rounding
		StrokeThickness = 1,
		StrokeTransparency = 0.5, -- Default stroke transparency (adjusts based on context)
		DisabledTransparency = 0.7,

		AnimationSpeed = 0.15, -- Base speed for tweens
		EasingStyle = Enum.EasingStyle.Quad,
		EasingDirection = Enum.EasingDirection.Out,

		BlurIntensity = 0.15, -- For UIBlur
	},
	Assets = { -- Using original assets, consider updating/replacing
		interFont = "rbxassetid://12187365364", -- Included in Theme.Font now
		userInfoBlurred = "rbxassetid://18824089198",
		toggleBackground = "rbxassetid://18772190202",
		togglerHead = "rbxassetid://18772309008",
		buttonImage = "rbxassetid://10709791437", -- Arrow/Chevron Right
		searchIcon = "rbxassetid://86737463322606",
		colorWheel = "rbxassetid://2849458409",
		colorTarget = "rbxassetid://73265255323268",
		grid = "rbxassetid://121484455191370", -- Transparency Grid
		globe = "rbxassetid://108952102602834", -- Global Settings Icon
		transform = "rbxassetid://90336395745819", -- Move Icon
		dropdown = "rbxassetid://18865373378", -- Dropdown Arrow
		sliderbar = "rbxassetid://18772615246",
		sliderhead = "rbxassetid://18772834246",
		defaultTabIcon = "rbxassetid://18821914323", -- Placeholder if needed
		settingsTabIcon = "rbxassetid://10734950309", -- Placeholder if needed
	},
	_Services = {},
	_Variables = {},
	_Internal = {
		CurrentWindow = nil,
		IsUnloaded = false,
		ActiveTweens = {}, -- To manage and potentially cancel tweens
		Connections = {}, -- To manage event connections
	},
}

-- // Service Getter // --
function AetheriumUI:GetService(serviceName)
	if not self._Services[serviceName] then
		local success, service = pcall(game.GetService, game, serviceName)
		if success then
			self._Services[serviceName] = service
		else
			warn("[AetheriumUI] Failed to get service:", serviceName, "-", service)
			return nil
		end
	end
	return self._Services[serviceName]
end

-- // Services // --
local TweenService = AetheriumUI:GetService("TweenService")
local RunService = AetheriumUI:GetService("RunService")
local HttpService = AetheriumUI:GetService("HttpService")
local ContentProvider = AetheriumUI:GetService("ContentProvider")
local UserInputService = AetheriumUI:GetService("UserInputService")
local Lighting = AetheriumUI:GetService("Lighting")
local Players = AetheriumUI:GetService("Players")
local CoreGui = AetheriumUI:GetService("CoreGui")
local StarterGui = AetheriumUI:GetService("StarterGui") -- For PlayerGui fallback

-- // Variables // --
AetheriumUI._Variables.IsStudio = RunService:IsStudio()
AetheriumUI._Variables.LocalPlayer = Players.LocalPlayer
AetheriumUI._Variables.Mouse = AetheriumUI._Variables.LocalPlayer and AetheriumUI._Variables.LocalPlayer:GetMouse()

-- // Utility Functions // --

-- Enhanced Instance Creation
local function Create(instanceType, properties)
	local instance = Instance.new(instanceType)
	for prop, value in pairs(properties or {}) do
		if prop == "Parent" then
			continue -- Handle parent last if needed, though properties table order isn't guaranteed
		end
		local success, err = pcall(function() instance[prop] = value end)
		if not success then
			warn(("[AetheriumUI] Failed to set property '%s' on %s: %s"):format(tostring(prop), instanceType, err))
		end
	end
	if properties and properties.Parent then
		instance.Parent = properties.Parent
	end
	return instance
end

-- Enhanced Tweening
local function TweenInstance(instance, propertyTable, overrideTweenInfo)
	local info = overrideTweenInfo or TweenInfo.new(
		AetheriumUI.Theme.AnimationSpeed,
		AetheriumUI.Theme.EasingStyle,
		AetheriumUI.Theme.EasingDirection
	)
	local tween = TweenService:Create(instance, info, propertyTable)
	tween:Play()

	-- Track active tweens for potential cleanup/override
	AetheriumUI._Internal.ActiveTweens[instance] = AetheriumUI._Internal.ActiveTweens[instance] or {}
	table.insert(AetheriumUI._Internal.ActiveTweens[instance], tween)
	tween.Completed:Connect(function()
		local list = AetheriumUI._Internal.ActiveTweens[instance]
		if list then
			local index = table.find(list, tween)
			if index then
				table.remove(list, index)
			end
			if #list == 0 then
				AetheriumUI._Internal.ActiveTweens[instance] = nil
			end
		end
	end)

	return tween
end

-- Stop Existing Tweens for an Instance
local function StopTweens(instance)
    if AetheriumUI._Internal.ActiveTweens[instance] then
        for _, tween in ipairs(AetheriumUI._Internal.ActiveTweens[instance]) do
            if tween and tween.PlaybackState ~= Enum.PlaybackState.Completed then
                tween:Cancel()
            end
        end
        AetheriumUI._Internal.ActiveTweens[instance] = nil
    end
end

-- Apply Standard Styling (Example - Extend as needed)
local function ApplyStyling(instance, styleType)
	if not instance then return end

	local theme = AetheriumUI.Theme
	if styleType == "TextLabel" then
		instance.Font = Enum.Font.SourceSans -- Fallback
		instance.TextColor3 = theme.Text
		instance.TextSize = 13
		instance.BackgroundTransparency = 1
		if theme.Font.Regular then instance.FontFace = theme.Font.Regular end
	elseif styleType == "TextButton" then
		instance.Font = Enum.Font.SourceSans
		instance.TextColor3 = theme.Text
		instance.TextSize = 14
		instance.BackgroundColor3 = theme.PrimaryInteraction
		instance.BackgroundTransparency = 0
		if theme.Font.Medium then instance.FontFace = theme.Font.Medium end
	elseif styleType == "Frame" then
		instance.BackgroundColor3 = theme.Background
		instance.BackgroundTransparency = 0
		instance.BorderSizePixel = 0
	elseif styleType == "Input" then
		instance.BackgroundColor3 = theme.BackgroundLighter
		instance.BackgroundTransparency = 0
		instance.TextColor3 = theme.Text
		instance.PlaceholderColor3 = theme.TextSecondary
		instance.TextSize = 12
		if theme.Font.Regular then instance.FontFace = theme.Font.Regular end
		Create("UICorner", { CornerRadius = theme.CornerRadius, Parent = instance })
		Create("UIStroke", { Thickness = theme.StrokeThickness, Color = theme.Stroke, Transparency = theme.StrokeTransparency, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = instance })
	-- Add more style types as needed
	end
end

-- Get Safe GUI Parent
local function GetGuiParent()
	local player = AetheriumUI._Variables.LocalPlayer
	if not player then return CoreGui end -- Fallback for no player

	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if AetheriumUI._Variables.IsStudio and playerGui then
		return playerGui -- Prefer PlayerGui in Studio for easier debugging
	end

	-- Exploit environment checks (keep if needed, but prioritize standard)
	if gethui then
		local success, hui = pcall(gethui)
		if success and hui then return hui end
	end
	if syn and syn.protect_gui then -- Example Synapse check
		local success, protectedGui = pcall(function()
			local pg = Instance.new("ScreenGui")
			syn.protect_gui(pg)
			pg.Name = "AetheriumProtected_" .. HttpService:GenerateGUID(false)
			pg.Parent = CoreGui
			return pg
		end)
		if success and protectedGui then return protectedGui end
	end

	-- Standard environment checks
	return playerGui or CoreGui -- Default to CoreGui if PlayerGui not found
end

-- Create the main ScreenGui
local function GetGui()
	local parent = GetGuiParent()
	local existingGui = parent:FindFirstChild("AetheriumUI_ScreenGui")
	if existingGui and existingGui:IsA("ScreenGui") then
		return existingGui -- Return existing if found
	end

	local newGui = Create("ScreenGui", {
		Name = "AetheriumUI_ScreenGui",
		ScreenInsets = Enum.ScreenInsets.None,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 2147483647, -- Max display order
		Parent = parent
	})
	return newGui
end

-- Manage Connections for Cleanup
local function ManageConnection(connection)
	table.insert(AetheriumUI._Internal.Connections, connection)
end

local function CleanupConnections()
	for _, conn in ipairs(AetheriumUI._Internal.Connections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	AetheriumUI._Internal.Connections = {}
end

local function CleanupTweens()
	for instance, tweens in pairs(AetheriumUI._Internal.ActiveTweens) do
		if tweens then
			for _, tween in ipairs(tweens) do
				if tween and tween.PlaybackState ~= Enum.PlaybackState.Completed then
					tween:Cancel()
				end
			end
		end
	end
	AetheriumUI._Internal.ActiveTweens = {}
end

-- // Main Library Functions // --

function AetheriumUI:Window(Settings)
	if AetheriumUI._Internal.CurrentWindow then
		warn("[AetheriumUI] Warning: Creating a new window while one already exists. The previous window reference might be lost.")
		-- Consider unloading the old one or returning the existing one based on desired behavior.
		-- For now, we allow creating a new one but warn.
	end
	if AetheriumUI._Internal.IsUnloaded then
		warn("[AetheriumUI] Library is unloaded. Cannot create a new window.")
		return nil
	end

	local WindowFunctions = { Settings = Settings }
	local theme = AetheriumUI.Theme -- Use the library's theme

	-- Merge user theme settings with defaults if provided
	if Settings.Theme then
		for k, v in pairs(Settings.Theme) do
			if type(v) == "table" and type(theme[k]) == "table" then
				for sk, sv in pairs(v) do
					theme[k][sk] = sv
				end
			else
				theme[k] = v
			end
		end
	end

	-- Determine Blur Settings
	local blurType = Settings.BlurType or "UIBlur" -- 'UIBlur', 'Acrylic', 'None'
	local useUIBlur = blurType == "UIBlur" and typeof(Instance.new("UIBlur")) == "Instance"
	local useAcrylicBlur = blurType == "Acrylic" and not useUIBlur
	local acrylicBlurEnabled = Settings.AcrylicBlurEnabled -- Specific toggle for acrylic state

	if acrylicBlurEnabled == nil then
		acrylicBlurEnabled = useUIBlur or useAcrylicBlur -- Enable if either blur type is active
	end

	local screenGui = GetGui()
	AetheriumUI._Internal.CurrentWindow = screenGui -- Store reference

	-- Base Container
	local base = Create("Frame", {
		Name = "Base",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = Settings.Position or UDim2.fromScale(0.5, 0.5),
		Size = Settings.Size or UDim2.fromOffset(868, 600),
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = (useUIBlur or useAcrylicBlur) and 0.3 or 0, -- Adjust transparency for blur
		BorderSizePixel = 0,
		ClipsDescendants = true, -- Important for rounded corners
		Parent = screenGui,
		Visible = true, -- Start visible by default
	})
	WindowFunctions.BaseFrame = base -- Expose base frame if needed

	local baseCorner = Create("UICorner", { CornerRadius = theme.CornerRadius, Parent = base })
	local baseStroke = Create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = theme.Stroke,
		Thickness = theme.StrokeThickness,
		Transparency = theme.StrokeTransparency * 0.5, -- Slightly less transparent stroke for main window
		Parent = base
	})
	local baseScale = Create("UIScale", { Name = "BaseScale", Parent = base })

	-- UIBlur Implementation
	local uiBlurEffect = nil
	if useUIBlur then
		uiBlurEffect = Create("UIBlur", {
			Name = "WindowBlur",
			Size = theme.BlurIntensity, -- Use theme setting
			Enabled = acrylicBlurEnabled,
			Parent = base
		})
	end

	-- Acrylic Blur Implementation (Part-based - Keep the original complex logic if needed)
	local acrylicParts = {}
	local acrylicUpdateConnection = nil
	local function UpdateAcrylicBlurState(enabled)
		if useAcrylicBlur then
			acrylicBlurEnabled = enabled
			base.BackgroundTransparency = enabled and 0.3 or 0 -- Adjust as needed
			if not enabled and acrylicUpdateConnection then
				acrylicUpdateConnection:Disconnect()
				acrylicUpdateConnection = nil
				for _, pt in pairs(acrylicParts) do pt.Parent = nil end
				-- Disable DepthOfField if it was created by this script
				local dof = Lighting:FindFirstChild("Aetherium_DepthOfField")
				if dof then dof.Enabled = false end
			elseif enabled and not acrylicUpdateConnection then
				-- Re-initialize or enable the acrylic effect parts and connection
				AetheriumUI:_InitializeAcrylicBlur(base, acrylicParts, theme) -- Pass theme if needed
				if AetheriumUI._Internal.AcrylicUpdateFunction then
					acrylicUpdateConnection = RunService.RenderStepped:Connect(AetheriumUI._Internal.AcrylicUpdateFunction)
					ManageConnection(acrylicUpdateConnection)
					-- Enable DepthOfField
					local dof = Lighting:FindFirstChild("Aetherium_DepthOfField")
					if dof then dof.Enabled = true end
				end
			end
		elseif useUIBlur and uiBlurEffect then
			acrylicBlurEnabled = enabled
			uiBlurEffect.Enabled = enabled
			base.BackgroundTransparency = enabled and 0.3 or 0 -- Adjust transparency for UIBlur too
		else
			acrylicBlurEnabled = false -- No blur enabled
			base.BackgroundTransparency = 0
		end
	end

	if useAcrylicBlur and acrylicBlurEnabled then
		AetheriumUI:_InitializeAcrylicBlur(base, acrylicParts, theme)
		if AetheriumUI._Internal.AcrylicUpdateFunction then
			acrylicUpdateConnection = RunService.RenderStepped:Connect(AetheriumUI._Internal.AcrylicUpdateFunction)
			ManageConnection(acrylicUpdateConnection)
		end
	end

	-- Notifications Container
	local notifications = Create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10, -- Above base
		Parent = screenGui
	})
	local notificationsListLayout = Create("UIListLayout", {
		Name = "NotificationsListLayout",
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = notifications
	})
	local notificationsPadding = Create("UIPadding", {
		Name = "NotificationsPadding",
		PaddingBottom = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = notifications
	})

	-- Sidebar
	local sidebar = Create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0.3, 0, 1, 0), -- Initial size relative to base
		BackgroundColor3 = theme.Background, -- Match base or slightly different
		BackgroundTransparency = 1, -- Let base handle transparency/blur
		BorderSizePixel = 0,
		Parent = base
	})

	-- Sidebar Divider (for resizing)
	local sidebarDivider = Create("Frame", {
		Name = "SidebarDivider",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 1, 1, 0), -- Thin line
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = theme.StrokeTransparency * 0.8,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = sidebar
	})
	local dividerInteract = Create("TextButton", {
		Name = "DividerInteract",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(0, 8, 1, 0), -- Wider interaction area
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 3,
		Parent = sidebarDivider
	})

	-- Content Area
	local content = Create("Frame", {
		Name = "Content",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(1 - sidebar.Size.X.Scale, 0, 1, 0), -- Fill remaining space
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 1, -- Let base handle transparency/blur
		BorderSizePixel = 0,
		Parent = base
	})

	-- Window Controls (Top-Left of Sidebar)
	local windowControls = Create("Frame", {
		Name = "WindowControls",
		Size = UDim2.new(1, 0, 0, 40), -- Increased height for better spacing
		BackgroundTransparency = 1,
		Parent = sidebar
	})
	local controlsContainer = Create("Frame", {
		Name = "ControlsContainer",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = windowControls
	})
	local controlsLayout = Create("UIListLayout", {
		Padding = UDim.new(0, 8),
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = controlsContainer
	})
	local controlsPadding = Create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		Parent = controlsContainer
	})

	-- Control Button Creation Helper
	local function CreateControlButton(name, color, order, onClick)
		local btn = Create("TextButton", {
			Name = name,
			Text = "",
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = color,
			AutoButtonColor = false,
			LayoutOrder = order,
			BorderSizePixel = 0,
			Parent = controlsContainer
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = btn })

		-- Inner Icon/Indicator (Optional, simple example)
		local icon = Create("Frame", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = theme.Background, -- Contrasting color
			BackgroundTransparency = 1, -- Hidden by default
			BorderSizePixel = 0,
			Parent = btn,
			Visible = false -- Manage visibility on hover/state
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = icon })


		ManageConnection(btn.MouseEnter:Connect(function()
			TweenInstance(btn, { BackgroundTransparency = 0.3 })
			icon.BackgroundTransparency = 0.5
			icon.Visible = true
		end))
		ManageConnection(btn.MouseLeave:Connect(function()
			TweenInstance(btn, { BackgroundTransparency = 0 })
			icon.BackgroundTransparency = 1
			icon.Visible = false
		end))
		if onClick then
			ManageConnection(btn.MouseButton1Click:Connect(onClick))
		end
		return btn
	end

	-- Window Control Buttons
	local windowState = true -- Track visibility state
	local menuKeybind = Settings.Keybind or Enum.KeyCode.RightControl

	local function ToggleMenuVisibility()
		windowState = not windowState
		base.Visible = windowState
		-- Optional: Add notification for toggle
		if WindowFunctions.Notify then
			WindowFunctions:Notify({
				Title = Settings.Title or "AetheriumUI",
				Description = (windowState and "Window Shown." or "Window Hidden.") .. " Press " .. menuKeybind.Name .. " to toggle.",
				Lifetime = 3,
				Style = "None"
			})
		end
	end

	local exitButton = CreateControlButton("Exit", theme.Red, 1, function()
		WindowFunctions:Dialog({
			Title = "Confirm Exit",
			Description = "Are you sure you want to unload the UI? Unsaved changes might be lost.",
			Buttons = {
				{ Name = "Unload", Callback = function() AetheriumUI:Unload() end },
				{ Name = "Cancel", Callback = function() print("Exit cancelled") end }
			}
		})
	end)
	local minimizeButton = CreateControlButton("Minimize", theme.Yellow, 2, ToggleMenuVisibility)
	local maximizeButton = CreateControlButton("Maximize", theme.Green, 3, nil) -- No function for maximize yet
	maximizeButton.Visible = false -- Hide maximize for now

	-- Disable specific controls if requested
	if Settings.DisabledWindowControls then
		for _, controlName in ipairs(Settings.DisabledWindowControls) do
			local btn = controlsContainer:FindFirstChild(controlName)
			if btn then btn.Visible = false end
		end
	end

	-- Divider below controls
	Create("Frame", {
		Name = "ControlsDivider",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = theme.StrokeTransparency,
		BorderSizePixel = 0,
		Parent = windowControls
	})

	-- Title/Subtitle Area
	local informationArea = Create("Frame", {
		Name = "InformationArea",
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.fromOffset(0, windowControls.Size.Y.Offset),
		BackgroundTransparency = 1,
		Parent = sidebar
	})
	local infoPadding = Create("UIPadding", {
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		Parent = informationArea
	})
	local infoLayout = Create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = informationArea,
	})

	local titleLabel = Create("TextLabel", {
		Name = "Title",
		Text = Settings.Title or "AetheriumUI",
		FontFace = theme.Font.SemiBold,
		TextColor3 = theme.Text,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -30, 0, 0), -- Leave space for global settings icon
		BackgroundTransparency = 1,
		Parent = informationArea
	})
	local subtitleLabel = Create("TextLabel", {
		Name = "Subtitle",
		Text = Settings.Subtitle or "UI Library",
		FontFace = theme.Font.Regular,
		TextColor3 = theme.TextSecondary,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -30, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = informationArea,
		Visible = (Settings.Subtitle ~= nil and Settings.Subtitle ~= "")
	})
	-- Global Settings Button
	local globalSettingsButton = Create("ImageButton", {
		Name = "GlobalSettingsButton",
		Image = AetheriumUI.Assets.globe,
		ImageColor3 = theme.TextSecondary,
		ImageTransparency = 0.3,
		Size = UDim2.fromOffset(18, 18),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), -- Position relative to infoArea center Y
		BackgroundTransparency = 1,
		Parent = informationArea
	})
	local globalSettingsFrame = nil -- Forward declare

	-- Divider below info
	Create("Frame", {
		Name = "InfoDivider",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = theme.StrokeTransparency,
		BorderSizePixel = 0,
		Parent = informationArea
	})


	-- Main Sidebar Content Area (Tabs + User Info)
	local sidebarContent = Create("Frame", {
		Name = "SidebarContent",
		Size = UDim2.new(1, 0, 1, -(windowControls.Size.Y.Offset + informationArea.Size.Y.Offset)),
		Position = UDim2.fromOffset(0, windowControls.Size.Y.Offset + informationArea.Size.Y.Offset),
		BackgroundTransparency = 1,
		Parent = sidebar
	})

	-- User Info (Bottom of Sidebar)
	local userInfoHeight = 65
	local showUserInfo = Settings.ShowUserInfo == nil or Settings.ShowUserInfo -- Default true
	local userInfo = Create("Frame", {
		Name = "UserInfo",
		Size = UDim2.new(1, 0, 0, userInfoHeight),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		BackgroundTransparency = 1,
		Parent = sidebarContent,
		Visible = showUserInfo
	})
	-- Divider above user info
	Create("Frame", {
		Name = "UserInfoDivider",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(0.9, 0, 0, 1), -- Slightly inset
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = theme.StrokeTransparency,
		BorderSizePixel = 0,
		Parent = userInfo
	})
	local userInfoPadding = Create("UIPadding", {
		PaddingLeft = UDim.new(0, 15),
		PaddingRight = UDim.new(0, 15),
		PaddingTop = UDim.new(0, 15), -- Add padding above divider
		PaddingBottom = UDim.new(0, 15),
		Parent = userInfo
	})
	local userInfoLayout = Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = userInfo
	})

	-- Headshot
	local headshotSize = 36
	local headshotImage = nil
	local isHeadshotReady = false
	if AetheriumUI._Variables.LocalPlayer then
		pcall(function()
			headshotImage, isHeadshotReady = Players:GetUserThumbnailAsync(AetheriumUI._Variables.LocalPlayer.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size48x48)
		end)
	end

	local headshot = Create("ImageLabel", {
		Name = "Headshot",
		Size = UDim2.fromOffset(headshotSize, headshotSize),
		Image = (isHeadshotReady and headshotImage) or AetheriumUI.Assets.userInfoBlurred, -- Fallback or blurred
		BackgroundColor3 = theme.BackgroundLighter,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Parent = userInfo
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = headshot })
	Create("UIStroke", { Color = theme.StrokeLight, Thickness = 1, Transparency = 0.5, Parent = headshot })

	-- Username/Display Name Frame
	local nameFrame = Create("Frame", {
		Name = "NameFrame",
		Size = UDim2.new(1, -(headshotSize + userInfoLayout.Padding.Offset), 1, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = userInfo
	})
	local nameLayout = Create("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = nameFrame
	})
	local displayNameLabel = Create("TextLabel", {
		Name = "DisplayName",
		Text = showUserInfo and (AetheriumUI._Variables.LocalPlayer and AetheriumUI._Variables.LocalPlayer.DisplayName or "DisplayName") or string.rep("•", 10),
		FontFace = theme.Font.Medium,
		TextSize = 14,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Parent = nameFrame
	})
	local usernameLabel = Create("TextLabel", {
		Name = "Username",
		Text = showUserInfo and (AetheriumUI._Variables.LocalPlayer and "@"..AetheriumUI._Variables.LocalPlayer.Name or "@Username") or "@" .. string.rep("•", 8),
		FontFace = theme.Font.Regular,
		TextSize = 12,
		TextColor3 = theme.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = nameFrame
	})

	-- Tab Switcher Area (Above User Info)
	local tabSwitcherArea = Create("Frame", {
		Name = "TabSwitcherArea",
		Size = UDim2.new(1, 0, 1, -userInfoHeight),
		BackgroundTransparency = 1,
		Parent = sidebarContent
	})
	local tabSwitcherScroll = Create("ScrollingFrame", {
		Name = "TabSwitcherScroll",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = theme.StrokeLight,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = tabSwitcherArea
	})
	local tabSwitcherLayout = Create("UIListLayout", {
		Name = "TabSwitcherLayout",
		Padding = UDim.new(0, 5), -- Spacing between tab groups/tabs
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabSwitcherScroll
	})
	local tabSwitcherPadding = Create("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 15),
		PaddingBottom = UDim.new(0, 15),
		Parent = tabSwitcherScroll
	})


	-- Top Bar (Content Area)
	local topbar = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 50), -- Slightly shorter topbar
		BackgroundTransparency = 1,
		Parent = content
	})
	-- Divider below topbar
	Create("Frame", {
		Name = "TopbarDivider",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = theme.StrokeTransparency,
		BorderSizePixel = 0,
		Parent = topbar
	})
	local topbarPadding = Create("UIPadding", {
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		Parent = topbar
	})

	local currentTabLabel = Create("TextLabel", {
		Name = "CurrentTabLabel",
		Text = "...", -- Will be updated when tab is selected
		FontFace = theme.Font.Medium,
		TextSize = 16,
		TextColor3 = theme.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -30, 1, 0), -- Leave space for move icon
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Parent = topbar
	})

	-- Move Icon (Top Right of Content Topbar)
	local useDragIcon = not Settings.DragStyle or Settings.DragStyle == 1
	local moveIcon = Create("ImageButton", {
		Name = "MoveIcon",
		Image = AetheriumUI.Assets.transform,
		ImageColor3 = theme.TextSecondary,
		ImageTransparency = 0.5,
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		BackgroundTransparency = 1,
		Visible = useDragIcon,
		Parent = topbar,
		ZIndex = 2
	})
	local moveInteract = Create("TextButton", { -- Larger interaction area for the icon
		Name = "MoveInteract",
		Size = UDim2.fromOffset(30, 30),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 3,
		Parent = moveIcon
	})
	if useDragIcon then
		ManageConnection(moveInteract.MouseEnter:Connect(function() TweenInstance(moveIcon, { ImageTransparency = 0.2 }) end))
		ManageConnection(moveInteract.MouseLeave:Connect(function() TweenInstance(moveIcon, { ImageTransparency = 0.5 }) end))
	end


	-- Main Content Area (Below Topbar)
	local contentElements = Create("Frame", {
		Name = "ContentElements",
		Size = UDim2.new(1, 0, 1, -topbar.Size.Y.Offset),
		Position = UDim2.fromOffset(0, topbar.Size.Y.Offset),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = content
	})

	-- Global Settings Frame (Initially Hidden)
	globalSettingsFrame = Create("Frame", {
		Name = "GlobalSettings",
		AnchorPoint = Vector2.new(0, 0), -- Adjust anchor as needed
		Position = UDim2.new(0, infoPadding.PaddingLeft.Offset, 0, windowControls.Size.Y.Offset + informationArea.Size.Y.Offset - 5), -- Position near button
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = theme.BackgroundLighter,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 15, -- Above most things
		Parent = base -- Parent to base so it appears over everything
	})
	Create("UICorner", { CornerRadius = theme.CornerRadius, Parent = globalSettingsFrame })
	Create("UIStroke", { Color = theme.StrokeLight, Thickness = 1, Parent = globalSettingsFrame })
	local gsPadding = Create("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		Parent = globalSettingsFrame
	})
	local gsLayout = Create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = globalSettingsFrame
	})
	local gsScale = Create("UIScale", { Name = "GlobalSettingsScale", Scale = 0, Parent = globalSettingsFrame }) -- Start hidden
	local gsOpen = false
	local gsHovering = false
	local hasGlobalSetting = false

	local function ToggleGlobalSettings(forceState)
		if not hasGlobalSetting then return end
		local targetState = forceState
		if targetState == nil then targetState = not gsOpen end

		if targetState ~= gsOpen then
			gsOpen = targetState
			local targetScale = gsOpen and 1 or 0
			local targetTransparency = gsOpen and 0 or 0.5
			local tweenInfo = TweenInfo.new(theme.AnimationSpeed * 1.2, theme.EasingStyle, theme.EasingDirection)

			StopTweens(gsScale) -- Stop any previous scale tweens
			if gsOpen then globalSettingsFrame.Visible = true end -- Make visible before scaling up

			TweenInstance(gsScale, { Scale = targetScale }, tweenInfo).Completed:Connect(function()
				if not gsOpen then globalSettingsFrame.Visible = false end -- Hide after scaling down
			end)
			TweenInstance(globalSettingsButton, { ImageTransparency = targetTransparency })
		end
	end

	ManageConnection(globalSettingsButton.MouseEnter:Connect(function() if not gsOpen then TweenInstance(globalSettingsButton, { ImageTransparency = 0 }) end end))
	ManageConnection(globalSettingsButton.MouseLeave:Connect(function() if not gsOpen then TweenInstance(globalSettingsButton, { ImageTransparency = 0.3 }) end end))
	ManageConnection(globalSettingsButton.MouseButton1Click:Connect(function() ToggleGlobalSettings() end))
	ManageConnection(globalSettingsFrame.MouseEnter:Connect(function() gsHovering = true end))
	ManageConnection(globalSettingsFrame.MouseLeave:Connect(function() gsHovering = false end))
	ManageConnection(UserInputService.InputBegan:Connect(function(input)
		if gsOpen and not gsHovering and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			-- Check if click is outside the global settings frame AND the button
			local mouseLoc = UserInputService:GetMouseLocation()
			local gsRect = Rect.new(globalSettingsFrame.AbsolutePosition, globalSettingsFrame.AbsolutePosition + globalSettingsFrame.AbsoluteSize)
			local btnRect = Rect.new(globalSettingsButton.AbsolutePosition, globalSettingsButton.AbsolutePosition + globalSettingsButton.AbsoluteSize)
			if not gsRect:Contains(mouseLoc) and not btnRect:Contains(mouseLoc) then
				ToggleGlobalSettings(false)
			end
		end
	end))

	-- // Dragging Logic // --
	local dragging = false
	local dragInput, dragStart, startPos
	local dragStyle = Settings.DragStyle or 1 -- 1 = Icon, 2 = Full Window

	local function UpdateDrag(input)
		local delta = input.Position - dragStart
		base.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	local function StartDrag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = base.Position
			local connection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if connection then connection:Disconnect() end -- Clean up connection
				end
			end)
		end
	end

	local dragTarget = (dragStyle == 1 and useDragIcon) and moveInteract or base
	ManageConnection(dragTarget.InputBegan:Connect(StartDrag))
	ManageConnection(UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			UpdateDrag(input)
		end
	end))
	-- InputEnded handled by Changed connection within StartDrag

	-- // Sidebar Resizing Logic // --
	local resizingSidebar = false
	local resizeStartMouseX, resizeStartSidebarWidth
	local minSidebarWidth = 150 -- Minimum width in pixels
	local defaultSidebarScale = sidebar.Size.X.Scale
	local defaultSidebarOffset = sidebar.Size.X.Offset

	ManageConnection(dividerInteract.MouseEnter:Connect(function() TweenInstance(sidebarDivider, { BackgroundTransparency = theme.StrokeTransparency * 0.4 }) end))
	ManageConnection(dividerInteract.MouseLeave:Connect(function() TweenInstance(sidebarDivider, { BackgroundTransparency = theme.StrokeTransparency * 0.8 }) end))

	ManageConnection(dividerInteract.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizingSidebar = true
			resizeStartMouseX = input.Position.X
			resizeStartSidebarWidth = sidebar.AbsoluteSize.X
			-- Change cursor maybe? UserInputService.MouseIconEnabled = false; UserInputService.MouseIcon = "rbxassetid://..."
			local connection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizingSidebar = false
					-- UserInputService.MouseIconEnabled = true;
					if connection then connection:Disconnect() end
				end
			end)
		end
	end))

	ManageConnection(UserInputService.InputChanged:Connect(function(input)
		if resizingSidebar and input.UserInputType == Enum.UserInputType.MouseMovement then
			local currentMouseX = input.Position.X
			local deltaX = currentMouseX - resizeStartMouseX
			local newSidebarWidth = resizeStartSidebarWidth + deltaX
			local maxSidebarWidth = base.AbsoluteSize.X - minSidebarWidth -- Max width

			newSidebarWidth = math.clamp(newSidebarWidth, minSidebarWidth, maxSidebarWidth)

			-- Snap back to default if close enough
			local defaultWidthPixels = defaultSidebarScale * base.AbsoluteSize.X + defaultSidebarOffset
			if math.abs(newSidebarWidth - defaultWidthPixels) < 15 then
				sidebar.Size = UDim2.new(defaultSidebarScale, defaultSidebarOffset, 1, 0)
			else
				sidebar.Size = UDim2.new(0, newSidebarWidth, 1, 0) -- Use offset for resizing
			end

			-- Update content area size based on sidebar's *absolute* size
			content.Size = UDim2.new(0, base.AbsoluteSize.X - sidebar.AbsoluteSize.X, 1, 0)
		end
	end))

	-- Listen for base size changes to potentially readjust content size
	ManageConnection(base:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if not resizingSidebar then -- Avoid conflicts during resize
			content.Size = UDim2.new(0, base.AbsoluteSize.X - sidebar.AbsoluteSize.X, 1, 0)
		end
	end))

	-- // Internal State // --
	local tabs = {} -- { [tabSwitcherButton] = { ContentFrame, NameLabel, IconImage, Stroke } }
	local currentTabInstance = nil
	local tabIndex = 0

	-- // Window Functions // --

	function WindowFunctions:UpdateTitle(newTitle)
		titleLabel.Text = newTitle
	end

	function WindowFunctions:UpdateSubtitle(newSubtitle)
		subtitleLabel.Text = newSubtitle
		subtitleLabel.Visible = (newSubtitle ~= nil and newSubtitle ~= "")
	end

	function WindowFunctions:SetState(state)
		if windowState == state then return end -- No change
		windowState = state
		base.Visible = state
		-- Consider adding an animation here
	end

	function WindowFunctions:GetState()
		return windowState
	end

	function WindowFunctions:SetKeybind(keycode)
		if typeof(keycode) == "EnumItem" and keycode.EnumType == Enum.KeyCode then
			menuKeybind = keycode
		else
			warn("[AetheriumUI] SetKeybind expects an Enum.KeyCode value.")
		end
	end

	function WindowFunctions:SetAcrylicBlurState(enabled)
		UpdateAcrylicBlurState(enabled)
	end

	function WindowFunctions:GetAcrylicBlurState()
		return acrylicBlurEnabled
	end

	function WindowFunctions:SetUserInfoState(enabled)
		showUserInfo = enabled
		userInfo.Visible = enabled
		-- Update text immediately if needed (could be done more cleanly)
		displayNameLabel.Text = showUserInfo and (AetheriumUI._Variables.LocalPlayer and AetheriumUI._Variables.LocalPlayer.DisplayName or "DisplayName") or string.rep("•", 10)
		usernameLabel.Text = showUserInfo and (AetheriumUI._Variables.LocalPlayer and "@"..AetheriumUI._Variables.LocalPlayer.Name or "@Username") or "@" .. string.rep("•", 8)
		headshot.Image = (showUserInfo and isHeadshotReady and headshotImage) or AetheriumUI.Assets.userInfoBlurred
	end

	function WindowFunctions:GetUserInfoState()
		return showUserInfo
	end

	function WindowFunctions:SetSize(newSize)
		if typeof(newSize) == "UDim2" then
			TweenInstance(base, { Size = newSize })
		else
			warn("[AetheriumUI] SetSize expects a UDim2 value.")
		end
	end

	function WindowFunctions:GetSize()
		return base.Size
	end

	function WindowFunctions:SetScale(newScale)
		if type(newScale) == "number" then
			TweenInstance(baseScale, { Scale = newScale })
		else
			warn("[AetheriumUI] SetScale expects a number.")
		end
	end

	function WindowFunctions:GetScale()
		return baseScale.Scale
	end

	function WindowFunctions:SetNotificationsState(enabled)
		notifications.Visible = enabled
	end

	function WindowFunctions:GetNotificationsState()
		return notifications.Visible
	end

	-- Global Setting Element
	function WindowFunctions:GlobalSetting(gsSettings)
		hasGlobalSetting = true -- Mark that at least one global setting exists
		local GlobalSettingFunctions = { Settings = gsSettings }
		local uniqueId = HttpService:GenerateGUID(false)

		local container = Create("Frame", {
			Name = "GlobalSetting_" .. (gsSettings.Name or uniqueId),
			Size = UDim2.new(1, 0, 0, 25), -- Fixed height for consistency
			BackgroundTransparency = 1,
			Parent = globalSettingsFrame
		})

		local layout = Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			Parent = container
		})

		local interactButton = Create("TextButton", { -- Covers the whole area for clicking
			Name = "Interact",
			Size = UDim2.fromScale(1, 1),
			Text = "",
			BackgroundTransparency = 1,
			ZIndex = 2,
			Parent = container
		})

		local checkmarkSize = 12
		local checkmark = Create("TextLabel", {
			Name = "Checkmark",
			Text = "✓",
			FontFace = theme.Font.Bold, -- Bold checkmark
			TextColor3 = theme.Accent,
			TextSize = checkmarkSize,
			TextTransparency = 1, -- Hidden initially
			Size = UDim2.fromOffset(0, checkmarkSize), -- Start collapsed horizontally
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			ClipsDescendants = true, -- Clip text when size is 0
			Parent = container
		})

		local settingName = Create("TextLabel", {
			Name = "SettingName",
			Text = gsSettings.Name or "Setting",
			FontFace = theme.Font.Regular,
			TextSize = 13,
			TextColor3 = theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -(checkmarkSize + layout.Padding.Offset), 1, 0), -- Fill remaining space
			AutomaticSize = Enum.AutomaticSize.X, -- Let it resize horizontally
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Parent = container
		})

		local isToggled = gsSettings.Default or false

		local function SetVisualState(state, noAnim)
			local targetCheckSize = state and UDim2.fromOffset(checkmarkSize, checkmarkSize) or UDim2.fromOffset(0, checkmarkSize)
			local targetCheckTrans = state and 0 or 1
			local targetNameColor = state and theme.Text or theme.TextSecondary
			local animSpeed = noAnim and 0 or theme.AnimationSpeed * 0.8

			StopTweens(checkmark)
			StopTweens(settingName)
			TweenInstance(checkmark, { Size = targetCheckSize, TextTransparency = targetCheckTrans }, TweenInfo.new(animSpeed, theme.EasingStyle, theme.EasingDirection))
			TweenInstance(settingName, { TextColor3 = targetNameColor }, TweenInfo.new(animSpeed, theme.EasingStyle, theme.EasingDirection))
		end

		SetVisualState(isToggled, true) -- Initial state

		ManageConnection(interactButton.MouseButton1Click:Connect(function()
			isToggled = not isToggled
			SetVisualState(isToggled)
			task.spawn(function()
				if gsSettings.Callback then
					gsSettings.Callback(isToggled)
				end
			end)
		end))

		-- Hover Effect
		ManageConnection(interactButton.MouseEnter:Connect(function()
			if not isToggled then TweenInstance(settingName, {TextColor3 = Color3.Lerp(theme.TextSecondary, theme.Text, 0.5)}) end
		end))
		ManageConnection(interactButton.MouseLeave:Connect(function()
			if not isToggled then TweenInstance(settingName, {TextColor3 = theme.TextSecondary}) end
		end))

		function GlobalSettingFunctions:UpdateName(newName)
			settingName.Text = newName
		end

		function GlobalSettingFunctions:UpdateState(newState, noCallback)
			if isToggled == newState then return end
			isToggled = newState
			SetVisualState(isToggled)
			if not noCallback then
				task.spawn(function()
					if gsSettings.Callback then
						gsSettings.Callback(isToggled)
					end
				end)
			end
		end

		function GlobalSettingFunctions:GetState()
			return isToggled
		end

		return GlobalSettingFunctions
	end

	function WindowFunctions:TabGroup(tgSettings)
		local TabGroupFunctions = {}
		tgSettings = tgSettings or {}

		local groupFrame = Create("Frame", {
			Name = "TabGroup_" .. (tgSettings.Name or "Default"),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0), -- Height determined by content
			Parent = tabSwitcherScroll
		})
		local groupLayout = Create("UIListLayout", {
			Padding = UDim.new(0, tgSettings.Padding or 10), -- Padding between group header and tabs
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = groupFrame
		})

		if tgSettings.Name then
			Create("TextLabel", {
				Name = "GroupName",
				Text = tgSettings.Name,
				FontFace = theme.Font.Medium,
				TextColor3 = theme.TextSecondary,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, 15),
				BackgroundTransparency = 1,
				LayoutOrder = -1, -- Appear above tabs in this group
				Parent = groupFrame
			})
			Create("Frame", { -- Divider below header
				Name = "GroupHeaderDivider",
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = theme.Stroke,
				BackgroundTransparency = theme.StrokeTransparency * 1.2,
				LayoutOrder = 0,
				Parent = groupFrame,
				Position = UDim2.fromOffset(0, 5) -- Add space below header text
			})
            groupLayout.Padding = UDim.new(0, 5) -- Reduce padding after divider
		end

		local tabsContainer = Create("Frame", {
			Name = "TabsContainer",
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 1,
			Parent = groupFrame
		})
		local tabsLayout = Create("UIListLayout", {
			Padding = UDim.new(0, 3), -- Padding between tabs
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = tabsContainer
		})

		-- Tab Function (Nested within TabGroup)
		function TabGroupFunctions:Tab(tabSettings)
			local TabFunctions = { Settings = tabSettings }
			tabIndex += 1

			local tabButton = Create("TextButton", {
				Name = "TabSwitcher_" .. (tabSettings.Name or tabIndex),
				Text = "",
				Size = UDim2.new(1, 0, 0, 35), -- Tab height
				BackgroundColor3 = theme.Background,
				BackgroundTransparency = 1, -- Fully transparent until selected/hovered
				AutoButtonColor = false,
				LayoutOrder = tabIndex,
				Parent = tabsContainer
			})
			local tabCorner = Create("UICorner", { CornerRadius = theme.CornerRadius, Parent = tabButton })
			local tabStroke = Create("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.Accent,
				Thickness = theme.StrokeThickness,
				Transparency = 1, -- Hidden until selected
				Parent = tabButton
			})
			local tabLayout = Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = tabButton
			})
			local tabPadding = Create("UIPadding", {
				PaddingLeft = UDim.new(0, 15),
				PaddingRight = UDim.new(0, 15),
				Parent = tabButton
			})

			-- Tab Icon
			local tabIcon = nil
			if tabSettings.Image then
				tabIcon = Create("ImageLabel", {
					Name = "TabIcon",
					Image = tabSettings.Image,
					ImageColor3 = theme.TextSecondary,
					ImageTransparency = 0, -- Control via color alpha if needed or direct tween
					Size = UDim2.fromOffset(18, 18),
					BackgroundTransparency = 1,
					Parent = tabButton
				})
			end

			-- Tab Name
			local tabNameLabel = Create("TextLabel", {
				Name = "TabName",
				Text = tabSettings.Name or "Tab",
				FontFace = theme.Font.Regular,
				TextSize = 14,
				TextColor3 = theme.TextSecondary,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, -( (tabIcon and tabIcon.Size.X.Offset or 0) + tabLayout.Padding.Offset), 1, 0),
				BackgroundTransparency = 1,
				LayoutOrder = tabIcon and 1 or 0,
				Parent = tabButton
			})

			-- Tab Content Frame (Initially parented to nil)
			local tabContentFrame = Create("ScrollingFrame", {
				Name = "TabContent_" .. (tabSettings.Name or tabIndex),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 4,
				ScrollBarImageColor3 = theme.StrokeLight,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ClipsDescendants = false, -- Allow elements like dropdowns to overflow
				Parent = nil -- Parented to contentElements when selected
			})
			local contentPadding = Create("UIPadding", {
				PaddingLeft = UDim.new(0, 15),
				PaddingRight = UDim.new(0, 15),
				PaddingTop = UDim.new(0, 15),
				PaddingBottom = UDim.new(0, 15),
				Parent = tabContentFrame
			})
			local contentLayout = Create("UIListLayout", { -- Main layout: Horizontal for columns
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Padding = UDim.new(0, 15), -- Space between columns
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = tabContentFrame
			})

			-- Columns within the Tab Content
			local leftColumn = Create("Frame", {
				Name = "LeftColumn",
				Size = UDim2.new(0.5, -contentLayout.Padding.Offset / 2, 0, 0), -- Half width minus padding
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Parent = tabContentFrame
			})
			local leftLayout = Create("UIListLayout", {
				Padding = UDim.new(0, 15), -- Space between sections/elements
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = leftColumn
			})

			local rightColumn = Create("Frame", {
				Name = "RightColumn",
				Size = UDim2.new(0.5, -contentLayout.Padding.Offset / 2, 0, 0), -- Half width minus padding
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				Parent = tabContentFrame
			})
			local rightLayout = Create("UIListLayout", {
				Padding = UDim.new(0, 15), -- Space between sections/elements
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = rightColumn
			})

			-- Store tab info
			tabs[tabButton] = {
				ContentFrame = tabContentFrame,
				NameLabel = tabNameLabel,
				IconImage = tabIcon,
				Stroke = tabStroke,
				Corner = tabCorner,
			}

			-- Tab Selection Logic
			local function SelectTab()
				if currentTabInstance == tabContentFrame then return end -- Already selected

				-- Deselect previous tab
				if currentTabInstance then
					currentTabInstance.Parent = nil -- Unparent old content
					for btn, data in pairs(tabs) do
						if data.ContentFrame == currentTabInstance then
							TweenInstance(btn, { BackgroundTransparency = 1 })
							TweenInstance(data.Stroke, { Transparency = 1 })
							TweenInstance(data.NameLabel, { TextColor3 = theme.TextSecondary, FontFace = theme.Font.Regular })
							if data.IconImage then TweenInstance(data.IconImage, { ImageColor3 = theme.TextSecondary }) end
							break
						end
					end
				end

				-- Select this tab
				tabContentFrame.Parent = contentElements -- Parent new content
				currentTabInstance = tabContentFrame
				currentTabLabel.Text = tabSettings.Name or "Tab"

				-- Animate selection visually
				TweenInstance(tabButton, { BackgroundTransparency = 0.85 }) -- Subtle background
				TweenInstance(tabStroke, { Transparency = 0 }) -- Show accent stroke
				TweenInstance(tabNameLabel, { TextColor3 = theme.Text, FontFace = theme.Font.Medium })
				if tabIcon then TweenInstance(tabIcon, { ImageColor3 = theme.Text }) end

			end

			ManageConnection(tabButton.MouseButton1Click:Connect(SelectTab))

			-- Hover Effects
			ManageConnection(tabButton.MouseEnter:Connect(function()
				if currentTabInstance ~= tabContentFrame then -- Don't apply hover if selected
					TweenInstance(tabButton, { BackgroundTransparency = 0.9 })
					TweenInstance(tabNameLabel, { TextColor3 = Color3.Lerp(theme.TextSecondary, theme.Text, 0.7) })
					if tabIcon then TweenInstance(tabIcon, { ImageColor3 = Color3.Lerp(theme.TextSecondary, theme.Text, 0.7) }) end
				end
			end))
			ManageConnection(tabButton.MouseLeave:Connect(function()
				if currentTabInstance ~= tabContentFrame then -- Revert if not selected
					TweenInstance(tabButton, { BackgroundTransparency = 1 })
					TweenInstance(tabNameLabel, { TextColor3 = theme.TextSecondary })
					if tabIcon then TweenInstance(tabIcon, { ImageColor3 = theme.TextSecondary }) end
				end
			end))

			-- Section Function (Nested within Tab)
			function TabFunctions:Section(secSettings)
				local SectionFunctions = {}
				secSettings = secSettings or {}
				local side = secSettings.Side == "Right" and rightColumn or leftColumn -- Default to left

				local sectionFrame = Create("Frame", {
					Name = "Section_" .. (secSettings.Name or HttpService:GenerateGUID(false)),
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = theme.BackgroundLight, -- Use slightly lighter background
					BackgroundTransparency = 0,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					Parent = side
				})
				local secCorner = Create("UICorner", { CornerRadius = theme.CornerRadius, Parent = sectionFrame })
				local secStroke = Create("UIStroke", {
					Color = theme.Stroke,
					Thickness = theme.StrokeThickness,
					Transparency = theme.StrokeTransparency * 0.8,
					Parent = sectionFrame
				})
				local secPadding = Create("UIPadding", {
					PaddingLeft = UDim.new(0, secSettings.PaddingX or 15),
					PaddingRight = UDim.new(0, secSettings.PaddingX or 15),
					PaddingTop = UDim.new(0, secSettings.PaddingY or 15),
					PaddingBottom = UDim.new(0, secSettings.PaddingY or 15),
					Parent = sectionFrame
				})
				local secLayout = Create("UIListLayout", {
					Padding = UDim.new(0, secSettings.Spacing or 10), -- Space between elements
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = sectionFrame
				})

				-- // Element Functions (Nested within Section) // --

				-- Header
				function SectionFunctions:Header(hSettings, flag)
					local HeaderFuncs = { Settings = hSettings, Class = "Header" }
					local text = hSettings.Text or hSettings.Name or "Header"

					local label = Create("TextLabel", {
						Name = flag or "Header_" .. text,
						Text = text,
						FontFace = theme.Font.SemiBold,
						TextColor3 = theme.Text,
						TextSize = 16,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextWrapped = true,
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.new(1, 0, 0, 20),
						BackgroundTransparency = 1,
						Parent = sectionFrame
					})
					Create("UIPadding", { PaddingBottom = UDim.new(0, 5), Parent = label }) -- Add space below header

					function HeaderFuncs:UpdateName(newName) label.Text = newName end
					function HeaderFuncs:SetVisibility(visible) label.Visible = visible end
					if flag then AetheriumUI.Options[flag] = HeaderFuncs end
					return HeaderFuncs
				end

				-- Label
				function SectionFunctions:Label(lSettings, flag)
					local LabelFuncs = { Settings = lSettings, Class = "Label" }
					local text = lSettings.Text or lSettings.Name or "Label"

					local label = Create("TextLabel", {
						Name = flag or "Label_" .. text,
						Text = text,
						RichText = lSettings.RichText or true,
						FontFace = theme.Font.Regular,
						TextColor3 = theme.TextSecondary,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextWrapped = true,
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.new(1, 0, 0, 18),
						BackgroundTransparency = 1,
						Parent = sectionFrame
					})

					function LabelFuncs:UpdateName(newName) label.Text = newName end
					function LabelFuncs:SetVisibility(visible) label.Visible = visible end
					if flag then AetheriumUI.Options[flag] = LabelFuncs end
					return LabelFuncs
				end

				-- SubLabel
				function SectionFunctions:SubLabel(slSettings, flag)
					local SubLabelFuncs = { Settings = slSettings, Class = "SubLabel" }
					local text = slSettings.Text or slSettings.Name or "SubLabel"

					local label = Create("TextLabel", {
						Name = flag or "SubLabel_" .. text,
						Text = text,
						RichText = slSettings.RichText or true,
						FontFace = theme.Font.Regular,
						TextColor3 = Color3.Lerp(theme.TextSecondary, theme.Background, 0.3), -- Even dimmer
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextWrapped = true,
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.new(1, 0, 0, 16),
						BackgroundTransparency = 1,
						Parent = sectionFrame
					})
					-- Reduce padding slightly after a sublabel if needed, or adjust layout padding
					label.LayoutOrder = (sectionFrame.UIListLayout:GetChildren()[#sectionFrame.UIListLayout:GetChildren()-1]?.LayoutOrder or 0) + 1 -- Ensure proper order

					function SubLabelFuncs:UpdateName(newName) label.Text = newName end
					function SubLabelFuncs:SetVisibility(visible) label.Visible = visible end
					if flag then AetheriumUI.Options[flag] = SubLabelFuncs end
					return SubLabelFuncs
				end

				-- Paragraph
				function SectionFunctions:Paragraph(pSettings, flag)
					local ParaFuncs = { Settings = pSettings, Class = "Paragraph" }
					local headerText = pSettings.Header or "Paragraph"
					local bodyText = pSettings.Body or "Paragraph body text."

					local container = Create("Frame", {
						Name = flag or "Paragraph_" .. headerText,
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 0),
						Parent = sectionFrame,
					})
					local layout = Create("UIListLayout", {
						Padding = UDim.new(0, 5),
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = container
					})

					local headerLabel = Create("TextLabel", {
						Name = "Header",
						Text = headerText,
						FontFace = theme.Font.Medium,
						TextColor3 = theme.Text,
						TextSize = 15,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextWrapped = true,
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.new(1, 0, 0, 18),
						BackgroundTransparency = 1,
						Parent = container
					})
					local bodyLabel = Create("TextLabel", {
						Name = "Body",
						Text = bodyText,
						RichText = pSettings.RichText or true,
						FontFace = theme.Font.Regular,
						TextColor3 = theme.TextSecondary,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextWrapped = true,
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.new(1, 0, 0, 16),
						BackgroundTransparency = 1,
						LayoutOrder = 1,
						Parent = container
					})

					function ParaFuncs:UpdateHeader(newText) headerLabel.Text = newText end
					function ParaFuncs:UpdateBody(newText) bodyLabel.Text = newText end
					function ParaFuncs:SetVisibility(visible) container.Visible = visible end
					if flag then AetheriumUI.Options[flag] = ParaFuncs end
					return ParaFuncs
				end

				-- Divider
				function SectionFunctions:Divider()
					local DividerFuncs = {}
					local divider = Create("Frame", {
						Name = "Divider",
						Size = UDim2.new(1, 0, 0, 1),
						BackgroundColor3 = theme.Stroke,
						BackgroundTransparency = theme.StrokeTransparency * 1.1, -- Slightly more transparent
						BorderSizePixel = 0,
						Parent = sectionFrame
					})
					-- Add vertical padding around the divider
					Create("UIPadding", {
						PaddingTop = UDim.new(0, math.floor(secLayout.Padding.Offset / 2)),
						PaddingBottom = UDim.new(0, math.floor(secLayout.Padding.Offset / 2)),
						Parent = divider
					})
					function DividerFuncs:Remove() divider:Destroy() end
					function DividerFuncs:SetVisibility(visible) divider.Visible = visible end
					return DividerFuncs
				end

				-- Spacer
				function SectionFunctions:Spacer(spSettings)
					local SpacerFuncs = {}
					spSettings = spSettings or {}
					local height = spSettings.Height or 10

					local spacer = Create("Frame", {
						Name = "Spacer",
						Size = UDim2.new(1, 0, 0, height),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Parent = sectionFrame
					})
					function SpacerFuncs:Remove() spacer:Destroy() end
					function SpacerFuncs:SetVisibility(visible) spacer.Visible = visible end
					return SpacerFuncs
				end

				-- Button
				function SectionFunctions:Button(bSettings, flag)
					local ButtonFuncs = { Settings = bSettings, Class = "Button" }
					local text = bSettings.Name or "Button"

					local button = Create("TextButton", {
						Name = flag or "Button_" .. text,
						Text = text,
						FontFace = theme.Font.Medium,
						TextColor3 = theme.Text,
						TextSize = 14,
						BackgroundColor3 = theme.PrimaryInteraction,
						Size = UDim2.new(1, 0, 0, 35), -- Button height
						AutoButtonColor = false,
						Parent = sectionFrame
					})
					Create("UICorner", { CornerRadius = theme.CornerRadius, Parent = button })

					-- Optional Icon
					if bSettings.Image then
						button.TextXAlignment = Enum.TextXAlignment.Left -- Align text left if icon exists
						local icon = Create("ImageLabel", {
							Name = "Icon",
							Image = bSettings.Image or AetheriumUI.Assets.buttonImage,
							ImageColor3 = theme.TextSecondary,
							Size = UDim2.fromOffset(16, 16),
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.new(1, -10, 0.5, 0), -- Position right
							BackgroundTransparency = 1,
							Parent = button
						})
						ManageConnection(button.MouseEnter:Connect(function() TweenInstance(icon, { ImageColor3 = theme.Text }) end))
						ManageConnection(button.MouseLeave:Connect(function() TweenInstance(icon, { ImageColor3 = theme.TextSecondary }) end))
					end

					ManageConnection(button.MouseEnter:Connect(function() TweenInstance(button, { BackgroundColor3 = theme.PrimaryInteractionHover }) end))
					ManageConnection(button.MouseLeave:Connect(function() TweenInstance(button, { BackgroundColor3 = theme.PrimaryInteraction }) end))
					ManageConnection(button.MouseButton1Click:Connect(function()
						TweenInstance(button, { BackgroundColor3 = theme.Accent }) -- Click feedback
						TweenInstance(button, { BackgroundColor3 = theme.PrimaryInteractionHover }, TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.1)) -- Return to hover state after delay
						task.spawn(function()
							if bSettings.Callback then bSettings.Callback() end
						end)
					end))

					function ButtonFuncs:UpdateName(newName) button.Text = newName end
					function ButtonFuncs:SetVisibility(visible) button.Visible = visible end
					if flag then AetheriumUI.Options[flag] = ButtonFuncs end
					return ButtonFuncs
				end

				-- Toggle
				function SectionFunctions:Toggle(tSettings, flag)
					local ToggleFuncs = { Settings = tSettings, IgnoreConfig = false, Class = "Toggle", State = tSettings.Default or false }
					local text = tSettings.Name or "Toggle"

					local container = Create("Frame", {
						Name = flag or "Toggle_" .. text,
						Size = UDim2.new(1, 0, 0, 30), -- Consistent height
						BackgroundTransparency = 1,
						Parent = sectionFrame
					})
					local layout = Create("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalAlignment = Enum.HorizontalAlignment.Left, -- Align items left
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = container
					})

					local nameLabel = Create("TextLabel", {
						Name = "ToggleName",
						Text = text,
						FontFace = theme.Font.Regular,
						TextColor3 = theme.Text,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, -55, 1, 0), -- Fill space minus toggle width + padding
						BackgroundTransparency = 1,
						Parent = container
					})

					local toggleWidth, toggleHeight = 40, 20
					local headSize = 16
					local toggleButton = Create("ImageButton", {
						Name = "ToggleSwitch",
						Size = UDim2.fromOffset(toggleWidth, toggleHeight),
						BackgroundColor3 = theme.BackgroundLighter, -- Default off color
						BackgroundTransparency = 0,
						AutoButtonColor = false,
						LayoutOrder = 1, -- Place it after the label
						Image = "", -- Use background color instead of image if desired
						Parent = container
					})
					Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleButton }) -- Pill shape

					local toggleHead = Create("Frame", { -- Use Frame for easier color tweening
						Name = "ToggleHead",
						Size = UDim2.fromOffset(headSize, headSize),
						BackgroundColor3 = theme.TextDisabled, -- Default off color
						BorderSizePixel = 0,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0, headSize / 2 + (toggleHeight - headSize)/2, 0.5, 0), -- Start Left
						Parent = toggleButton,
						ZIndex = 2
					})
					Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleHead })

					local function SetToggleState(state, noAnim)
						ToggleFuncs.State = state
						local animSpeed = noAnim and 0 or theme.AnimationSpeed
						local tweenInfo = TweenInfo.new(animSpeed, theme.EasingStyle, theme.EasingDirection)

						local targetHeadPos = state and UDim2.new(1, -(headSize / 2 + (toggleHeight - headSize)/2), 0.5, 0) or UDim2.new(0, headSize / 2 + (toggleHeight - headSize)/2, 0.5, 0)
						local targetHeadColor = state and theme.Text or theme.TextDisabled
						local targetBgColor = state and theme.Accent or theme.BackgroundLighter

						StopTweens(toggleHead)
						StopTweens(toggleButton)
						TweenInstance(toggleHead, { Position = targetHeadPos, BackgroundColor3 = targetHeadColor }, tweenInfo)
						TweenInstance(toggleButton, { BackgroundColor3 = targetBgColor }, tweenInfo)
					end

					SetToggleState(ToggleFuncs.State, true) -- Initial state

					ManageConnection(toggleButton.MouseButton1Click:Connect(function()
						SetToggleState(not ToggleFuncs.State)
						task.spawn(function()
							if tSettings.Callback then tSettings.Callback(ToggleFuncs.State) end
						end)
					end))

					-- Hover effects (optional, subtle)
					ManageConnection(toggleButton.MouseEnter:Connect(function()
						TweenInstance(toggleHead, { BackgroundTransparency = 0.1 })
					end))
					ManageConnection(toggleButton.MouseLeave:Connect(function()
						TweenInstance(toggleHead, { BackgroundTransparency = 0 })
					end))


					function ToggleFuncs:UpdateState(newState, noCallback)
						if ToggleFuncs.State == newState then return end
						SetToggleState(newState, true) -- Usually update state instantly visually
						if not noCallback then
							task.spawn(function()
								if tSettings.Callback then tSettings.Callback(ToggleFuncs.State) end
							end)
						end
					end
					function ToggleFuncs:GetState() return ToggleFuncs.State end
					function ToggleFuncs:UpdateName(newName) nameLabel.Text = newName end
					function ToggleFuncs:SetVisibility(visible) container.Visible = visible end
					if flag then AetheriumUI.Options[flag] = ToggleFuncs end
					return ToggleFuncs
				end

				-- Slider
				function SectionFunctions:Slider(sSettings, flag)
					local SliderFuncs = { Settings = sSettings, IgnoreConfig = false, Class = "Slider" }
					local text = sSettings.Name or "Slider"
					local minVal, maxVal = sSettings.Minimum or 0, sSettings.Maximum or 100
					local defaultVal = math.clamp(sSettings.Default or minVal, minVal, maxVal)
					local precision = sSettings.Precision or 0
					local displayMethod = sSettings.DisplayMethod or "Value" -- Value, Percent, Degrees etc.
					local prefix = sSettings.Prefix or ""
					local suffix = sSettings.Suffix or ""

					SliderFuncs.Value = defaultVal

					local container = Create("Frame", {
						Name = flag or "Slider_" .. text,
						Size = UDim2.new(1, 0, 0, 45), -- Increased height for better spacing
						BackgroundTransparency = 1,
						Parent = sectionFrame
					})
					local layout = Create("UIListLayout", { -- Vertical layout for name and slider row
						Padding = UDim.new(0, 5),
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = container
					})

					local nameLabel = Create("TextLabel", {
						Name = "SliderName",
						Text = text,
						FontFace = theme.Font.Regular,
						TextColor3 = theme.Text,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, 0, 0, 15),
						BackgroundTransparency = 1,
						Parent = container
					})

					local sliderRow = Create("Frame", { -- Frame for slider bar and value box
						Name = "SliderRow",
						Size = UDim2.new(1, 0, 0, 20),
						BackgroundTransparency = 1,
						LayoutOrder = 1,
						Parent = container
					})
					local rowLayout = Create("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 10),
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = sliderRow
					})

					local valueBoxWidth = 55
					local valueBox = Create("TextBox", {
						Name = "SliderValue",
						Text = "", -- Set later
						FontFace = theme.Font.Regular,
						TextColor3 = theme.Text,
						TextSize = 12,
						PlaceholderColor3 = theme.TextSecondary,
						TextXAlignment = Enum.TextXAlignment.Center,
						BackgroundColor3 = theme.BackgroundLighter,
						ClearTextOnFocus = false,
						Size = UDim2.fromOffset(valueBoxWidth, 20),
						LayoutOrder = 1, -- Place value box last
						Parent = sliderRow
					})
					ApplyStyling(valueBox, "Input") -- Reuse input styling

					local sliderTrack = Create("Frame", { -- The background track
						Name = "SliderTrack",
						Size = UDim2.new(1, -(valueBoxWidth + rowLayout.Padding.Offset), 0, 6), -- Fill remaining space, fixed height
						BackgroundColor3 = theme.BackgroundLighter,
						BackgroundTransparency = 0,
						BorderSizePixel = 0,
						LayoutOrder = 0, -- Place track first
						Parent = sliderRow
					})
					Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderTrack })

					local sliderFill = Create("Frame", { -- The filled part of the track
						Name = "SliderFill",
						Size = UDim2.fromScale(0, 1), -- Width based on value
						BackgroundColor3 = theme.Accent,
						BorderSizePixel = 0,
						Parent = sliderTrack
					})
					Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderFill })

					local sliderHeadSize = 14
					local sliderHead = Create("Frame", {
						Name = "SliderHead",
						Size = UDim2.fromOffset(sliderHeadSize, sliderHeadSize),
						BackgroundColor3 = theme.Text, -- White head
						BorderSizePixel = 0,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0, 0.5), -- Initial position based on value
						Parent = sliderFill, -- Parent to fill for easier positioning
						ZIndex = 2
					})
					Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderHead })
					-- Use TextButton for interaction detection on head
					local headInteract = Create("TextButton", {
						Name = "HeadInteract",
						Size = UDim2.fromScale(1.5, 1.5), -- Larger interaction area
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 3,
						Parent = sliderHead
					})

					-- Value Formatting Logic
					local DisplayMethods = {
						Round = function(val, prec) return string.format("%." .. (prec or 0) .. "f", val) end,
						Percent = function(val, prec)
							local percentage = ((val - minVal) / (maxVal - minVal)) * 100
							return string.format("%." .. (prec or 0) .. "f", percentage) .. "%"
						end,
						Degrees = function(val, prec) return string.format("%." .. (prec or 0) .. "f", val) .. "°" end,
						Value = function(val, prec) return string.format("%." .. (prec or 0) .. "f", val) end,
					}
					local FormatValue = DisplayMethods[displayMethod] or DisplayMethods.Value

					local function UpdateSliderVisuals(value, noAnim)
						local percent = (value - minVal) / (maxVal - minVal)
						percent = math.clamp(percent, 0, 1)
						local targetSize = UDim2.fromScale(percent, 1)
						local animSpeed = noAnim and 0 or theme.AnimationSpeed * 0.5
						local tweenInfo = TweenInfo.new(animSpeed, theme.EasingStyle, theme.EasingDirection)

						StopTweens(sliderFill)
						TweenInstance(sliderFill, { Size = targetSize }, tweenInfo)
						-- Head position updates instantly with fill size change due to parenting

						valueBox.Text = prefix .. FormatValue(value, precision) .. suffix
						SliderFuncs.Value = value
					end

					local function UpdateValueFromInput(inputVal, source) -- source: "drag", "textbox"
						local newValue
						if source == "drag" then
							local mouseX = AetheriumUI._Variables.Mouse.X
							local relativeX = mouseX - sliderTrack.AbsolutePosition.X
							local percent = math.clamp(relativeX / sliderTrack.AbsoluteSize.X, 0, 1)
							newValue = minVal + percent * (maxVal - minVal)
						elseif source == "textbox" then
							local text = valueBox.Text
							-- Attempt to parse number, removing prefix/suffix/symbols potentially added by FormatValue
							local numStr = text:gsub("[%s"..prefix..suffix.."%%°]", "") -- Remove formatting
							newValue = tonumber(numStr)
							if displayMethod == "Percent" and newValue then
								newValue = minVal + (newValue / 100) * (maxVal - minVal)
							end
							if newValue == nil then newValue = SliderFuncs.Value end -- Revert if invalid
						else
							newValue = inputVal -- Direct value set
						end

						newValue = math.clamp(newValue, minVal, maxVal)

						-- Round to step if defined
						if sSettings.Step and sSettings.Step > 0 then
							newValue = math.round(newValue / sSettings.Step) * sSettings.Step
						end

						UpdateSliderVisuals(newValue, source ~= "drag") -- Animate only on textbox/direct set

						-- Trigger callback only if value changed significantly
						local roundedNew = tonumber(string.format("%.".. (precision + 2) .."f", newValue)) -- Avoid floating point issues
						local roundedOld = tonumber(string.format("%.".. (precision + 2) .."f", SliderFuncs.Value))
						if roundedNew ~= roundedOld then
							task.spawn(function()
								if sSettings.Callback then sSettings.Callback(newValue) end
							end)
						end
					end

					UpdateSliderVisuals(defaultVal, true) -- Set initial value

					-- Dragging Logic
					local isDragging = false
					ManageConnection(headInteract.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							isDragging = true
							UpdateValueFromInput(nil, "drag") -- Update immediately on click
							local connection
							connection = input.Changed:Connect(function()
								if input.UserInputState == Enum.UserInputState.End then
									isDragging = false
									task.spawn(function()
										if sSettings.onInputComplete then sSettings.onInputComplete(SliderFuncs.Value) end
									end)
									if connection then connection:Disconnect() end
								end
							end)
						end
					end))
					ManageConnection(UserInputService.InputChanged:Connect(function(input)
						if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							UpdateValueFromInput(nil, "drag")
						end
					end))

					-- TextBox Input Logic
					ManageConnection(valueBox.FocusLost:Connect(function(enterPressed)
						UpdateValueFromInput(nil, "textbox")
						task.spawn(function()
							if sSettings.onInputComplete then sSettings.onInputComplete(SliderFuncs.Value) end
						end)
					end))

					function SliderFuncs:UpdateValue(newValue, noCallback)
						UpdateValueFromInput(newValue, "direct")
						if not noCallback then
							task.spawn(function()
								if sSettings.Callback then sSettings.Callback(SliderFuncs.Value) end
							end)
						end
					end
					function SliderFuncs:GetValue() return SliderFuncs.Value end
					function SliderFuncs:UpdateName(newName) nameLabel.Text = newName end
					function SliderFuncs:SetVisibility(visible) container.Visible = visible end
					if flag then AetheriumUI.Options[flag] = SliderFuncs end
					return SliderFuncs
				end

				-- Input
				function SectionFunctions:Input(iSettings, flag)
					local InputFuncs = { Settings = iSettings, IgnoreConfig = false, Class = "Input", Text = iSettings.Default or "" }
					local text = iSettings.Name or "Input"
					local placeholder = iSettings.Placeholder or "Enter text..."
					local charLimit = iSettings.CharacterLimit
					local clearOnFocus = iSettings.ClearTextOnFocus == nil or iSettings.ClearTextOnFocus

					local container = Create("Frame", {
						Name = flag or "Input_" .. text,
						Size = UDim2.new(1, 0, 0, 55), -- Taller to fit name and box comfortably
						BackgroundTransparency = 1,
						Parent = sectionFrame
					})
					local layout = Create("UIListLayout", {
						Padding = UDim.new(0, 5),
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = container
					})

					local nameLabel = Create("TextLabel", {
						Name = "InputName",
						Text = text,
						FontFace = theme.Font.Regular,
						TextColor3 = theme.Text,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, 0, 0, 15),
						BackgroundTransparency = 1,
						Parent = container
					})

					local inputBox = Create("TextBox", {
						Name = "InputBox",
						Text = InputFuncs.Text,
						PlaceholderText = placeholder,
						ClearTextOnFocus = clearOnFocus,
						MultiLine = iSettings.MultiLine or false,
						TextWrapped = iSettings.MultiLine or false,
						FontFace = theme.Font.Regular,
						TextColor3 = theme.Text,
						TextSize = 13,
						PlaceholderColor3 = theme.TextSecondary,
						BackgroundColor3 = theme.BackgroundLighter,
						Size = UDim2.new(1, 0, 0, iSettings.MultiLine and 60 or 30), -- Taller for multiline
						LayoutOrder = 1,
						TextXAlignment = iSettings.MultiLine and Enum.TextXAlignment.Left or Enum.TextXAlignment.Left,
						TextYAlignment = iSettings.MultiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
						Parent = container
					})
					ApplyStyling(inputBox, "Input") -- Reuse styling
					if iSettings.MultiLine then
						inputBox.Padding = UDim.new(0, 8) -- Add padding for multiline
					else
						Create("UIPadding", {PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), Parent = inputBox})
					end


					-- Character Filtering Logic
					local function FilterText(currentText)
						local filtered = currentText
						if iSettings.AcceptedCharacters == "Numeric" then
							filtered = filtered:gsub("[^%d.,%-]", "") -- Allow digits, dot, comma, minus
							-- More complex validation might be needed for proper number format
						elseif iSettings.AcceptedCharacters == "Alphabetic" then
							filtered = filtered:gsub("[^%a%s]", "") -- Allow letters and spaces
						elseif iSettings.AcceptedCharacters == "AlphaNumeric" then
							filtered = filtered:gsub("[^%w%s]", "") -- Allow letters, numbers, underscore, spaces
						elseif type(iSettings.AcceptedCharacters) == "function" then
							filtered = iSettings.AcceptedCharacters(filtered) -- Custom filter function
						end

						if charLimit and #filtered > charLimit then
							filtered = filtered:sub(1, charLimit)
						end
						return filtered
					end

					ManageConnection(inputBox:GetPropertyChangedSignal("Text"):Connect(function()
						local currentText = inputBox.Text
						local filteredText = FilterText(currentText)
						if currentText ~= filteredText then
							inputBox.Text = filteredText -- Update if filtering changed text
						end
						InputFuncs.Text = filteredText
						task.spawn(function()
							if iSettings.onChanged then iSettings.onChanged(InputFuncs.Text) end
						end)
					end))

					ManageConnection(inputBox.FocusLost:Connect(function(enterPressed)
						-- Final filter pass on focus lost
						local currentText = inputBox.Text
						local filteredText = FilterText(currentText)
						if currentText ~= filteredText then
							inputBox.Text = filteredText
						end
						InputFuncs.Text = filteredText

						task.spawn(function()
							if iSettings.Callback then iSettings.Callback(InputFuncs.Text) end
						end)
					end))

					function InputFuncs:UpdateText(newText, noCallback)
						local filtered = FilterText(tostring(newText))
						inputBox.Text = filtered
						InputFuncs.Text = filtered
						if not noCallback then
							task.spawn(function()
								if iSettings.Callback then iSettings.Callback(InputFuncs.Text) end
							end)
						end
					end
					function InputFuncs:GetInput() return InputFuncs.Text end
					function InputFuncs:UpdatePlaceholder(newPlaceholder) inputBox.PlaceholderText = newPlaceholder end
					function InputFuncs:UpdateName(newName) nameLabel.Text = newName end
					function InputFuncs:SetVisibility(visible) container.Visible = visible end
					if flag then AetheriumUI.Options[flag] = InputFuncs end
					return InputFuncs
				end

				-- Keybind
				function SectionFunctions:Keybind(kSettings, flag)
					local KeybindFuncs = { Settings = kSettings, IgnoreConfig = false, Class = "Keybind", Bind = kSettings.Default or nil } -- Store EnumItem or nil
					local text = kSettings.Name or "Keybind"

					local container = Create("Frame", {
						Name = flag or "Keybind_" .. text,
						Size = UDim2.new(1, 0, 0, 30),
						BackgroundTransparency = 1,
						Parent = sectionFrame
					})
					local layout = Create("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = container
					})

					local nameLabel = Create("TextLabel", {
						Name = "KeybindName",
						Text = text,
						FontFace = theme.Font.Regular,
						TextColor3 = theme.Text,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, -75, 1, 0), -- Fill space minus keybind box width + padding
						BackgroundTransparency = 1,
						Parent = container
					})

					local keybindBoxWidth = 70
					local keybindBox = Create("TextButton", { -- Use TextButton for easy focus/text display
						Name = "KeybindBox",
						Text = KeybindFuncs.Bind and KeybindFuncs.Bind.Name or "...",
						FontFace = theme.Font.Regular,
						TextColor3 = theme.Text,
						TextSize = 12,
						BackgroundColor3 = theme.BackgroundLighter,
						Size = UDim2.fromOffset(keybindBoxWidth, 25),
						AutoButtonColor = false,
						LayoutOrder = 1,
						Parent = container
					})
					ApplyStyling(keybindBox, "Input") -- Reuse input styling

					local isBinding = false
					local currentBind = KeybindFuncs.Bind

					local function UpdateKeybindVisuals(bind)
						currentBind = bind
						KeybindFuncs.Bind = bind
						keybindBox.Text = bind and bind.Name or "..."
						keybindBox.TextColor3 = bind and theme.Text or theme.TextSecondary
					end

					local listeningConnection = nil
					ManageConnection(keybindBox.MouseButton1Click:Connect(function()
						if isBinding then return end -- Don't re-bind if already binding

						isBinding = true
						keybindBox.Text = "..."
						keybindBox.TextColor3 = theme.Accent
						keybindBox.BackgroundColor3 = theme.AccentLight

						-- Start listening for input
						listeningConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
							if gameProcessed and not kSettings.AllowGameProcessed then return end -- Ignore if game processed it unless allowed

							local newBind = nil
							local isValid = false

							if input.UserInputType == Enum.UserInputType.Keyboard then
								newBind = input.KeyCode
								isValid = true
							elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
								newBind = Enum.UserInputType.MouseButton1
								isValid = true
							elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
								newBind = Enum.UserInputType.MouseButton2
								isValid = true
							elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
								newBind = Enum.UserInputType.MouseButton3
								isValid = true -- Allow M3 if needed
							end

							-- Blacklist Check
							if isValid and kSettings.Blacklist then
								local list = kSettings.Blacklist
								if (newBind.EnumType == Enum.KeyCode and table.find(list, newBind)) or
								   (newBind.EnumType == Enum.UserInputType and table.find(list, newBind)) then
									isValid = false
									print("[AetheriumUI] Keybind blacklisted:", newBind.Name)
									-- Optionally provide feedback?
								end
							end

							-- Unbind with Escape
							if input.KeyCode == Enum.KeyCode.Escape then
								isValid = true
								newBind = nil -- Set to nil to unbind
							end

							if isValid then
								isBinding = false
								UpdateKeybindVisuals(newBind)
								keybindBox:ReleaseFocus(false) -- Release focus
								keybindBox.BackgroundColor3 = theme.BackgroundLighter -- Revert style
								if listeningConnection then listeningConnection:Disconnect() end
								listeningConnection = nil

								task.spawn(function()
									if kSettings.onBinded then kSettings.onBinded(newBind) end
								end)
							end
						end)
					end))

					-- Handle focus lost without binding (revert visual state)
					ManageConnection(keybindBox.FocusLost:Connect(function()
						if isBinding then -- If focus is lost while waiting for input
							isBinding = false
							UpdateKeybindVisuals(currentBind) -- Revert to previous bind
							keybindBox.BackgroundColor3 = theme.BackgroundLighter
							if listeningConnection then listeningConnection:Disconnect() end
							listeningConnection = nil
						end
					end))

					-- Keybind Execution Logic
					local keybindPressed = false
					ManageConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
						if isBinding then return end -- Don't trigger while binding
						if gameProcessed and not kSettings.AllowGameProcessed then return end
						if not currentBind then return end

						if (input.KeyCode == currentBind) or (input.UserInputType == currentBind) then
							keybindPressed = true
							task.spawn(function()
								if kSettings.Callback then kSettings.Callback(currentBind) end
								if kSettings.onBindHeld then kSettings.onBindHeld(true, currentBind) end
							end)
						end
					end))
					ManageConnection(UserInputService.InputEnded:Connect(function(input, gameProcessed)
						if isBinding then return end
						if not currentBind then return end
						-- gameProcessed check might not be needed here if we only care about releasing our own key

						if (input.KeyCode == currentBind) or (input.UserInputType == currentBind) then
							if keybindPressed then -- Ensure it was actually pressed down by this handler
								keybindPressed = false
								task.spawn(function()
									if kSettings.onBindHeld then kSettings.onBindHeld(false, currentBind) end
								end)
							end
						end
					end))


					function KeybindFuncs:Bind(key, noCallback)
						if typeof(key) == "EnumItem" and (key.EnumType == Enum.KeyCode or key.EnumType == Enum.UserInputType) then
							UpdateKeybindVisuals(key)
							if not noCallback then task.spawn(function() if kSettings.onBinded then kSettings.onBinded(key) end end)
						elseif key == nil then
							UpdateKeybindVisuals(nil)
							if not noCallback then task.spawn(function() if kSettings.onBinded then kSettings.onBinded(nil) end end)
						else
							warn("[AetheriumUI] Bind function expects an Enum.KeyCode, Enum.UserInputType, or nil.")
						end
					end
					function KeybindFuncs:Unbind(noCallback) KeybindFuncs:Bind(nil, noCallback) end
					function KeybindFuncs:GetBind() return KeybindFuncs.Bind end
					function KeybindFuncs:UpdateName(newName) nameLabel.Text = newName end
					function KeybindFuncs:SetVisibility(visible) container.Visible = visible end
					if flag then AetheriumUI.Options[flag] = KeybindFuncs end
					return KeybindFuncs
				end

				-- Dropdown
				function SectionFunctions:Dropdown(dSettings, flag)
					local DropdownFuncs = { Settings = dSettings, IgnoreConfig = false, Class = "Dropdown" }
					local text = dSettings.Name or "Dropdown"
					local options = dSettings.Options or {} -- Can be array or dictionary { value = display }
					local isMulti = dSettings.Multi or false
					local isRequired = dSettings.Required or false
					local useSearch = dSettings.Search or false

					local selectedValues = {} -- Stores the *actual* values selected
					local displayValues = {} -- Stores the *display* text of selected values

					-- Process initial default selection
					if dSettings.Default then
						local defaults = type(dSettings.Default) == "table" and (isMulti and dSettings.Default or {dSettings.Default[1]}) or {dSettings.Default}
						for _, defVal in ipairs(defaults) do
							local found = false
							if type(options) == "table" and options[1] then -- Array options
								if table.find(options, defVal) then
									table.insert(selectedValues, defVal)
									table.insert(displayValues, defVal)
									found = true
								end
							else -- Dictionary options { value = display }
								for val, disp in pairs(options) do
									if val == defVal then
										table.insert(selectedValues, val)
										table.insert(displayValues, disp)
										found = true
										break
									end
								end
							end
							if not isMulti and found then break end -- Stop after one if not multi
						end
					end
					DropdownFuncs.Value = isMulti and selectedValues or selectedValues[1] -- Set initial Value property

					local container = Create("Frame", {
						Name = flag or "Dropdown_" .. text,
						Size = UDim2.new(1, 0, 0, 35), -- Default height
						BackgroundColor3 = theme.BackgroundLighter,
						BackgroundTransparency = 0,
						ClipsDescendants = false, -- Allow dropdown list to overflow
						Parent = sectionFrame,
						ZIndex = 2 -- Dropdowns need to appear above elements below them
					})
					local containerCorner = Create("UICorner", { CornerRadius = theme.CornerRadius, Parent = container })
					local containerStroke = Create("UIStroke", { Color = theme.Stroke, Thickness = theme.StrokeThickness, Parent = container })

					local mainButton = Create("TextButton", { -- The main interactable part
						Name = "MainButton",
						Text = "",
						Size = UDim2.new(1, 0, 0, 35),
						BackgroundTransparency = 1,
						Parent = container,
						ZIndex = 3
					})
					local mainLayout = Create("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 5),
						Parent = mainButton
					})
					local mainPadding = Create("UIPadding", {
						PaddingLeft = UDim.new(0, 12),
						PaddingRight = UDim.new(0, 10),
						Parent = mainButton
					})

					local dropdownIconSize = 14
					local dropdownIcon = Create("ImageLabel", {
						Name = "DropdownIcon",
						Image = AetheriumUI.Assets.dropdown,
						ImageColor3 = theme.TextSecondary,
						Size = UDim2.fromOffset(dropdownIconSize, dropdownIconSize),
						BackgroundTransparency = 1,
						LayoutOrder = 1, -- Icon on the right
						Parent = mainButton
					})

					local nameLabel = Create("TextLabel", {
						Name = "DropdownName",
						Text = text, -- Update later with selection
						FontFace = theme.Font.Regular,
						TextColor3 = theme.TextSecondary, -- Dimmer when nothing selected
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, -(dropdownIconSize + mainLayout.Padding.Offset + 5), 1, 0), -- Fill remaining space
						BackgroundTransparency = 1,
						Parent = mainButton
					})

					local function UpdateDisplayText()
						if #selectedValues > 0 then
							nameLabel.Text = text .. ": " .. table.concat(displayValues, ", ")
							nameLabel.TextColor3 = theme.Text
						else
							nameLabel.Text = text .. "..."
							nameLabel.TextColor3 = theme.TextSecondary
						end
						-- Truncate if necessary (might need manual truncation logic)
						-- nameLabel.ClipsDescendants = true -- Enable if TextTruncate needed (not reliable)
					end
					UpdateDisplayText()

					-- Dropdown Options Frame
					local optionsHeight = 150 -- Max height before scrolling
					local optionsFrame = Create("Frame", {
						Name = "OptionsFrame",
						Size = UDim2.new(1, 0, 0, 0), -- Starts closed
						Position = UDim2.new(0, 0, 1, 3), -- Position below main button with spacing
						BackgroundColor3 = theme.BackgroundLighter,
						BorderSizePixel = 0,
						ClipsDescendants = true,
						Visible = false, -- Start hidden
						Parent = container,
						ZIndex = 10 -- Above other elements in the section
					})
					local optionsCorner = Create("UICorner", { CornerRadius = theme.CornerRadius, Parent = optionsFrame })
					local optionsStroke = Create("UIStroke", { Color = theme.StrokeLight, Thickness = 1, Parent = optionsFrame })
					local optionsPadding = Create("UIPadding", {
						PaddingTop = UDim.new(0, 5),
						PaddingBottom = UDim.new(0, 5),
						PaddingLeft = UDim.new(0, 5),
						PaddingRight = UDim.new(0, 5),
						Parent = optionsFrame
					})

					-- Search Box (if enabled)
					local searchBox = nil
					if useSearch then
						searchBox = Create("TextBox", {
							Name = "SearchBox",
							Size = UDim2.new(1, -10, 0, 25), -- Full width minus padding
							Position = UDim2.fromOffset(5, 5), -- Positioned via padding essentially
							PlaceholderText = "Search...",
							FontFace = theme.Font.Regular,
							TextSize = 12,
							TextColor3 = theme.Text,
							PlaceholderColor3 = theme.TextSecondary,
							BackgroundColor3 = theme.Background, -- Slightly darker than options bg
							ClearTextOnFocus = true,
							Parent = optionsFrame,
							ZIndex = 12
						})
						ApplyStyling(searchBox, "Input") -- Basic styling
						optionsPadding.PaddingTop = UDim.new(0, 35) -- Adjust padding for search box
					end

					-- Options Scroll Area
					local optionsScroll = Create("ScrollingFrame", {
						Name = "OptionsScroll",
						Size = UDim2.new(1, 0, 1, useSearch and -30 or 0), -- Adjust height if search exists
						Position = UDim2.new(0, 0, 0, useSearch and 30 or 0),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ScrollBarThickness = 4,
						ScrollBarImageColor3 = theme.StrokeLight,
						CanvasSize = UDim2.new(0,0,0,0), -- Auto canvas Y
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						Parent = optionsFrame,
						ZIndex = 11
					})
					local optionsLayout = Create("UIListLayout", {
						Padding = UDim.new(0, 2),
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = optionsScroll
					})

					local optionObjects = {} -- { [value] = { Button, NameLabel, Checkmark?, DisplayText } }

					local function CreateOptionButton(value, displayText)
						local optionButton = Create("TextButton", {
							Name = "Option_" .. tostring(value),
							Text = "",
							Size = UDim2.new(1, 0, 0, 28), -- Option height
							BackgroundColor3 = theme.BackgroundLighter,
							BackgroundTransparency = 1, -- Transparent until hover/selected
							AutoButtonColor = false,
							Parent = optionsScroll
						})
						local optCorner = Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = optionButton }) -- Slightly less round
						local optLayout = Create("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							Padding = UDim.new(0, 8),
							Parent = optionButton
						})
						local optPadding = Create("UIPadding", {
							PaddingLeft = UDim.new(0, 8),
							PaddingRight = UDim.new(0, 8),
							Parent = optionButton
						})

						local checkmark = nil
						if isMulti then
							checkmark = Create("TextLabel", {
								Name = "Checkmark",
								Text = "✓",
								FontFace = theme.Font.Bold,
								TextColor3 = theme.Accent,
								TextSize = 14,
								TextTransparency = 1, -- Hidden until selected
								Size = UDim2.fromOffset(0, 14), -- Collapsed
								TextXAlignment = Enum.TextXAlignment.Center,
								BackgroundTransparency = 1,
								Parent = optionButton,
								ClipsDescendants = true,
							})
						end

						local optNameLabel = Create("TextLabel", {
							Name = "OptionName",
							Text = displayText,
							FontFace = theme.Font.Regular,
							TextSize = 13,
							TextColor3 = theme.TextSecondary, -- Default state
							TextXAlignment = Enum.TextXAlignment.Left,
							Size = UDim2.new(1, -(isMulti and 14 + 8 or 0), 1, 0), -- Fill space
							BackgroundTransparency = 1,
							LayoutOrder = isMulti and 1 or 0,
							Parent = optionButton
						})

						optionObjects[value] = {
							Button = optionButton,
							NameLabel = optNameLabel,
							Checkmark = checkmark,
							DisplayText = displayText,
							Value = value,
						}

						-- Selection Visual Update
						local function SetOptionVisualState(isSelected)
							local targetBgTrans = isSelected and 0.8 or 1
							local targetTextColor = isSelected and theme.Text or theme.TextSecondary
							local targetCheckSize = isSelected and UDim2.fromOffset(14, 14) or UDim2.fromOffset(0, 14)
							local targetCheckTrans = isSelected and 0 or 1

							TweenInstance(optionButton, { BackgroundTransparency = targetBgTrans })
							TweenInstance(optNameLabel, { TextColor3 = targetTextColor })
							if checkmark then
								TweenInstance(checkmark, { Size = targetCheckSize, TextTransparency = targetCheckTrans })
							end
						end

						SetOptionVisualState(table.find(selectedValues, value) ~= nil)

						-- Click Logic
						ManageConnection(optionButton.MouseButton1Click:Connect(function()
							local wasSelected = table.find(selectedValues, value) ~= nil
							local index = table.find(selectedValues, value)

							if isMulti then
								if wasSelected then
									if not isRequired or #selectedValues > 1 then -- Prevent unselecting last if required
										table.remove(selectedValues, index)
										table.remove(displayValues, index) -- Assuming order matches (careful!)
									else return end -- Don't allow change
								else
									table.insert(selectedValues, value)
									table.insert(displayValues, displayText)
								end
								-- Update visuals for this option
								SetOptionVisualState(not wasSelected)
							else
								if wasSelected then
									-- If required, don't allow unselecting the only selected item
									if isRequired and #selectedValues == 1 then return end
									-- If not required, allow unselecting
									selectedValues = {}
									displayValues = {}
									SetOptionVisualState(false) -- Deselect this one
								else
									-- Deselect all others visually
									for _, data in pairs(optionObjects) do
										if data.Value ~= value then
											local otherWasSelected = table.find(selectedValues, data.Value) ~= nil
											if otherWasSelected then
												data.Button.BackgroundTransparency = 1 -- Instantly deselect others
												data.NameLabel.TextColor3 = theme.TextSecondary
											end
										end
									end
									selectedValues = { value } -- Select only this one
									displayValues = { displayText }
									SetOptionVisualState(true) -- Select this one
								end
								-- Close dropdown after selection for single-select
								ToggleDropdown(false)
							end

							DropdownFuncs.Value = isMulti and selectedValues or selectedValues[1] -- Update main Value property
							UpdateDisplayText() -- Update the main button text

							task.spawn(function()
								if dSettings.Callback then
									local cbValue = isMulti and selectedValues or selectedValues[1]
									-- If multi, maybe return a table { val = true } instead?
									if isMulti then
										local multiResult = {}
										for _, v in ipairs(selectedValues) do multiResult[v] = true end
										cbValue = multiResult
									end
									dSettings.Callback(cbValue)
								end
							end)
						end))

						-- Hover Effect
						ManageConnection(optionButton.MouseEnter:Connect(function()
							if not table.find(selectedValues, value) then -- Only if not selected
								TweenInstance(optionButton, { BackgroundTransparency = 0.9 })
							end
						end))
						ManageConnection(optionButton.MouseLeave:Connect(function()
							if not table.find(selectedValues, value) then
								TweenInstance(optionButton, { BackgroundTransparency = 1 })
							end
						end))

					end

					-- Populate Options
					local function PopulateOptions(optionsTable)
						-- Clear existing
						for _, child in ipairs(optionsScroll:GetChildren()) do
							if child:IsA("GuiButton") then child:Destroy() end
						end
						optionObjects = {}

						if type(optionsTable) == "table" and optionsTable[1] then -- Array
							for _, optValue in ipairs(optionsTable) do
								CreateOptionButton(optValue, tostring(optValue))
							end
						else -- Dictionary { value = display }
							for optValue, optDisplay in pairs(optionsTable) do
								CreateOptionButton(optValue, tostring(optDisplay))
							end
						end
						-- Recalculate canvas size? Might happen automatically.
						-- optionsScroll.CanvasSize = UDim2.new(0,0,0, optionsLayout.AbsoluteContentSize.Y)
					end
					PopulateOptions(options) -- Initial population

					-- Search Logic
					if searchBox then
						ManageConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
							local searchTerm = searchBox.Text:lower()
							local visibleCount = 0
							for val, data in pairs(optionObjects) do
								local isVisible = searchTerm == "" or data.DisplayText:lower():find(searchTerm, 1, true)
								data.Button.Visible = isVisible
								if isVisible then visibleCount += 1 end
							end
							-- Adjust scroll canvas size based on visible items? Might be complex/slow.
						end))
					end

					-- Dropdown Open/Close Logic
					local isOpen = false
					local openCloseTween = nil

					function ToggleDropdown(forceState)
						local targetState = forceState
						if targetState == nil then targetState = not isOpen end
						if targetState == isOpen then return end -- No change

						isOpen = targetState

						-- Stop previous animation
						if openCloseTween and openCloseTween.PlaybackState ~= Enum.PlaybackState.Completed then
							openCloseTween:Cancel()
						end

						local targetHeight = 0
						if isOpen then
							optionsFrame.Visible = true
							-- Calculate required height (up to max)
							local contentHeight = optionsLayout.AbsoluteContentSize.Y + optionsPadding.PaddingTop.Offset + optionsPadding.PaddingBottom.Offset
							if useSearch then contentHeight += 30 end -- Add search box height + spacing
							targetHeight = math.min(contentHeight, optionsHeight)
						end

						local targetRotation = isOpen and 180 or 0
						local tweenInfo = TweenInfo.new(theme.AnimationSpeed * 1.5, Enum.EasingStyle.Quint, theme.EasingDirection) -- Slower for dropdown

						openCloseTween = TweenInstance(optionsFrame, { Size = UDim2.new(1, 0, 0, targetHeight) }, tweenInfo)
						TweenInstance(dropdownIcon, { Rotation = targetRotation }, tweenInfo)

						container.ZIndex = isOpen and 5 or 2 -- Bring container to front when open

						if not isOpen then
							openCloseTween.Completed:Connect(function()
								if not isOpen then optionsFrame.Visible = false end -- Hide only after animation completes
							end)
						end
					end

					ManageConnection(mainButton.MouseButton1Click:Connect(function() ToggleDropdown() end))
					-- Close when clicking outside? Add InputBegan check on UserInputService similar to Global Settings.


					-- Dropdown API Functions
					function DropdownFuncs:UpdateSelection(newSelection, noCallback)
						local newSelectedValues = {}
						local newDisplayValues = {}

						local selection = type(newSelection) == "table" and (isMulti and newSelection or {newSelection[1]}) or {newSelection}
						if isMulti and type(newSelection) == "table" and not newSelection[1] then -- Handle {val=true} format
						    selection = {}
						    for k, v in pairs(newSelection) do if v then table.insert(selection, k) end end
						end


						for _, selVal in ipairs(selection) do
							if optionObjects[selVal] then
								table.insert(newSelectedValues, selVal)
								table.insert(newDisplayValues, optionObjects[selVal].DisplayText)
								if not isMulti then break end
							end
						end

						-- Update visuals for all options
						for val, data in pairs(optionObjects) do
							local isSelected = table.find(newSelectedValues, val) ~= nil
							SetOptionVisualState(isSelected)
						end

						selectedValues = newSelectedValues
						displayValues = newDisplayValues
						DropdownFuncs.Value = isMulti and selectedValues or selectedValues[1]
						UpdateDisplayText()

						if not noCallback then
							task.spawn(function()
								if dSettings.Callback then
									local cbValue = DropdownFuncs.Value
									if isMulti then
										local multiResult = {}
										for _, v in ipairs(selectedValues) do multiResult[v] = true end
										cbValue = multiResult
									end
									dSettings.Callback(cbValue)
								end
							end)
						end
					end
					function DropdownFuncs:InsertOptions(newOptions) -- Add options, doesn't clear existing
						if type(newOptions) == "table" then
							PopulateOptions(newOptions) -- For now, this replaces existing. Modify if additive is needed.
						end
					end
					function DropdownFuncs:ClearOptions() PopulateOptions({}) end
					function DropdownFuncs:GetOptions() return optionObjects end -- Returns internal table
					function DropdownFuncs:GetSelection() return DropdownFuncs.Value end
					-- Add RemoveOptions, IsOption if needed, similar to original MacLib
					function DropdownFuncs:UpdateName(newName) text = newName; UpdateDisplayText() end
					function DropdownFuncs:SetVisibility(visible) container.Visible = visible end
					if flag then AetheriumUI.Options[flag] = DropdownFuncs end
					return DropdownFuncs
				end

				-- Colorpicker
				function SectionFunctions:Colorpicker(cSettings, flag)
					local ColorpickerFuncs = { Settings = cSettings, IgnoreConfig = false, Class = "Colorpicker" }
					local text = cSettings.Name or "Colorpicker"
					local defaultColor = cSettings.Default or Color3.new(1, 1, 1)
					local defaultAlpha = cSettings.Alpha -- Number between 0 (opaque) and 1 (transparent)
					local useAlpha = defaultAlpha ~= nil

					ColorpickerFuncs.Color = defaultColor
					ColorpickerFuncs.Alpha = useAlpha and defaultAlpha or 0

					local container = Create("Frame", {
						Name = flag or "Colorpicker_" .. text,
						Size = UDim2.new(1, 0, 0, 30),
						BackgroundTransparency = 1,
						Parent = sectionFrame
					})
					local layout = Create("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = container
					})

					local nameLabel = Create("TextLabel", {
						Name = "ColorpickerName",
						Text = text,
						FontFace = theme.Font.Regular,
						TextColor3 = theme.Text,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, -35, 1, 0), -- Fill space minus color preview width + padding
						BackgroundTransparency = 1,
						Parent = container
					})

					local previewSize = 22
					local colorPreview = Create("Frame", { -- Outer frame for border/corner
						Name = "ColorPreview",
						Size = UDim2.fromOffset(previewSize, previewSize),
						BackgroundColor3 = theme.Stroke, -- Border color
						BackgroundTransparency = 0.5,
						LayoutOrder = 1,
						Parent = container
					})
					Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = colorPreview })

					local checkerboard = Create("ImageLabel", { -- Background checkerboard for alpha
						Name = "Checkerboard",
						Image = AetheriumUI.Assets.grid,
						TileSize = UDim2.fromOffset(8, 8), -- Smaller tiles
						ScaleType = Enum.ScaleType.Tile,
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						ZIndex = 1,
						ImageTransparency = 0.8,
						Parent = colorPreview,
						Visible = useAlpha -- Only show if alpha is used
					})
					Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = checkerboard })

					local colorDisplay = Create("Frame", { -- The actual color
						Name = "ColorDisplay",
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = ColorpickerFuncs.Color,
						BackgroundTransparency = ColorpickerFuncs.Alpha,
						BorderSizePixel = 0,
						ZIndex = 2,
						Parent = colorPreview
					})
					Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = colorDisplay })

					local previewButton = Create("TextButton", { -- Interaction layer
						Name = "PreviewButton",
						Text = "",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						ZIndex = 3,
						Parent = colorPreview
					})

					-- Color Picker Popup Logic (Simplified structure, using CanvasGroup)
					local pickerCanvas = nil -- Lazy load
					local isPickerOpen = false

					local function DestroyPicker()
						if pickerCanvas and pickerCanvas.Parent then
							pickerCanvas:Destroy()
						end
						pickerCanvas = nil
						isPickerOpen = false
					end

					local function CreatePickerPopup()
						DestroyPicker() -- Ensure old one is gone

						pickerCanvas = Create("CanvasGroup", {
							Name = "ColorpickerPopupCanvas",
							Size = UDim2.fromScale(1, 1),
							Position = UDim2.fromScale(0,0),
							BackgroundTransparency = 1,
							GroupTransparency = 1, -- Start hidden
							ZIndex = 100, -- High ZIndex
							Parent = base -- Parent to base to overlay everything
						})

						-- Background Overlay
						local overlay = Create("Frame", {
							Name = "Overlay",
							Size = UDim2.fromScale(1, 1),
							BackgroundColor3 = theme.Overlay,
							BackgroundTransparency = 1, -- Fade in
							ZIndex = 1,
							Parent = pickerCanvas
						})
						local overlayButton = Create("TextButton", { -- Click overlay to close
						    Name = "OverlayButton",
						    Size = UDim2.fromScale(1, 1),
						    BackgroundTransparency = 1,
						    Text = "",
						    ZIndex = 2,
						    Parent = overlay,
						})
						ManageConnection(overlayButton.MouseButton1Click:Connect(function() ClosePickerPopup(true) end)) -- Close on overlay click


						-- Picker Frame
						local pickerFrame = Create("Frame", {
							Name = "PickerFrame",
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromOffset(280, 350), -- Adjusted size
							BackgroundColor3 = theme.BackgroundLight,
							BorderSizePixel = 0,
							Parent = pickerCanvas,
							ZIndex = 3,
							Scale = 0.95 -- Start slightly scaled down
						})
						Create("UICorner", { CornerRadius = theme.CornerRadius, Parent = pickerFrame })
						Create("UIStroke", { Color = theme.StrokeLight, Thickness = 1, Parent = pickerFrame })
						local pickerPadding = Create("UIPadding", {
							Padding = UDim.new(0, 15),
							Parent = pickerFrame
						})
						local pickerLayout = Create("UIListLayout", {
							Padding = UDim.new(0, 10),
							SortOrder = Enum.SortOrder.LayoutOrder,
							Parent = pickerFrame
						})

						-- Title
						Create("TextLabel", {
							Name = "PickerTitle",
							Text = text,
							FontFace = theme.Font.Medium,
							TextColor3 = theme.Text,
							TextSize = 16,
							Size = UDim2.new(1, 0, 0, 20),
							BackgroundTransparency = 1,
							Parent = pickerFrame
						})

						-- Color Wheel / Saturation/Value Box (Using Image for Wheel)
						local wheelSize = 180
						local wheelFrame = Create("Frame", {
							Name = "WheelFrame",
							Size = UDim2.fromOffset(wheelSize, wheelSize),
							BackgroundTransparency = 1,
							Parent = pickerFrame
						})
						local colorWheel = Create("ImageLabel", {
							Name = "ColorWheel",
							Size = UDim2.fromScale(1, 1),
							Image = AetheriumUI.Assets.colorWheel,
							BackgroundTransparency = 1,
							Parent = wheelFrame
						})
						local wheelInteract = Create("ImageButton", { -- Interaction layer for wheel
							Name = "WheelInteract",
							Size = UDim2.fromScale(1, 1),
							Image = "", -- Transparent image / no image
							BackgroundTransparency = 1,
							Parent = colorWheel,
							ZIndex = 2
						})

						local targetSize = 16
						local svTarget = Create("ImageLabel", {
							Name = "SVTarget",
							Image = AetheriumUI.Assets.colorTarget, -- Circle outline
							ImageColor3 = Color3.new(0,0,0), -- Start black or white based on initial color
							Size = UDim2.fromOffset(targetSize, targetSize),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5), -- Start center
							BackgroundTransparency = 1,
							Parent = colorWheel,
							ZIndex = 3
						})

						-- Hue Slider
						local hueSliderFrame = Create("Frame", {
							Name = "HueSliderFrame",
							Size = UDim2.new(1, 0, 0, 15),
							BackgroundTransparency = 1,
							Parent = pickerFrame
						})
						local hueGradient = Create("UIGradient", {
							Color = ColorSequence.new({ -- Rainbow gradient
								ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
								ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
								ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
								ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
								ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
								ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
								ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
							}),
							Rotation = 0,
							Parent = hueSliderFrame
						})
						Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueSliderFrame })
						local hueSliderInteract = Create("TextButton", { -- Interaction layer
							Name = "HueInteract",
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							Text="",
							Parent = hueSliderFrame,
							ZIndex = 2
						})
						local hueHead = Create("Frame", {
							Name = "HueHead",
							Size = UDim2.new(0, 6, 1, 4), -- Thin vertical line, slightly taller
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0, 0.5),
							BackgroundColor3 = Color3.new(1,1,1),
							BorderSizePixel = 1,
							BorderColor3 = Color3.new(0,0,0),
							Parent = hueSliderFrame,
							ZIndex = 3
						})

						-- Alpha Slider (if enabled)
						local alphaSliderFrame, alphaInteract, alphaHead
						if useAlpha then
							alphaSliderFrame = Create("Frame", {
								Name = "AlphaSliderFrame",
								Size = UDim2.new(1, 0, 0, 15),
								BackgroundColor3 = theme.Background, -- Base color for gradient transparency
								Parent = pickerFrame
							})
							Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = alphaSliderFrame })
							local alphaChecker = Create("ImageLabel", { -- Checkerboard background
								Name = "AlphaChecker",
								Image = AetheriumUI.Assets.grid,
								TileSize = UDim2.fromOffset(8, 8),
								ScaleType = Enum.ScaleType.Tile,
								Size = UDim2.fromScale(1, 1),
								BackgroundTransparency = 1,
								ImageTransparency = 0.8,
								Parent = alphaSliderFrame,
								ZIndex = 1
							})
							Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = alphaChecker })
							local alphaGradient = Create("UIGradient", { -- Color to transparent gradient
								Color = ColorSequence.new({
									ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), -- Updated based on hue/sv
									ColorSequenceKeypoint.new(1, Color3.new(1,1,1)) -- Updated based on hue/sv
								}),
								Transparency = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 0), -- Opaque
									NumberSequenceKeypoint.new(1, 1)  -- Transparent
								}),
								Rotation = 0,
								Parent = alphaSliderFrame,
								ZIndex = 2
							})
							alphaInteract = Create("TextButton", {
								Name = "AlphaInteract",
								Size = UDim2.fromScale(1, 1),
								BackgroundTransparency = 1, Text="", Parent = alphaSliderFrame, ZIndex = 3
							})
							alphaHead = Create("Frame", {
								Name = "AlphaHead",
								Size = UDim2.new(0, 6, 1, 4),
								AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
								BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 1, BorderColor3 = Color3.new(0,0,0),
								Parent = alphaSliderFrame, ZIndex = 4
							})
						end

						-- Input Fields (RGB, Hex) in a horizontal layout
						local inputsFrame = Create("Frame", {
							Name = "InputsFrame",
							Size = UDim2.new(1, 0, 0, 30),
							BackgroundTransparency = 1,
							Parent = pickerFrame
						})
						local inputsLayout = Create("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							Padding = UDim.new(0, 5),
							SortOrder = Enum.SortOrder.LayoutOrder,
							Parent = inputsFrame
						})

						local inputFields = {}
						local function CreateInputField(name, width, filterFunc, updateFunc)
							local fieldContainer = Create("Frame", {
								Name = name .. "Field",
								Size = UDim2.new(0, width, 1, 0),
								BackgroundTransparency = 1,
								Parent = inputsFrame
							})
							local fieldLayout = Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = fieldContainer })
							local fieldLabel = Create("TextLabel", {
								Name = "Label", Text = name, FontFace = theme.Font.Regular, TextSize = 10, TextColor3 = theme.TextSecondary,
								Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center, Parent = fieldContainer
							})
							local fieldInput = Create("TextBox", {
								Name = "Input", FontFace = theme.Font.Regular, TextSize = 12, TextColor3 = theme.Text,
								PlaceholderColor3 = theme.TextSecondary, BackgroundColor3 = theme.Background, Size = UDim2.new(1, 0, 0, 18),
								TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, LayoutOrder = 1, Parent = fieldContainer
							})
							ApplyStyling(fieldInput, "Input")

							inputFields[name] = fieldInput
							ManageConnection(fieldInput.FocusLost:Connect(updateFunc))
							ManageConnection(fieldInput:GetPropertyChangedSignal("Text"):Connect(function()
								local current = fieldInput.Text
								local filtered = filterFunc(current)
								if current ~= filtered then fieldInput.Text = filtered end
							end))
							return fieldInput
						end

						local function filterRGB(t) return t:gsub("[^%d]",""):sub(1,3) end
						local function filterHex(t) return "#"..t:gsub("[^%x]",""):upper():sub(1,6) end
						local function filterAlpha(t) return t:gsub("[^%d%.]",""):sub(1,4) end -- Allow dot for alpha

						CreateInputField("R", 35, filterRGB, function() UpdateColor("rgb") end)
						CreateInputField("G", 35, filterRGB, function() UpdateColor("rgb") end)
						CreateInputField("B", 35, filterRGB, function() UpdateColor("rgb") end)
						if useAlpha then
							CreateInputField("A", 40, filterAlpha, function() UpdateColor("alpha") end)
						end
						CreateInputField("Hex", 60, filterHex, function() UpdateColor("hex") end)


						-- Old/New Color Previews
						local previewFrame = Create("Frame", { Name = "PreviewFrame", Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = pickerFrame })
						local previewLayout = Create("UIGridLayout", { CellSize = UDim2.new(0.5, -2.5, 1, 0), CellPadding = UDim.new(0,5,0,0), Parent = previewFrame})
						local oldColorPreview = Create("Frame", { Name = "OldColor", BackgroundColor3 = defaultColor, BackgroundTransparency = useAlpha and defaultAlpha or 0, Parent = previewFrame})
						Create("UICorner", {CornerRadius=UDim.new(0,4), Parent=oldColorPreview})
						Create("ImageLabel", { Name="CheckerOld", Image=AetheriumUI.Assets.grid, TileSize=UDim2.fromOffset(8,8), ScaleType=Enum.ScaleType.Tile, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=1, ImageTransparency=0.8, Parent=oldColorPreview, Visible=useAlpha})
						local newColorPreview = Create("Frame", { Name = "NewColor", BackgroundColor3 = defaultColor, BackgroundTransparency = useAlpha and defaultAlpha or 0, Parent = previewFrame})
						Create("UICorner", {CornerRadius=UDim.new(0,4), Parent=newColorPreview})
						Create("ImageLabel", { Name="CheckerNew", Image=AetheriumUI.Assets.grid, TileSize=UDim2.fromOffset(8,8), ScaleType=Enum.ScaleType.Tile, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=1, ImageTransparency=0.8, Parent=newColorPreview, Visible=useAlpha})


						-- Internal Color State
						local currentHue, currentSat, currentVal = defaultColor:ToHSV()
						local currentAlpha = useAlpha and defaultAlpha or 0

						local function hexToCol3(hex)
							hex = hex:gsub("#","")
							local r = tonumber("0x"..hex:sub(1,2) or "FF") / 255
							local g = tonumber("0x"..hex:sub(3,4) or "FF") / 255
							local b = tonumber("0x"..hex:sub(5,6) or "FF") / 255
							return Color3.new(r, g, b)
						end
						local function col3ToHex(col)
							return string.format("#%02X%02X%02X", math.clamp(math.floor(col.R*255+.5),0,255), math.clamp(math.floor(col.G*255+.5),0,255), math.clamp(math.floor(col.B*255+.5),0,255))
						end

						-- Update Function (Source: "hsv", "rgb", "hex", "alpha")
						local function UpdateColor(source)
							local newColor
							local newAlpha = currentAlpha

							if source == "hsv" then
								newColor = Color3.fromHSV(currentHue, currentSat, currentVal)
							elseif source == "rgb" then
								local r = math.clamp(tonumber(inputFields.R.Text) or 0, 0, 255) / 255
								local g = math.clamp(tonumber(inputFields.G.Text) or 0, 0, 255) / 255
								local b = math.clamp(tonumber(inputFields.B.Text) or 0, 0, 255) / 255
								newColor = Color3.new(r, g, b)
								currentHue, currentSat, currentVal = newColor:ToHSV() -- Update HSV from RGB change
							elseif source == "hex" then
								newColor = hexToCol3(inputFields.Hex.Text)
								currentHue, currentSat, currentVal = newColor:ToHSV() -- Update HSV from Hex change
							elseif source == "alpha" then
								newAlpha = math.clamp(tonumber(inputFields.A.Text) or 0, 0, 1)
								currentAlpha = newAlpha -- Update alpha state
								newColor = Color3.fromHSV(currentHue, currentSat, currentVal) -- Keep current color
							end

							-- Update Visuals
							newColorPreview.BackgroundColor3 = newColor
							newColorPreview.BackgroundTransparency = newAlpha

							-- Update SV Target based on new color
							local targetColor = (currentVal > 0.6 or currentSat < 0.4) and Color3.new(0,0,0) or Color3.new(1,1,1)
							svTarget.ImageColor3 = targetColor

							-- Update Input Fields if source wasn't them
							if source ~= "rgb" and source ~= "hex" then
								inputFields.R.Text = tostring(math.floor(newColor.R*255+.5))
								inputFields.G.Text = tostring(math.floor(newColor.G*255+.5))
								inputFields.B.Text = tostring(math.floor(newColor.B*255+.5))
							end
							if source ~= "hex" then
								inputFields.Hex.Text = col3ToHex(newColor)
							end
							if useAlpha and source ~= "alpha" then
								inputFields.A.Text = string.format("%.2f", currentAlpha) -- Keep alpha field consistent
							end

							-- Update Hue Slider BG Color
							colorWheel.ImageColor3 = Color3.fromHSV(currentHue, 1, 1) -- Set wheel image color (acts as SV box background)

							-- Update Alpha Slider Gradient
							if useAlpha then
								local alphaCol = Color3.fromHSV(currentHue, currentSat, currentVal)
								alphaSliderFrame:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new({
									ColorSequenceKeypoint.new(0, alphaCol),
									ColorSequenceKeypoint.new(1, alphaCol)
								})
							end

							-- Update positions if source was RGB/Hex
							if source == "rgb" or source == "hex" then
								local huePos = UDim2.fromScale(currentHue, 0.5)
								hueHead.Position = huePos

								local wheelRadius = wheelSize / 2
								local angle = currentHue * 2 * math.pi - math.pi / 2 -- Adjust angle based on image orientation
								local dist = currentSat * wheelRadius
								local svX = math.cos(angle) * dist
								local svY = math.sin(angle) * dist
								svTarget.Position = UDim2.new(0.5, svX, 0.5, svY)
							end
							if useAlpha and (source == "rgb" or source == "hex") then
							 	alphaHead.Position = UDim2.fromScale(currentAlpha, 0.5)
							end

							-- Trigger callback in real-time? (Optional)
							-- if cSettings.onChanged then cSettings.onChanged(newColor, newAlpha) end
						end

						-- Initial state update
						local function InitializePickerState()
							currentHue, currentSat, currentVal = ColorpickerFuncs.Color:ToHSV()
							currentAlpha = ColorpickerFuncs.Alpha
							UpdateColor("hsv") -- Initial update based on stored HSV

							-- Set initial slider/target positions
							hueHead.Position = UDim2.fromScale(currentHue, 0.5)
							local wheelRadius = wheelSize / 2
							local angle = currentHue * 2 * math.pi - math.pi / 2
							local dist = currentSat * wheelRadius
							local svX = math.cos(angle) * dist
							local svY = math.sin(angle) * dist
							svTarget.Position = UDim2.new(0.5, svX, 0.5, svY)
							if useAlpha then
								alphaHead.Position = UDim2.fromScale(currentAlpha, 0.5)
							end
						end
						InitializePickerState()

						-- Interaction Logic
						local wheelDragging, hueDragging, alphaDragging = false, false, false

						ManageConnection(wheelInteract.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
								wheelDragging = true
								local mousePos = input.Position - colorWheel.AbsolutePosition
								local center = wheelFrame.AbsoluteSize / 2
								local vec = mousePos - center
								local radius = wheelFrame.AbsoluteSize.X / 2
								local dist = vec.Magnitude
								local angle = math.atan2(vec.Y, vec.X)

								currentHue = (angle / (2 * math.pi) + 0.25) % 1 -- Adjust angle based on image start
								currentSat = math.clamp(dist / radius, 0, 1)

								svTarget.Position = UDim2.new(0.5, math.clamp(vec.X, -radius, radius), 0.5, math.clamp(vec.Y, -radius, radius))
								hueHead.Position = UDim2.fromScale(currentHue, 0.5) -- Update hue head too
								UpdateColor("hsv")
							end
						end))
						ManageConnection(hueSliderInteract.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
								hueDragging = true
								local relativeX = input.Position.X - hueSliderFrame.AbsolutePosition.X
								currentHue = math.clamp(relativeX / hueSliderFrame.AbsoluteSize.X, 0, 1)
								hueHead.Position = UDim2.fromScale(currentHue, 0.5)
								UpdateColor("hsv")
							end
						end))
						if useAlpha then
							ManageConnection(alphaInteract.InputBegan:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
									alphaDragging = true
									local relativeX = input.Position.X - alphaSliderFrame.AbsolutePosition.X
									currentAlpha = math.clamp(relativeX / alphaSliderFrame.AbsoluteSize.X, 0, 1)
									alphaHead.Position = UDim2.fromScale(currentAlpha, 0.5)
									UpdateColor("alpha")
								end
							end))
						end

						ManageConnection(UserInputService.InputChanged:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
								if wheelDragging then
									local mousePos = input.Position - colorWheel.AbsolutePosition
									local center = wheelFrame.AbsoluteSize / 2
									local vec = mousePos - center
									local radius = wheelFrame.AbsoluteSize.X / 2
									local dist = vec.Magnitude
									local angle = math.atan2(vec.Y, vec.X)

									currentHue = (angle / (2 * math.pi) + 0.25) % 1
									currentSat = math.clamp(dist / radius, 0, 1)

									svTarget.Position = UDim2.new(0.5, math.clamp(vec.X, -radius, radius), 0.5, math.clamp(vec.Y, -radius, radius))
									hueHead.Position = UDim2.fromScale(currentHue, 0.5)
									UpdateColor("hsv")
								elseif hueDragging then
									local relativeX = input.Position.X - hueSliderFrame.AbsolutePosition.X
									currentHue = math.clamp(relativeX / hueSliderFrame.AbsoluteSize.X, 0, 1)
									hueHead.Position = UDim2.fromScale(currentHue, 0.5)
									UpdateColor("hsv")
								elseif alphaDragging then
									local relativeX = input.Position.X - alphaSliderFrame.AbsolutePosition.X
									currentAlpha = math.clamp(relativeX / alphaSliderFrame.AbsoluteSize.X, 0, 1)
									alphaHead.Position = UDim2.fromScale(currentAlpha, 0.5)
									UpdateColor("alpha")
								end
							end
						end))

						local function endDrag(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
								wheelDragging, hueDragging, alphaDragging = false, false, false
							end
						end
						ManageConnection(UserInputService.InputEnded:Connect(endDrag))


						-- Confirm/Cancel Buttons
						local buttonsFrame = Create("Frame", {Name="Buttons", Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Parent=pickerFrame})
						local buttonsLayout = Create("UIGridLayout", {CellSize=UDim2.new(0.5,-2.5,1,0), CellPadding=UDim.new(0,5,0,0), Parent=buttonsFrame})

						local confirmButton = Create("TextButton", {Name="Confirm", Text="Confirm", FontFace=theme.Font.Medium, TextColor3=theme.Text, BackgroundColor3=theme.Accent, Size=UDim2.fromScale(1,1), AutoButtonColor=false, Parent=buttonsFrame})
						Create("UICorner",{CornerRadius=theme.CornerRadius,Parent=confirmButton})
						ManageConnection(confirmButton.MouseButton1Click:Connect(function() ClosePickerPopup(false) end)) -- Close and save

						local cancelButton = Create("TextButton", {Name="Cancel", Text="Cancel", FontFace=theme.Font.Medium, TextColor3=theme.TextSecondary, BackgroundColor3=theme.PrimaryInteraction, Size=UDim2.fromScale(1,1), AutoButtonColor=false, Parent=buttonsFrame})
						Create("UICorner",{CornerRadius=theme.CornerRadius,Parent=cancelButton})
						ManageConnection(cancelButton.MouseButton1Click:Connect(function() ClosePickerPopup(true) end)) -- Close and discard


						return pickerCanvas, pickerFrame
					end

					local function OpenPickerPopup()
						if isPickerOpen then return end
						isPickerOpen = true

						local canvas, frame = CreatePickerPopup()
						local tweenInfo = TweenInfo.new(theme.AnimationSpeed * 1.5, theme.EasingStyle, theme.EasingDirection)

						-- Animate In
						TweenInstance(canvas, { GroupTransparency = 0 }, tweenInfo)
						TweenInstance(canvas.Overlay, {BackgroundTransparency = 0.5}, tweenInfo)
						TweenInstance(frame, { Scale = 1 }, tweenInfo)
					end

					local function ClosePickerPopup(isCancel)
						if not isPickerOpen or not pickerCanvas then return end
						isPickerOpen = false

						local canvas = pickerCanvas
						local frame = canvas:FindFirstChild("PickerFrame")
						local overlay = canvas:FindFirstChild("Overlay")
						local tweenInfo = TweenInfo.new(theme.AnimationSpeed * 1.5, theme.EasingStyle, theme.EasingDirection)

						-- Animate Out
						TweenInstance(canvas, { GroupTransparency = 1 }, tweenInfo)
						TweenInstance(overlay, {BackgroundTransparency = 1}, tweenInfo)
						TweenInstance(frame, { Scale = 0.95 }, tweenInfo).Completed:Connect(function()
							if not isCancel then -- Save the color if not cancelled
								ColorpickerFuncs.Color = newColorPreview.BackgroundColor3
								ColorpickerFuncs.Alpha = newColorPreview.BackgroundTransparency
								colorDisplay.BackgroundColor3 = ColorpickerFuncs.Color
								colorDisplay.BackgroundTransparency = ColorpickerFuncs.Alpha
								task.spawn(function()
									if cSettings.Callback then cSettings.Callback(ColorpickerFuncs.Color, useAlpha and ColorpickerFuncs.Alpha or nil) end
								end)
							end
							DestroyPicker() -- Clean up after animation
						end)
					end


					ManageConnection(previewButton.MouseButton1Click:Connect(OpenPickerPopup))

					-- API Functions
					function ColorpickerFuncs:SetColor(color3, noCallback)
						if typeof(color3) == "Color3" then
							ColorpickerFuncs.Color = color3
							colorDisplay.BackgroundColor3 = color3
							-- Need to update internal picker state too if it's open
							if isPickerOpen then InitializePickerState() end
							if not noCallback then
								task.spawn(function()
									if cSettings.Callback then cSettings.Callback(ColorpickerFuncs.Color, useAlpha and ColorpickerFuncs.Alpha or nil) end
								end)
							end
						end
					end
					function ColorpickerFuncs:SetAlpha(alpha, noCallback)
						if useAlpha and type(alpha) == "number" then
							ColorpickerFuncs.Alpha = math.clamp(alpha, 0, 1)
							colorDisplay.BackgroundTransparency = ColorpickerFuncs.Alpha
							if isPickerOpen then InitializePickerState() end
							if not noCallback then
								task.spawn(function()
									if cSettings.Callback then cSettings.Callback(ColorpickerFuncs.Color, ColorpickerFuncs.Alpha) end
								end)
							end
						end
					end
					function ColorpickerFuncs:GetColor() return ColorpickerFuncs.Color end
					function ColorpickerFuncs:GetAlpha() return useAlpha and ColorpickerFuncs.Alpha or nil end
					function ColorpickerFuncs:UpdateName(newName) nameLabel.Text = newName end
					function ColorpickerFuncs:SetVisibility(visible) container.Visible = visible end
					if flag then AetheriumUI.Options[flag] = ColorpickerFuncs end
					return ColorpickerFuncs
				end


				return SectionFunctions
			end -- End Section Function

			function TabFunctions:Select() SelectTab() end

			-- Config Section - Embed directly for simplicity, could be refactored
			function TabFunctions:InsertConfigSection(side)
				local configSection = self:Section({ Side = side or "Left", Name = "Configuration" })
				local isCfgSysAvailable = not AetheriumUI._Variables.IsStudio and pcall(function() return isfolder, makefolder, writefile, readfile, listfiles end)

				if not isCfgSysAvailable then
					configSection:Label({ Text = "Configuration system unavailable in this environment." })
					return
				end

				local inputPath = ""
				local selectedConfig = nil

				local nameInput = configSection:Input({
					Name = "Config Name", Placeholder = "Enter name...", Default = "",
					Callback = function(txt) inputPath = txt:gsub("[^%w_%.%-]", "") end -- Sanitize name
				})

				local configDropdown = configSection:Dropdown({
					Name = "Select Config", Options = AetheriumUI:RefreshConfigList(), Multi = false,
					Callback = function(val) selectedConfig = val end
				})

				configSection:Button({ Name = "Create/Save", Callback = function()
					if not inputPath or inputPath == "" then
						WindowFunctions:Notify({ Title="Config Error", Description="Please enter a config name.", Style="Cancel"}) return
					end
					local success, msg = AetheriumUI:SaveConfig(inputPath)
					WindowFunctions:Notify({ Title=success and "Config Saved" or "Save Error", Description=success and ("Saved as '"..inputPath.."'") or msg, Style=success and "Confirm" or "Cancel"})
					if success then configDropdown:InsertOptions(AetheriumUI:RefreshConfigList()); configDropdown:UpdateSelection(inputPath) end
				end})

				configSection:Button({ Name = "Load Selected", Callback = function()
					if not selectedConfig then
						WindowFunctions:Notify({ Title="Config Error", Description="Please select a config to load.", Style="Cancel"}) return
					end
					local success, msg = AetheriumUI:LoadConfig(selectedConfig)
					WindowFunctions:Notify({ Title=success and "Config Loaded" or "Load Error", Description=success and ("Loaded '"..selectedConfig.."'") or msg, Style=success and "Confirm" or "Cancel"})
				end})

				configSection:Button({ Name = "Delete Selected", Callback = function()
					if not selectedConfig then
						WindowFunctions:Notify({ Title="Config Error", Description="Please select a config to delete.", Style="Cancel"}) return
					end
					WindowFunctions:Dialog({ Title="Confirm Delete", Description="Delete '"..selectedConfig.."'? This cannot be undone.", Buttons={
						{ Name="Delete", Callback = function()
								local success, msg = AetheriumUI:DeleteConfig(selectedConfig)
								WindowFunctions:Notify({ Title=success and "Config Deleted" or "Delete Error", Description=success and ("Deleted '"..selectedConfig.."'") or msg, Style=success and "Confirm" or "Cancel"})
								if success then configDropdown:InsertOptions(AetheriumUI:RefreshConfigList()); configDropdown:UpdateSelection(nil) end
						}},
						{ Name="Cancel" }
					}})
				end})

				configSection:Button({ Name = "Refresh List", Callback = function()
					configDropdown:ClearOptions()
					configDropdown:InsertOptions(AetheriumUI:RefreshConfigList())
					WindowFunctions:Notify({ Title="Config", Description="Refreshed config list.", Style="None"})
				end})

				local autoloadLabel = configSection:Label({ Text = "Autoload: None" })
				local currentAutoload = AetheriumUI:GetAutoLoadConfigName()
				if currentAutoload then autoloadLabel:UpdateName("Autoload: " .. currentAutoload) end

				configSection:Button({ Name = "Set Autoload", Callback = function()
					if not selectedConfig then
						WindowFunctions:Notify({ Title="Config Error", Description="Please select a config to set as autoload.", Style="Cancel"}) return
					end
					local success, msg = AetheriumUI:SetAutoLoadConfig(selectedConfig)
					WindowFunctions:Notify({ Title=success and "Autoload Set" or "Autoload Error", Description=success and ("Set '"..selectedConfig.."' as autoload") or msg, Style=success and "Confirm" or "Cancel"})
					if success then autoloadLabel:UpdateName("Autoload: " .. selectedConfig) end
				end})
				configSection:Button({ Name = "Clear Autoload", Callback = function()
					local success, msg = AetheriumUI:SetAutoLoadConfig(nil) -- Pass nil to clear
					WindowFunctions:Notify({ Title=success and "Autoload Cleared" or "Autoload Error", Description=success and "Cleared autoload config." or msg, Style=success and "Confirm" or "Cancel"})
					if success then autoloadLabel:UpdateName("Autoload: None") end
				end})

			end


            return TabFunctions
		end -- End Tab Function

		return TabGroupFunctions
	end -- End TabGroup Function


	-- Notification Function
	function WindowFunctions:Notify(nSettings)
		local NotifyFuncs = {}
		local lifetime = nSettings.Lifetime == nil and 3 or nSettings.Lifetime -- Default 3 seconds, 0 for permanent until dismissed
		local style = nSettings.Style or "None" -- None, Confirm, Cancel

		local notification = Create("Frame", {
			Name = "Notification",
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(0, nSettings.SizeX or 250, 0, 0), -- Width, auto height
			BackgroundColor3 = theme.BackgroundLighter,
			Parent = notifications -- Parent to the main notifications container
		})
		-- Use LayoutOrder to position new notifications at the top/bottom based on layout settings
		notification.LayoutOrder = tick()

		local nCorner = Create("UICorner", { CornerRadius = theme.CornerRadius, Parent = notification })
		local nStroke = Create("UIStroke", { Color = theme.StrokeLight, Thickness = 1, Parent = notification })
		local nPadding = Create("UIPadding", {
			PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
			Parent = notification
		})
		local nLayout = Create("UIListLayout", {
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = notification
		})
		local nScale = Create("UIScale", { Scale = 0, Parent = notification }) -- For animation

		-- Title
		local titleLabel = Create("TextLabel", {
			Name = "Title", Text = nSettings.Title or "Notification", FontFace = theme.Font.Medium, TextSize = 14, TextColor3 = theme.Text,
			AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			Parent = notification
		})

		-- Description
		local descLabel = Create("TextLabel", {
			Name = "Description", Text = nSettings.Description or "", FontFace = theme.Font.Regular, TextSize = 12, TextColor3 = theme.TextSecondary,
			TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1, Parent = notification, Visible = (nSettings.Description and nSettings.Description ~= "")
		})

		-- Dismiss Button (Optional)
		local dismissButton = nil
		if style ~= "None" or lifetime == 0 then -- Show dismiss if permanent or styled
			dismissButton = Create("TextButton", {
				Name = "DismissButton",
				Size = UDim2.fromOffset(18, 18),
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -5, 0, 5), -- Top right corner
				BackgroundTransparency = 1, Text = "", ZIndex = 2, Parent = notification
			})
			local dismissIcon = Create("TextLabel", { -- Simple 'X' icon
				Name = "DismissIcon", Font = Enum.Font.SourceSansBold, Text = "✕", TextSize = 14, TextColor3 = theme.TextSecondary,
				Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Parent = dismissButton
			})
			ManageConnection(dismissButton.MouseEnter:Connect(function() TweenInstance(dismissIcon, {TextColor3 = theme.Red}) end))
			ManageConnection(dismissButton.MouseLeave:Connect(function() TweenInstance(dismissIcon, {TextColor3 = theme.TextSecondary}) end))
			ManageConnection(dismissButton.MouseButton1Click:Connect(function() NotifyFuncs:Cancel() end))

			-- Adjust padding if dismiss button exists
			nPadding.PaddingRight = UDim.new(0, 25)
		end

		-- Style Indicator (Optional)
		if style == "Confirm" then
			nStroke.Color = theme.Green
		elseif style == "Cancel" then
			nStroke.Color = theme.Red
		end

		-- Animation
		local animTween = nil
		local function Animate(fadeIn)
			if animTween and animTween.PlaybackState ~= Enum.PlaybackState.Completed then animTween:Cancel() end

			local targetScale = fadeIn and 1 or 0
			local tweenInfo = TweenInfo.new(theme.AnimationSpeed * 1.5, theme.EasingStyle, theme.EasingDirection)
			animTween = TweenInstance(nScale, { Scale = targetScale }, tweenInfo)
			return animTween
		end

		local lifetimeCoroutine = nil
		Animate(true).Completed:Connect(function()
			if lifetime > 0 then
				lifetimeCoroutine = task.delay(lifetime, function()
					if notification and notification.Parent then -- Check if not already cancelled
						Animate(false).Completed:Connect(function()
							if notification and notification.Parent then notification:Destroy() end
						end)
					end
				end)
			end
		end)

		function NotifyFuncs:Cancel()
			if lifetimeCoroutine then task.cancel(lifetimeCoroutine); lifetimeCoroutine = nil end
			if notification and notification.Parent then
				Animate(false).Completed:Connect(function()
					if notification and notification.Parent then notification:Destroy() end
				end)
			end
		end
		function NotifyFuncs:UpdateTitle(newTitle) titleLabel.Text = newTitle end
		function NotifyFuncs:UpdateDescription(newDesc) descLabel.Text = newDesc; descLabel.Visible = (newDesc and newDesc ~= "") end

		return NotifyFuncs
	end

	-- Dialog Function
	function WindowFunctions:Dialog(dSettings)
		local DialogFuncs = {}
		local wasClosed = false

		local dialogCanvas = Create("CanvasGroup", {
			Name = "DialogCanvas", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 200, Parent = base
		})
		local overlay = Create("Frame", {
			Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = theme.Overlay, BackgroundTransparency = 1, ZIndex = 1, Parent = dialogCanvas
		})
		local prompt = Create("Frame", {
			Name = "Prompt", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(dSettings.Width or 320, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = theme.BackgroundLight, ZIndex = 2, Scale = 0.95, Parent = dialogCanvas
		})
		Create("UICorner", { CornerRadius = theme.CornerRadius, Parent = prompt })
		Create("UIStroke", { Color = theme.StrokeLight, Thickness = 1, Parent = prompt })
		local promptPadding = Create("UIPadding", { Padding = UDim.new(0, 20), Parent = prompt })
		local promptLayout = Create("UIListLayout", { Padding = UDim.new(0, 15), SortOrder = Enum.SortOrder.LayoutOrder, Parent = prompt })

		-- Title
		Create("TextLabel", {
			Name = "Title", Text = dSettings.Title or "Dialog", FontFace = theme.Font.SemiBold, TextSize = 18, TextColor3 = theme.Text,
			TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center,
			Parent = prompt
		})
		-- Description
		Create("TextLabel", {
			Name = "Description", Text = dSettings.Description or "", FontFace = theme.Font.Regular, TextSize = 14, TextColor3 = theme.TextSecondary,
			TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 1, Parent = prompt
		})

		-- Buttons Frame
		local buttonsFrame = Create("Frame", { Name = "ButtonsFrame", Size = UDim2.new(1, 0, 0, 35), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = 2, Parent = prompt })
		local buttonsLayout = Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = buttonsFrame
		})

		-- Animation Function
		local function AnimateDialog(fadeIn)
			local tweenInfo = TweenInfo.new(theme.AnimationSpeed * 1.5, theme.EasingStyle, theme.EasingDirection)
			local targetGroupTrans = fadeIn and 0 or 1
			local targetOverlayTrans = fadeIn and 0.5 or 1
			local targetScale = fadeIn and 1 or 0.95

			TweenInstance(dialogCanvas, { GroupTransparency = targetGroupTrans }, tweenInfo)
			TweenInstance(overlay, { BackgroundTransparency = targetOverlayTrans }, tweenInfo)
			local scaleTween = TweenInstance(prompt, { Scale = targetScale }, tweenInfo)
			return scaleTween
		end

		local function CloseDialog()
			if wasClosed then return end
			wasClosed = true
			AnimateDialog(false).Completed:Connect(function()
				if dialogCanvas and dialogCanvas.Parent then dialogCanvas:Destroy() end
			end)
		end

		-- Create Buttons
		for i, btnData in ipairs(dSettings.Buttons or {}) do
			local isPrimary = i == 1 -- Assume first button is primary action
			local btn = Create("TextButton", {
				Name = btnData.Name or "Button", Text = btnData.Name or "Okay",
				FontFace = theme.Font.Medium, TextSize = 14,
				TextColor3 = isPrimary and theme.Background or theme.Text,
				BackgroundColor3 = isPrimary and theme.Accent or theme.PrimaryInteraction,
				AutomaticSize = Enum.AutomaticSize.X, -- Auto width based on text
				Size = UDim2.new(0, 0, 1, 0), -- Use fixed height from parent
				AutoButtonColor = false,
				Parent = buttonsFrame
			})
			Create("UICorner", { CornerRadius = theme.CornerRadius, Parent = btn })
			Create("UIPadding", { PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), Parent = btn }) -- Horizontal padding

			ManageConnection(btn.MouseEnter:Connect(function() TweenInstance(btn, { BackgroundColor3 = isPrimary and theme.AccentLight or theme.PrimaryInteractionHover }) end))
			ManageConnection(btn.MouseLeave:Connect(function() TweenInstance(btn, { BackgroundColor3 = isPrimary and theme.Accent or theme.PrimaryInteraction }) end))
			ManageConnection(btn.MouseButton1Click:Connect(function()
				CloseDialog()
				task.spawn(function() if btnData.Callback then btnData.Callback() end end)
			end))
		end

		AnimateDialog(true) -- Show dialog

		function DialogFuncs:Cancel() CloseDialog() end
		-- Add UpdateTitle/Description if needed

		return DialogFuncs
	end

	-- Unload Function
	local onUnloadCallback = nil
	function WindowFunctions.onUnloaded(callback) onUnloadCallback = callback end
	function WindowFunctions:Unload() AetheriumUI:Unload() end -- Point to library unload


	-- Keybind Listener for Toggle
	ManageConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == menuKeybind then
			ToggleMenuVisibility()
		end
	end))


	-- Initial Setup Calls
	if useAcrylicBlur and acrylicBlurEnabled then
		UpdateAcrylicBlurState(true) -- Ensure acrylic starts correctly if enabled
	elseif useUIBlur and acrylicBlurEnabled then
		UpdateAcrylicBlurState(true) -- Ensure UIBlur starts correctly
	end

	WindowFunctions:SetUserInfoState(showUserInfo) -- Set initial user info visibility

	-- Automatically select the first tab if any exist
	local firstGroup = tabSwitcherScroll:FindFirstChildOfClass("Frame")
	if firstGroup then
		local firstTabButton = firstGroup:FindFirstChild("TabsContainer"):FindFirstChildOfClass("TextButton")
		if firstTabButton and tabs[firstTabButton] then
			task.wait() -- Allow UI to draw once
			tabs[firstTabButton].Button:MouseButton1Click() -- Simulate click to select
		end
	end

	AetheriumUI:LoadAutoLoadConfig() -- Load autoload config after UI is setup

	return WindowFunctions
end -- End AetheriumUI:Window


-- // Config System Functions // --
local ClassParser = { -- Based on the element's .Class property
	["Toggle"] = {
		Save = function(flag, data) return { type="Toggle", flag=flag, state=data.State } end,
		Load = function(flag, data) if AetheriumUI.Options[flag] then AetheriumUI.Options[flag]:UpdateState(data.state, true) end end
	},
	["Slider"] = {
		Save = function(flag, data) return { type="Slider", flag=flag, value=data.Value } end,
		Load = function(flag, data) if AetheriumUI.Options[flag] then AetheriumUI.Options[flag]:UpdateValue(data.value, true) end end
	},
	["Input"] = {
		Save = function(flag, data) return { type="Input", flag=flag, text=data.Text } end,
		Load = function(flag, data) if AetheriumUI.Options[flag] then AetheriumUI.Options[flag]:UpdateText(data.text, true) end end
	},
	["Keybind"] = {
		Save = function(flag, data) return { type="Keybind", flag=flag, bind=data.Bind and data.Bind.Name or nil, bindType=data.Bind and data.Bind.EnumType.Name or nil } end,
		Load = function(flag, data) if AetheriumUI.Options[flag] and data.bind and data.bindType then
			local enumType = Enum[data.bindType]
			if enumType then local key = enumType[data.bind]; if key then AetheriumUI.Options[flag]:Bind(key, true) end end
		elseif AetheriumUI.Options[flag] and data.bind == nil then AetheriumUI.Options[flag]:Unbind(true) end end
	},
	["Dropdown"] = {
		Save = function(flag, data) return { type="Dropdown", flag=flag, value=data.Value } end,
		Load = function(flag, data) if AetheriumUI.Options[flag] then AetheriumUI.Options[flag]:UpdateSelection(data.value, true) end end
	},
	["Colorpicker"] = {
		Save = function(flag, data) return { type="Colorpicker", flag=flag, color=AetheriumUI:_Col3ToTable(data.Color), alpha=data.Alpha } end,
		Load = function(flag, data) if AetheriumUI.Options[flag] then
			local col = data.color and AetheriumUI:_TableToCol3(data.color) or nil
			if col then AetheriumUI.Options[flag]:SetColor(col, true) end
			if data.alpha ~= nil then AetheriumUI.Options[flag]:SetAlpha(data.alpha, true) end
		end end
	}
	-- Add parsers for other saveable element types if needed
}

function AetheriumUI:_Col3ToTable(col) return { R=col.R, G=col.G, B=col.B } end
function AetheriumUI:_TableToCol3(tbl) return Color3.new(tbl.R, tbl.G, tbl.B) end

function AetheriumUI:_GetConfigPath(filename)
	return self.Folder .. "/Configs/" .. (filename or "")
end

function AetheriumUI:_EnsureFolders()
	if AetheriumUI._Variables.IsStudio or not pcall(function() return isfolder, makefolder end) then return false end
	local success = pcall(function()
		if not isfolder(self.Folder) then makefolder(self.Folder) end
		if not isfolder(self.Folder .. "/Configs") then makefolder(self.Folder .. "/Configs") end
		if not isfolder(self.Folder .. "/Settings") then makefolder(self.Folder .. "/Settings") end -- For autoload etc.
	end)
	return success
end

function AetheriumUI:SetFolder(folderName)
	if type(folderName) == "string" and folderName ~= "" then
		self.Folder = folderName
		self:_EnsureFolders()
	else
		warn("[AetheriumUI] SetFolder expects a non-empty string.")
	end
end

function AetheriumUI:SaveConfig(filename)
	if not self:_EnsureFolders() then return false, "File system not available or failed to create folders." end
	if not filename or filename == "" then return false, "Filename cannot be empty." end

	local configData = { Elements = {} }
	for flag, element in pairs(self.Options) do
		if not element.IgnoreConfig and element.Class and ClassParser[element.Class] then
			local success, data = pcall(ClassParser[element.Class].Save, flag, element)
			if success then
				table.insert(configData.Elements, data)
			else
				warn(("[AetheriumUI] Failed to save element '%s': %s"):format(flag, tostring(data)))
			end
		end
	end

	local success, encoded = pcall(HttpService.JSONEncode, HttpService, configData)
	if not success then return false, "Failed to encode config data." end

	local path = self:_GetConfigPath(filename .. ".json")
	local writeSuccess, writeError = pcall(writefile, path, encoded)
	if not writeSuccess then return false, "Failed to write file: " .. tostring(writeError) end

	return true
end

function AetheriumUI:LoadConfig(filename)
	if AetheriumUI._Variables.IsStudio or not pcall(function() return isfile, readfile end) then return false, "File system not available." end
	if not filename or filename == "" then return false, "Filename cannot be empty." end

	local path = self:_GetConfigPath(filename .. ".json")
	if not isfile(path) then return false, "Config file not found." end

	local readSuccess, content = pcall(readfile, path)
	if not readSuccess then return false, "Failed to read file: " .. tostring(content) end

	local decodeSuccess, configData = pcall(HttpService.JSONDecode, HttpService, content)
	if not decodeSuccess then return false, "Failed to decode config data." end

	if type(configData) ~= "table" or type(configData.Elements) ~= "table" then return false, "Invalid config format." end

	local loadErrors = {}
	for _, elementData in ipairs(configData.Elements) do
		if type(elementData) == "table" and elementData.type and elementData.flag then
			if ClassParser[elementData.type] then
				local success, err = pcall(ClassParser[elementData.type].Load, elementData.flag, elementData)
				if not success then
					table.insert(loadErrors, ("Failed to load element '%s': %s"):format(elementData.flag, tostring(err)))
				end
			else
				table.insert(loadErrors, ("Unknown element type '%s' for flag '%s'"):format(elementData.type, elementData.flag))
			end
		end
	end

	if #loadErrors > 0 then
		warn("[AetheriumUI] Errors occurred during config load:\n" .. table.concat(loadErrors, "\n"))
		-- Return true even with partial load errors, but signal issues?
		return true, "Loaded with some errors."
	end

	return true
end

function AetheriumUI:DeleteConfig(filename)
	if not self:_EnsureFolders() then return false, "File system not available." end
	if not filename or filename == "" then return false, "Filename cannot be empty." end

	local path = self:_GetConfigPath(filename .. ".json")
	if not isfile(path) then return false, "Config file not found." end

	-- Check if it's the autoload config first
	if filename == self:GetAutoLoadConfigName() then
		self:SetAutoLoadConfig(nil) -- Clear autoload if deleting the autoloaded file
	end

	local delSuccess, delError = pcall(delfile, path)
	if not delSuccess then return false, "Failed to delete file: " .. tostring(delError) end

	return true
end


function AetheriumUI:RefreshConfigList()
	if not self:_EnsureFolders() then return {} end
	if not pcall(function() return listfiles end) then return {} end

	local files = listfiles(self.Folder .. "/Configs/")
	local configNames = {}
	for _, filePath in ipairs(files) do
		local name = filePath:match("([^/\\]-)%.json$") -- Extract name without extension
		if name then
			table.insert(configNames, name)
		end
	end
	table.sort(configNames)
	return configNames
end

function AetheriumUI:GetAutoLoadConfigName()
	if not pcall(function() return isfile, readfile end) then return nil end
	local path = self.Folder .. "/Settings/autoload.cfg"
	if isfile(path) then
		local success, name = pcall(readfile, path)
		if success and type(name) == "string" and name ~= "" then return name end
	end
	return nil
end

function AetheriumUI:SetAutoLoadConfig(filename)
	if not self:_EnsureFolders() then return false, "File system not available." end
	local path = self.Folder .. "/Settings/autoload.cfg"

	if filename == nil or filename == "" then -- Clear autoload
		if isfile(path) then
			local delSuccess, delError = pcall(delfile, path)
			if not delSuccess then return false, "Failed to clear autoload: " .. tostring(delError) end
		end
		return true -- Success (cleared or already clear)
	else -- Set autoload
		local writeSuccess, writeError = pcall(writefile, path, filename)
		if not writeSuccess then return false, "Failed to set autoload: " .. tostring(writeError) end
		return true
	end
end

function AetheriumUI:LoadAutoLoadConfig()
	local autoLoadName = self:GetAutoLoadConfigName()
	if autoLoadName then
		print("[AetheriumUI] Attempting to autoload config:", autoLoadName)
		local success, msg = self:LoadConfig(autoLoadName)
		if AetheriumUI._Internal.CurrentWindow and AetheriumUI._Internal.CurrentWindow.WindowFunctions.Notify then
			AetheriumUI._Internal.CurrentWindow.WindowFunctions:Notify({
				Title = success and "Autoload Success" or "Autoload Failed",
				Description = success and ("Loaded '"..autoLoadName.."'") or ("Failed: " .. (msg or "Unknown error")),
				Style = success and "Confirm" or "Cancel"
			})
		end
		return success
	end
	return false -- No autoload set
end

-- // Unload Function // --
function AetheriumUI:Unload()
	if AetheriumUI._Internal.IsUnloaded then return end
	AetheriumUI._Internal.IsUnloaded = true
	print("[AetheriumUI] Unloading...")

	-- Trigger unload callback if window exists
	if AetheriumUI._Internal.CurrentWindow and AetheriumUI._Internal.CurrentWindow.onUnloadCallback then
		pcall(AetheriumUI._Internal.CurrentWindow.onUnloadCallback)
	end

	-- Disconnect all managed connections
	CleanupConnections()

	-- Stop all active tweens
	CleanupTweens()

	-- Destroy the ScreenGui
	local gui = GetGuiParent():FindFirstChild("AetheriumUI_ScreenGui")
	if gui then gui:Destroy() end

	-- Cleanup Acrylic Blur resources if they exist
	AetheriumUI:_CleanupAcrylicBlur()

	-- Clear references
	AetheriumUI.Options = {}
	AetheriumUI._Internal.CurrentWindow = nil

	print("[AetheriumUI] Unloaded.")
end

-- // Acrylic Blur Implementation (Separate for Clarity) // --
AetheriumUI._Internal.AcrylicDOF = nil
AetheriumUI._Internal.AcrylicParts = {}
AetheriumUI._Internal.AcrylicUpdateFunction = nil
AetheriumUI._Internal.AcrylicBlurTarget = nil

function AetheriumUI:_InitializeAcrylicBlur(targetFrame, partsTable, theme)
	if not pcall(function() return workspace.CurrentCamera end) then
		warn("[AetheriumUI] Acrylic Blur: Cannot get CurrentCamera.")
		return
	end
	local camera = workspace.CurrentCamera
	local HS = HttpService -- Assuming available
	if not HS then warn("[AetheriumUI] Acrylic Blur: HttpService not available."); return end

	AetheriumUI._Internal.AcrylicBlurTarget = targetFrame
	AetheriumUI._Internal.AcrylicParts = partsTable

	-- Create or find DepthOfField
	local DepthOfField = AetheriumUI._Internal.AcrylicDOF
	if not DepthOfField or not DepthOfField.Parent then
		DepthOfField = Lighting:FindFirstChild("Aetherium_DepthOfField")
		if not DepthOfField or not DepthOfField:IsA("DepthOfFieldEffect") then
			DepthOfField = Create("DepthOfFieldEffect", {
				Name = "Aetherium_DepthOfField", FarIntensity = 0, FocusDistance = 50, InFocusRadius = 40, NearIntensity = 0.8, Enabled = false, Parent = Lighting
			})
		end
		AetheriumUI._Internal.AcrylicDOF = DepthOfField
	end
	DepthOfField.Enabled = true

	-- Helper functions from original MacLib (ensure math functions are available)
	local acos, max, pi, sqrt = math.acos, math.max, math.pi, math.sqrt
	local sz = 0.2
	local wedgeguid = HS:GenerateGUID(false)

	local function DrawTriangle(v1, v2, v3, p0, p1)
		local s1 = (v1 - v2).Magnitude; local s2 = (v2 - v3).Magnitude; local s3 = (v3 - v1).Magnitude
		local smax = max(s1, s2, s3)
		local A, B, C
		if s1 == smax then A, B, C = v1, v2, v3 elseif s2 == smax then A, B, C = v2, v3, v1 else A, B, C = v3, v1, v2 end

		local AB, AC = B - A, C - A
		local para = AB:Dot(AC) / AB.Magnitude
		local perp = sqrt(AC.Magnitude^2 - para*para)
		local dif_para = AB.Magnitude - para

		local st = CFrame.lookAt(B, A)
		local za = CFrame.Angles(pi/2, 0, 0)
		local cf0 = st
		local Top_Look = (cf0 * za).LookVector
		local Mid_Point = A + (B - A).Unit * para
		local Needed_Look = (C - Mid_Point).Unit
		local dot = Top_Look:Dot(Needed_Look)

		local angle = acos(math.clamp(dot, -1, 1))
		local ac = CFrame.Angles(0, 0, angle)
		cf0 = cf0 * ac
		if ((cf0 * za).LookVector - Needed_Look).Magnitude > 0.01 then cf0 = cf0 * CFrame.Angles(0, 0, -2 * angle) end
		cf0 = cf0 * CFrame.new(0, perp/2, -(dif_para + para/2))

		local cf1 = st * CFrame.Angles(0, 0, -angle) * CFrame.Angles(0, pi, 0)
		if ((cf1 * za).LookVector - Needed_Look).Magnitude > 0.01 then cf1 = cf1 * CFrame.Angles(0, 0, 2 * angle) end
		cf1 = cf1 * CFrame.new(0, perp/2, dif_para/2)


		if not p0 then
			p0 = Create("Part", { FormFactor = Enum.FormFactor.Custom, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth, Anchored = true, CanCollide = false, CastShadow = false, Material = Enum.Material.Glass, Size = Vector3.new(sz, sz, sz), Name = HS:GenerateGUID(false) })
			local mesh = Create("SpecialMesh", { MeshType = Enum.MeshType.Wedge, Name = wedgeguid, Parent = p0 })
		end
		local mesh0 = p0:FindFirstChild(wedgeguid) or Create("SpecialMesh", { MeshType = Enum.MeshType.Wedge, Name = wedgeguid, Parent = p0 })
		mesh0.Scale = Vector3.new(0, perp/sz, para/sz)
		p0.CFrame = cf0

		if not p1 then p1 = p0:Clone() end
		local mesh1 = p1:FindFirstChild(wedgeguid) or Create("SpecialMesh", { MeshType = Enum.MeshType.Wedge, Name = wedgeguid, Parent = p1 })
		mesh1.Scale = Vector3.new(0, perp/sz, dif_para/sz)
		p1.CFrame = cf1

		return p0, p1
	end

	local function DrawQuad(v1, v2, v3, v4, parts)
		local p1, p2, p3, p4
		p1, p2 = DrawTriangle(v1, v2, v3, parts[1], parts[2])
		p3, p4 = DrawTriangle(v3, v2, v4, parts[3], parts[4])
		return p1, p2, p3, p4
	end

	-- RenderStepped Update Function
	AetheriumUI._Internal.AcrylicUpdateFunction = function()
		local target = AetheriumUI._Internal.AcrylicBlurTarget
		local parts = AetheriumUI._Internal.AcrylicParts
		local dof = AetheriumUI._Internal.AcrylicDOF

		if not target or not target.Parent or not target.Visible or not acrylicBlurEnabled or AetheriumUI._Internal.IsUnloaded then
			for i = 1, 4 do if parts[i] then parts[i].Parent = nil end end
			if dof then dof.Enabled = false end
			return
		end
		if not dof or not dof.Parent then return end
		dof.Enabled = true

		local zIndex = 1 - 0.05 * target.AbsoluteWindowSize.Z -- Approximation

		local tl_pos, br_pos = target.AbsolutePosition, target.AbsolutePosition + target.AbsoluteSize
		local tr_pos, bl_pos = Vector2.new(br_pos.X, tl_pos.Y), Vector2.new(tl_pos.X, br_pos.Y)

		-- Simple rotation handling (only affects corners if rotated)
		if target.Rotation ~= 0 then
			local mid = tl_pos:Lerp(br_pos, 0.5)
			local rad = math.rad(target.Rotation)
			local cosR, sinR = math.cos(rad), math.sin(rad)
			local function rotate(v)
				local x, y = v.X - mid.X, v.Y - mid.Y
				return Vector2.new(mid.X + x * cosR - y * sinR, mid.Y + x * sinR + y * cosR)
			end
			tl_pos, tr_pos, bl_pos, br_pos = rotate(tl_pos), rotate(tr_pos), rotate(bl_pos), rotate(br_pos)
		end

		local success, v1, v2, v3, v4 = pcall(function()
			return camera:ScreenPointToRay(tl_pos.X, tl_pos.Y, zIndex).Origin,
			       camera:ScreenPointToRay(tr_pos.X, tr_pos.Y, zIndex).Origin,
			       camera:ScreenPointToRay(bl_pos.X, bl_pos.Y, zIndex).Origin,
			       camera:ScreenPointToRay(br_pos.X, br_pos.Y, zIndex).Origin
		end)

		if not success then return end -- ScreenPointToRay can fail during loading

		local p1, p2, p3, p4 = DrawQuad(v1, v2, v3, v4, parts)
		parts[1], parts[2], parts[3], parts[4] = p1, p2, p3, p4 -- Update table

		for i=1, 4 do
			if parts[i] then
				parts[i].Parent = camera
				parts[i].Transparency = 0.98 -- High transparency for blur effect
				parts[i].Color = Color3.new(1,1,1) -- Institutional white
				parts[i].Reflectance = 0.1
			end
		end
	end
end

function AetheriumUI:_CleanupAcrylicBlur()
	if AetheriumUI._Internal.AcrylicUpdateFunction and AetheriumUI._Internal.Connections then
		-- Find and disconnect the RenderStepped connection if managed
        -- This part is tricky without storing the connection explicitly.
        -- Assuming it's managed via ManageConnection:
        -- Iterate AetheriumUI._Internal.Connections and find the one linked to AcrylicUpdateFunction?
        -- For now, rely on general cleanup
	end
	AetheriumUI._Internal.AcrylicUpdateFunction = nil

	for _, part in pairs(AetheriumUI._Internal.AcrylicParts) do
		if part and part.Parent then part:Destroy() end
	end
	AetheriumUI._Internal.AcrylicParts = {}

	if AetheriumUI._Internal.AcrylicDOF and AetheriumUI._Internal.AcrylicDOF.Parent then
		if AetheriumUI._Internal.AcrylicDOF.Name == "Aetherium_DepthOfField" then
			AetheriumUI._Internal.AcrylicDOF:Destroy() -- Only destroy if created by the lib
		else
			AetheriumUI._Internal.AcrylicDOF.Enabled = false -- Disable if pre-existing
		end
	end
	AetheriumUI._Internal.AcrylicDOF = nil
	AetheriumUI._Internal.AcrylicBlurTarget = nil
end

-- // Preload Assets // --
function AetheriumUI:PreloadAssets()
	local assetList = {}
	for _, assetId in pairs(self.Assets) do
		if type(assetId) == "string" and assetId:match("^rbx") then
			table.insert(assetList, assetId)
		end
	end
	if #assetList > 0 then
		print("[AetheriumUI] Preloading", #assetList, "assets...")
		local success, err = pcall(ContentProvider.PreloadAsync, ContentProvider, assetList)
		if not success then
			warn("[AetheriumUI] Asset preloading failed:", err)
		else
			print("[AetheriumUI] Asset preloading complete.")
		end
	end
end
-- Call preload when the library is first loaded/required
AetheriumUI:PreloadAssets()


-- // Demo Function // --
function AetheriumUI:Demo()
	print("[AetheriumUI] Launching Demo Window...")
	local Window = AetheriumUI:Window({
		Title = "AetheriumUI Demo",
		Subtitle = "Showcasing UI Elements",
		Size = UDim2.fromOffset(900, 650),
		Keybind = Enum.KeyCode.RightControl,
		-- Theme = {}, -- Optionally override theme here
		BlurType = "UIBlur", -- Try UIBlur first, falls back if needed
		AcrylicBlurEnabled = true, -- Enable blur by default
		ShowUserInfo = true,
	})

	if not Window then print("Failed to create AetheriumUI window."); return end

	-- Global Settings Examples
	Window:GlobalSetting({ Name = "UI Blur", Default = Window:GetAcrylicBlurState(), Callback = function(state)
		Window:SetAcrylicBlurState(state); Window:Notify({Title="Setting", Description="UI Blur "..(state and "Enabled" or "Disabled")})
	end})
	Window:GlobalSetting({ Name = "Notifications", Default = Window:GetNotificationsState(), Callback = function(state)
		Window:SetNotificationsState(state); Window:Notify({Title="Setting", Description="Notifications "..(state and "Enabled" or "Disabled")})
	end})
	Window:GlobalSetting({ Name = "User Info", Default = Window:GetUserInfoState(), Callback = function(state)
		Window:SetUserInfoState(state); Window:Notify({Title="Setting", Description="User Info "..(state and "Shown" or "Hidden")})
	end})

	-- Tabs
	local mainTabGroup = Window:TabGroup({ Name = "Main Features" })
	local settingsTabGroup = Window:TabGroup({ Name = "Configuration" })

	local mainTab = mainTabGroup:Tab({ Name = "Elements", Image = AetheriumUI.Assets.defaultTabIcon })
	local configTab = settingsTabGroup:Tab({ Name = "Settings", Image = AetheriumUI.Assets.settingsTabIcon })

	-- Sections in Main Tab
	local sectionLeft = mainTab:Section({ Side = "Left" })
	local sectionRight = mainTab:Section({ Side = "Right" })

	-- Left Section Content
	sectionLeft:Header({ Text = "Basic Elements" })
	sectionLeft:Button({ Name = "Show Dialog", Callback = function()
		Window:Dialog({ Title = "Example Dialog", Description = "This is a test dialog popup.", Buttons = { { Name = "Confirm" }, { Name = "Cancel" } }})
	end})
	sectionLeft:Button({ Name = "Show Notification", Callback = function()
		Window:Notify({ Title = "Demo Notification", Description = "This notification will disappear.", Style="Confirm", Lifetime=4 })
	end})
	sectionLeft:Toggle({ Name = "Simple Toggle", Default = true, Callback = function(s) print("Toggle state:", s) end }, "DemoToggle")
	sectionLeft:Label({Text = "This is a descriptive label."})
	sectionLeft:Divider()
	sectionLeft:Header({ Text = "Input Elements" })
	sectionLeft:Input({ Name = "Text Input", Placeholder = "Enter text...", Default = "Hello", CharacterLimit = 50 }, "DemoInput")
	sectionLeft:Input({ Name = "Numeric Input", Placeholder = "Enter numbers...", AcceptedCharacters = "Numeric" })
	sectionLeft:Keybind({ Name = "Action Keybind", Default = Enum.KeyCode.F, Callback = function(k) Window:Notify({ Title="Keybind", Description=k.Name.." pressed!"}) end }, "DemoKeybind")

	-- Right Section Content
	sectionRight:Header({ Text = "Advanced Elements" })
	sectionRight:Slider({ Name = "Percentage Slider", Minimum=0, Maximum=100, Default=50, Precision=0, DisplayMethod="Percent" }, "DemoSlider")
	sectionRight:Slider({ Name = "Value Slider", Minimum=-10, Maximum=10, Default=0, Precision=1, Step=0.5, Suffix=" units" })
	local demoOptions = {"Option A", "Option B", "Option C", "Long Option Name Example"}
	sectionRight:Dropdown({ Name = "Single Select", Options = demoOptions, Default = demoOptions[1], Required = true }, "DemoDropdown")
	sectionRight:Dropdown({ Name = "Multi Select", Options = {"Apple", "Banana", "Cherry", "Date", "Fig", "Grape"}, Multi = true, Search = true, Default = {"Apple", "Cherry"} }, "DemoMultiDropdown")
	sectionRight:Colorpicker({ Name = "Primary Color", Default = Color3.fromRGB(80, 120, 255) }, "DemoColorpicker")
	sectionRight:Colorpicker({ Name = "Secondary Color (Alpha)", Default = Color3.fromRGB(255, 80, 80), Alpha = 0.5 }, "DemoColorpickerAlpha")
	sectionRight:Paragraph({Header="Info Paragraph", Body="This section contains more complex UI elements like sliders and dropdowns."})
	sectionRight:SubLabel({Text="Color pickers allow selection of RGB and optionally Alpha values."})

	-- Config Section
	configTab:InsertConfigSection("Left")

	-- Select initial tab
	mainTab:Select()

	print("[AetheriumUI] Demo setup complete.")
end


return AetheriumUI
