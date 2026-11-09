-- language: Lua, file: TG_Mick_v5_Ultimate_Combo.lua
-- ===== TG_Mick_v5 Ultimate Combo (Part 1/9) =====

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
ScreenGui.Name = "TG_Mick_Ultimate_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

-- ===== ตัวแปรสถานะ =====
local isUIOpen = false
local isLocked = false
local iPadMode = false
local NORMAL_UI_SIZE = Vector2.new(UI_WIDTH, UI_HEIGHT)
local IPAD_UI_SIZE = Vector2.new(680, 460)

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
            flyBG.P = 1000
            flyBG.D = 50
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
-- ===== TG_Mick_v5 Ultimate Combo (Part 2/9) =====
-- (ต่อจาก Part 1)

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

-- ===== ปุ่มสลับโหมด iPad =====
local IPadBtn = Instance.new("TextButton")
IPadBtn.Name = "IPadModeButton"
IPadBtn.Size = UDim2.new(0, 58, 0, 20)
IPadBtn.Position = UDim2.new(1, -92, 0.5, -10)
IPadBtn.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
IPadBtn.Text = "จอใหญ่"
IPadBtn.TextColor3 = TextWhite
IPadBtn.TextSize = 10
IPadBtn.Font = Enum.Font.GothamBold
IPadBtn.AutoButtonColor = true
IPadBtn.Parent = Header
local IPadBtnCorner = Instance.new("UICorner")
IPadBtnCorner.CornerRadius = UDim.new(0, 5)
IPadBtnCorner.Parent = IPadBtn
local IPadBtnStroke = Instance.new("UIStroke")
IPadBtnStroke.Color = PrimaryColor
IPadBtnStroke.Thickness = 1
IPadBtnStroke.Parent = IPadBtn

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
-- ===== TG_Mick_v5 Ultimate Combo (Part 3/9) =====
-- (ต่อจาก Part 2)

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

-- ===== Header ของ Panel =====
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

-- ===== Dropdown Player List =====
local DropdownList = Instance.new("ScrollingFrame")
DropdownList.Size = UDim2.new(1, -12, 0, 120)
DropdownList.Position = UDim2.new(0, 6, 0, currentYMid - 120)
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
-- ===== TG_Mick_v5 Ultimate Combo (Part 4/9) =====
-- (ต่อจาก Part 3)

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

-- ===== สลับโหมด iPad / ปกติ =====
local function setIPadMode(enabled)
	iPadMode = enabled

	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
	local targetSize = enabled and IPAD_UI_SIZE or NORMAL_UI_SIZE

	local maxWidth = math.max(280, viewport.X * 0.94)
	local maxHeight = math.max(220, viewport.Y * 0.88)
	local finalWidth = math.min(targetSize.X, maxWidth)
	local finalHeight = math.min(targetSize.Y, maxHeight)

	MainUI.Size = UDim2.new(0, finalWidth, 0, finalHeight)
	MainUI.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainUI.AnchorPoint = Vector2.new(0.5, 0.5)

	IPadBtn.Text = enabled and "จอเล็ก" or "จอใหญ่"
	IPadBtn.BackgroundColor3 = enabled and PrimaryColor or Color3.fromRGB(30, 35, 45)
	IPadBtn.TextColor3 = enabled and Color3.fromRGB(0, 0, 0) or TextWhite
end

IPadBtn.MouseButton1Click:Connect(function()
	setIPadMode(not iPadMode)
end)
-- ===== TG_Mick_v5 Ultimate Combo (Part 5/9) =====
-- (ต่อจาก Part 4)

