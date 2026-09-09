-- Sakura UI Library (Cleaned, No Game Logic, No Hardcoded Colors)
local UserInputService = cloneref and cloneref(game:GetService('UserInputService')) or game:GetService('UserInputService')
local ContentProvider = cloneref and cloneref(game:GetService('ContentProvider')) or game:GetService('ContentProvider')
local TweenService = cloneref and cloneref(game:GetService('TweenService')) or game:GetService('TweenService')
local HttpService = cloneref and cloneref(game:GetService('HttpService')) or game:GetService('HttpService')
local TextService = cloneref and cloneref(game:GetService('TextService')) or game:GetService('TextService')
local RunService = cloneref and cloneref(game:GetService('RunService')) or game:GetService('RunService')
local Lighting = cloneref and cloneref(game:GetService('Lighting')) or game:GetService('Lighting')
local Players = cloneref and cloneref(game:GetService('Players')) or game:GetService('Players')
local CoreGui = cloneref and cloneref(game:GetService('CoreGui')) or game:GetService('CoreGui')
local Debris = cloneref and cloneref(game:GetService('Debris')) or game:GetService('Debris')

local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()

local old_Sakura = CoreGui:FindFirstChild('Xinve')
if old_Sakura then Debris:AddItem(old_Sakura, 0) end

pcall(function()
    if getgenv()._Sakura_Cleanup then
        getgenv()._Sakura_Cleanup()
        getgenv()._Sakura_Cleanup = nil
    end
end)

if not isfolder("Sakura") then makefolder("Sakura") end

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
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        table.insert(result, trimmedValue)
    end
    return result
end

local function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end

local Config = setmetatable({
    save = function(self, file_name, config)
        local success, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            writefile('Sakura/'..file_name..'.json', flags)
        end)
        if not success then warn('Failed to save config', result) end
    end,
    load = function(self, file_name, config)
        local success, result = pcall(function()
            if not isfile('Sakura/'..file_name..'.json') then
                self:save(file_name, config)
                return
            end
            local flags = readfile('Sakura/'..file_name..'.json')
            if not flags then
                self:save(file_name, config)
                return
            end
            return HttpService:JSONDecode(flags)
        end)
        if not success then warn('Failed to load config', result) end
        if not result then result = { _flags = {}, _keybinds = {}, _library = {} } end
        return result
    end
}, Config)

local DefaultTheme = {
    Background = Color3.fromRGB(20, 20, 20),
    Group = Color3.fromRGB(30, 30, 30),
    GroupStroke = Color3.fromRGB(45, 45, 45),
    Control = Color3.fromRGB(40, 40, 40),
    Divider = Color3.fromRGB(50, 50, 50),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(160, 160, 160),
    Accent = Color3.fromRGB(255, 255, 255),
}

local Theme = {}
for k, v in pairs(DefaultTheme) do
    Theme[k] = typeof(v) == "Color3" and Color3.new(v.R, v.G, v.B) or v
end

local Library = {
    _config = Config:load(game.GameId),
    _choosing_keybind = false,
    _device = nil,
    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,
    _dragging = false,
    _drag_start = nil,
    _container_position = nil,
    _elements = {},
    _background = nil,
    _tab = 0
}
Library.__index = Library
Library.Connections = Connections

function Library.new()
    local self = setmetatable({
        _loaded = false,
        _tab = 0
    }, Library)
    self:create_ui()
    return self
end

-- Notification System
local NotificationHost = Instance.new("ScreenGui")
NotificationHost.Name = "SakuraNotifications"
NotificationHost.ResetOnSpawn = false
NotificationHost.IgnoreGuiInset = true
NotificationHost.DisplayOrder = 101
NotificationHost.Parent = CoreGui

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "NotificationContainer"
NotificationContainer.Size = UDim2.new(0, 320, 0, 0)
NotificationContainer.Position = UDim2.new(0.8, 0, 0, 10)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y
NotificationContainer.Parent = NotificationHost

local UIListLayout_Notif = Instance.new("UIListLayout")
UIListLayout_Notif.FillDirection = Enum.FillDirection.Vertical
UIListLayout_Notif.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Notif.Padding = UDim.new(0, 10)
UIListLayout_Notif.Parent = NotificationContainer

