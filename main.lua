-- language: Lua, file: TG_Mick_v5_Part1.lua
-- ===== PART 1: UI หลัก + ตัวแปร + ฟังก์ชันฟิสิกส์ (ขนาดพอดีมือถือ) =====

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

local PrimaryColor = Color3.fromRGB(0, 229, 255)
local BgDark = Color3.fromRGB(15, 17, 21)
local PanelBg = Color3.fromRGB(22, 24, 31)
local FeatureBoxBg = Color3.fromRGB(28, 32, 42)
local TextGray = Color3.fromRGB(170, 170, 170)
local TextWhite = Color3.fromRGB(255, 255, 255)
local StatusGreen = Color3.fromRGB(0, 255, 136)
local StatusRed = Color3.fromRGB(255, 50, 50)

local UI_WIDTH = 420
local UI_HEIGHT = 300

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TG_Mick_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

-- ===== ตัวแปรสถานะ =====
local isUIOpen = false
local isLocked = false
local currentLang = "TH"

local WalkSpeedEnabled = false
local JumpPowerEnabled = false
local FlyEnabled = false
local InfJumpEnabled = false
local NoclipEnabled = false
local AirWalkEnabled = false

local selectedPlayer = nil
local FollowEnabled = false
local followConn = nil

local TargetWalkSpeed = 16
local TargetJumpPower = 50
local FlySpeed = 50
local FlyUpDownSpeed = 50

-- ===== กระโดดไม่จำกัด =====
UserInputService.JumpRequest:Connect(function()
    if InfJumpEnabled then
        pcall(function()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end)

-- ===== Noclip =====
local noclipConnection = nil
local function toggleNoclip(state)
    if state then
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
                local char = player.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
        end
    else
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

-- ===== ยืนกลางอากาศ =====
local airWalkPlatform = nil
local function toggleAirWalk(state)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if state then
        if hrp and (not airWalkPlatform or not airWalkPlatform.Parent) then
            airWalkPlatform = Instance.new("Part")
            airWalkPlatform.Size = Vector3.new(50, 1, 50)
            airWalkPlatform.Transparency = 1
            airWalkPlatform.Anchored = true
            airWalkPlatform.CanCollide = true
            airWalkPlatform.Parent = workspace
        end
    else
        if airWalkPlatform then airWalkPlatform:Destroy() airWalkPlatform = nil end
    end
end

RunService.RenderStepped:Connect(function()
    if AirWalkEnabled and airWalkPlatform then
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then airWalkPlatform.CFrame = hrp.CFrame - Vector3.new(0, 3.5, 0) end
    end
end)

-- ===== บินตามผู้เล่น =====
local function toggleFollow(state)
    if followConn then followConn:Disconnect() followConn = nil end
    if state and selectedPlayer then
        followConn = RunService.RenderStepped:Connect(function()
            if FollowEnabled and selectedPlayer and selectedPlayer.Character then
                local tHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                local cHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if tHRP and cHRP then cHRP.CFrame = tHRP.CFrame * CFrame.new(0, 2, 5) end
            end
        end)
    end
end

-- ===== Fly =====
local flyBV, flyBG = nil, nil
local function toggleFly(state)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if state then
        if hrp then
            flyBV = Instance.new("BodyVelocity")
            flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBV.Velocity = Vector3.new(0, 0, 0)
            flyBV.Parent = hrp
            flyBG = Instance.new("BodyGyro")
            flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            flyBG.P = 1000 flyBG.D = 50
            flyBG.Parent = hrp
        end
    else
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
    end
end

RunService.RenderStepped:Connect(function()
    if FlyEnabled and flyBV and flyBG then
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera
        if hrp and hum then
            hum.PlatformStand = true
            flyBG.CFrame = cam.CFrame
            local moveDir = hum.MoveDirection
            local finalVel = Vector3.new(0,0,0)
            if moveDir.Magnitude > 0 then
                finalVel = Vector3.new(moveDir.X, 0, moveDir.Z) * FlySpeed
                local lookY = cam.CFrame.LookVector.Y
                if lookY > 0.1 then finalVel = finalVel + Vector3.new(0, FlyUpDownSpeed, 0)
                elseif lookY < -0.1 then finalVel = finalVel - Vector3.new(0, FlyUpDownSpeed, 0) end
                if finalVel.Magnitude > 0 then finalVel = finalVel.Unit * FlySpeed end
            end
            flyBV.Velocity = finalVel
        end
    else
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.PlatformStand and not FlyEnabled then hum.PlatformStand = false end
    end
end)

-- ===== ไอคอนลอย =====
local FloatingLogo = Instance.new("ImageButton")
FloatingLogo.Name = "FloatingLogo"
FloatingLogo.Size = UDim2.new(0, 40, 0, 40)
FloatingLogo.Position = UDim2.new(0, 10, 0.5, -20)
FloatingLogo.BackgroundColor3 = BgDark
FloatingLogo.Image = "rbxassetid://78858384475525"
FloatingLogo.ScaleType = Enum.ScaleType.Crop
FloatingLogo.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatingLogo
local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = PrimaryColor
FloatStroke.Thickness = 2
FloatStroke.Parent = FloatingLogo

local StatusDot = Instance.new("TextButton")
StatusDot.Size = UDim2.new(0, 12, 0, 12)
StatusDot.Position = UDim2.new(1, -8, 1, -8)
StatusDot.BackgroundColor3 = StatusGreen
StatusDot.Text = ""
StatusDot.Parent = FloatingLogo
local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = StatusDot
local DotStroke = Instance.new("UIStroke")
DotStroke.Color = Color3.fromRGB(15, 17, 21)
DotStroke.Thickness = 2
DotStroke.Parent = StatusDot

-- ===== Main UI =====
local MainUI = Instance.new("Frame")
MainUI.Name = "MainUI"
MainUI.Size = UDim2.new(0, UI_WIDTH, 0, UI_HEIGHT)
MainUI.Position = UDim2.new(0.5, -UI_WIDTH/2, 0.5, -UI_HEIGHT/2)
MainUI.BackgroundColor3 = BgDark
MainUI.Visible = false
MainUI.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainUI
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = PrimaryColor
UIStroke.Thickness = 1.5
UIStroke.Transparency = 0.5
UIStroke.Parent = MainUI

-- ===== Sidebar =====
local SIDEBAR_W = 50
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 23, 28)
Sidebar.Parent = MainUI
local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

