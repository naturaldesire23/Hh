-- IceLib UI Library (Fully Functional - Fixed)
local UserInputService = cloneref and cloneref(game:GetService('UserInputService')) or game:GetService('UserInputService')
local TweenService = cloneref and cloneref(game:GetService('TweenService')) or game:GetService('TweenService')
local HttpService = cloneref and cloneref(game:GetService('HttpService')) or game:GetService('HttpService')
local TextService = cloneref and cloneref(game:GetService('TextService')) or game:GetService('TextService')
local RunService = cloneref and cloneref(game:GetService('RunService')) or game:GetService('RunService')
local Players = cloneref and cloneref(game:GetService('Players')) or game:GetService('Players')
local CoreGui = cloneref and cloneref(game:GetService('CoreGui')) or game:GetService('CoreGui')
local Debris = cloneref and cloneref(game:GetService('Debris')) or game:GetService('Debris')
local GuiService = cloneref and cloneref(game:GetService('GuiService')) or game:GetService('GuiService')

local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()

local old_IceLib = CoreGui:FindFirstChild('IceLib')
if old_IceLib then Debris:AddItem(old_IceLib, 0) end

pcall(function()
    if getgenv()._IceLib_Cleanup then
        getgenv()._IceLib_Cleanup()
        getgenv()._IceLib_Cleanup = nil
    end
end)

if not isfolder("IceLib") then makefolder("IceLib") end

local Connections = setmetatable({}, {
    __index = {
        disconnect = function(self, key)
            if self[key] then
                self[key]:Disconnect()
                self[key] = nil
            end
        end,
        disconnect_all = function(self)
            for k, v in pairs(self) do
                if type(v) ~= 'function' then
                    pcall(v.Disconnect, v)
                    self[k] = nil
                end
            end
        end
    }
})

local function convertStringToTable(inputString)
    local result = {}
    if type(inputString) ~= "string" then return result end
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        table.insert(result, trimmedValue)
    end
    return result
end

local function convertTableToString(inputTable)
    if type(inputTable) ~= "table" then return "" end
    return table.concat(inputTable, ", ")
end

local Config = setmetatable({
    save = function(self, file_name, config)
        local success, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            writefile('IceLib/'..file_name..'.json', flags)
        end)
        if not success then warn('Failed to save config', result) end
    end,
    load = function(self, file_name, config)
        local success, result = pcall(function()
            if not isfile('IceLib/'..file_name..'.json') then
                self:save(file_name, config)
                return
            end
            local flags = readfile('IceLib/'..file_name..'.json')
            if not flags then
                self:save(file_name, config)
                return
            end
            return HttpService:JSONDecode(flags)
        end)
        if not success then warn('Failed to load config', result) end
        if not result then result = { _flags = {}, _keybinds = {} } end
        return result
    end
}, Config)

-- Default Theme
local DefaultTheme = {
    Background = Color3.fromRGB(0, 0, 0),
    Group = Color3.fromRGB(20, 20, 20),
    GroupStroke = Color3.fromRGB(45, 45, 45),
    Control = Color3.fromRGB(30, 30, 30),
    ControlHover = Color3.fromRGB(40, 40, 40),
    Divider = Color3.fromRGB(35, 35, 35),
    Text = Color3.fromRGB(238, 238, 242),
    TextDim = Color3.fromRGB(142, 142, 151),
    TextSoft = Color3.fromRGB(195, 195, 202),
    Accent = Color3.fromRGB(224, 224, 224),
}

local Theme = {}
for k, v in pairs(DefaultTheme) do
    Theme[k] = typeof(v) == "Color3" and Color3.new(v.R, v.G, v.B) or v
end

local Library = {
    _config = Config:load(game.GameId, { _flags = {}, _keybinds = {} }),
    _choosing_keybind = false,
    _device = nil,
    _ui_open = true,
    _ui_scale = 1,
    _ui = nil,
    _dragging = false,
    _drag_start = nil,
    _container_position = nil,
    _flag_registry = {},
    _keybind_registry = {},
    _elements = {},
    _notif_side = "Right",
    _notif_opacity = 0.0,
    _keybind_list = {},
    _background = nil,
    _container = nil,
    _tab = 0
}
Library.__index = Library
Library.Connections = Connections

function Library.new()
    local self = setmetatable({ _tab = 0, _elements = {} }, Library)
    self:create_ui()
    return self
end

-- Notification System
local NotificationHost = Instance.new("ScreenGui")
NotificationHost.Name = "IceLibNotifications"
NotificationHost.ResetOnSpawn = false
NotificationHost.IgnoreGuiInset = true
NotificationHost.DisplayOrder = 101
NotificationHost.Parent = CoreGui

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "NotificationContainer"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y
NotificationContainer.Parent = NotificationHost

local UIListLayout_Notif = Instance.new("UIListLayout")
UIListLayout_Notif.FillDirection = Enum.FillDirection.Vertical
UIListLayout_Notif.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Notif.Padding = UDim.new(0, 8)
UIListLayout_Notif.Parent = NotificationContainer

function Library:SetNotificationSide(side)
    self._notif_side = side
    if side == "Left" then
        NotificationContainer.AnchorPoint = Vector2.new(0, 1)
        NotificationContainer.Position = UDim2.new(0, 22, 1, -22)
        UIListLayout_Notif.VerticalAlignment = Enum.VerticalAlignment.Bottom
    else
        NotificationContainer.AnchorPoint = Vector2.new(1, 1)
        NotificationContainer.Position = UDim2.new(1, -22, 1, -22)
        UIListLayout_Notif.VerticalAlignment = Enum.VerticalAlignment.Bottom
    end
end
Library:SetNotificationSide("Right")