-- ===== PART 4: ESP System =====
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
        data.Line.Thickness = 1.2 
        data.Line.Color = ESP.LineColor 
        data.Line.Transparency = 1 
        data.Line.Visible = false

        data.Box = Drawing.new("Square")
        data.Box.Thickness = 1.2 
        data.Box.Color = ESP.BoxColor 
        data.Box.Filled = false 
        data.Box.Transparency = 1 
        data.Box.Visible = false

        data.Name = Drawing.new("Text")
        data.Name.Size = 12 
        data.Name.Center = true 
        data.Name.Outline = true 
        data.Name.Color = ESP.TextColor 
        data.Name.Font = 2 
        data.Name.Visible = false

        data.Distance = Drawing.new("Text")
        data.Distance.Size = 11 
        data.Distance.Center = true 
        data.Distance.Outline = true 
        data.Distance.Color = Color3.fromRGB(255, 200, 0) 
        data.Distance.Visible = false

        data.Health = Drawing.new("Square")
        data.Health.Thickness = 1 
        data.Health.Filled = true 
        data.Health.Visible = false
    else
        local function mkBb(size)
            local bb = Instance.new("BillboardGui")
            bb.Size = size 
            bb.AlwaysOnTop = true 
            bb.LightInfluence = 0 
            bb.ResetOnSpawn = false 
            bb.Enabled = false 
            bb.Parent = espFolder
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,0,1,0) 
            lbl.BackgroundTransparency = 1 
            lbl.TextColor3 = Color3.new(1,1,1)
            lbl.TextStrokeTransparency = 0 
            lbl.TextSize = 12 
            lbl.Font = Enum.Font.GothamBold 
            lbl.Parent = bb
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

-- ===== Tab 👁️ (UI ESP) =====
local ESPTabBtn, ESPTabStroke = createNavBtn("👁️", 90)

local ESPPage = Instance.new("Frame")
ESPPage.Size = UDim2.new(1, 0, 1, 0)
ESPPage.BackgroundTransparency = 1
ESPPage.Visible = false
ESPPage.Parent = PagesContainer

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
-- ===== TG_Mick_v5 Ultimate Combo (Part 6/9 - Map Hub Final) =====
-- (ต่อจาก Part 5)

-- ===== PART 5: แถบ 📄 (Map Hub) + ℹ️ (Info) + ⚙️ (Settings) =====
local DocTabBtn, DocTabStroke = createNavBtn("📄", 130)
local InfoTabBtn, InfoTabStroke = createNavBtn("ℹ️", 170)
local SettingTabBtn, SettingTabStroke = createNavBtn("⚙️", 210)

local DocPage = Instance.new("Frame")
DocPage.Size = UDim2.new(1, 0, 1, 0)
DocPage.BackgroundTransparency = 1
DocPage.Visible = false
DocPage.Parent = PagesContainer

local InfoPage = Instance.new("Frame")
InfoPage.Size = UDim2.new(1, 0, 1, 0)
InfoPage.BackgroundTransparency = 1
InfoPage.Visible = false
InfoPage.Parent = PagesContainer

local SettingPage = Instance.new("Frame")
SettingPage.Size = UDim2.new(1, 0, 1, 0)
SettingPage.BackgroundTransparency = 1
SettingPage.Visible = false
SettingPage.Parent = PagesContainer

-- ระบบสลับหน้า 5 แท็บ
local function ResetAllTabs()
    local allTabs = {
        {Btn = BtnHome, Stroke = HomeStroke, Page = HomePage},
        {Btn = ESPTabBtn, Stroke = ESPTabStroke, Page = ESPPage},
        {Btn = DocTabBtn, Stroke = DocTabStroke, Page = DocPage},
        {Btn = InfoTabBtn, Stroke = InfoTabStroke, Page = InfoPage},
        {Btn = SettingTabBtn, Stroke = SettingTabStroke, Page = SettingPage}
    }
    for _, tab in ipairs(allTabs) do
        tab.Page.Visible = false
        tab.Btn.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
        tab.Btn.TextColor3 = TextGray
        tab.Stroke.Color = Color3.fromRGB(50, 55, 65)
    end
end