local SidebarFix = Instance.new("Frame")
SidebarFix.Size = UDim2.new(0, 15, 1, 0)
SidebarFix.Position = UDim2.new(1, -15, 0, 0)
SidebarFix.BackgroundColor3 = Color3.fromRGB(20, 23, 28)
SidebarFix.BorderSizePixel = 0
SidebarFix.Parent = Sidebar

local SideLogo = Instance.new("ImageLabel")
SideLogo.Size = UDim2.new(0, 34, 0, 34)
SideLogo.Position = UDim2.new(0.5, -17, 0, 8)
SideLogo.BackgroundTransparency = 1
SideLogo.Image = "rbxassetid://78858384475525"
SideLogo.Parent = Sidebar
local SideLogoCorner = Instance.new("UICorner")
SideLogoCorner.CornerRadius = UDim.new(1, 0)
SideLogoCorner.Parent = SideLogo
local SideLogoStroke = Instance.new("UIStroke")
SideLogoStroke.Color = PrimaryColor
SideLogoStroke.Thickness = 1.5
SideLogoStroke.Parent = SideLogo
-- language: Lua, file: TG_Mick_v5_Part2.lua
-- ===== PART 2: UI Components + Teleport Tool (ขนาดพอดีมือถือ) =====

-- ===== ฟังก์ชันสร้าง Nav Button =====
local function createNavBtn(textIcon, yPos)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 32, 0, 32)
	btn.Position = UDim2.new(0.5, -16, 0, yPos)
	btn.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
	btn.Text = textIcon
	btn.TextColor3 = TextGray
	btn.TextSize = 15
	btn.Font = Enum.Font.GothamBold
	btn.Parent = Sidebar
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = btn
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(50, 55, 65)
	stroke.Parent = btn
	return btn, stroke
end

local BtnHome, HomeStroke = createNavBtn("🏠", 50)
BtnHome.BackgroundColor3 = PrimaryColor
BtnHome.TextColor3 = Color3.fromRGB(0,0,0)
HomeStroke.Color = PrimaryColor

-- ===== Content Area =====
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -SIDEBAR_W, 1, 0)
ContentArea.Position = UDim2.new(0, SIDEBAR_W, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainUI

local HEADER_H = 36
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, HEADER_H)
Header.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
Header.Parent = ContentArea

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(1, -90, 1, 0)
HeaderTitle.Position = UDim2.new(0, 10, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "TG:mick_2009 | FPS: -- | Ping: --"
HeaderTitle.TextColor3 = PrimaryColor
HeaderTitle.TextSize = 11
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = Header

local LangToggleBtn = Instance.new("TextButton")
LangToggleBtn.Size = UDim2.new(0, 26, 0, 18)
LangToggleBtn.Position = UDim2.new(1, -64, 0.5, -9)
LangToggleBtn.BackgroundTransparency = 1
LangToggleBtn.Text = "🇹🇭"
LangToggleBtn.TextSize = 14
LangToggleBtn.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -12)
CloseBtn.BackgroundColor3 = PrimaryColor
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header
local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 5)
CloseBtnCorner.Parent = CloseBtn

-- ===== Pages Container =====
local PagesContainer = Instance.new("Frame")
PagesContainer.Size = UDim2.new(1, -16, 1, -(HEADER_H + 8))
PagesContainer.Position = UDim2.new(0, 8, 0, HEADER_H + 4)
PagesContainer.BackgroundTransparency = 1
PagesContainer.Parent = ContentArea

local HomePage = Instance.new("Frame")
HomePage.Size = UDim2.new(1, 0, 1, 0)
HomePage.BackgroundTransparency = 1
HomePage.Visible = true
HomePage.Parent = PagesContainer

-- ===== Panel (3 คอลัมน์) =====
local PAD = 4
local function makePanel(xScale, xOffset)
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(0.33, -PAD, 1, 0)
    p.Position = UDim2.new(xScale, xOffset, 0, 0)
    p.BackgroundColor3 = PanelBg
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 2
    p.ScrollBarImageColor3 = PrimaryColor
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.Parent = HomePage
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = p
    return p
end

local PanelLeft = makePanel(0, 0)
local PanelMid = makePanel(0.33, 2)
local PanelRight = makePanel(0.66, 4)

-- ===== Header =====
local function createHeader(parent, text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -12, 0, 20)
	lbl.Position = UDim2.new(0, 6, 0, 6)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = TextWhite
	lbl.TextSize = 12
	lbl.Font = Enum.Font.GothamBold
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 10
	lbl.Parent = parent
	return lbl