function Library:Notify(settings)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 72)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer
    Notification.AutomaticSize = Enum.AutomaticSize.Y

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Notification

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 0, 72)
    InnerFrame.Position = UDim2.new(0, 0, 0, 0)
    InnerFrame.BackgroundColor3 = Theme.Background
    InnerFrame.BackgroundTransparency = 0
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.Parent = Notification
    InnerFrame.AutomaticSize = Enum.AutomaticSize.Y
    table.insert(Library._elements, {obj = InnerFrame, prop = "BackgroundColor3", tKey = "Background"})

    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 4)
    InnerUICorner.Parent = InnerFrame

    local InnerStroke = Instance.new("UIStroke")
    InnerStroke.Color = Theme.GroupStroke
    InnerStroke.Transparency = 0.5
    InnerStroke.Thickness = 1
    InnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    InnerStroke.Parent = InnerFrame
    table.insert(Library._elements, {obj = InnerStroke, prop = "Color", tKey = "GroupStroke"})

    local Title = Instance.new("TextLabel")
    Title.Text = tostring(settings.title or "Notification Title")
    Title.TextColor3 = Theme.Text
    Title.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Title.TextSize = 15
    Title.Size = UDim2.new(1, -10, 0, 22)
    Title.Position = UDim2.new(0, 7, 0, 7)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextWrapped = true
    Title.AutomaticSize = Enum.AutomaticSize.Y
    Title.Parent = InnerFrame
    table.insert(Library._elements, {obj = Title, prop = "TextColor3", tKey = "Text"})

    local Body = Instance.new("TextLabel")
    Body.Text = tostring(settings.text or "This is the body of the notification.")
    Body.TextColor3 = Theme.TextDim
    Body.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Body.TextSize = 13
    Body.Size = UDim2.new(1, -16, 0, 34)
    Body.Position = UDim2.new(0, 7, 0, 30)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Top
    Body.TextWrapped = true
    Body.AutomaticSize = Enum.AutomaticSize.Y
    Body.Parent = InnerFrame
    table.insert(Library._elements, {obj = Body, prop = "TextColor3", tKey = "TextDim"})

    task.spawn(function()
        wait(0.1)
        local totalHeight = Title.TextBounds.Y + Body.TextBounds.Y + 12
        InnerFrame.Size = UDim2.new(1, 0, 0, totalHeight)
    end)

    task.spawn(function()
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 10 + NotificationContainer.Size.Y.Offset)
        })
        tweenIn:Play()

        local duration = settings.duration or 5
        wait(duration)

        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 310, 0, 10 + NotificationContainer.Size.Y.Offset)
        })
        tweenOut:Play()

        tweenOut.Completed:Connect(function()
            Notification:Destroy()
        end)
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
        self._background.Image = source
        self._background.Visible = true
        self._background.ImageTransparency = transparency or 0.5
        self._background.ScaleType = Enum.ScaleType.Crop
    else
        self._background.Visible = false
    end
    self._config._flags['Background_Image'] = source or ''
    self._config._flags['Background_Transparency'] = transparency or 0.5
    Config:save(game.GameId, Library._config)
end

function Library:SetColor(key, color)
    Theme[key] = color
    for _, element in ipairs(Library._elements or {}) do
        if element.tKey == key then
            pcall(function()
                element.obj[element.prop] = color
            end)
        end
    end
    self._config._flags['Theme_'..key] = self:rgbToHex(color)
    Config:save(game.GameId, Library._config)
end

function Library:GetColor(key)
    return Theme[key]
end

function Library:create_ui()
    local old_Xinve = CoreGui:FindFirstChild('Xinve')
    if old_Xinve then Debris:AddItem(old_Xinve, 0) end

    local Xinve = Instance.new('ScreenGui')
    Xinve.ResetOnSpawn = false
    Xinve.Name = 'Xinve'
    Xinve.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Xinve.Parent = CoreGui
    
    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0
    Container.BackgroundColor3 = Theme.Background
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = Xinve
    table.insert(Library._elements, {obj = Container, prop = "BackgroundColor3", tKey = "Background"})

    local Background = Instance.new("ImageLabel")
    Background.Name = "Background"
    Background.Parent = Container
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.BackgroundTransparency = 1
    Background.Image = ''
    Background.ImageTransparency = 0.5
    Background.ScaleType = Enum.ScaleType.Crop
    Background.Visible = false
    Background.ZIndex = 0
    self._background = Background

    local SideBar = Instance.new("Frame")
    SideBar.Name = "GradientSide"
    SideBar.Parent = Container
    SideBar.Size = UDim2.new(0, 10, 1, 0)
    SideBar.Position = UDim2.new(0, 0, 0, 0)
    SideBar.BackgroundTransparency = 1

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Theme.GroupStroke
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container
    table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "GroupStroke"})
    
    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Theme.Background
    Handler.Parent = Container
    table.insert(Library._elements, {obj = Handler, prop = "BackgroundColor3", tKey = "Background"})
    
    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0.026, 0, 0.111, 0)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler
    
    local UIListLayout_Tabs = Instance.new('UIListLayout')
    UIListLayout_Tabs.Padding = UDim.new(0, 4)
    UIListLayout_Tabs.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout_Tabs.Parent = Tabs
    
    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Theme.Text
    ClientName.Text = 'Sakura'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 100, 0, 13)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.056, 0, 0.055, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.TextSize = 13
    ClientName.Parent = Handler
    table.insert(Library._elements, {obj = ClientName, prop = "TextColor3", tKey = "Text"})
    
    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0.026, 0, 0.136, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = Theme.Accent
    Pin.Parent = Handler
    table.insert(Library._elements, {obj = Pin, prop = "BackgroundColor3", tKey = "Accent"})
    
    local UICorner2 = Instance.new('UICorner')
    UICorner2.CornerRadius = UDim.new(1, 0)
    UICorner2.Parent = Pin
    
    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.235, 0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 479)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Theme.Divider
    Divider.Parent = Handler
    table.insert(Library._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "Divider"})
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    
    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Theme.Text
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020, 0, 0.029, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.TextSize = 14
    Minimize.Parent = Handler
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container    
    
    self._ui = Xinve
    self._container = Container
    self._tabs = Tabs
    self._sections = Sections
    self._pin = Pin
    self._handler = Handler
    self._uiscale = UIScale

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
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)
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

    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightControl then
            self._ui_open = not self._ui_open
            self:change_visiblity(self._ui_open)
        end
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)
end

function Library:change_visiblity(state)
    Library._ui_open = state
    if self._container then
        if state then
            TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479)
            }):Play()
        else
            TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end