function Library:Notify(settings)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 62)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 1, 0)
    InnerFrame.Position = UDim2.new(self._notif_side == "Left" and 1 or -1, -320, 0, 0)
    InnerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    InnerFrame.BackgroundTransparency = self._notif_opacity
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.ZIndex = 1
    InnerFrame.Parent = Notification

    local InnerGradient = Instance.new("UIGradient")
    InnerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(92, 92, 92)),
        ColorSequenceKeypoint.new(0.34, Color3.fromRGB(18, 18, 18)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    InnerGradient.Rotation = 90
    InnerGradient.Parent = InnerFrame

    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 8)
    InnerUICorner.Parent = InnerFrame

    local InnerStroke = Instance.new("UIStroke")
    InnerStroke.Color = Color3.fromRGB(255, 255, 255)
    InnerStroke.Transparency = 0.72
    InnerStroke.Thickness = 1
    InnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    InnerStroke.Parent = InnerFrame

    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or "Notification"
    Title.TextColor3 = Theme.Text
    Title.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    Title.TextSize = 16
    Title.Size = UDim2.new(1, -28, 0, 15)
    Title.Position = UDim2.new(0, 14, 0, 12)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextTruncate = Enum.TextTruncate.AtEnd
    Title.ZIndex = 2
    Title.Parent = InnerFrame

    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or "Notification message"
    Body.TextColor3 = Theme.TextDim
    Body.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    Body.TextSize = 14
    Body.Size = UDim2.new(1, -28, 0, 14)
    Body.Position = UDim2.new(0, 14, 0, 33)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Center
    Body.TextTruncate = Enum.TextTruncate.AtEnd
    Body.ZIndex = 2
    Body.Parent = InnerFrame

    task.spawn(function()
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        })
        tweenIn:Play()

        task.wait(settings.duration or 5)

        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(self._notif_side == "Left" and 1 or -1, -320, 0, 0)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        Notification:Destroy()
    end)
end

function Library:get_screen_scale()
    local viewport_size_x = workspace.CurrentCamera.ViewportSize.X
    self._ui_scale = viewport_size_x / 1400
end

function Library:get_device()
    local device = 'Unknown'
    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end
    self._device = device
end

function Library:removed(action)
    self._ui.AncestryChanged:Once(action)
end

function Library:flag_type(flag, flag_type)
    if Library._config._flags[flag] == nil then return end
    return typeof(Library._config._flags[flag]) == flag_type
end

function Library:remove_table_value(__table, table_value)
    for index, value in __table do
        if value ~= table_value then continue end
        table.remove(__table, index)
    end
end