end

local TitleLeft = createHeader(PanelLeft, "ฟิสิกส์")
local TitleMid = createHeader(PanelMid, "ติดตาม/วาร์ป")
local TitleRight = createHeader(PanelRight, "ตั้งค่า")

local currentYLeft, currentYMid, currentYRight = 30, 30, 30

-- ===== Toggle =====
local function createToggle(parent, text, yPos, callback)
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, -12, 0, 32)
	box.Position = UDim2.new(0, 6, 0, yPos)
	box.BackgroundColor3 = FeatureBoxBg
	box.Parent = parent
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 6)
	boxCorner.Parent = box
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Color3.fromRGB(45, 50, 60)
	boxStroke.Parent = box

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -46, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.TextSize = 11
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = box

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 32, 0, 16)
	toggleBtn.Position = UDim2.new(1, -40, 0.5, -8)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	toggleBtn.Text = ""
	toggleBtn.Parent = box
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggleBtn

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 12, 0, 12)
	knob.Position = UDim2.new(0, 2, 0.5, -6)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.Parent = toggleBtn
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local isToggled = false
	toggleBtn.MouseButton1Click:Connect(function()
		isToggled = not isToggled
		if isToggled then
			toggleBtn.BackgroundColor3 = PrimaryColor
			TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(1, -14, 0.5, -6)}):Play()
		else
			toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
		end
		if callback then callback(isToggled) end
	end)
	return label
end

-- ===== Panel ซ้าย =====
local ToggleWalkText = createToggle(PanelLeft, "วิ่งเร็ว", currentYLeft, function(s) WalkSpeedEnabled = s end)
currentYLeft = currentYLeft + 36
local ToggleJumpText = createToggle(PanelLeft, "กระโดดสูง", currentYLeft, function(s) JumpPowerEnabled = s end)
currentYLeft = currentYLeft + 36
local ToggleFlyText = createToggle(PanelLeft, "บิน", currentYLeft, function(s) FlyEnabled = s; toggleFly(s) end)
currentYLeft = currentYLeft + 36
local ToggleInfJumpText = createToggle(PanelLeft, "กระโดดไม่จำกัด", currentYLeft, function(s) InfJumpEnabled = s end)
currentYLeft = currentYLeft + 36
local ToggleNoclipText = createToggle(PanelLeft, "ทะลุกำแพง", currentYLeft, function(s) NoclipEnabled = s; toggleNoclip(s) end)
currentYLeft = currentYLeft + 36
local ToggleAirWalkText = createToggle(PanelLeft, "ยืนกลางอากาศ", currentYLeft, function(s) AirWalkEnabled = s; toggleAirWalk(s) end)
currentYLeft = currentYLeft + 36
PanelLeft.CanvasSize = UDim2.new(0, 0, 0, currentYLeft + 8)

-- ===== Panel กลาง =====
local dropBox = Instance.new("Frame")
dropBox.Size = UDim2.new(1, -12, 0, 26)
dropBox.Position = UDim2.new(0, 6, 0, currentYMid)
dropBox.BackgroundColor3 = FeatureBoxBg
dropBox.Parent = PanelMid
local dropCorner = Instance.new("UICorner")
dropCorner.CornerRadius = UDim.new(0, 6)
dropCorner.Parent = dropBox
local dropStroke = Instance.new("UIStroke")
dropStroke.Color = Color3.fromRGB(45, 50, 60)
dropStroke.Parent = dropBox

local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Size = UDim2.new(1, 0, 1, 0)
DropdownBtn.BackgroundTransparency = 1
DropdownBtn.Text = "เลือกผู้เล่น ▼"
DropdownBtn.TextColor3 = TextWhite
DropdownBtn.TextSize = 11
DropdownBtn.Font = Enum.Font.GothamBold
DropdownBtn.Parent = dropBox
currentYMid = currentYMid + 32

local TargetDisplay = Instance.new("TextLabel")
TargetDisplay.Size = UDim2.new(1, -12, 0, 22)
TargetDisplay.Position = UDim2.new(0, 6, 0, currentYMid)
TargetDisplay.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
TargetDisplay.Text = "เป้าหมาย: ไม่มี"
TargetDisplay.TextColor3 = PrimaryColor
TargetDisplay.TextSize = 10
TargetDisplay.Font = Enum.Font.GothamBold
TargetDisplay.Parent = PanelMid
local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 5)
targetCorner.Parent = TargetDisplay
currentYMid = currentYMid + 28

local ToggleFollowText = createToggle(PanelMid, "บินตามผู้เล่น", currentYMid, function(s)
    FollowEnabled = s
    toggleFollow(s)
end)
currentYMid = currentYMid + 36

local TeleportBtn = Instance.new("TextButton")
TeleportBtn.Size = UDim2.new(1, -12, 0, 26)
TeleportBtn.Position = UDim2.new(0, 6, 0, currentYMid)
TeleportBtn.BackgroundColor3 = PrimaryColor
TeleportBtn.Text = "วาร์ปไปหาเป้าหมาย"
TeleportBtn.TextColor3 = Color3.fromRGB(0,0,0)
TeleportBtn.TextSize = 11
TeleportBtn.Font = Enum.Font.GothamBold
TeleportBtn.Parent = PanelMid
local tpCorner = Instance.new("UICorner")
tpCorner.CornerRadius = UDim.new(0, 5)
tpCorner.Parent = TeleportBtn
currentYMid = currentYMid + 32