end

function Library:load()
    local content = {}
    for _, object in self._ui:GetDescendants() do
        if object:IsA('ImageLabel') then
            table.insert(content, object)
        end
    end
    ContentProvider:PreloadAsync(content)
    
    self:get_device()

    if self._device == 'Mobile' or self._device == 'Unknown' then
        self:get_screen_scale()
        if self._uiscale then
            self._uiscale.Scale = self._ui_scale
        end
        Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
            self:get_screen_scale()
            if self._uiscale then
                self._uiscale.Scale = self._ui_scale
            end
        end)
    end

    if self._container then
        TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(698, 479)
        }):Play()
    end

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

    self._ui_loaded = true
end

function Library:update_tabs(tab)
    for _, object in self._tabs:GetChildren() do
        if object.Name ~= 'Tab' then continue end

        if object == tab then
            if object.BackgroundTransparency ~= 0.5 then
                local offset = object.LayoutOrder * (0.113 / 1.3)

                TweenService:Create(self._pin, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = UDim2.fromScale(0.026, 0.135 + offset)
                }):Play()    

                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0.5
                }):Play()

                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.2,
                    TextColor3 = Theme.Text
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.2,
                    ImageColor3 = Theme.Accent
                }):Play()
            end
        else
            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                
                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.7,
                    TextColor3 = Theme.TextDim
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8,
                    ImageColor3 = Theme.TextDim
                }):Play()
            end
        end
    end
end

function Library:update_sections(left_section, right_section)
    for _, object in self._sections:GetChildren() do
        if object == left_section or object == right_section then
            object.Visible = true
        else
            object.Visible = false
        end
    end
end