BtnHome.MouseButton1Click:Connect(function() ResetAllTabs(); HomePage.Visible = true; BtnHome.BackgroundColor3 = PrimaryColor; BtnHome.TextColor3 = Color3.fromRGB(0,0,0); HomeStroke.Color = PrimaryColor end)
ESPTabBtn.MouseButton1Click:Connect(function() ResetAllTabs(); ESPPage.Visible = true; ESPTabBtn.BackgroundColor3 = PrimaryColor; ESPTabBtn.TextColor3 = Color3.fromRGB(0,0,0); ESPTabStroke.Color = PrimaryColor end)
DocTabBtn.MouseButton1Click:Connect(function() ResetAllTabs(); DocPage.Visible = true; DocTabBtn.BackgroundColor3 = PrimaryColor; DocTabBtn.TextColor3 = Color3.fromRGB(0,0,0); DocTabStroke.Color = PrimaryColor end)
InfoTabBtn.MouseButton1Click:Connect(function() ResetAllTabs(); InfoPage.Visible = true; InfoTabBtn.BackgroundColor3 = PrimaryColor; InfoTabBtn.TextColor3 = Color3.fromRGB(0,0,0); InfoTabStroke.Color = PrimaryColor end)
SettingTabBtn.MouseButton1Click:Connect(function() ResetAllTabs(); SettingPage.Visible = true; SettingTabBtn.BackgroundColor3 = PrimaryColor; SettingTabBtn.TextColor3 = Color3.fromRGB(0,0,0); SettingTabStroke.Color = PrimaryColor end)

-- ===== [ แถบ 📄 : Map Hub ] =====
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 26)
TopBar.BackgroundTransparency = 1
TopBar.Parent = DocPage

local MapDropdownBtn = Instance.new("TextButton")
MapDropdownBtn.Size = UDim2.new(0.5, -4, 1, 0)
MapDropdownBtn.BackgroundColor3 = FeatureBoxBg
MapDropdownBtn.Text = "เลือก Map ▼"
MapDropdownBtn.TextColor3 = TextWhite
MapDropdownBtn.TextSize = 11
MapDropdownBtn.Font = Enum.Font.GothamBold
MapDropdownBtn.Parent = TopBar
local mapDdCorner = Instance.new("UICorner") mapDdCorner.CornerRadius = UDim.new(0, 5) mapDdCorner.Parent = MapDropdownBtn

local ContactBtn = Instance.new("TextButton")
ContactBtn.Size = UDim2.new(0.5, -4, 1, 0)
ContactBtn.Position = UDim2.new(0.5, 4, 0, 0)
ContactBtn.BackgroundColor3 = PrimaryColor
ContactBtn.Text = "ช่องทางติดต่อ"
ContactBtn.TextColor3 = Color3.fromRGB(0,0,0)
ContactBtn.TextSize = 11
ContactBtn.Font = Enum.Font.GothamBold
ContactBtn.Parent = TopBar
local contactCorner = Instance.new("UICorner") contactCorner.CornerRadius = UDim.new(0, 5) contactCorner.Parent = ContactBtn

local MapList = Instance.new("ScrollingFrame")
MapList.Size = UDim2.new(0.5, -4, 0, 120)
MapList.Position = UDim2.new(0, 0, 0, 28)
MapList.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
MapList.BorderSizePixel = 1
MapList.BorderColor3 = PrimaryColor
MapList.Visible = false
MapList.ZIndex = 60
MapList.Parent = DocPage
local mapListCorner = Instance.new("UICorner") mapListCorner.CornerRadius = UDim.new(0, 5) mapListCorner.Parent = MapList
local mapListLayout = Instance.new("UIListLayout") mapListLayout.Parent = MapList

local ScriptListPanel = Instance.new("ScrollingFrame")
ScriptListPanel.Size = UDim2.new(1, 0, 1, -32)
ScriptListPanel.Position = UDim2.new(0, 0, 0, 32)
ScriptListPanel.BackgroundTransparency = 1
ScriptListPanel.BorderSizePixel = 0
ScriptListPanel.ScrollBarThickness = 2
ScriptListPanel.ScrollBarImageColor3 = PrimaryColor
ScriptListPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
ScriptListPanel.Parent = DocPage
local slpLayout = Instance.new("UIListLayout") slpLayout.Padding = UDim.new(0, 6) slpLayout.Parent = ScriptListPanel