TeleportBtn.MouseButton1Click:Connect(function()
    if selectedPlayer and selectedPlayer.Character then
        local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP and myHRP then myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 2, 3) end
    end
end)

local CreateToolBtn = Instance.new("TextButton")
CreateToolBtn.Size = UDim2.new(1, -12, 0, 26)
CreateToolBtn.Position = UDim2.new(0, 6, 0, currentYMid)
CreateToolBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
CreateToolBtn.Text = "สร้างไอเทมวาร์ป"
CreateToolBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CreateToolBtn.TextSize = 11
CreateToolBtn.Font = Enum.Font.GothamBold
CreateToolBtn.Parent = PanelMid
local ctCorner = Instance.new("UICorner")
ctCorner.CornerRadius = UDim.new(0, 5)
ctCorner.Parent = CreateToolBtn
currentYMid = currentYMid + 32

local RemoveToolBtn = Instance.new("TextButton")
RemoveToolBtn.Size = UDim2.new(1, -12, 0, 26)
RemoveToolBtn.Position = UDim2.new(0, 6, 0, currentYMid)
RemoveToolBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
RemoveToolBtn.Text = "ลบไอเทมวาร์ป"
RemoveToolBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RemoveToolBtn.TextSize = 11
RemoveToolBtn.Font = Enum.Font.GothamBold
RemoveToolBtn.Parent = PanelMid
local rtCorner = Instance.new("UICorner")
rtCorner.CornerRadius = UDim.new(0, 5)
rtCorner.Parent = RemoveToolBtn
currentYMid = currentYMid + 32

-- ===== Teleport Tool =====
local teleportTool, toolConn, clickConn = nil, nil, nil
local function createTeleportTool()
    if teleportTool then return end
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end
    teleportTool = Instance.new("Tool")
    teleportTool.Name = "ไอเทมวาร์ป"
    teleportTool.RequiresHandle = false
    teleportTool.CanBeDropped = false
    teleportTool.Parent = backpack

    toolConn = teleportTool.Equipped:Connect(function()
        clickConn = UserInputService.InputEnded:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Touch then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local cam = workspace.CurrentCamera
                if hrp and hum and hum.MoveDirection.Magnitude == 0 then
                    local ray = cam:ScreenPointToRay(input.Position.X, input.Position.Y)
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {char}
                    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
                    if result then hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end
                end
            end
        end)
    end)

    teleportTool.Unequipped:Connect(function()
        if clickConn then clickConn:Disconnect() clickConn = nil end
    end)
end
local function removeTeleportTool()
    if teleportTool then teleportTool:Destroy() teleportTool = nil end
    if toolConn then toolConn:Disconnect() toolConn = nil end
    if clickConn then clickConn:Disconnect() clickConn = nil end
end
CreateToolBtn.MouseButton1Click:Connect(createTeleportTool)
RemoveToolBtn.MouseButton1Click:Connect(removeTeleportTool)

-- ===== Dropdown Player List =====
local DropdownList = Instance.new("ScrollingFrame")
DropdownList.Size = UDim2.new(1, -12, 0, 120)
DropdownList.Position = UDim2.new(0, 6, 0, currentYMid - 180)
DropdownList.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
DropdownList.BorderSizePixel = 1
DropdownList.BorderColor3 = PrimaryColor
DropdownList.Visible = false
DropdownList.ZIndex = 50
DropdownList.Parent = PanelMid
local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 5)
listCorner.Parent = DropdownList
local listLayout = Instance.new("UIListLayout")
listLayout.Parent = DropdownList

local function updatePlayerList()
    for _, child in ipairs(DropdownList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 22)
            btn.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
            btn.Text = plr.Name
            btn.TextColor3 = TextWhite
            btn.TextSize = 10
            btn.Font = Enum.Font.GothamBold
            btn.Parent = DropdownList
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = plr
                TargetDisplay.Text = "เป้าหมาย: " .. plr.Name
                DropdownList.Visible = false
            end)
        end
    end
    DropdownList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end
DropdownBtn.MouseButton1Click:Connect(function()
    DropdownList.Visible = not DropdownList.Visible
    if DropdownList.Visible then updatePlayerList() end
end)
PanelMid.CanvasSize = UDim2.new(0, 0, 0, currentYMid + 8)
-- language: Lua, file: TG_Mick_v5_Part3.lua
-- ===== PART 3: Panel ขวา (Slider) + ระบบภาษา + Loop หลัก (ขนาดพอดีมือถือ) =====

-- ===== Slider =====
local function createSlider(parent, text, yPos, min, max, default, callback)
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, -12, 0, 44)
	box.Position = UDim2.new(0, 6, 0, yPos)
	box.BackgroundColor3 = FeatureBoxBg
	box.Parent = parent
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 6)
	boxCorner.Parent = box
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Color3.fromRGB(45, 50, 60)
	boxStroke.Parent = box

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 16)
	label.Position = UDim2.new(0, 8, 0, 4)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.TextSize = 11
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = box

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, -20, 0, 16)
	valueLabel.Position = UDim2.new(0, 8, 0, 4)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(default)
	valueLabel.TextColor3 = PrimaryColor
	valueLabel.TextSize = 11
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = box

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -16, 0, 4)
	barBg.Position = UDim2.new(0, 8, 0, 30)
	barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	barBg.Parent = box
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(1, 0)
	bgCorner.Parent = barBg

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = PrimaryColor
	fill.Parent = barBg
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 12, 0, 12)
	knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.Parent = barBg
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local dragging = false
	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	barBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local relX = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
			local val = math.floor(min + (max - min) * relX)
			fill.Size = UDim2.new(relX, 0, 1, 0)
			knob.Position = UDim2.new(relX, -6, 0.5, -6)
			valueLabel.Text = tostring(val)
			if callback then callback(val) end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	return label, valueLabel