function Library:hexToRGB(hex)
    hex = hex:gsub("#","")
    return Color3.fromRGB(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
end

function Library:rgbToHex(color)
    return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

function Library:SetBackground(source, transparency)
    if not self._background then return end
    if source and source ~= '' then
        self._background.Image = tostring(source)
        self._background.Visible = true
        self._background.ImageTransparency = transparency or 0.5
        self._background.ScaleType = Enum.ScaleType.Crop
    else
        self._background.Visible = false
    end
    self._config._flags['Background_Image'] = tostring(source or '')
    self._config._flags['Background_Transparency'] = transparency or 0.5
    Config:save(game.GameId, Library._config)
end

function Library:SetColor(key, color)
    Theme[key] = color
    for _, element in ipairs(self._elements or {}) do
        if element.tKey == key then
            if element.stateKey ~= nil then
                -- Skip state-based elements
            else
                pcall(function()
                    element.obj[element.prop] = color
                end)
            end
        end
    end
    self._config._flags['Theme_'..key] = self:rgbToHex(color)
    Config:save(game.GameId, Library._config)
end

function Library:GetColor(key)
    return Theme[key]
end

function Library:create_ui()
    local old = CoreGui:FindFirstChild('IceLib')
    if old then Debris:AddItem(old, 0) end

    local IceLibGui = Instance.new('ScreenGui')
    IceLibGui.ResetOnSpawn = false
    IceLibGui.Name = 'IceLib'
    IceLibGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    IceLibGui.Parent = CoreGui

    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0
    Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = IceLibGui

    local Background = Instance.new('ImageLabel')
    Background.Name = 'Background'
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.Position = UDim2.new(0, 0, 0, 0)
    Background.BackgroundTransparency = 1
    Background.BorderSizePixel = 0
    Background.Image = ''
    Background.ImageTransparency = 0.5
    Background.ScaleType = Enum.ScaleType.Crop
    Background.Visible = false
    Background.ZIndex = 0
    Background.Parent = Container

    local BackgroundCorner = Instance.new('UICorner')
    BackgroundCorner.CornerRadius = UDim.new(0, 10)
    BackgroundCorner.Parent = Background

    local ContainerGradient = Instance.new("UIGradient")
    ContainerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(92, 92, 92)),
        ColorSequenceKeypoint.new(0.34, Color3.fromRGB(18, 18, 18)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    ContainerGradient.Rotation = 90
    ContainerGradient.Parent = Container

    local ShadowHolder = Instance.new('Frame')
    ShadowHolder.Name = 'ShadowHolder'
    ShadowHolder.AnchorPoint = Container.AnchorPoint
    ShadowHolder.Position = Container.Position
    ShadowHolder.Size = Container.Size
    ShadowHolder.BackgroundTransparency = 1
    ShadowHolder.BorderSizePixel = 0
    ShadowHolder.ZIndex = 0
    ShadowHolder.Parent = IceLibGui

    Container:GetPropertyChangedSignal('Position'):Connect(function()
        ShadowHolder.Position = Container.Position
    end)
    Container:GetPropertyChangedSignal('Size'):Connect(function()
        ShadowHolder.Size = Container.Size
    end)

    local ShadowOuter = Instance.new('ImageLabel')
    ShadowOuter.Name = 'SoftShadowOuter'
    ShadowOuter.AnchorPoint = Vector2.new(0.5, 0.5)
    ShadowOuter.Position = UDim2.new(0.5, 0, 0.5, 2)
    ShadowOuter.Size = UDim2.new(1, 58, 1, 58)
    ShadowOuter.BackgroundTransparency = 1
    ShadowOuter.BorderSizePixel = 0
    ShadowOuter.Image = 'rbxassetid://6014261993'
    ShadowOuter.ImageColor3 = Color3.fromRGB(0, 0, 0)
    ShadowOuter.ImageTransparency = 0.43
    ShadowOuter.ScaleType = Enum.ScaleType.Slice
    ShadowOuter.SliceCenter = Rect.new(49, 49, 450, 450)
    ShadowOuter.ZIndex = 0
    ShadowOuter.Parent = ShadowHolder

    local ShadowInner = Instance.new('ImageLabel')
    ShadowInner.Name = 'SoftShadowInner'
    ShadowInner.AnchorPoint = Vector2.new(0.5, 0.5)
    ShadowInner.Position = UDim2.new(0.5, 0, 0.5, 1)
    ShadowInner.Size = UDim2.new(1, 32, 1, 32)
    ShadowInner.BackgroundTransparency = 1
    ShadowInner.BorderSizePixel = 0
    ShadowInner.Image = 'rbxassetid://6014261993'
    ShadowInner.ImageColor3 = Color3.fromRGB(0, 0, 0)
    ShadowInner.ImageTransparency = 0.30
    ShadowInner.ScaleType = Enum.ScaleType.Slice
    ShadowInner.SliceCenter = Rect.new(49, 49, 450, 450)
    ShadowInner.ZIndex = 0
    ShadowInner.Parent = ShadowHolder

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container

    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Theme.GroupStroke
    UIStroke.Transparency = 0.58
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container

    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 752, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container

    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0, 18, 0, 67)
    Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler

    local UIListLayout_Tabs = Instance.new('UIListLayout')
    UIListLayout_Tabs.Padding = UDim.new(0, 4)
    UIListLayout_Tabs.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout_Tabs.Parent = Tabs

    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Theme.Text
    ClientName.TextTransparency = 0
    ClientName.Text = 'IceLib'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 110, 0, 19)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0, 43, 0, 26)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.TextSize = 16
    ClientName.Parent = Handler
    table.insert(self._elements, {obj = ClientName, prop = "TextColor3", tKey = "Text"})

    local Logo = Instance.new('ImageLabel')
    Logo.Name = 'Logo'
    Logo.Size = UDim2.new(0, 26, 0, 26)
    Logo.AnchorPoint = Vector2.new(0, 0.5)
    Logo.Position = UDim2.new(0, 14, 0, 26)
    Logo.BackgroundTransparency = 1
    Logo.BorderSizePixel = 0
    Logo.Image = 'rbxassetid://119051552929078'
    Logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Logo.ImageTransparency = 0
    Logo.ScaleType = Enum.ScaleType.Fit
    Logo.Parent = Handler

    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0, 18, 0, 79)
    Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = Theme.Accent
    Pin.Parent = Handler
    table.insert(self._elements, {obj = Pin, prop = "BackgroundColor3", tKey = "Accent"})

    local PinCorner = Instance.new('UICorner')
    PinCorner.CornerRadius = UDim.new(1, 0)
    PinCorner.Parent = Pin

    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.65
    Divider.Position = UDim2.new(0, 164, 0, 75)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 330)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Theme.Divider
    Divider.Parent = Handler
    table.insert(self._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "Divider"})

    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler

    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.02, 0, 0.029, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler

    local Search = Instance.new('ImageButton')
    Search.Name = 'Search'
    Search.AutoButtonColor = false
    Search.BackgroundTransparency = 1
    Search.BorderSizePixel = 0
    Search.Image = 'rbxassetid://102373102520464'
    Search.ImageColor3 = Color3.fromRGB(188, 188, 188)
    Search.ImageTransparency = 0
    Search.ScaleType = Enum.ScaleType.Fit
    Search.AnchorPoint = Vector2.new(1, 0.5)
    Search.Position = UDim2.new(0, 734, 0, 26)
    Search.Size = UDim2.new(0, 22, 0, 22)
    Search.Parent = Handler

    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container

    self._ui = IceLibGui
    self._container = Container
    self._background = Background
    self._tabs = Tabs
    self._sections = Sections
    self._pin = Pin
    self._handler = Handler

    local function on_drag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position

            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                Connections:disconnect('container_input_ended')
                self._dragging = false
            end)
        end
    end

    local function update_drag(input)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(
            self._container_position.X.Scale,
            self._container_position.X.Offset + delta.X,
            self._container_position.Y.Scale,
            self._container_position.Y.Offset + delta.Y
        )
        TweenService:Create(Container, TweenInfo.new(0.2), { Position = position }):Play()
    end

    local function drag(input)
        if not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:change_visibility(state)
        Library._ui_open = state
        ShadowHolder.Visible = state
        if state then
            TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(752, 479)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end

    function self:load()
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale

            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end

        ShadowHolder.Visible = true

        TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(752, 479)
        }):Play()

        local saved_bg = self._config._flags['Background_Image']
        if saved_bg and saved_bg ~= '' then
            local trans = self._config._flags['Background_Transparency'] or 0.5
            self:SetBackground(saved_bg, trans)
        end

        for key, color in pairs(DefaultTheme) do
            local saved = self._config._flags['Theme_'..key]
            if saved then
                self:SetColor(key, self:hexToRGB(saved))
            end
        end
    end

    function self:update_tabs(tab)
        for _, object in self._tabs:GetChildren() do
            if object.Name ~= 'Tab' then continue end

            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * 42

                    TweenService:Create(self._pin, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 18, 0, 79 + offset)
                    }):Play()

                    TweenService:Create(object, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()

                    local textLabel = object:FindFirstChild("TextLabel")
                    if textLabel then
                        TweenService:Create(textLabel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            TextTransparency = 0,
                            TextColor3 = Theme.Text
                        }):Play()
                    end

                    local icon = object:FindFirstChild("Icon")
                    if icon then
                        TweenService:Create(icon, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            ImageColor3 = icon:GetAttribute('ActiveColor') or Theme.Text
                        }):Play()
                    end
                end
            else
                if object.BackgroundTransparency ~= 1 then
                    TweenService:Create(object, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 1
                    }):Play()

                    local textLabel = object:FindFirstChild("TextLabel")
                    if textLabel then
                        TweenService:Create(textLabel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            TextTransparency = 0,
                            TextColor3 = Theme.TextDim
                        }):Play()
                    end

                    local icon = object:FindFirstChild("Icon")
                    if icon then
                        TweenService:Create(icon, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            ImageColor3 = icon:GetAttribute('IdleColor') or Theme.TextDim
                        }):Play()
                    end
                end
            end
        end
    end

    function self:update_sections(left_section, right_section)
        for _, object in self._sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true
            else
                object.Visible = false
            end
        end
    end

    function self:create_tab(title, icon, icon_size, idle_color, active_color)
        local TabManager = {}

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000

        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not self._tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        Tab.Parent = self._tabs
        Tab.LayoutOrder = self._tab

        local TabCorner = Instance.new('UICorner')
        TabCorner.CornerRadius = UDim.new(0, 5)
        TabCorner.Parent = Tab

        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Theme.TextDim
        TextLabel.TextTransparency = 0
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0, 37, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.TextSize = 13
        TextLabel.Parent = Tab
        TextLabel.Name = 'TextLabel'
        table.insert(self._elements, {obj = TextLabel, prop = "TextColor3", tKey = "TextDim"})

        local Icon = Instance.new('ImageLabel')
        Icon.Name = 'Icon'
        Icon.Size = UDim2.new(0, icon_size or 16, 0, icon_size or 16)
        Icon.AnchorPoint = Vector2.new(0.5, 0.5)
        Icon.Position = UDim2.new(0, 19, 0.5, 0)
        Icon.BackgroundTransparency = 1
        Icon.BorderSizePixel = 0
        Icon.Image = icon or ''
        Icon.ImageColor3 = idle_color or Theme.TextDim
        Icon:SetAttribute('IdleColor', idle_color or Theme.TextDim)
        Icon:SetAttribute('ActiveColor', active_color or Theme.Text)
        Icon.ImageTransparency = 0
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.Size = UDim2.new(0, 243, 0, 395)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0)
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0, 203, 0, 67)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = self._sections

        local UIListLayout_L = Instance.new('UIListLayout')
        UIListLayout_L.Padding = UDim.new(0, 11)
        UIListLayout_L.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_L.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_L.Parent = LeftSection
        local UIPadding_L = Instance.new('UIPadding')
        UIPadding_L.PaddingTop = UDim.new(0, 1)
        UIPadding_L.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 395)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0, 474, 0, 67)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = self._sections

        local UIListLayout_R = Instance.new('UIListLayout')
        UIListLayout_R.Padding = UDim.new(0, 11)
        UIListLayout_R.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_R.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_R.Parent = RightSection

        local UIPadding_R = Instance.new('UIPadding')
        UIPadding_R.PaddingTop = UDim.new(0, 1)
        UIPadding_R.Parent = RightSection

        self._tab = self._tab + 1

        if first_tab then
            self:update_tabs(Tab)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:create_module(settings)
            local LayoutOrderModule = 0
            local ModuleManager = {
                _state = false,
                _size = 0,
                _multiplier = 0
            }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0
            Module.Position = UDim2.new(0.0041, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Theme.Group
            Module.Parent = settings.section
            if self._elements then
                table.insert(self._elements, {obj = Module, prop = "BackgroundColor3", tKey = "Group"})
            end

            local UIListLayout_Mod = Instance.new('UIListLayout')
            UIListLayout_Mod.Padding = UDim.new(0, 2)
            UIListLayout_Mod.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout_Mod.Parent = Module

            local ModuleCorner = Instance.new('UICorner')
            ModuleCorner.CornerRadius = UDim.new(0, 9)
            ModuleCorner.Parent = Module

            local ModuleStroke = Instance.new('UIStroke')
            ModuleStroke.Color = Theme.GroupStroke
            ModuleStroke.Transparency = 0.72
            ModuleStroke.Thickness = 1
            ModuleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            ModuleStroke.Parent = Module
            if self._elements then
                table.insert(self._elements, {obj = ModuleStroke, prop = "Color", tKey = "GroupStroke"})
            end

            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module

            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Theme.Text
            ModuleName.TextTransparency = 0
            ModuleName.Text = settings.title or "Module"
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 205, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0, 14, 0, 22)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.BorderSizePixel = 0
            ModuleName.TextSize = 13
            ModuleName.Parent = Header
            if self._elements then
                table.insert(self._elements, {obj = ModuleName, prop = "TextColor3", tKey = "Text"})
            end

            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Theme.TextDim
            Description.TextTransparency = 0
            Description.Text = settings.description or ''
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0, 14, 0, 40)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BorderSizePixel = 0
            Description.TextSize = 10
            Description.Parent = Header
            if self._elements then
                table.insert(self._elements, {obj = Description, prop = "TextColor3", tKey = "TextDim"})
            end

            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0
            Toggle.Position = UDim2.new(0, 229, 0, 76)
            Toggle.AnchorPoint = Vector2.new(1, 0.5)
            Toggle.Size = UDim2.new(0, 30, 0, 16)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Theme.Control
            Toggle.Parent = Header
            if self._elements then
                table.insert(self._elements, {obj = Toggle, prop = "BackgroundColor3", tKey = "Control", stateKey = false})
            end

            local ToggleCorner = Instance.new('UICorner')
            ToggleCorner.CornerRadius = UDim.new(1, 0)
            ToggleCorner.Parent = Toggle

            local Circle = Instance.new('Frame')
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0
            Circle.Position = UDim2.new(0, 2, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Theme.TextDim
            Circle.Parent = Toggle
            if self._elements then
                table.insert(self._elements, {obj = Circle, prop = "BackgroundColor3", tKey = "TextDim", stateKey = false})
            end

            local CircleCorner = Instance.new('UICorner')
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = Circle

            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.72
            Divider.Position = UDim2.new(0.5, 0, 0.62, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Theme.Divider
            Divider.Parent = Header
            if self._elements then
                table.insert(self._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "Divider"})
            end

            local Divider2 = Instance.new('Frame')
            Divider2.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider2.AnchorPoint = Vector2.new(0.5, 0)
            Divider2.BackgroundTransparency = 0.72
            Divider2.Position = UDim2.new(0.5, 0, 1, 0)
            Divider2.Name = 'Divider'
            Divider2.Size = UDim2.new(0, 241, 0, 1)
            Divider2.BorderSizePixel = 0
            Divider2.BackgroundColor3 = Theme.Divider
            Divider2.Parent = Header
            if self._elements then
                table.insert(self._elements, {obj = Divider2, prop = "BackgroundColor3", tKey = "Divider"})
            end

            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 2)
            Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout_Opts = Instance.new('UIListLayout')
            UIListLayout_Opts.Padding = UDim.new(0, 7)
            UIListLayout_Opts.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout_Opts.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout_Opts.Parent = Options

            function ModuleManager:change_state(state)
                self._state = state

                if self._state then
                    TweenService:Create(Module, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Accent
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Group,
                        Position = UDim2.new(1, -14, 0.5, 0)
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Control
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.TextDim,
                        Position = UDim2.new(0, 2, 0.5, 0)
                    }):Play()
                end

                Library._config._flags[settings.flag] = self._state
                settings.callback(self._state)
                Config:save(game.GameId, Library._config)
            end

            if Library._config._flags[settings.flag] == nil then
                Library._config._flags[settings.flag] = false
            end

            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = Library._config._flags[settings.flag]
                settings.callback(ModuleManager._state)

                if ModuleManager._state then
                    Toggle.BackgroundColor3 = Theme.Accent
                    Circle.BackgroundColor3 = Theme.Group
                    Circle.Position = UDim2.new(1, -14, 0.5, 0)
                else
                    Toggle.BackgroundColor3 = Theme.Control
                    Circle.BackgroundColor3 = Theme.TextDim
                    Circle.Position = UDim2.new(0, 2, 0.5, 0)
                end
            end

            Library._flag_registry[settings.flag] = function(state)
                ModuleManager:change_state(state)
            end

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            function ModuleManager:create_checkbox(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }

                if self._size == 0 then self._size = 11 end
                self._size = self._size + 28

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)

                local Row = Instance.new("TextButton")
                Row.Name = "ToggleRow"
                Row.Size = UDim2.new(0, 207, 0, 22)
                Row.BackgroundTransparency = 1
                Row.BorderSizePixel = 0
                Row.Text = ""
                Row.AutoButtonColor = false
                Row.Parent = Options
                Row.LayoutOrder = LayoutOrderModule

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                TitleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TitleLabel.TextSize = 12
                TitleLabel.TextColor3 = Theme.Text
                TitleLabel.Text = settings.title or "Toggle"
                TitleLabel.Size = UDim2.new(1, -64, 1, 0)
                TitleLabel.Position = UDim2.new(0, 0, 0, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
                TitleLabel.Parent = Row
                if self._elements then
                    table.insert(self._elements, {obj = TitleLabel, prop = "TextColor3", tKey = "Text"})
                end

                local Toggle = Instance.new("Frame")
                Toggle.Name = "Toggle"
                Toggle.Size = UDim2.fromOffset(31, 17)
                Toggle.Position = UDim2.new(1, 0, 0.5, 0)
                Toggle.AnchorPoint = Vector2.new(1, 0.5)
                Toggle.BackgroundColor3 = Theme.Control
                Toggle.BorderSizePixel = 0
                Toggle.Parent = Row
                if self._elements then
                    table.insert(self._elements, {obj = Toggle, prop = "BackgroundColor3", tKey = "Control", stateKey = false})
                end

                local ToggleStroke = Instance.new("UIStroke")
                ToggleStroke.Color = Theme.GroupStroke
                ToggleStroke.Transparency = 0.62
                ToggleStroke.Thickness = 1
                ToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ToggleStroke.Parent = Toggle
                if self._elements then
                    table.insert(self._elements, {obj = ToggleStroke, prop = "Color", tKey = "GroupStroke"})
                end

                local ToggleCorner = Instance.new("UICorner")
                ToggleCorner.CornerRadius = UDim.new(1, 0)
                ToggleCorner.Parent = Toggle

                local Knob = Instance.new("Frame")
                Knob.Name = "Knob"
                Knob.Size = UDim2.fromOffset(13, 13)
                Knob.Position = UDim2.new(0, 2, 0.5, 0)
                Knob.AnchorPoint = Vector2.new(0, 0.5)
                Knob.BackgroundColor3 = Theme.TextDim
                Knob.BorderSizePixel = 0
                Knob.Parent = Toggle
                if self._elements then
                    table.insert(self._elements, {obj = Knob, prop = "BackgroundColor3", tKey = "TextDim", stateKey = false})
                end

                local KnobCorner = Instance.new("UICorner")
                KnobCorner.CornerRadius = UDim.new(1, 0)
                KnobCorner.Parent = Knob

                function CheckboxManager:change_state(state)
                    self._state = state
                    TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = state and Theme.Accent or Theme.Control
                    }):Play()
                    TweenService:Create(Knob, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = state and Theme.Group or Theme.TextDim,
                        Position = state and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                    }):Play()
                    Library._config._flags[settings.flag] = self._state
                    settings.callback(self._state)
                    Config:save(game.GameId, Library._config)
                end

                if Library._config._flags[settings.flag] == nil then
                    Library._config._flags[settings.flag] = false
                end

                if Library:flag_type(settings.flag, "boolean") then
                    CheckboxManager._state = Library._config._flags[settings.flag]
                    if CheckboxManager._state then
                        Toggle.BackgroundColor3 = Theme.Accent
                        Knob.BackgroundColor3 = Theme.Group
                        Knob.Position = UDim2.new(1, -15, 0.5, 0)
                    else
                        Toggle.BackgroundColor3 = Theme.Control
                        Knob.BackgroundColor3 = Theme.TextDim
                        Knob.Position = UDim2.new(0, 2, 0.5, 0)
                    end
                    settings.callback(CheckboxManager._state)
                end

                Library._flag_registry[settings.flag] = function(state)
                    CheckboxManager:change_state(state)
                end

                Row.MouseButton1Click:Connect(function()
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)

                return CheckboxManager
            end

            function ModuleManager:create_slider(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local SliderManager = {}

                if self._size == 0 then self._size = 11 end
                self._size = self._size + 40

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)

                local Slider = Instance.new('TextButton')
                Slider.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Slider.TextSize = 14
                Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 33)
                Slider.BorderSizePixel = 0
                Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule

                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TextLabel.TextSize = 12
                TextLabel.TextColor3 = Theme.Text
                TextLabel.TextTransparency = 0
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 160, 0, 14)
                TextLabel.Position = UDim2.new(0, 0, 0, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Slider
                if self._elements then
                    table.insert(self._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})
                end

                local Drag = Instance.new('Frame')
                Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0
                Drag.Position = UDim2.new(0.5, 0, 0.94, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 6)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Theme.Group
                Drag.Parent = Slider
                if self._elements then
                    table.insert(self._elements, {obj = Drag, prop = "BackgroundColor3", tKey = "Group"})
                end

                local DragCorner = Instance.new('UICorner')
                DragCorner.CornerRadius = UDim.new(1, 0)
                DragCorner.Parent = Drag

                local Fill = Instance.new('Frame')
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 6)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Theme.Accent
                Fill.Parent = Drag
                if self._elements then
                    table.insert(self._elements, {obj = Fill, prop = "BackgroundColor3", tKey = "Accent"})
                end

                local FillCorner = Instance.new('UICorner')
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill

                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Circle.Size = UDim2.new(0, 10, 0, 10)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Theme.Accent
                Circle.Parent = Fill
                if self._elements then
                    table.insert(self._elements, {obj = Circle, prop = "BackgroundColor3", tKey = "Accent"})
                end

                local CircleCorner = Instance.new('UICorner')
                CircleCorner.CornerRadius = UDim.new(1, 0)
                CircleCorner.Parent = Circle

                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Theme.TextSoft
                Value.TextTransparency = 0.2
                Value.Text = '50'
                Value.Name = 'Value'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.BorderSizePixel = 0
                Value.TextSize = 10
                Value.Parent = Slider
                if self._elements then
                    table.insert(self._elements, {obj = Value, prop = "TextColor3", tKey = "TextSoft"})
                end

                function SliderManager:set_percentage(percentage)
                    local rounded_number = 0
                    if settings.round_number then
                        rounded_number = math.floor(percentage)
                    else
                        rounded_number = math.floor(percentage * 10) / 10
                    end

                    percentage = (percentage - settings.minimum_value) / (settings.maximum_value - settings.minimum_value)
                    local slider_size = math.clamp(percentage, 0.02, 1) * 207
                    local number_threshold = math.clamp(rounded_number, settings.minimum_value, settings.maximum_value)

                    Library._config._flags[settings.flag] = number_threshold
                    Value.Text = tostring(number_threshold)

                    TweenService:Create(Fill, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, 6)
                    }):Play()

                    settings.callback(number_threshold)
                    Config:save(game.GameId, Library._config)
                end

                function SliderManager:update()
                    local mouse_pos = (mouse.X - Drag.AbsolutePosition.X) / 207
                    local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_pos
                    self:set_percentage(percentage)
                end

                function SliderManager:input()
                    SliderManager:update()
                    Connections['slider_drag_'..settings.flag] = mouse.Move:Connect(function()
                        SliderManager:update()
                    end)
                    Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                        Connections:disconnect('slider_drag_'..settings.flag)
                        Connections:disconnect('slider_input_'..settings.flag)
                    end)
                end

                if Library:flag_type(settings.flag, 'number') then
                    if not settings.ignoresaved then
                        SliderManager:set_percentage(Library._config._flags[settings.flag])
                    else
                        SliderManager:set_percentage(settings.value)
                    end
                else
                    SliderManager:set_percentage(settings.value)
                end

                Slider.MouseButton1Down:Connect(function()
                    SliderManager:input()
                end)

                Library._flag_registry[settings.flag] = function(value)
                    SliderManager:set_percentage(value)
                end

                return SliderManager
            end

            function ModuleManager:create_button(settings)
                LayoutOrderModule = LayoutOrderModule + 1

                if self._size == 0 then self._size = 11 end
                self._size = self._size + 29

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                end
                Options.Size = UDim2.fromOffset(241, self._size + self._multiplier)

                local Holder = Instance.new('Frame')
                Holder.Name = 'ButtonHolder'
                Holder.Size = UDim2.fromOffset(207, 23)
                Holder.BackgroundTransparency = 1
                Holder.BorderSizePixel = 0
                Holder.LayoutOrder = LayoutOrderModule
                Holder.Parent = Options

                local Btn = Instance.new('TextButton')
                Btn.Name = 'Button'
                Btn.AnchorPoint = Vector2.new(0, 1)
                Btn.Position = UDim2.new(0, 0, 1, 0)
                Btn.Size = UDim2.fromOffset(207, 22)
                Btn.BackgroundColor3 = Theme.Control
                Btn.BorderSizePixel = 0
                Btn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Btn.TextColor3 = Theme.Text
                Btn.TextSize = 12
                Btn.AutoButtonColor = false
                Btn.Text = settings.title
                Btn.Parent = Holder
                if self._elements then
                    table.insert(self._elements, {obj = Btn, prop = "BackgroundColor3", tKey = "Control"})
                    table.insert(self._elements, {obj = Btn, prop = "TextColor3", tKey = "Text"})
                end

                local BtnCorner = Instance.new('UICorner')
                BtnCorner.CornerRadius = UDim.new(0, 4)
                BtnCorner.Parent = Btn

                local BtnStroke = Instance.new('UIStroke')
                BtnStroke.Color = Theme.GroupStroke
                BtnStroke.Transparency = 0.72
                BtnStroke.Thickness = 1
                BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                BtnStroke.Parent = Btn
                if self._elements then
                    table.insert(self._elements, {obj = BtnStroke, prop = "Color", tKey = "GroupStroke"})
                end

                Btn.MouseButton1Click:Connect(settings.callback)
            end

            function ModuleManager:create_input(settings)
                LayoutOrderModule = LayoutOrderModule + 1

                if self._size == 0 then self._size = 11 end
                self._size = self._size + 29

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                end
                Options.Size = UDim2.fromOffset(241, self._size + self._multiplier)

                local Holder = Instance.new('Frame')
                Holder.Name = 'TextboxHolder'
                Holder.Size = UDim2.fromOffset(207, 23)
                Holder.BackgroundTransparency = 1
                Holder.BorderSizePixel = 0
                Holder.LayoutOrder = LayoutOrderModule
                Holder.Parent = Options

                local Box = Instance.new('TextBox')
                Box.Name = 'TextBox'
                Box.AnchorPoint = Vector2.new(0, 1)
                Box.Position = UDim2.new(0, 0, 1, 0)
                Box.Size = UDim2.fromOffset(207, 22)
                Box.BackgroundColor3 = Theme.Control
                Box.BorderSizePixel = 0
                Box.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Box.TextColor3 = Theme.Text
                Box.TextSize = 12
                Box.PlaceholderText = settings.placeholder or ''
                Box.PlaceholderColor3 = Theme.TextDim
                Box.ClearTextOnFocus = false
                Box.Parent = Holder
                if self._elements then
                    table.insert(self._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Control"})
                    table.insert(self._elements, {obj = Box, prop = "TextColor3", tKey = "Text"})
                    table.insert(self._elements, {obj = Box, prop = "PlaceholderColor3", tKey = "TextDim"})
                end

                -- FIX: Ensure Box.Text is always a string
                if Library._config._flags[settings.flag] ~= nil then
                    Box.Text = tostring(Library._config._flags[settings.flag])
                else
                    Box.Text = tostring(settings.value or '')
                end

                local BoxCorner = Instance.new('UICorner')
                BoxCorner.CornerRadius = UDim.new(0, 4)
                BoxCorner.Parent = Box

                local BoxStroke = Instance.new('UIStroke')
                BoxStroke.Color = Theme.GroupStroke
                BoxStroke.Transparency = 0.72
                BoxStroke.Thickness = 1
                BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                BoxStroke.Parent = Box
                if self._elements then
                    table.insert(self._elements, {obj = BoxStroke, prop = "Color", tKey = "GroupStroke"})
                end

                Box.FocusLost:Connect(function()
                    Library._config._flags[settings.flag] = Box.Text
                    settings.callback(Box.Text)
                    Config:save(game.GameId, Library._config)
                end)

                Library._flag_registry[settings.flag] = function(value)
                    Box.Text = tostring(value or '')
                end

                return Box
            end

            function ModuleManager:create_dropdown(settings)
                if not settings.Order then
                    LayoutOrderModule = LayoutOrderModule + 1
                end

                local DropdownManager = { _state = false, _size = 0 }

                if not settings.Order then
                    if self._size == 0 then self._size = 11 end
                    self._size = self._size + 53
                end

                if not settings.Order then
                    if ModuleManager._state then
                        Module.Size = UDim2.fromOffset(241, 93 + self._size)
                    end
                    Options.Size = UDim2.fromOffset(241, self._size)
                end

                local Dropdown = Instance.new('TextButton')
                Dropdown.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Text = ''
                Dropdown.AutoButtonColor = false
                Dropdown.BackgroundTransparency = 1
                Dropdown.Name = 'Dropdown'
                Dropdown.Size = UDim2.new(0, 210, 0, 45)
                Dropdown.BorderSizePixel = 0
                Dropdown.TextSize = 14
                Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Parent = Options

                if not settings.Order then
                    Dropdown.LayoutOrder = LayoutOrderModule
                else
                    Dropdown.LayoutOrder = settings.OrderValue
                end

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {}
                end

                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TextLabel.TextSize = 11
                TextLabel.TextColor3 = Theme.Text
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.Parent = Dropdown
                if self._elements then
                    table.insert(self._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})
                end

                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0
                Box.Position = UDim2.new(0.5, 0, 1.3, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 210, 0, 28)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Theme.Control
                Box.Parent = TextLabel
                if self._elements then
                    table.insert(self._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Control"})
                end

                local BoxCorner = Instance.new('UICorner')
                BoxCorner.CornerRadius = UDim.new(0, 5)
                BoxCorner.Parent = Box

                local BoxStroke = Instance.new('UIStroke')
                BoxStroke.Color = Theme.GroupStroke
                BoxStroke.Transparency = 0.48
                BoxStroke.Thickness = 1
                BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                BoxStroke.Parent = Box
                if self._elements then
                    table.insert(self._elements, {obj = BoxStroke, prop = "Color", tKey = "GroupStroke"})
                end

                local Header = Instance.new('Frame')
                Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Header.AnchorPoint = Vector2.new(0.5, 0)
                Header.BackgroundTransparency = 1
                Header.Position = UDim2.new(0.5, 0, 0, 0)
                Header.Name = 'Header'
                Header.Size = UDim2.new(0, 210, 0, 28)
                Header.BorderSizePixel = 0
                Header.Parent = Box

                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Theme.Text
                CurrentOption.TextTransparency = 0
                CurrentOption.Name = 'CurrentOption'
                CurrentOption.Size = UDim2.new(0, 164, 0, 16)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0, 10, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.BorderSizePixel = 0
                CurrentOption.TextSize = 11
                CurrentOption.Parent = Header
                if self._elements then
                    table.insert(self._elements, {obj = CurrentOption, prop = "TextColor3", tKey = "Text"})
                end

                local Arrow = Instance.new('ImageLabel')
                Arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.ImageColor3 = Theme.TextDim
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(1, -16, 0.5, 0)
                Arrow.Name = 'Arrow'
                Arrow.Size = UDim2.new(0, 9, 0, 9)
                Arrow.BorderSizePixel = 0
                Arrow.Parent = Header
                if self._elements then
                    table.insert(self._elements, {obj = Arrow, prop = "ImageColor3", tKey = "TextDim"})
                end

                local OptionsList = Instance.new('ScrollingFrame')
                OptionsList.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
                OptionsList.Active = true
                OptionsList.ScrollBarImageTransparency = 1
                OptionsList.AutomaticCanvasSize = Enum.AutomaticSize.XY
                OptionsList.ScrollBarThickness = 0
                OptionsList.Name = 'Options'
                OptionsList.Size = UDim2.new(0, 207, 0, 0)
                OptionsList.BackgroundTransparency = 1
                OptionsList.Position = UDim2.new(0, 0, 1, 0)
                OptionsList.BorderColor3 = Color3.fromRGB(0, 0, 0)
                OptionsList.BorderSizePixel = 0
                OptionsList.CanvasSize = UDim2.new(0, 0, 0.5, 0)
                OptionsList.Parent = Box

                local OptionsLayout = Instance.new('UIListLayout')
                OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                OptionsLayout.Parent = OptionsList

                local OptionsPadding = Instance.new('UIPadding')
                OptionsPadding.PaddingTop = UDim.new(0, 4)
                OptionsPadding.PaddingLeft = UDim.new(0, 11)
                OptionsPadding.Parent = OptionsList

                function DropdownManager:update(option)
                    if settings.multi_dropdown then
                        if not Library._config._flags[settings.flag] then
                            Library._config._flags[settings.flag] = {}
                        end

                        local CurrentTargetValue = nil
                        if #Library._config._flags[settings.flag] > 0 then
                            CurrentTargetValue = convertTableToString(Library._config._flags[settings.flag])
                        end

                        local selected = {}
                        if CurrentTargetValue then
                            for value in string.gmatch(CurrentTargetValue, "([^,]+)") do
                                local trimmedValue = value:match("^%s*(.-)%s*$")
                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        else
                            for value in string.gmatch(CurrentOption.Text, "([^,]+)") do
                                local trimmedValue = value:match("^%s*(.-)%s*$")
                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        end

                        local CurrentTextGet = convertStringToTable(CurrentOption.Text)
                        local optionSkibidi = typeof(option) ~= 'string' and option.Name or option

                        for i, v in pairs(CurrentTextGet) do
                            if v == optionSkibidi then
                                table.remove(CurrentTextGet, i)
                                break
                            end
                        end

                        CurrentOption.Text = table.concat(selected, ", ")
                        local OptionsChild = {}

                        for _, object in OptionsList:GetChildren() do
                            if object.Name == "Option" then
                                table.insert(OptionsChild, object.Text)
                                if table.find(selected, object.Text) then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end

                        CurrentTargetValue = convertStringToTable(CurrentOption.Text)
                        for _, v in CurrentTargetValue do
                            if not table.find(OptionsChild, v) and table.find(selected, v) then
                                table.remove(selected, _)
                            end
                        end

                        CurrentOption.Text = table.concat(selected, ", ")
                        Library._config._flags[settings.flag] = convertStringToTable(CurrentOption.Text)
                    else
                        CurrentOption.Text = (typeof(option) == "string" and option) or (option and option.Name) or ''
                        for _, object in OptionsList:GetChildren() do
                            if object.Name == "Option" then
                                object.TextTransparency = object.Text == CurrentOption.Text and 0.2 or 0.6
                            end
                        end
                        Library._config._flags[settings.flag] = option
                    end

                    settings.callback(option)
                    Config:save(game.GameId, Library._config)
                end

                function DropdownManager:unfold_settings()
                    self._state = not self._state
                    local extra = self._state and self._size or 0

                    if self._state then
                        ModuleManager._multiplier = ModuleManager._multiplier + self._size
                    else
                        ModuleManager._multiplier = ModuleManager._multiplier - self._size
                    end

                    TweenService:Create(Module, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                    }):Play()

                    TweenService:Create(Module.Options, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                    }):Play()

                    TweenService:Create(Dropdown, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(210, 45 + extra)
                    }):Play()

                    TweenService:Create(Box, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(210, 28 + extra)
                    }):Play()

                    TweenService:Create(Arrow, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Rotation = self._state and 180 or 0
                    }):Play()
                end

                if #settings.options > 0 then
                    DropdownManager._size = 8
                    for index, value in settings.options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = false
                        Option.TextTransparency = 0.32
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 11
                        Option.Size = UDim2.new(0, 184, 0, 19)
                        Option.TextColor3 = Theme.Text
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.Text = (typeof(value) == "string" and value) or value.Name
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.BorderSizePixel = 0
                        Option.Parent = OptionsList
                        if self._elements then
                            table.insert(self._elements, {obj = Option, prop = "TextColor3", tKey = "Text"})
                        end

                        Option.MouseButton1Click:Connect(function()
                            if not Library._config._flags[settings.flag] then
                                Library._config._flags[settings.flag] = {}
                            end

                            if settings.multi_dropdown then
                                if table.find(Library._config._flags[settings.flag], value) then
                                    Library:remove_table_value(Library._config._flags[settings.flag], value)
                                else
                                    table.insert(Library._config._flags[settings.flag], value)
                                end
                            end

                            DropdownManager:update(value)
                        end)

                        if settings.maximum_options and index > settings.maximum_options then continue end
                        DropdownManager._size = DropdownManager._size + 19
                        OptionsList.Size = UDim2.fromOffset(210, DropdownManager._size)
                    end
                end

                if Library:flag_type(settings.flag, 'string') or Library:flag_type(settings.flag, 'table') then
                    DropdownManager:update(Library._config._flags[settings.flag])
                elseif settings.options[1] then
                    DropdownManager:update(settings.options[1])
                end

                Dropdown.MouseButton1Click:Connect(function()
                    DropdownManager:unfold_settings()
                end)

                Library._flag_registry[settings.flag] = function(value)
                    DropdownManager:update(value)
                end

                return DropdownManager
            end

            function ModuleManager:create_divider(settings)
                LayoutOrderModule = LayoutOrderModule + 1

                if self._size == 0 then self._size = 11 end
                self._size = self._size + 27

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)

                local OuterFrame = Instance.new('Frame')
                OuterFrame.Size = UDim2.new(0, 207, 0, 20)
                OuterFrame.BackgroundTransparency = 1
                OuterFrame.Name = 'OuterFrame'
                OuterFrame.Parent = Options
                OuterFrame.LayoutOrder = LayoutOrderModule

                if settings and settings.title then
                    local TextLabel = Instance.new('TextLabel')
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextColor3 = Theme.Text
                    TextLabel.TextTransparency = 0
                    TextLabel.Text = settings.title
                    TextLabel.Size = UDim2.new(0, 153, 0, 13)
                    TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
                    TextLabel.BackgroundTransparency = 1
                    TextLabel.TextXAlignment = Enum.TextXAlignment.Center
                    TextLabel.BorderSizePixel = 0
                    TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                    TextLabel.TextSize = 11
                    TextLabel.ZIndex = 3
                    TextLabel.Parent = OuterFrame
                    if self._elements then
                        table.insert(self._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})
                    end
                end

                if not settings or not settings.disableline then
                    local Divider = Instance.new('Frame')
                    Divider.Size = UDim2.new(1, 0, 0, 1)
                    Divider.BackgroundColor3 = Theme.Divider
                    Divider.BorderSizePixel = 0
                    Divider.Name = 'Divider'
                    Divider.Parent = OuterFrame
                    Divider.ZIndex = 2
                    Divider.Position = UDim2.new(0, 0, 0.5, -0.5)
                    if self._elements then
                        table.insert(self._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "Divider"})
                    end

                    local Gradient = Instance.new('UIGradient')
                    Gradient.Parent = Divider
                    Gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255, 0))
                    })
                    Gradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    Gradient.Rotation = 0
                end

                return true
            end

            return ModuleManager
        end

        return TabManager
    end

    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightControl then
            self._ui_open = not self._ui_open
            self:change_visibility(self._ui_open)
        end
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visibility(self._ui_open)
    end)

    return self