-- ฟังก์ชันสร้างการ์ดสคริปต์ (คลิกการ์ดเพื่อโหลดสคริปต์ทันที)
local function renderScriptCard(titleText, creditText, scriptUrl, imageId, hasKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 60)
    btn.BackgroundColor3 = FeatureBoxBg
    btn.Text = ""
    btn.Parent = ScriptListPanel
    local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 6) btnCorner.Parent = btn
    local btnStroke = Instance.new("UIStroke") btnStroke.Color = Color3.fromRGB(45, 50, 60) btnStroke.Parent = btn

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, 45, 0, 45)
    img.Position = UDim2.new(0, 8, 0.5, -22.5)
    img.BackgroundColor3 = Color3.fromRGB(15, 17, 21)
    if imageId and imageId ~= "" then img.Image = "rbxassetid://" .. imageId end
    img.ScaleType = Enum.ScaleType.Crop
    img.Parent = btn
    local imgCorner = Instance.new("UICorner") imgCorner.CornerRadius = UDim.new(0, 4) imgCorner.Parent = img

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0.5, 0, 0, 20)
    nameLbl.Position = UDim2.new(0, 60, 0, 10)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = titleText
    nameLbl.TextColor3 = TextWhite
    nameLbl.TextSize = 13
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Parent = btn

    local creditLbl = Instance.new("TextLabel")
    creditLbl.Size = UDim2.new(0.5, 0, 0, 14)
    creditLbl.Position = UDim2.new(0, 60, 0, 32)
    creditLbl.BackgroundTransparency = 1
    creditLbl.Text = creditText
    creditLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    creditLbl.TextSize = 10
    creditLbl.Font = Enum.Font.Gotham
    creditLbl.TextXAlignment = Enum.TextXAlignment.Left
    creditLbl.Parent = btn

    -- ป้ายสถานะคีย์: ไม่มีคีย์=เขียว, มีคีย์=แดง
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(0, 65, 0, 28)
    statusLbl.Position = UDim2.new(1, -75, 0.5, -14)
    if hasKey then
        statusLbl.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        statusLbl.Text = "มีคีย์"
    else
        statusLbl.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        statusLbl.Text = "ไม่มีคีย์"
    end
    statusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLbl.TextSize = 11
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.Parent = btn
    local statusCorner = Instance.new("UICorner") statusCorner.CornerRadius = UDim.new(0, 4) statusCorner.Parent = statusLbl

    btn.MouseButton1Click:Connect(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "กำลังโหลด...", Text = "ดึงข้อมูล: " .. titleText, Duration = 3 })
        pcall(function() loadstring(game:HttpGet(scriptUrl))() end)
    end)
end

-- ฐานข้อมูลสคริปต์
local mapDatabase = {
    ["Monster Hunter"] = {
        {name = "Monster Hunter", credit = "by:TG:mick_2009", url = "https://pastefy.app/BBZJqV3Q/raw", image = "106291676248397", hasKey = false}
    },
    ["FPS MOVE"] = {
        {name = "FPS MOVE", credit = "by:TG:mick_2009", url = "https://pastefy.app/V2LUWyP5/raw", image = "131897810457113", hasKey = true}
    },
    ["Ability Arena"] = {
        {name = "Ability Arena", credit = "by:TG:mick_2009", url = "https://pastefy.app/HCmmUj6q/raw", image = "134304687191664", hasKey = true}
    }
}

