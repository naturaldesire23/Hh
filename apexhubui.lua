local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local KeyUI = Instance.new("ScreenGui")
KeyUI.Name = "ApexKeySystem"
KeyUI.ResetOnSpawn = false
KeyUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
KeyUI.Parent = (gethui and gethui() or CoreGui)

local MainWindow = Instance.new("Frame")
MainWindow.Size = UDim2.new(0, 350, 0, 180)
MainWindow.Position = UDim2.new(0.5, -175, 0.5, -90)
MainWindow.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
MainWindow.BorderSizePixel = 0
MainWindow.Parent = KeyUI

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainWindow

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 1.5
UIStroke.Parent = MainWindow
local StrokeGradient = Instance.new("UIGradient")
StrokeGradient.Rotation = 0
StrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 54, 62)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 150, 165)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 54, 62))
})
StrokeGradient.Parent = UIStroke

local BgGradient = Instance.new("UIGradient")
BgGradient.Rotation = 90
BgGradient.Color = ColorSequence.new(Color3.fromRGB(35, 37, 42), Color3.fromRGB(18, 19, 22))
BgGradient.Parent = MainWindow

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -20, 0, 40)
TitleLabel.Position = UDim2.new(0, 20, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamSemibold
TitleLabel.Text = "Apex Key System"
TitleLabel.TextColor3 = Color3.fromRGB(235, 237, 240)
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainWindow

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(1, -40, 0, 40)
KeyInput.Position = UDim2.new(0, 20, 0, 60)
KeyInput.BackgroundColor3 = Color3.fromRGB(28, 30, 35)
KeyInput.BorderSizePixel = 0
KeyInput.Font = Enum.Font.Gotham
KeyInput.PlaceholderText = "Enter Key..."
KeyInput.Text = ""
KeyInput.TextColor3 = Color3.fromRGB(235, 237, 240)
KeyInput.PlaceholderColor3 = Color3.fromRGB(150, 155, 165)
KeyInput.TextSize = 14
KeyInput.Parent = MainWindow

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = KeyInput

local InputStroke = Instance.new("UIStroke")
InputStroke.Thickness = 1
InputStroke.Color = Color3.fromRGB(60, 64, 72)
InputStroke.Parent = KeyInput

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Size = UDim2.new(1, -40, 0, 40)
SubmitBtn.Position = UDim2.new(0, 20, 0, 115)
SubmitBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 35)
SubmitBtn.BorderSizePixel = 0
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.Text = "Verify Key"
SubmitBtn.TextColor3 = Color3.fromRGB(235, 237, 240)
SubmitBtn.TextSize = 14
SubmitBtn.AutoButtonColor = false
SubmitBtn.Parent = MainWindow

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = SubmitBtn

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Thickness = 1
BtnStroke.Parent = SubmitBtn
local BtnStrokeGrad = Instance.new("UIGradient")
BtnStrokeGrad.Rotation = 0
BtnStrokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 54, 62)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 150, 165)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 54, 62))
})
BtnStrokeGrad.Parent = BtnStroke

local Dragging, DragInput, DragStart, StartPos
MainWindow.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = Input.Position
        StartPos = MainWindow.Position
        Input.Changed:Connect(function()
            if Input.UserInputState == Enum.UserInputState.End then Dragging = false end
        end)
    end
end)
MainWindow.InputChanged:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then DragInput = Input end
end)
UserInputService.InputChanged:Connect(function(Input)
    if Input == DragInput and Dragging then
        local Delta = Input.Position - DragStart
        TweenService:Create(MainWindow, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)}):Play()
    end
end)

SubmitBtn.MouseButton1Click:Connect(function()
    local key = KeyInput.Text
    if key == "ApexUI" then
        SubmitBtn.Text = "Verified"
        TweenService:Create(SubmitBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(TitleLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(KeyInput, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
        TweenService:Create(InputStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
        TweenService:Create(BtnStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
        TweenService:Create(UIStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
        
        task.wait(0.2)
        TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 350, 0, 0), BackgroundTransparency = 1}):Play()
        
        task.wait(0.3)
        MainWindow:Destroy()

        local NotifGui = Instance.new("ScreenGui")
        NotifGui.Name = "ApexNotifs"
        NotifGui.ResetOnSpawn = false
        NotifGui.Parent = (gethui and gethui() or CoreGui)
        local Notif = Instance.new("Frame")
        Notif.Size = UDim2.new(0, 240, 0, 70)
        Notif.Position = UDim2.new(1, -260, 0, 10)
        Notif.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
        Notif.BorderSizePixel = 0
        Notif.Parent = NotifGui
        local NCorner = Instance.new("UICorner")
        NCorner.CornerRadius = UDim.new(0, 6)
        NCorner.Parent = Notif
        local NTitle = Instance.new("TextLabel")
        NTitle.Size = UDim2.new(1, -20, 0, 20)
        NTitle.Position = UDim2.new(0, 14, 0, 14)
        NTitle.BackgroundTransparency = 1
        NTitle.Font = Enum.Font.GothamSemibold
        NTitle.Text = "Keys Verified"
        NTitle.TextColor3 = Color3.fromRGB(235, 237, 240)
        NTitle.TextSize = 14
        NTitle.TextXAlignment = Enum.TextXAlignment.Left
        NTitle.Parent = Notif
        local NDesc = Instance.new("TextLabel")
        NDesc.Size = UDim2.new(1, -20, 0, 20)
        NDesc.Position = UDim2.new(0, 14, 0, 36)
        NDesc.BackgroundTransparency = 1
        NDesc.Font = Enum.Font.Gotham
        NDesc.Text = "Loading ApexHub..."
        NDesc.TextColor3 = Color3.fromRGB(150, 155, 165)
        NDesc.TextSize = 13
        NDesc.TextXAlignment = Enum.TextXAlignment.Left
        NDesc.Parent = Notif

        Notif.Position = UDim2.new(1, 0, 0, 10)
        TweenService:Create(Notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -260, 0, 10)}):Play()

        task.delay(2, function()
            TweenService:Create(Notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, 20, 0, 10)}):Play()
            task.wait(0.3)
            NotifGui:Destroy()
        end)
        
        task.wait(1)
        local success, err = pcall(function()
            loadstring(game:HttpGet("YOUR_APEXHUB_RAW_URL_HERE"))()
        end)
        
        if not success then
            warn("Failed to load ApexHub: " .. tostring(err))
        end
    else
        TweenService:Create(MainWindow, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -165, 0.5, -90)}):Play()
        task.wait(0.05)
        TweenService:Create(MainWindow, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -185, 0.5, -90)}):Play()
        task.wait(0.05)
        TweenService:Create(MainWindow, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -175, 0.5, -90)}):Play()
        KeyInput.Text = "Invalid Key"
    end
end)