end

-- ===== Panel ขวา: Slider =====
local SliderSpeedText = createSlider(PanelRight, "ความเร็วเดิน", currentYRight, 16, 100, 16, function(v) TargetWalkSpeed = v end)
currentYRight = currentYRight + 48
local SliderJumpText = createSlider(PanelRight, "พลังกระโดด", currentYRight, 50, 200, 50, function(v) TargetJumpPower = v end)
currentYRight = currentYRight + 48
local SliderFlyText = createSlider(PanelRight, "ความเร็วบิน", currentYRight, 20, 200, 50, function(v) FlySpeed = v end)
currentYRight = currentYRight + 48
local SliderFlyUpDownText = createSlider(PanelRight, "ความเร็วขึ้น-ลง", currentYRight, 10, 100, 50, function(v) FlyUpDownSpeed = v end)
currentYRight = currentYRight + 48
PanelRight.CanvasSize = UDim2.new(0, 0, 0, currentYRight + 8)

-- ===== อัปเดตภาษา =====
local function updateLanguage()
	if currentLang == "TH" then
		LangToggleBtn.Text = "🇹🇭"
		TitleLeft.Text = "ฟิสิกส์"
		TitleMid.Text = "ติดตาม/วาร์ป"
		TitleRight.Text = "ตั้งค่า"
		ToggleWalkText.Text = "วิ่งเร็ว"
		ToggleJumpText.Text = "กระโดดสูง"
		ToggleFlyText.Text = "บิน"
		ToggleInfJumpText.Text = "กระโดดไม่จำกัด"
		ToggleNoclipText.Text = "ทะลุกำแพง"
		ToggleAirWalkText.Text = "ยืนกลางอากาศ"
		ToggleFollowText.Text = "บินตามผู้เล่น"
		DropdownBtn.Text = "เลือกผู้เล่น ▼"
		TargetDisplay.Text = selectedPlayer and ("เป้าหมาย: " .. selectedPlayer.Name) or "เป้าหมาย: ไม่มี"
		TeleportBtn.Text = "วาร์ปไปหาเป้าหมาย"
		CreateToolBtn.Text = "สร้างไอเทมวาร์ป"
		RemoveToolBtn.Text = "ลบไอเทมวาร์ป"
		SliderSpeedText.Text = "ความเร็วเดิน"
		SliderJumpText.Text = "พลังกระโดด"
		SliderFlyText.Text = "ความเร็วบิน"
		SliderFlyUpDownText.Text = "ความเร็วขึ้น-ลง"
	else
		LangToggleBtn.Text = "🇬🇧"
		TitleLeft.Text = "Physics"
		TitleMid.Text = "Follow / Warp"
		TitleRight.Text = "Settings"
		ToggleWalkText.Text = "Speed"
		ToggleJumpText.Text = "Jump"
		ToggleFlyText.Text = "Fly"
		ToggleInfJumpText.Text = "Infinite Jump"
		ToggleNoclipText.Text = "Noclip"
		ToggleAirWalkText.Text = "Air Stand"
		ToggleFollowText.Text = "Follow Player"
		DropdownBtn.Text = "Select Player ▼"
		TargetDisplay.Text = selectedPlayer and ("Target: " .. selectedPlayer.Name) or "Target: None"
		TeleportBtn.Text = "Teleport to Target"
		CreateToolBtn.Text = "Create Warp Tool"
		RemoveToolBtn.Text = "Remove Warp Tool"
		SliderSpeedText.Text = "Walk Speed"
		SliderJumpText.Text = "Jump Power"
		SliderFlyText.Text = "Fly Speed"
		SliderFlyUpDownText.Text = "Fly Up/Down"
	end
end

LangToggleBtn.MouseButton1Click:Connect(function()
	if currentLang == "TH" then currentLang = "EN" else currentLang = "TH" end
	updateLanguage()
end)

-- ===== Speed/Jump Loop =====
RunService.Heartbeat:Connect(function()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		if WalkSpeedEnabled then hum.WalkSpeed = TargetWalkSpeed else if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end end
		if JumpPowerEnabled then hum.UseJumpPower = true; hum.JumpPower = TargetJumpPower else if hum.JumpPower ~= 50 then hum.JumpPower = 50 end end
	end
end)

-- ===== FPS/Ping =====
local frameCount, fpsUpdateTimer, pingValue = 0, 0, 0
RunService.RenderStepped:Connect(function(dt)
	frameCount = frameCount + 1
	fpsUpdateTimer = fpsUpdateTimer + dt
	if fpsUpdateTimer >= 1 then
		local fps = math.floor(frameCount / fpsUpdateTimer)
		pcall(function()
			local pingItem = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
			if pingItem then pingValue = math.floor(pingItem:GetValue()) end
		end)
		if pingValue == 0 then pingValue = math.floor(1000 / (fps > 0 and fps or 60)) end
		HeaderTitle.Text = string.format("TG:mick_2009 | FPS: %d | Ping: %d", fps, pingValue)
		frameCount, fpsUpdateTimer = 0, 0
	end
end)