local function loadMapData(mapName)
    MapDropdownBtn.Text = mapName .. " ▼"
    MapList.Visible = false

    for _, child in ipairs(ScriptListPanel:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    if mapDatabase[mapName] then
        for _, data in ipairs(mapDatabase[mapName]) do
            renderScriptCard(data.name, data.credit, data.url, data.image, data.hasKey)
        end
    end

    task.wait()
    ScriptListPanel.CanvasSize = UDim2.new(0, 0, 0, slpLayout.AbsoluteContentSize.Y + 10)
end

for mapName, _ in pairs(mapDatabase) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
    btn.Text = mapName
    btn.TextColor3 = TextWhite
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = MapList

    btn.MouseButton1Click:Connect(function()
        loadMapData(mapName)
    end)
end
MapList.CanvasSize = UDim2.new(0, 0, 0, mapListLayout.AbsoluteContentSize.Y)
MapDropdownBtn.MouseButton1Click:Connect(function() MapList.Visible = not MapList.Visible end)

loadMapData("Monster Hunter")

-- Contact Popup
local ContactPopup = Instance.new("Frame")
ContactPopup.Size = UDim2.new(0, 220, 0, 100)
ContactPopup.Position = UDim2.new(0.5, -110, 0.5, -50)
ContactPopup.BackgroundColor3 = BgDark
ContactPopup.Visible = false
ContactPopup.ZIndex = 100
ContactPopup.Parent = ScreenGui
local cpCorner = Instance.new("UICorner") cpCorner.CornerRadius = UDim.new(0, 10) cpCorner.Parent = ContactPopup
local cpStroke = Instance.new("UIStroke") cpStroke.Color = PrimaryColor cpStroke.Thickness = 1.5 cpStroke.Parent = ContactPopup

local CpTitle = Instance.new("TextLabel")
CpTitle.Size = UDim2.new(1, -30, 0, 30) CpTitle.Position = UDim2.new(0, 15, 0, 10)
CpTitle.BackgroundTransparency = 1 CpTitle.Text = "ช่องทางติดต่อ" CpTitle.TextColor3 = TextWhite CpTitle.TextSize = 14 CpTitle.Font = Enum.Font.GothamBold CpTitle.TextXAlignment = Enum.TextXAlignment.Left CpTitle.ZIndex = 101 CpTitle.Parent = ContactPopup

local CpCloseBtn = Instance.new("TextButton")
CpCloseBtn.Size = UDim2.new(0, 24, 0, 24) CpCloseBtn.Position = UDim2.new(1, -30, 0, 8)
CpCloseBtn.BackgroundColor3 = StatusRed CpCloseBtn.Text = "X" CpCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255) CpCloseBtn.TextSize = 12 CpCloseBtn.Font = Enum.Font.GothamBold CpCloseBtn.ZIndex = 101 CpCloseBtn.Parent = ContactPopup
local cpCloseCorner = Instance.new("UICorner") cpCloseCorner.CornerRadius = UDim.new(0, 6) cpCloseCorner.Parent = CpCloseBtn

local TgBtn = Instance.new("TextButton")
TgBtn.Size = UDim2.new(1, -30, 0, 35) TgBtn.Position = UDim2.new(0, 15, 0, 50)
TgBtn.BackgroundColor3 = Color3.fromRGB(0, 136, 204) TgBtn.Text = "Telegram : mick_2009" TgBtn.TextColor3 = Color3.fromRGB(255, 255, 255) TgBtn.TextSize = 12 TgBtn.Font = Enum.Font.GothamBold TgBtn.ZIndex = 101 TgBtn.Parent = ContactPopup
local tgCorner = Instance.new("UICorner") tgCorner.CornerRadius = UDim.new(0, 6) tgCorner.Parent = TgBtn

ContactBtn.MouseButton1Click:Connect(function() ContactPopup.Visible = true end)
CpCloseBtn.MouseButton1Click:Connect(function() ContactPopup.Visible = false end)
TgBtn.MouseButton1Click:Connect(function()
    pcall(function()
        setclipboard("https://t.me/mick_2009")
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "คัดลอกลิงก์แล้ว!", Text = "นำไปวางในเบราว์เซอร์เพื่อเข้าห้อง Telegram", Duration = 5})
    end)
end)
-- ===== TG_Mick_v5 Ultimate Combo (Part 7/9) =====
-- (ต่อจาก Part 6)

-- ===== [ แถบ ℹ️ : ข้อมูลผู้เล่น ] =====
local InfoScroll = Instance.new("ScrollingFrame")
InfoScroll.Size = UDim2.new(1, 0, 1, 0)
InfoScroll.BackgroundColor3 = PanelBg
InfoScroll.BorderSizePixel = 0
InfoScroll.ScrollBarThickness = 2
InfoScroll.ScrollBarImageColor3 = PrimaryColor
InfoScroll.CanvasSize = UDim2.new(0, 0, 0, 400)
InfoScroll.Parent = InfoPage
local infoCorner = Instance.new("UICorner") infoCorner.CornerRadius = UDim.new(0, 8) infoCorner.Parent = InfoScroll
local infoLayout = Instance.new("UIListLayout") infoLayout.Padding = UDim.new(0, 4) infoLayout.Parent = InfoScroll