function Library:create_tab(title, icon)
    local TabManager = {}

    local font_params = Instance.new('GetTextBoundsParams')
    font_params.Text = title
    font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    font_params.Size = 13
    font_params.Width = 10000

    local font_size = TextService:GetTextBoundsAsync(font_params)
    local first_tab = not self._tabs:FindFirstChild('Tab')

    local Tab = Instance.new('TextButton')
    Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Tab.TextColor3 = Theme.Text
    Tab.Text = ''
    Tab.AutoButtonColor = false
    Tab.BackgroundTransparency = 1
    Tab.Name = 'Tab'
    Tab.Size = UDim2.new(0, 129, 0, 38)
    Tab.BorderSizePixel = 0
    Tab.TextSize = 14
    Tab.BackgroundColor3 = Theme.Group
    Tab.Parent = self._tabs
    Tab.LayoutOrder = self._tab
    table.insert(Library._elements, {obj = Tab, prop = "BackgroundColor3", tKey = "Group"})
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 5)
    UICorner.Parent = Tab
    
    local TextLabel = Instance.new('TextLabel')
    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    TextLabel.TextColor3 = Theme.TextDim
    TextLabel.TextTransparency = 0.7
    TextLabel.Text = title
    TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
    TextLabel.AnchorPoint = Vector2.new(0, 0.5)
    TextLabel.Position = UDim2.new(0.240, 0, 0.5, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.TextSize = 13
    TextLabel.Parent = Tab
    table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "TextDim"})
    
    local Icon = Instance.new('ImageLabel')
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.ImageTransparency = 0.8
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.100, 0, 0.5, 0)
    Icon.Name = 'Icon'
    Icon.Image = icon
    Icon.Size = UDim2.new(0, 12, 0, 12)
    Icon.BorderSizePixel = 0
    Icon.BackgroundColor3 = Theme.TextDim
    Icon.Parent = Tab
    table.insert(Library._elements, {obj = Icon, prop = "ImageColor3", tKey = "TextDim"})

    local LeftSection = Instance.new('ScrollingFrame')
    LeftSection.Name = 'LeftSection'
    LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
    LeftSection.ScrollBarThickness = 0
    LeftSection.Size = UDim2.new(0, 243, 0, 445)
    LeftSection.Selectable = false
    LeftSection.AnchorPoint = Vector2.new(0, 0.5)
    LeftSection.ScrollBarImageTransparency = 1
    LeftSection.BackgroundTransparency = 1
    LeftSection.Position = UDim2.new(0.259, 0, 0.5, 0)
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
    RightSection.Size = UDim2.new(0, 243, 0, 445)
    RightSection.Selectable = false
    RightSection.AnchorPoint = Vector2.new(0, 0.5)
    RightSection.ScrollBarImageTransparency = 1
    RightSection.BackgroundTransparency = 1
    RightSection.Position = UDim2.new(0.629, 0, 0.5, 0)
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
        Module.BackgroundTransparency = 0.5
        Module.Position = UDim2.new(0.004, 0, 0, 0)
        Module.Name = 'Module'
        Module.Size = UDim2.new(0, 241, 0, 93)
        Module.BorderSizePixel = 0
        Module.BackgroundColor3 = Theme.Group
        Module.Parent = settings.section
        table.insert(Library._elements, {obj = Module, prop = "BackgroundColor3", tKey = "Group"})

        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = Module
        
        local UIStroke = Instance.new('UIStroke')
        UIStroke.Color = Theme.GroupStroke
        UIStroke.Transparency = 0.5
        UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        UIStroke.Parent = Module
        table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "GroupStroke"})
        
        local Header = Instance.new('TextButton')
        Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Header.TextColor3 = Theme.Text
        Header.Text = ''
        Header.AutoButtonColor = false
        Header.BackgroundTransparency = 1
        Header.Name = 'Header'
        Header.Size = UDim2.new(0, 241, 0, 93)
        Header.BorderSizePixel = 0
        Header.TextSize = 14
        Header.Parent = Module
        
        local ModuleName = Instance.new('TextLabel')
        ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        ModuleName.TextColor3 = Theme.Text
        ModuleName.TextTransparency = 0.2
        ModuleName.Text = settings.title or "Module"
        ModuleName.Name = 'ModuleName'
        ModuleName.Size = UDim2.new(0, 205, 0, 13)
        ModuleName.AnchorPoint = Vector2.new(0, 0.5)
        ModuleName.Position = UDim2.new(0.073, 0, 0.240, 0)
        ModuleName.BackgroundTransparency = 1
        ModuleName.TextXAlignment = Enum.TextXAlignment.Left
        ModuleName.TextSize = 13
        ModuleName.Parent = Header
        table.insert(Library._elements, {obj = ModuleName, prop = "TextColor3", tKey = "Text"})
        
        local Description = Instance.new('TextLabel')
        Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Description.TextColor3 = Theme.TextDim
        Description.TextTransparency = 0.7
        Description.Text = settings.description or ''
        Description.Name = 'Description'
        Description.Size = UDim2.new(0, 205, 0, 13)
        Description.AnchorPoint = Vector2.new(0, 0.5)
        Description.Position = UDim2.new(0.073, 0, 0.420, 0)
        Description.BackgroundTransparency = 1
        Description.TextXAlignment = Enum.TextXAlignment.Left
        Description.TextSize = 10
        Description.Parent = Header
        table.insert(Library._elements, {obj = Description, prop = "TextColor3", tKey = "TextDim"})
        
        local Toggle = Instance.new('Frame')
        Toggle.Name = 'Toggle'
        Toggle.BackgroundTransparency = 0.7
        Toggle.Position = UDim2.new(0.820, 0, 0.757, 0)
        Toggle.Size = UDim2.new(0, 25, 0, 12)
        Toggle.BorderSizePixel = 0
        Toggle.BackgroundColor3 = Theme.Control
        Toggle.Parent = Header
        table.insert(Library._elements, {obj = Toggle, prop = "BackgroundColor3", tKey = "Control"})
        
        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(1, 0)
        UICorner.Parent = Toggle
        
        local Circle = Instance.new('Frame')
        Circle.AnchorPoint = Vector2.new(0, 0.5)
        Circle.BackgroundTransparency = 0.2
        Circle.Position = UDim2.new(0, 0, 0.5, 0)
        Circle.Name = 'Circle'
        Circle.Size = UDim2.new(0, 12, 0, 12)
        Circle.BorderSizePixel = 0
        Circle.BackgroundColor3 = Theme.TextDim
        Circle.Parent = Toggle
        table.insert(Library._elements, {obj = Circle, prop = "BackgroundColor3", tKey = "TextDim"})
        
        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(1, 0)
        UICorner.Parent = Circle
        
        local Divider = Instance.new('Frame')
        Divider.AnchorPoint = Vector2.new(0.5, 0)
        Divider.BackgroundTransparency = 0.5
        Divider.Position = UDim2.new(0.5, 0, 0.620, 0)
        Divider.Name = 'Divider'
        Divider.Size = UDim2.new(0, 241, 0, 1)
        Divider.BorderSizePixel = 0
        Divider.BackgroundColor3 = Theme.Divider
        Divider.Parent = Header
        table.insert(Library._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "Divider"})
        
        local Divider2 = Instance.new('Frame')
        Divider2.AnchorPoint = Vector2.new(0.5, 0)
        Divider2.BackgroundTransparency = 0.5
        Divider2.Position = UDim2.new(0.5, 0, 1, 0)
        Divider2.Name = 'Divider'
        Divider2.Size = UDim2.new(0, 241, 0, 1)
        Divider2.BorderSizePixel = 0
        Divider2.BackgroundColor3 = Theme.Divider
        Divider2.Parent = Header
        table.insert(Library._elements, {obj = Divider2, prop = "BackgroundColor3", tKey = "Divider"})
        
        local Options = Instance.new('Frame')
        Options.Name = 'Options'
        Options.BackgroundTransparency = 1
        Options.Position = UDim2.new(0, 0, 1, 0)
        Options.Size = UDim2.new(0, 241, 0, 8)
        Options.BorderSizePixel = 0
        Options.Parent = Module

        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 8)
        UIPadding.Parent = Options

        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 5)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = Options

        function ModuleManager:change_state(state)
            self._state = state
            if self._state then
                TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                }):Play()
                TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Theme.Accent
                }):Play()
                TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Theme.Group,
                    Position = UDim2.fromScale(0.53, 0.5)
                }):Play()
            else
                TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(241, 93)
                }):Play()
                TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Theme.Control
                }):Play()
                TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Theme.TextDim,
                    Position = UDim2.fromScale(0, 0.5)
                }):Play()
            end
            Library._config._flags[settings.flag] = self._state
            Config:save(game.GameId, Library._config)
            settings.callback(self._state)
        end

        if Library:flag_type(settings.flag, 'boolean') then
            ModuleManager._state = Library._config._flags[settings.flag]
            settings.callback(ModuleManager._state)
            if ModuleManager._state then
                Toggle.BackgroundColor3 = Theme.Accent
                Circle.BackgroundColor3 = Theme.Group
                Circle.Position = UDim2.fromScale(0.53, 0.5)
            else
                Toggle.BackgroundColor3 = Theme.Control
                Circle.BackgroundColor3 = Theme.TextDim
                Circle.Position = UDim2.fromScale(0, 0.5)
            end
        end

        Library._flag_registry = Library._flag_registry or {}
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
            self._size = self._size + 20
            
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)
            
            local Checkbox = Instance.new("TextButton")
            Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Checkbox.TextColor3 = Theme.Text
            Checkbox.Text = ""
            Checkbox.AutoButtonColor = false
            Checkbox.BackgroundTransparency = 1
            Checkbox.Name = "Checkbox"
            Checkbox.Size = UDim2.new(0, 207, 0, 15)
            Checkbox.BorderSizePixel = 0
            Checkbox.TextSize = 14
            Checkbox.Parent = Options
            Checkbox.LayoutOrder = LayoutOrderModule
            
            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Name = "TitleLabel"
            TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TitleLabel.TextSize = 11
            TitleLabel.TextColor3 = Theme.Text
            TitleLabel.TextTransparency = 0.2
            TitleLabel.Text = settings.title or "Checkbox"
            TitleLabel.Size = UDim2.new(0, 142, 0, 13)
            TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
            TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = Checkbox
            table.insert(Library._elements, {obj = TitleLabel, prop = "TextColor3", tKey = "Text"})

            local Box = Instance.new("Frame")
            Box.AnchorPoint = Vector2.new(1, 0.5)
            Box.BackgroundTransparency = 0.9
            Box.Position = UDim2.new(1, 0, 0.5, 0)
            Box.Name = "Box"
            Box.Size = UDim2.new(0, 15, 0, 15)
            Box.BorderSizePixel = 0
            Box.BackgroundColor3 = Theme.Control
            Box.Parent = Checkbox
            table.insert(Library._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Control"})
            
            local BoxCorner = Instance.new("UICorner")
            BoxCorner.CornerRadius = UDim.new(0, 4)
            BoxCorner.Parent = Box
            
            local Fill = Instance.new("Frame")
            Fill.AnchorPoint = Vector2.new(0.5, 0.5)
            Fill.BackgroundTransparency = 0.2
            Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
            Fill.Name = "Fill"
            Fill.BorderSizePixel = 0
            Fill.BackgroundColor3 = Theme.Accent
            Fill.Parent = Box
            table.insert(Library._elements, {obj = Fill, prop = "BackgroundColor3", tKey = "Accent"})
            
            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(0, 3)
            FillCorner.Parent = Fill
            
            function CheckboxManager:change_state(state)
                self._state = state
                if self._state then
                    TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.7
                    }):Play()
                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(9, 9)
                    }):Play()
                else
                    TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.9
                    }):Play()
                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(0, 0)
                    }):Play()
                end
                Library._config._flags[settings.flag] = self._state
                Config:save(game.GameId, Library._config)
                settings.callback(self._state)
            end
            
            if Library:flag_type(settings.flag, "boolean") then
                CheckboxManager:change_state(Library._config._flags[settings.flag])
            end
            
            Checkbox.MouseButton1Click:Connect(function()
                CheckboxManager:change_state(not CheckboxManager._state)
            end)
            
            return CheckboxManager
        end

        function ModuleManager:create_button(settings)
            LayoutOrderModule = LayoutOrderModule + 1
            
            if self._size == 0 then self._size = 11 end
            self._size = self._size + 20
            
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)
            
            local Button = Instance.new("TextButton")
            Button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Button.TextColor3 = Theme.Text
            Button.TextTransparency = 0.2
            Button.Text = settings.title or "Button"
            Button.AutoButtonColor = true
            Button.BackgroundTransparency = 0.2
            Button.BackgroundColor3 = Theme.Control
            Button.Name = "Button"
            Button.Size = UDim2.new(0, 207, 0, 20)
            Button.BorderSizePixel = 0
            Button.TextSize = 11
            Button.Parent = Options
            Button.LayoutOrder = LayoutOrderModule
            table.insert(Library._elements, {obj = Button, prop = "BackgroundColor3", tKey = "Control"})
            table.insert(Library._elements, {obj = Button, prop = "TextColor3", tKey = "Text"})

            local ButtonCorner = Instance.new("UICorner")
            ButtonCorner.CornerRadius = UDim.new(0, 4)
            ButtonCorner.Parent = Button

            Button.MouseButton1Click:Connect(function()
                if settings.callback then settings.callback() end
            end)
        end
        
        function ModuleManager:create_slider(settings)
            LayoutOrderModule = LayoutOrderModule + 1
            local SliderManager = {}

            if self._size == 0 then self._size = 11 end
            self._size = self._size + 27

            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)

            local Slider = Instance.new('TextButton')
            Slider.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Slider.TextSize = 14
            Slider.TextColor3 = Theme.Text
            Slider.Text = ''
            Slider.AutoButtonColor = false
            Slider.BackgroundTransparency = 1
            Slider.Name = 'Slider'
            Slider.Size = UDim2.new(0, 207, 0, 22)
            Slider.BorderSizePixel = 0
            Slider.Parent = Options
            Slider.LayoutOrder = LayoutOrderModule
            
            local TextLabel = Instance.new('TextLabel')
            TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TextLabel.TextSize = 11
            TextLabel.TextColor3 = Theme.Text
            TextLabel.TextTransparency = 0.2
            TextLabel.Text = settings.title
            TextLabel.Size = UDim2.new(0, 153, 0, 13)
            TextLabel.Position = UDim2.new(0, 0, 0.050, 0)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.Parent = Slider
            table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})
            
            local Drag = Instance.new('Frame')
            Drag.AnchorPoint = Vector2.new(0.5, 1)
            Drag.BackgroundTransparency = 0.9
            Drag.Position = UDim2.new(0.5, 0, 0.950, 0)
            Drag.Name = 'Drag'
            Drag.Size = UDim2.new(0, 207, 0, 4)
            Drag.BorderSizePixel = 0
            Drag.BackgroundColor3 = Theme.Group
            Drag.Parent = Slider
            table.insert(Library._elements, {obj = Drag, prop = "BackgroundColor3", tKey = "Group"})
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Drag
            
            local Fill = Instance.new('Frame')
            Fill.AnchorPoint = Vector2.new(0, 0.5)
            Fill.BackgroundTransparency = 0.5
            Fill.Position = UDim2.new(0, 0, 0.5, 0)
            Fill.Name = 'Fill'
            Fill.Size = UDim2.new(0, 103, 0, 4)
            Fill.BorderSizePixel = 0
            Fill.BackgroundColor3 = Theme.Accent
            Fill.Parent = Drag
            table.insert(Library._elements, {obj = Fill, prop = "BackgroundColor3", tKey = "Accent"})
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 3)
            UICorner.Parent = Fill
            
            local Circle = Instance.new('Frame')
            Circle.AnchorPoint = Vector2.new(1, 0.5)
            Circle.Name = 'Circle'
            Circle.Position = UDim2.new(1, 0, 0.5, 0)
            Circle.Size = UDim2.new(0, 6, 0, 6)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Theme.Accent
            Circle.Parent = Fill
            table.insert(Library._elements, {obj = Circle, prop = "BackgroundColor3", tKey = "Accent"})
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle
            
            local Value = Instance.new('TextLabel')
            Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Value.TextColor3 = Theme.TextDim
            Value.TextTransparency = 0.2
            Value.Text = '50'
            Value.Name = 'Value'
            Value.Size = UDim2.new(0, 42, 0, 13)
            Value.AnchorPoint = Vector2.new(1, 0)
            Value.Position = UDim2.new(1, 0, 0, 0)
            Value.BackgroundTransparency = 1
            Value.TextXAlignment = Enum.TextXAlignment.Right
            Value.TextSize = 10
            Value.Parent = Slider
            table.insert(Library._elements, {obj = Value, prop = "TextColor3", tKey = "TextDim"})

            function SliderManager:set_percentage(percentage)
                local rounded_number = 0
                if settings.round_number then
                    rounded_number = math.floor(percentage)
                else
                    rounded_number = math.floor(percentage * 10) / 10
                end

                percentage = (percentage - settings.minimum_value) / (settings.maximum_value - settings.minimum_value)
                local slider_size = math.clamp(percentage, 0.02, 1) * (Drag.AbsoluteSize.X ~= 0 and Drag.AbsoluteSize.X or Drag.Size.X.Offset)
                local number_threshold = math.clamp(rounded_number, settings.minimum_value, settings.maximum_value)

                Library._config._flags[settings.flag] = number_threshold
                Value.Text = tostring(number_threshold)

                TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(slider_size, (Drag.AbsoluteSize.Y ~= 0 and Drag.AbsoluteSize.Y or Drag.Size.Y.Offset))
                }):Play()

                settings.callback(number_threshold)
            end

            function SliderManager:update()
                local success, mouse_location = pcall(function() return UserInputService:GetMouseLocation() end)
                local mouse_x = (success and mouse_location and mouse_location.X) or (mouse and mouse.X) or 0
                local drag_width = (Drag.AbsoluteSize and Drag.AbsoluteSize.X) or Drag.Size.X.Offset
                if drag_width == 0 then drag_width = Drag.Size.X.Offset end
                local mouse_position = (mouse_x - Drag.AbsolutePosition.X) / drag_width
                local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position

                self:set_percentage(percentage)
            end

            function SliderManager:input()
                SliderManager:update()
                Connections['slider_drag_'..settings.flag] = UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                        SliderManager:update()
                    end
                end)
                Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    Connections:disconnect('slider_drag_'..settings.flag)
                    Connections:disconnect('slider_input_'..settings.flag)
                    if not settings.ignoresaved then
                        Config:save(game.GameId, Library._config)
                    end
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

            return SliderManager
        end

        function ModuleManager:create_textbox(settings)
            LayoutOrderModule = LayoutOrderModule + 1
            local TextboxManager = { _text = "" }
            
            if self._size == 0 then self._size = 11 end
            self._size = self._size + 32
            
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)
            
            local Label = Instance.new('TextLabel')
            Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Label.TextColor3 = Theme.Text
            Label.TextTransparency = 0.2
            Label.Text = settings.title or "Enter text"
            Label.Size = UDim2.new(0, 207, 0, 13)
            Label.Position = UDim2.new(0, 0, 0, 0)
            Label.BackgroundTransparency = 1
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextSize = 10
            Label.Parent = Options
            Label.LayoutOrder = LayoutOrderModule
            table.insert(Library._elements, {obj = Label, prop = "TextColor3", tKey = "Text"})
            
            local Textbox = Instance.new('TextBox')
            Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Textbox.TextColor3 = Theme.Text
            Textbox.PlaceholderText = tostring(settings.placeholder or "Enter text...")
            Textbox.PlaceholderColor3 = Theme.TextDim
            Textbox.Text = tostring(Library._config._flags[settings.flag] or "")
            Textbox.Name = 'Textbox'
            Textbox.Size = UDim2.new(0, 207, 0, 15)
            Textbox.BorderSizePixel = 0
            Textbox.TextSize = 10
            Textbox.BackgroundColor3 = Theme.Control
            Textbox.BackgroundTransparency = 0.9
            Textbox.ClearTextOnFocus = false
            Textbox.Parent = Options
            Textbox.LayoutOrder = LayoutOrderModule
            table.insert(Library._elements, {obj = Textbox, prop = "BackgroundColor3", tKey = "Control"})
            table.insert(Library._elements, {obj = Textbox, prop = "TextColor3", tKey = "Text"})
            table.insert(Library._elements, {obj = Textbox, prop = "PlaceholderColor3", tKey = "TextDim"})
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 4)
            UICorner.Parent = Textbox
            
            function TextboxManager:update_text(text)
                self._text = text
                Library._config._flags[settings.flag] = self._text
                Config:save(game.GameId, Library._config)
                settings.callback(self._text)
            end
            
            if Library:flag_type(settings.flag, 'string') then
                TextboxManager:update_text(Library._config._flags[settings.flag])
            end
            
            Textbox.FocusLost:Connect(function()
                TextboxManager:update_text(Textbox.Text)
            end)
            
            return TextboxManager
        end

        function ModuleManager:create_dropdown(settings)
            LayoutOrderModule = LayoutOrderModule + 1
            local DropdownManager = { _state = false, _size = 0 }
            
            if self._size == 0 then self._size = 11 end
            self._size = self._size + 44
            
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)

            local Dropdown = Instance.new('TextButton')
            Dropdown.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Dropdown.TextColor3 = Theme.Text
            Dropdown.Text = ''
            Dropdown.AutoButtonColor = false
            Dropdown.BackgroundTransparency = 1
            Dropdown.Name = 'Dropdown'
            Dropdown.Size = UDim2.new(0, 207, 0, 39)
            Dropdown.BorderSizePixel = 0
            Dropdown.TextSize = 14
            Dropdown.Parent = Options
            Dropdown.LayoutOrder = LayoutOrderModule

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
            TextLabel.Parent = Dropdown
            table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})
            
            local Box = Instance.new('Frame')
            Box.ClipsDescendants = true
            Box.AnchorPoint = Vector2.new(0.5, 0)
            Box.BackgroundTransparency = 0.9
            Box.Position = UDim2.new(0.5, 0, 1.200, 0)
            Box.Name = 'Box'
            Box.Size = UDim2.new(0, 207, 0, 22)
            Box.BorderSizePixel = 0
            Box.BackgroundColor3 = Theme.Control
            Box.Parent = TextLabel
            table.insert(Library._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Control"})
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 4)
            UICorner.Parent = Box
            
            local Header = Instance.new('Frame')
            Header.AnchorPoint = Vector2.new(0.5, 0)
            Header.BackgroundTransparency = 1
            Header.Position = UDim2.new(0.5, 0, 0, 0)
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 207, 0, 22)
            Header.BorderSizePixel = 0
            Header.Parent = Box
            
            local CurrentOption = Instance.new('TextLabel')
            CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            CurrentOption.TextColor3 = Theme.Text
            CurrentOption.TextTransparency = 0.2
            CurrentOption.Name = 'CurrentOption'
            CurrentOption.Size = UDim2.new(0, 161, 0, 13)
            CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
            CurrentOption.Position = UDim2.new(0.050, 0, 0.5, 0)
            CurrentOption.BackgroundTransparency = 1
            CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
            CurrentOption.TextSize = 10
            CurrentOption.Parent = Header
            table.insert(Library._elements, {obj = CurrentOption, prop = "TextColor3", tKey = "Text"})
            
            local Arrow = Instance.new('ImageLabel')
            Arrow.AnchorPoint = Vector2.new(0, 0.5)
            Arrow.Image = 'rbxassetid://84232453189324'
            Arrow.ImageColor3 = Theme.TextDim
            Arrow.BackgroundTransparency = 1
            Arrow.Position = UDim2.new(0.910, 0, 0.5, 0)
            Arrow.Name = 'Arrow'
            Arrow.Size = UDim2.new(0, 8, 0, 8)
            Arrow.BorderSizePixel = 0
            Arrow.Parent = Header
            table.insert(Library._elements, {obj = Arrow, prop = "ImageColor3", tKey = "TextDim"})
            
            local OptionsList = Instance.new('ScrollingFrame')
            OptionsList.Active = true
            OptionsList.ScrollBarImageTransparency = 1
            OptionsList.AutomaticCanvasSize = Enum.AutomaticSize.XY
            OptionsList.ScrollBarThickness = 0
            OptionsList.Name = 'Options'
            OptionsList.Size = UDim2.new(0, 207, 0, 0)
            OptionsList.BackgroundTransparency = 1
            OptionsList.Position = UDim2.new(0, 0, 1, 0)
            OptionsList.BorderSizePixel = 0
            OptionsList.CanvasSize = UDim2.new(0, 0, 0.5, 0)
            OptionsList.Parent = Box
            
            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = OptionsList
            
            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, -1)
            UIPadding.PaddingLeft = UDim.new(0, 10)
            UIPadding.Parent = OptionsList

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
                    local optionSkibidi = (typeof(option) == "string" and option) or (typeof(option) == "Instance" and option.Name) or tostring(option)

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
                    CurrentOption.Text = (typeof(option) == "string" and option) or (typeof(option) == "Instance" and option.Name) or tostring(option)
                    for _, object in OptionsList:GetChildren() do
                        if object.Name == "Option" then
                            object.TextTransparency = object.Text == CurrentOption.Text and 0.2 or 0.6
                        end
                    end
                    Library._config._flags[settings.flag] = option
                end

                Config:save(game.GameId, Library._config)
                settings.callback(option)
            end

            function DropdownManager:unfold_settings()
                self._state = not self._state
                local extra = self._state and self._size or 0

                if self._state then
                    ModuleManager._multiplier = ModuleManager._multiplier + self._size
                else
                    ModuleManager._multiplier = ModuleManager._multiplier - self._size
                end

                TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                }):Play()

                TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                }):Play()

                TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(207, 39 + extra)
                }):Play()

                TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(207, 22 + extra)
                }):Play()

                TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Rotation = self._state and 180 or 0
                }):Play()
            end

            if #settings.options > 0 then
                DropdownManager._size = 3
                for index, value in settings.options do
                    local Option = Instance.new('TextButton')
                    Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    Option.Active = false
                    Option.TextTransparency = 0.6
                    Option.AnchorPoint = Vector2.new(0, 0.5)
                    Option.TextSize = 10
                    Option.Size = UDim2.new(0, 186, 0, 16)
                    Option.TextColor3 = Theme.Text
                    Option.Text = (typeof(value) == "string" and value) or value.Name
                    Option.AutoButtonColor = false
                    Option.Name = 'Option'
                    Option.BackgroundTransparency = 1
                    Option.TextXAlignment = Enum.TextXAlignment.Left
                    Option.Selectable = false
                    Option.Position = UDim2.new(0.050, 0, 0.342, 0)
                    Option.BorderSizePixel = 0
                    Option.Parent = OptionsList
                    table.insert(Library._elements, {obj = Option, prop = "TextColor3", tKey = "Text"})

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
                    DropdownManager._size = DropdownManager._size + 16
                    OptionsList.Size = UDim2.fromOffset(207, DropdownManager._size)
                end
            end

            if Library:flag_type(settings.flag, 'string') then
                DropdownManager:update(Library._config._flags[settings.flag])
            else
                DropdownManager:update(settings.options[1])
            end

            Dropdown.MouseButton1Click:Connect(function()
                DropdownManager:unfold_settings()
            end)

            return DropdownManager
        end

        function ModuleManager:create_divider(settings)
            LayoutOrderModule = LayoutOrderModule + 1
            if self._size == 0 then self._size = 11 end
            self._size = self._size + 27
            
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end

            local OuterFrame = Instance.new('Frame')
            OuterFrame.Size = UDim2.new(0, 207, 0, 20)
            OuterFrame.BackgroundTransparency = 1
            OuterFrame.Name = 'OuterFrame'
            OuterFrame.Parent = Options
            OuterFrame.LayoutOrder = LayoutOrderModule

            if settings and settings.showtopic then
                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TextLabel.TextColor3 = Theme.Text
                TextLabel.TextTransparency = 0
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0.5, 0, 0.501, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Center
                TextLabel.BorderSizePixel = 0
                TextLabel.AnchorPoint = Vector2.new(0.5,0.5)
                TextLabel.TextSize = 11
                TextLabel.ZIndex = 3
                TextLabel.Parent = OuterFrame
                table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})
            end
            
            if not settings or settings and not settings.disableline then
                local Divider = Instance.new('Frame')
                Divider.Size = UDim2.new(1, 0, 0, 1)
                Divider.BackgroundColor3 = Theme.Divider
                Divider.BorderSizePixel = 0
                Divider.Name = 'Divider'
                Divider.Parent = OuterFrame
                Divider.ZIndex = 2
                Divider.Position = UDim2.new(0, 0, 0.5, -0.5)
                table.insert(Library._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "Divider"})
            end
            
            return true
        end

        return ModuleManager
    end

    return TabManager
end

function Library:build_interface_tab()
    local InterfaceTab = self:create_tab('Interface', 'rbxassetid://94381583400007')

    local bg_module = InterfaceTab:create_module({
        title = 'Background',
        flag = 'UI_Background',
        description = 'Set custom background image',
        section = 'left',
        callback = function(state)
            if not self._background then return end
            if state and self._background.Image ~= '' then
                self._background.Visible = true
            else
                self._background.Visible = false
            end
        end
    })

    bg_module:create_textbox({
        title = 'Image URL/ID',
        flag = 'Background_Input',
        placeholder = 'Asset ID or image URL',
        callback = function(value)
            if value and value ~= '' then
                local trans = self._config._flags['Background_Transparency'] or 0.5
                self:SetBackground(value, trans)
                local bg_flag = self._config._flags['UI_Background']
                self._background.Visible = bg_flag ~= false
            else
                self._background.Visible = false
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

    local appearance_module = InterfaceTab:create_module({
        title = 'Appearance',
        flag = 'UI_Appearance',
        description = 'Customize UI colors',
        section = 'right',
        callback = function(state) end
    })

    local color_targets = {
        'Text', 'TextDim', 'Accent', 'Group', 'Control', 'Divider', 'Background', 'GroupStroke'
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