-- ===== ลาก UI =====
local function makeDraggable(guiObject, isMainMenu)
	local dragging, dragInput, dragStart, startPos, holdTimer, isHolding = false, nil, nil, nil, 0, false
	guiObject.InputBegan:Connect(function(input)
		if isLocked then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isHolding = true
			if not isMainMenu then holdTimer = tick() else dragging = true; dragStart = input.Position; startPos = guiObject.Position end
		end
	end)
	guiObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
			if isHolding and not isMainMenu then
				if tick() - holdTimer > 0.15 then
					if not dragging then dragging = true; dragStart = input.Position; startPos = guiObject.Position end
				end
			end
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if isHolding and not dragging and not isMainMenu then
				if tick() - holdTimer <= 0.15 then isUIOpen = not isUIOpen; MainUI.Visible = isUIOpen end
			end
			dragging, isHolding, dragInput = false, false, nil
		end
	end)
end
makeDraggable(FloatingLogo, false)
makeDraggable(MainUI, true)

StatusDot.MouseButton1Click:Connect(function()
	isLocked = not isLocked
	StatusDot.BackgroundColor3 = isLocked and StatusRed or StatusGreen
end)
CloseBtn.MouseButton1Click:Connect(function()
	isUIOpen = false
	MainUI.Visible = false
end)
-- language: Lua, file: TG_Mick_v5_Part4.lua
-- ===== PART 4: ESP Tab (👁️) — ภาษาไทยล้วน + UI ขนาดมือถือ =====

local Drawing = (typeof(Drawing) == "table") and Drawing or nil
local espFolder = Instance.new("Folder")
espFolder.Name = "TG_ESP_Folder"
espFolder.Parent = game:GetService("CoreGui")

local ESP = {
    Enabled = false,
    Lines = false, Boxes = false, Names = false, Distance = false, Health = false,
    TeamCheck = true,
    MaxDistance = 500,
    BoxColor = Color3.fromRGB(0, 229, 255),
    LineColor = Color3.fromRGB(0, 255, 136),
    TextColor = Color3.fromRGB(255, 255, 255),
}

local espCache = {}

local function worldToViewport(pos)
    local cam = workspace.CurrentCamera
    local sp, onScreen = cam:WorldToViewportPoint(pos)
    if sp.Z < 0 then return nil end
    return Vector2.new(sp.X, sp.Y), onScreen
end

local function createESPFor(plr)
    if plr == player then return end
    if espCache[plr] then return end
    local data = { Player = plr }
    if Drawing and Drawing.new then
        data.Line = Drawing.new("Line")
        data.Line.Thickness = 1.2 data.Line.Color = ESP.LineColor data.Line.Transparency = 1 data.Line.Visible = false

        data.Box = Drawing.new("Square")
        data.Box.Thickness = 1.2 data.Box.Color = ESP.BoxColor data.Box.Filled = false data.Box.Transparency = 1 data.Box.Visible = false

        data.Name = Drawing.new("Text")
        data.Name.Size = 12 data.Name.Center = true data.Name.Outline = true data.Name.Color = ESP.TextColor data.Name.Font = 2 data.Name.Visible = false

        data.Distance = Drawing.new("Text")
        data.Distance.Size = 11 data.Distance.Center = true data.Distance.Outline = true data.Distance.Color = Color3.fromRGB(255, 200, 0) data.Distance.Visible = false

        data.Health = Drawing.new("Square")
        data.Health.Thickness = 1 data.Health.Filled = true data.Health.Visible = false
    else
        -- fallback billboard
        local function mkBb(size)
            local bb = Instance.new("BillboardGui")
            bb.Size = size bb.AlwaysOnTop = true bb.LightInfluence = 0 bb.ResetOnSpawn = false bb.Enabled = false bb.Parent = espFolder
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,0,1,0) lbl.BackgroundTransparency = 1 lbl.TextColor3 = Color3.new(1,1,1)
            lbl.TextStrokeTransparency = 0 lbl.TextSize = 12 lbl.Font = Enum.Font.GothamBold lbl.Parent = bb
            return bb, lbl
        end
        local bb, lbl = mkBb(UDim2.new(0, 150, 0, 20)); data.Name = { Billboard = bb, Label = lbl }
        local bb2, lbl2 = mkBb(UDim2.new(0, 100, 0, 16)); data.Distance = { Billboard = bb2, Label = lbl2 }
        data.Line = nil
        data.Box = nil
        data.Health = nil
    end
    espCache[plr] = data
end

local function removeESPFor(plr)
    local data = espCache[plr]
    if not data then return end
    for _, obj in pairs(data) do
        if type(obj) == "table" then
            if obj.Remove then pcall(function() obj:Remove() end) end
            if obj.Billboard then obj.Billboard:Destroy() end
        end
    end
    espCache[plr] = nil
end

local function hideAll(d)
    if d.Line and d.Line.Remove then d.Line.Visible = false end
    if d.Box and d.Box.Remove then d.Box.Visible = false end
    if d.Name and d.Name.Remove then d.Name.Visible = false end
    if d.Distance and d.Distance.Remove then d.Distance.Visible = false end
    if d.Health and d.Health.Remove then d.Health.Visible = false end
    if d.Name and d.Name.Billboard then d.Name.Billboard.Enabled = false end
    if d.Distance and d.Distance.Billboard then d.Distance.Billboard.Enabled = false end
end