local InfoLabels = {}
local function createInfoLabel(titleText, valueText)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -12, 0, 40)
    box.BackgroundColor3 = FeatureBoxBg
    box.Parent = InfoScroll
    local boxCorner = Instance.new("UICorner") boxCorner.CornerRadius = UDim.new(0, 6) boxCorner.Parent = box
    local boxStroke = Instance.new("UIStroke") boxStroke.Color = Color3.fromRGB(45, 50, 60) boxStroke.Parent = box

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 16) titleLbl.Position = UDim2.new(0, 10, 0, 4)
    titleLbl.BackgroundTransparency = 1 titleLbl.Text = titleText titleLbl.TextColor3 = Color3.fromRGB(150, 150, 150) titleLbl.TextSize = 10 titleLbl.Font = Enum.Font.GothamBold titleLbl.TextXAlignment = Enum.TextXAlignment.Left titleLbl.Parent = box

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, -20, 0, 16) valLbl.Position = UDim2.new(0, 10, 0, 20)
    valLbl.BackgroundTransparency = 1 valLbl.Text = valueText valLbl.TextColor3 = TextWhite valLbl.TextSize = 12 valLbl.Font = Enum.Font.GothamBold valLbl.TextXAlignment = Enum.TextXAlignment.Left valLbl.Parent = box
    return {Title = titleLbl, Value = valLbl}
end

pcall(function()
    table.insert(InfoLabels, createInfoLabel("ชื่อผู้เล่น (Username)", player.Name))
    table.insert(InfoLabels, createInfoLabel("รหัสผู้เล่น (User ID)", tostring(player.UserId)))
    local createdStr = "ไม่ทราบข้อมูล"
    pcall(function() local joinDate = player.AccountAge; local d = os.date("*t", os.time() - (joinDate * 86400)); createdStr = string.format("วันที่ %d เดือน %d ปี %d (เล่นมา %d วัน)", d.day, d.month, d.year, joinDate) end)
    table.insert(InfoLabels, createInfoLabel("สร้างบัญชีเมื่อ", createdStr))
    local isPremium = player.MembershipType == Enum.MembershipType.Premium
    table.insert(InfoLabels, createInfoLabel("สถานะพรีเมี่ยม", isPremium and "เป็นพรีเมี่ยม (Premium) 👑" or "ไม่ใช่พรีเมี่ยม"))
    local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    local playersCount = #game.Players:GetPlayers()
    local serverId = game.JobId
    table.insert(InfoLabels, createInfoLabel("ชื่อเซิร์ฟเวอร์ (Server)", placeName .. " [" .. (serverId ~= "" and "Public" or "Private") .. "]"))
    table.insert(InfoLabels, createInfoLabel("จำนวนผู้เล่นในเซิฟ", tostring(playersCount) .. " คน"))
    local osInfo, ramInfo, bitInfo = "ไม่ทราบข้อมูล", "ไม่ทราบข้อมูล", "ไม่ทราบข้อมูล"
    pcall(function()
        osInfo = game:GetService("UserInputService").TouchEnabled and "มือถือ / แท็บเล็ต (Mobile)" or "คอมพิวเตอร์ (PC)"
        ramInfo = string.format("%.2f MB (ใช้งานจริง)", game:GetService("Stats"):GetTotalMemoryUsageMb())
        bitInfo = game:GetService("UserInputService").KeyboardEnabled and "64-bit (PC / Console)" or "ARM (Mobile - รองรับ 32/64 bit ตามเครื่อง)"
    end)
    table.insert(InfoLabels, createInfoLabel("ระบบปฏิบัติการ (OS)", osInfo))
    table.insert(InfoLabels, createInfoLabel("หน่วยความจำ (RAM)", ramInfo))
    table.insert(InfoLabels, createInfoLabel("สถาปัตยกรรม (Bit)", bitInfo))
end)
InfoScroll.CanvasSize = UDim2.new(0, 0, 0, infoLayout.AbsoluteContentSize.Y + 10)