end

-- Build Interface Tab with Background and Appearance controls
function Library:build_interface_tab()
    local InterfaceTab = self:create_tab('Interface', 'rbxassetid://94381583400007', 16, Color3.fromRGB(100, 100, 100), Color3.fromRGB(190, 190, 190))

    -- Background Module
    local bg_module = InterfaceTab:create_module({
        title = 'Background',
        flag = 'UI_Background',
        description = 'Set custom background image',
        section = 'left',
        callback = function(state)
            if not self._background then return end
            self._background.Visible = state
        end
    })

    bg_module:create_input({
        title = 'Image URL/ID',
        flag = 'Background_Input',
        placeholder = 'Asset ID or image URL',
        value = self._config._flags['Background_Image'] or '',
        callback = function(value)
            if value and value ~= '' then
                local trans = self._config._flags['Background_Transparency'] or 0.5
                self:SetBackground(value, trans)
            end
        end
    })

    bg_module:create_slider({
        title = 'Transparency',
        flag = 'Background_Transparency',
        minimum_value = 0,
        maximum_value = 100,
        value = (self._config._flags['Background_Transparency'] or 0.5) * 100,
        round_number = true,
        callback = function(value)
            if self._background and self._background.Image and self._background.Image ~= '' then
                self._background.ImageTransparency = value / 100
                self._config._flags['Background_Transparency'] = value / 100
                Config:save(game.GameId, Library._config)
            end
        end
    })

    bg_module:create_button({
        title = 'Reset Background',
        callback = function()
            if self._background then
                self._background.Image = ''
                self._background.Visible = false
                self._config._flags['Background_Image'] = ''
                self._config._flags['Background_Transparency'] = 0.5
                Config:save(game.GameId, Library._config)
                self:Notify({title = 'Background', text = 'Background reset', duration = 2})
            end
        end
    })

    -- Appearance Module
    local appearance_module = InterfaceTab:create_module({
        title = 'Appearance',
        flag = 'UI_Appearance',
        description = 'Customize UI colors',
        section = 'right',
        callback = function(state) end
    })

    local color_targets = {
        'Text', 'TextDim', 'TextSoft',
        'Accent', 'Group', 'Control', 'Divider'
    }

    for _, target in ipairs(color_targets) do
        appearance_module:create_button({
            title = target,
            callback = function()
                local color = Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(100, 255))
                self:SetColor(target, color)
                self:Notify({title = 'Color', text = target..' set to '..self:rgbToHex(color), duration = 2})
            end
        })
    end

    appearance_module:create_button({
        title = 'Reset Colors',
        callback = function()
            for key, color in pairs(DefaultTheme) do
                if typeof(color) == "Color3" then
                    self:SetColor(key, color)
                end
            end
            self:Notify({title = 'Appearance', text = 'Colors reset to default', duration = 2})
        end
    })

    return InterfaceTab
end

return Library