local function updateESP()
    for plr, data in pairs(espCache) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not ESP.Enabled or not hrp or not hum or hum.Health <= 0 then hideAll(data) continue end

        if ESP.TeamCheck and plr.Team and player.Team and plr.Team == player.Team then hideAll(data) continue end

        local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local dist = myHRP and (myHRP.Position - hrp.Position).Magnitude or 0
        if dist > ESP.MaxDistance then hideAll(data) continue end

        local head = char:FindFirstChild("Head")
        local headPos = head and head.Position or (hrp.Position + Vector3.new(0, 1.5, 0))
        local footPos = hrp.Position - Vector3.new(0, 3, 0)
        local hs = worldToViewport(headPos + Vector3.new(0, 0.5, 0))
        local fs = worldToViewport(footPos)
        if not hs or not fs then hideAll(data) continue end

        local bh = math.abs(fs.Y - hs.Y)
        local bw = bh * 0.55
        local bx = hs.X - bw / 2
        local by = hs.Y

        if data.Line and data.Line.Remove then
            if ESP.Lines then
                local vp = workspace.CurrentCamera.ViewportSize
                data.Line.From = Vector2.new(vp.X/2, vp.Y)
                data.Line.To = Vector2.new(hs.X, hs.Y)
                data.Line.Visible = true
            else data.Line.Visible = false end
        end
        if data.Box and data.Box.Remove then
            if ESP.Boxes then
                data.Box.Size = Vector2.new(bw, bh)
                data.Box.Position = Vector2.new(bx, by)
                data.Box.Visible = true
            else data.Box.Visible = false end
        end
        if data.Name and data.Name.Remove then
            if ESP.Names then
                data.Name.Text = plr.Name
                data.Name.Position = Vector2.new(hs.X, hs.Y - 16)
                data.Name.Visible = true
            else data.Name.Visible = false end
        elseif data.Name and data.Name.Billboard then
            data.Name.Billboard.Enabled = ESP.Names
            data.Name.Billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
            if ESP.Names then data.Name.Label.Text = plr.Name end
        end
        if data.Distance and data.Distance.Remove then
            if ESP.Distance then
                data.Distance.Text = string.format("[%d ม.]", math.floor(dist))
                data.Distance.Position = Vector2.new(hs.X, fs.Y + 2)
                data.Distance.Visible = true
            else data.Distance.Visible = false end
        elseif data.Distance and data.Distance.Billboard then
            data.Distance.Billboard.Enabled = ESP.Distance
            data.Distance.Billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
            if ESP.Distance then data.Distance.Label.Text = string.format("[%d ม.]", math.floor(dist)) end
        end
        if data.Health and data.Health.Remove then
            if ESP.Health then
                local hpPct = hum.Health / hum.MaxHealth
                local barH = bh * hpPct
                data.Health.Size = Vector2.new(3, barH)
                data.Health.Position = Vector2.new(bx - 6, by + (bh - barH))
                data.Health.Color = Color3.fromRGB(math.floor(255*(1-hpPct)), math.floor(255*hpPct), 0)
                data.Health.Visible = true
            else data.Health.Visible = false end
        end
    end
end

Players.PlayerAdded:Connect(createESPFor)
Players.PlayerRemoving:Connect(removeESPFor)
for _, plr in ipairs(Players:GetPlayers()) do createESPFor(plr) end

RunService.RenderStepped:Connect(function()
    if ESP.Enabled then updateESP() end
end)

-- ===== Tab 👁️ =====
local ESPTabBtn, ESPTabStroke = createNavBtn("👁️", 90)

local ESPPage = Instance.new("Frame")
ESPPage.Size = UDim2.new(1, 0, 1, 0)
ESPPage.BackgroundTransparency = 1
ESPPage.Visible = false
ESPPage.Parent = PagesContainer

BtnHome.MouseButton1Click:Connect(function()
    HomePage.Visible = true
    ESPPage.Visible = false
    BtnHome.BackgroundColor3 = PrimaryColor
    BtnHome.TextColor3 = Color3.fromRGB(0,0,0)
    HomeStroke.Color = PrimaryColor
    ESPTabBtn.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    ESPTabBtn.TextColor3 = TextGray
    ESPTabStroke.Color = Color3.fromRGB(50, 55, 65)
end)

ESPTabBtn.MouseButton1Click:Connect(function()
    HomePage.Visible = false
    ESPPage.Visible = true
    ESPTabBtn.BackgroundColor3 = PrimaryColor
    ESPTabBtn.TextColor3 = Color3.fromRGB(0,0,0)
    ESPTabStroke.Color = PrimaryColor
    BtnHome.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    BtnHome.TextColor3 = TextGray
    HomeStroke.Color = Color3.fromRGB(50, 55, 65)
end)

-- ===== 2 Panel: ซ้าย toggle, ขวาตั้งค่า =====
local ESPPanel1 = Instance.new("ScrollingFrame")
ESPPanel1.Size = UDim2.new(0.5, -PAD, 1, 0)
ESPPanel1.Position = UDim2.new(0, 0, 0, 0)
ESPPanel1.BackgroundColor3 = PanelBg
ESPPanel1.BorderSizePixel = 0
ESPPanel1.ScrollBarThickness = 2
ESPPanel1.ScrollBarImageColor3 = PrimaryColor
ESPPanel1.CanvasSize = UDim2.new(0, 0, 0, 0)
ESPPanel1.Parent = ESPPage
local e1c = Instance.new("UICorner") e1c.CornerRadius = UDim.new(0, 8) e1c.Parent = ESPPanel1