-- ===== [ แถบ ⚙️ : ตั้งค่า ] =====
local SettingScroll = Instance.new("ScrollingFrame")
SettingScroll.Size = UDim2.new(1, 0, 1, 0)
SettingScroll.BackgroundColor3 = PanelBg
SettingScroll.BorderSizePixel = 0
SettingScroll.ScrollBarThickness = 2
SettingScroll.ScrollBarImageColor3 = PrimaryColor
SettingScroll.CanvasSize = UDim2.new(0, 0, 0, 300)
SettingScroll.Parent = SettingPage
local setCorner = Instance.new("UICorner") setCorner.CornerRadius = UDim.new(0, 8) setCorner.Parent = SettingScroll
local setLayout = Instance.new("UIListLayout") setLayout.Padding = UDim.new(0, 6) setLayout.Parent = SettingScroll

local function createTelegramGroup(title, link, imageId)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -12, 0, 65)
    box.BackgroundColor3 = FeatureBoxBg
    box.Parent = SettingScroll
    local boxCorner = Instance.new("UICorner") boxCorner.CornerRadius = UDim.new(0, 6) boxCorner.Parent = box
    local boxStroke = Instance.new("UIStroke") boxStroke.Color = Color3.fromRGB(45, 50, 60) boxStroke.Parent = box

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, 45, 0, 45) img.Position = UDim2.new(0, 6, 0.5, -22.5)
    img.BackgroundColor3 = Color3.fromRGB(15, 17, 21) img.Image = "rbxassetid://" .. imageId img.ScaleType = Enum.ScaleType.Crop img.Parent = box
    local imgCorner = Instance.new("UICorner") imgCorner.CornerRadius = UDim.new(0, 6) imgCorner.Parent = img

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -120, 0, 20) nameLbl.Position = UDim2.new(0, 58, 0, 10)
    nameLbl.BackgroundTransparency = 1 nameLbl.Text = title nameLbl.TextColor3 = TextWhite nameLbl.TextSize = 13 nameLbl.Font = Enum.Font.GothamBold nameLbl.TextXAlignment = Enum.TextXAlignment.Left nameLbl.Parent = box

    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(0, 70, 0, 26) joinBtn.Position = UDim2.new(1, -78, 0.5, -13)
    joinBtn.BackgroundColor3 = Color3.fromRGB(0, 136, 204) joinBtn.Text = "เข้าร่วม" joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255) joinBtn.TextSize = 11 joinBtn.Font = Enum.Font.GothamBold joinBtn.Parent = box
    local joinCorner = Instance.new("UICorner") joinCorner.CornerRadius = UDim.new(0, 4) joinCorner.Parent = joinBtn

    joinBtn.MouseButton1Click:Connect(function()
        pcall(function()
            setclipboard(link)
            game:GetService("StarterGui"):SetCore("SendNotification", { Title = "คัดลอกลิงก์แล้ว!", Text = "ลิงก์กลุ่ม: " .. title, Duration = 5 })
        end)
    end)
end

local function createSettingBtn(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 40) btn.BackgroundColor3 = color btn.Text = text btn.TextColor3 = Color3.fromRGB(255, 255, 255) btn.TextSize = 13 btn.Font = Enum.Font.GothamBold btn.Parent = SettingScroll
    local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 6) btnCorner.Parent = btn
    btn.MouseButton1Click:Connect(callback)
end

createTelegramGroup("กลุ่ม Official", "https://t.me/phanto_official", "94766389472143")
createTelegramGroup("กลุ่มพูดคุย", "https://t.me/phan4", "109248063696059")

createSettingBtn("💾 เซฟเมนู", Color3.fromRGB(46, 204, 113), function()
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "เซฟเมนูสำเร็จ", Text = "บันทึกการตั้งค่าแล้ว", Duration = 3})
end)
createSettingBtn("🗑️ ลบเซฟเมนู", Color3.fromRGB(231, 76, 60), function()
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "ลบเซฟเมนูสำเร็จ", Text = "ล้างข้อมูลการตั้งค่าแล้ว", Duration = 3})
end)
createSettingBtn("🔄 เปลี่ยนเซิร์ฟเวอร์", Color3.fromRGB(52, 152, 219), function()
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "กำลังเปลี่ยนเซิร์ฟเวอร์...", Text = "กรุณารอสักครู่", Duration = 3})
    task.delay(1, function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, player) end) end)