local ESPPanel2 = Instance.new("ScrollingFrame")
ESPPanel2.Size = UDim2.new(0.5, -PAD, 1, 0)
ESPPanel2.Position = UDim2.new(0.5, 2, 0, 0)
ESPPanel2.BackgroundColor3 = PanelBg
ESPPanel2.BorderSizePixel = 0
ESPPanel2.ScrollBarThickness = 2
ESPPanel2.ScrollBarImageColor3 = PrimaryColor
ESPPanel2.CanvasSize = UDim2.new(0, 0, 0, 0)
ESPPanel2.Parent = ESPPage
local e2c = Instance.new("UICorner") e2c.CornerRadius = UDim.new(0, 8) e2c.Parent = ESPPanel2

local ESPTitle1 = createHeader(ESPPanel1, "เปิด/ปิด")
local ESPTitle2 = createHeader(ESPPanel2, "ตั้งค่า")

local espY1, espY2 = 30, 30

local ToggleESPEnabled = createToggle(ESPPanel1, "เปิดการมองเห็น", espY1, function(s) ESP.Enabled = s end)
espY1 = espY1 + 36
local ToggleLines = createToggle(ESPPanel1, "มองเส้น", espY1, function(s) ESP.Lines = s end)
espY1 = espY1 + 36
local ToggleBoxes = createToggle(ESPPanel1, "มองกล่อง", espY1, function(s) ESP.Boxes = s end)
espY1 = espY1 + 36
local ToggleNames = createToggle(ESPPanel1, "มองชื่อ", espY1, function(s) ESP.Names = s end)
espY1 = espY1 + 36
local ToggleDistance = createToggle(ESPPanel1, "มองระยะทาง", espY1, function(s) ESP.Distance = s end)
espY1 = espY1 + 36
local ToggleHealth = createToggle(ESPPanel1, "มองเลือด", espY1, function(s) ESP.Health = s end)
espY1 = espY1 + 36
local ToggleTeam = createToggle(ESPPanel1, "ซ่อนทีมเดียวกัน", espY1, function(s) ESP.TeamCheck = s end)
espY1 = espY1 + 36
ESPPanel1.CanvasSize = UDim2.new(0, 0, 0, espY1 + 8)

local SliderESPDist = createSlider(ESPPanel2, "ระยะมองสูงสุด (เมตร)", espY2, 50, 2000, 500, function(v) ESP.MaxDistance = v end)
espY2 = espY2 + 48

-- สีกล่อง / สีเส้น
local function makeColorRow(parent, labelText, getColor, setColor)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -12, 0, 32)
    box.Position = UDim2.new(0, 6, 0, espY2)
    box.BackgroundColor3 = FeatureBoxBg
    box.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = box
    local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(45, 50, 60) s.Parent = box

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = box

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 22)
    btn.Position = UDim2.new(1, -48, 0.5, -11)
    btn.BackgroundColor3 = getColor()
    btn.Text = ""
    btn.Parent = box
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 5) bc.Parent = btn
    btn.MouseButton1Click:Connect(function()
        local h, s, v = getColor():ToHSV()
        h = (h + 0.12) % 1
        local new = Color3.fromHSV(h, s, v)
        setColor(new)
        btn.BackgroundColor3 = new
    end)
    espY2 = espY2 + 36
    return lbl
end

local BoxColorLbl = makeColorRow(ESPPanel2, "สีกล่อง", function() return ESP.BoxColor end, function(c)
    ESP.BoxColor = c
    for _, d in pairs(espCache) do if d.Box and d.Box.Remove then d.Box.Color = c end end
end)
local LineColorLbl = makeColorRow(ESPPanel2, "สีเส้น", function() return ESP.LineColor end, function(c)
    ESP.LineColor = c
    for _, d in pairs(espCache) do if d.Line and d.Line.Remove then d.Line.Color = c end end
end)

ESPPanel2.CanvasSize = UDim2.new(0, 0, 0, espY2 + 8)

-- ===== ผูกภาษา =====
local baseUpdateLang = updateLanguage
updateLanguage = function()
    baseUpdateLang()
    if currentLang == "TH" then
        ESPTitle1.Text = "เปิด/ปิด"
        ESPTitle2.Text = "ตั้งค่า"
        ToggleESPEnabled.Text = "เปิดการมองเห็น"
        ToggleLines.Text = "มองเส้น"
        ToggleBoxes.Text = "มองกล่อง"
        ToggleNames.Text = "มองชื่อ"
        ToggleDistance.Text = "มองระยะทาง"
        ToggleHealth.Text = "มองเลือด"
        ToggleTeam.Text = "ซ่อนทีมเดียวกัน"
        SliderESPDist.Text = "ระยะมองสูงสุด (เมตร)"
        BoxColorLbl.Text = "สีกล่อง"
        LineColorLbl.Text = "สีเส้น"
    else
        ESPTitle1.Text = "Toggle"
        ESPTitle2.Text = "Settings"
        ToggleESPEnabled.Text = "Enable ESP"
        ToggleLines.Text = "Show Lines"
        ToggleBoxes.Text = "Show Boxes"
        ToggleNames.Text = "Show Names"
        ToggleDistance.Text = "Show Distance"
        ToggleHealth.Text = "Show Health"
        ToggleTeam.Text = "Hide Teammates"
        SliderESPDist.Text = "Max Distance (m)"
        BoxColorLbl.Text = "Box Color"
        LineColorLbl.Text = "Line Color"
    end
end