end)

SettingScroll.CanvasSize = UDim2.new(0, 0, 0, setLayout.AbsoluteContentSize.Y + 10)
-- ===== TG_Mick_v5 Ultimate Combo (Part 8/9) =====
-- (ต่อจาก Part 7)

-- ===== ระบบ Auto-Farm (เพิ่มเข้าไปในเมนูหลัก) =====
local AutoClickEnabled = false
local AutoRebirthEnabled = false
local AutoAbilityEnabled = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClickEvent, AttackEvent, RebirthEvent, SpecialEvent
pcall(function()
    ClickEvent   = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Click")
    AttackEvent  = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AttackEnemy")
    RebirthEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Rebirth")
    SpecialEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SpecialAttack")
end)

local function getEnemyIds()
    local ids = {}
    local folder = workspace:FindFirstChild("ClientEnemies")
    if not folder then return ids end
    for _, obj in ipairs(folder:GetChildren()) do
        local num = tonumber(string.match(obj.Name, "^Enemy_(%d+)$"))
        if num then
            table.insert(ids, num)
        end
    end
    return ids
end

-- ระบบ Auto-Click
task.spawn(function()
    while true do
        task.wait(0.08)
        if AutoClickEnabled and ClickEvent then
            pcall(function() ClickEvent:FireServer() end)
        end
    end
end)

-- ระบบ Auto-Ability
task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoAbilityEnabled and SpecialEvent then
            local ids = getEnemyIds()
            if #ids > 0 then
                pcall(function() SpecialEvent:InvokeServer(ids[1], ids) end)
            end
        end
    end
end)

-- ระบบ Auto-Rebirth
task.spawn(function()
    while true do
        task.wait(1)
        if AutoRebirthEnabled and RebirthEvent then
            local pg = player:FindFirstChild("PlayerGui")
            local hud = pg and pg:FindFirstChild("HUD")
            local sideMenu = hud and hud:FindFirstChild("SideMenu")
            local tiles = sideMenu and sideMenu:FindFirstChild("Tiles")
            local rebirthBtn = tiles and tiles:FindFirstChild("RebirthButton")
            local percent = rebirthBtn and rebirthBtn:FindFirstChild("Percent")

            if percent and percent.Text == "100%" then
                pcall(function() RebirthEvent:InvokeServer() end)
                task.wait(2)
            end
        end
    end
end)

-- เพิ่มปุ่มควบคุม Auto-Farm ลงใน PanelLeft
createToggle(PanelLeft, "ออโต้ฟาร์ม (คลิก)", currentYLeft, function(s) AutoClickEnabled = s end)
currentYLeft = currentYLeft + 36
createToggle(PanelLeft, "ออโต้สกิล", currentYLeft, function(s) AutoAbilityEnabled = s end)
currentYLeft = currentYLeft + 36
createToggle(PanelLeft, "ออโต้รีเบอส", currentYLeft, function(s) AutoRebirthEnabled = s end)
currentYLeft = currentYLeft + 36

PanelLeft.CanvasSize = UDim2.new(0, 0, 0, currentYLeft + 8)
-- ===== TG_Mick_v5 Ultimate Combo (Part 9/9) =====
-- (ต่อจาก Part 8)

-- ===== ปิดท้ายสคริปต์ =====
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "โหลดเมนูสำเร็จ!",
        Text = "TG:mick_2009 Ultimate Combo พร้อมใช้งาน",
        Duration = 5
    })
end)

print("[TG Hub] โหลด TG_Mick_v5 Ultimate Combo สำเร็จ!")
print("[TG Hub] ระบบทั้งหมด: ฟิสิกส์, ESP, Map Hub, Auto-Farm ทำงานพร้อมกัน")