-- UI Library (standalone, no game logic)
-- Load with: local UI = loadstring(game:HttpGet("https://your-url/uilibrary.lua"))()
-- Then: UI:CreateWindow("My Window")

local Library = {}
Library.__index = Library
Library._windows = {} -- FIX: Initialize windows table

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

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
                if type(v) ~= "function" then
                    pcall(v.Disconnect, v)
                    self[k] = nil
                end
            end
        end
    }
})

local function create_notification_container()
    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.Size = UDim2.new(0, 320, 0, 0)
    container.Position = UDim2.new(0.8, 0, 0, 10)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = false
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = CoreGui:FindFirstChild("RobloxGui") or CoreGui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = container

    return container
end

local notification_container = create_notification_container()

local function send_notification(settings)
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(1, 0, 0, 72)
    notification.BackgroundTransparency = 1
    notification.BorderSizePixel = 0
    notification.Name = "Notification"
    notification.AutomaticSize = Enum.AutomaticSize.Y
    notification.Parent = notification_container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = notification

    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(1, 0, 0, 72)
    inner.Position = UDim2.new(0, 0, 0, 0)
    inner.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    inner.BackgroundTransparency = 0
    inner.BorderSizePixel = 0
    inner.Name = "InnerFrame"
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.Parent = notification

    local inner_corner = Instance.new("UICorner")
    inner_corner.CornerRadius = UDim.new(0, 4)
    inner_corner.Parent = inner

    local title = Instance.new("TextLabel")
    title.Text = settings.title or "Notification"
    title.TextColor3 = Color3.fromRGB(255, 183, 197)
    title.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    title.TextSize = 15
    title.Size = UDim2.new(1, -10, 0, 22)
    title.Position = UDim2.new(0, 7, 0, 7)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.TextWrapped = true
    title.AutomaticSize = Enum.AutomaticSize.Y
    title.Parent = inner

    local body = Instance.new("TextLabel")
    body.Text = settings.text or ""
    body.TextColor3 = Color3.fromRGB(255, 183, 197)
    body.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    body.TextSize = 13
    body.Size = UDim2.new(1, -16, 0, 34)
    body.Position = UDim2.new(0, 7, 0, 30)
    body.BackgroundTransparency = 1
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextWrapped = true
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Parent = inner

    task.spawn(function()
        wait(0.1)
        local total_height = title.TextBounds.Y + body.TextBounds.Y + 12
        inner.Size = UDim2.new(1, 0, 0, total_height)
    end)

    task.spawn(function()
        local tween_in = TweenService:Create(inner, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 10 + notification_container.Size.Y.Offset)
        })
        tween_in:Play()

        local duration = settings.duration or 5
        wait(duration)

        local tween_out = TweenService:Create(inner, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 310, 0, 10 + notification_container.Size.Y.Offset)
        })
        tween_out:Play()
        tween_out.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

function Library:Notify(settings)
    send_notification(settings)
end

function Library.new()
    local self = setmetatable({}, Library)
    self._windows = {} -- Ensure windows table exists
    self._connections = Connections
    return self
end

function Library:CreateWindow(title)
    local window = {
        _title = title,
        _tabs = {},
        _active_tab_index = 0,
        _ui = nil,
        _container = nil,
        _handler = nil,
        _tabs_frame = nil,
        _sections_folder = nil,
        _pin = nil,
        _ui_open = true,
        _dragging = false,
        _drag_start = nil,
        _container_position = nil,
        _connections = setmetatable({}, {__index = Connections}),
        _tab_buttons = {},
        _windows = self._windows -- Store reference
    }

    local function create_ui()
        local old = CoreGui:FindFirstChild("Xinve")
        if old then
            Debris:AddItem(old, 0)
        end

        local screen_gui = Instance.new("ScreenGui")
        screen_gui.ResetOnSpawn = false
        screen_gui.Name = "Xinve"
        screen_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screen_gui.Parent = CoreGui

        local container = Instance.new("Frame")
        container.ClipsDescendants = true
        container.BorderColor3 = Color3.fromRGB(0, 0, 0)
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.Name = "Container"
        container.BackgroundTransparency = 1
        container.BackgroundColor3 = Color3.fromRGB(48, 54, 70)
        container.Position = UDim2.new(0.5, 0, 0.5, 0)
        container.Size = UDim2.new(0, 0, 0, 0)
        container.Active = true
        container.BorderSizePixel = 0
        container.Parent = screen_gui

        local bg = Instance.new("ImageLabel")
        bg.Name = "Background"
        bg.Parent = container
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundTransparency = 1
        bg.Image = "rbxassetid://124990780858879"
        bg.ScaleType = Enum.ScaleType.Crop
        bg.ZIndex = 0

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(8, 8, 8))
        })
        gradient.Rotation = 90
        gradient.Parent = container

        local side_bar = Instance.new("Frame")
        side_bar.Name = "GradientSide"
        side_bar.Parent = container
        side_bar.Size = UDim2.new(0, 10, 1, 0)
        side_bar.Position = UDim2.new(0, 0, 0, 0)
        side_bar.BackgroundTransparency = 1

        local side_gradient = Instance.new("UIGradient")
        side_gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(8, 8, 8))
        })
        side_gradient.Rotation = 90
        side_gradient.Parent = side_bar

        local side_corner = Instance.new("UICorner")
        side_corner.CornerRadius = UDim.new(0, 10)
        side_corner.Parent = side_bar

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = container

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(52, 66, 89)
        stroke.Transparency = 0.5
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = container

        local handler = Instance.new("Frame")
        handler.BackgroundTransparency = 1
        handler.Name = "Handler"
        handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
        handler.Size = UDim2.new(0, 698, 0, 479)
        handler.BorderSizePixel = 0
        handler.BackgroundColor3 = Color3.fromRGB(48, 54, 70)
        handler.Parent = container

        local tabs_frame = Instance.new("ScrollingFrame")
        tabs_frame.ScrollBarImageTransparency = 1
        tabs_frame.ScrollBarThickness = 0
        tabs_frame.Name = "Tabs"
        tabs_frame.Size = UDim2.new(0, 129, 0, 401)
        tabs_frame.Selectable = false
        tabs_frame.AutomaticCanvasSize = Enum.AutomaticSize.XY
        tabs_frame.BackgroundTransparency = 1
        tabs_frame.Position = UDim2.new(0.026, 0, 0.111, 0)
        tabs_frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        tabs_frame.BackgroundColor3 = Color3.fromRGB(48, 54, 70)
        tabs_frame.BorderSizePixel = 0
        tabs_frame.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        tabs_frame.Parent = handler

        local tabs_layout = Instance.new("UIListLayout")
        tabs_layout.Padding = UDim.new(0, 4)
        tabs_layout.SortOrder = Enum.SortOrder.LayoutOrder
        tabs_layout.Parent = tabs_frame

        local client_name = Instance.new("TextLabel")
        client_name.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        client_name.TextColor3 = Color3.fromRGB(255, 183, 197)
        client_name.TextTransparency = 0.2
        client_name.Text = window._title or "UI"
        client_name.Name = "ClientName"
        client_name.Size = UDim2.new(0, 31, 0, 13)
        client_name.AnchorPoint = Vector2.new(0, 0.5)
        client_name.Position = UDim2.new(0.056, 0, 0.055, 0)
        client_name.BackgroundTransparency = 1
        client_name.TextXAlignment = Enum.TextXAlignment.Left
        client_name.BorderSizePixel = 0
        client_name.BorderColor3 = Color3.fromRGB(0, 0, 0)
        client_name.TextSize = 13
        client_name.BackgroundColor3 = Color3.fromRGB(48, 54, 70)
        client_name.Parent = handler

        local name_gradient = Instance.new("UIGradient")
        name_gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        })
        name_gradient.Parent = client_name

        local pin = Instance.new("Frame")
        pin.Name = "Pin"
        pin.Position = UDim2.new(0.026, 0, 0.136, 0)
        pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
        pin.Size = UDim2.new(0, 2, 0, 16)
        pin.BorderSizePixel = 0
        pin.BackgroundColor3 = Color3.fromRGB(255, 250, 250)
        pin.Parent = handler

        local pin_corner = Instance.new("UICorner")
        pin_corner.CornerRadius = UDim.new(1, 0)
        pin_corner.Parent = pin

        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Parent = handler
        icon.ImageColor3 = Color3.fromRGB(255, 250, 250)
        icon.ScaleType = Enum.ScaleType.Fit
        icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.BackgroundTransparency = 1
        icon.Position = UDim2.new(0.025, 0, 0.055, 0)
        icon.Size = UDim2.new(0, 18, 0, 18)
        icon.BorderSizePixel = 0
        icon.BackgroundColor3 = Color3.fromRGB(48, 54, 70)
        icon.Image = "rbxassetid://100375298524189"

        local divider = Instance.new("Frame")
        divider.Name = "Divider"
        divider.BackgroundTransparency = 0.5
        divider.Position = UDim2.new(0.235, 0, 0, 0)
        divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
        divider.Size = UDim2.new(0, 1, 0, 479)
        divider.BorderSizePixel = 0
        divider.BackgroundColor3 = Color3.fromRGB(52, 66, 89)
        divider.Parent = handler

        local sections = Instance.new("Folder")
        sections.Name = "Sections"
        sections.Parent = handler

        local minimize = Instance.new("TextButton")
        minimize.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        minimize.TextColor3 = Color3.fromRGB(255, 183, 197)
        minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
        minimize.Text = ""
        minimize.AutoButtonColor = false
        minimize.Name = "Minimize"
        minimize.BackgroundTransparency = 1
        minimize.Position = UDim2.new(0.02, 0, 0.029, 0)
        minimize.Size = UDim2.new(0, 24, 0, 24)
        minimize.BorderSizePixel = 0
        minimize.TextSize = 14
        minimize.BackgroundColor3 = Color3.fromRGB(48, 54, 70)
        minimize.Parent = handler

        local scale = Instance.new("UIScale")
        scale.Parent = container

        window._ui = screen_gui
        window._container = container
        window._handler = handler
        window._tabs_frame = tabs_frame
        window._sections_folder = sections
        window._pin = pin
        window._scale = scale

        local function on_drag(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                window._dragging = true
                window._drag_start = input.Position
                window._container_position = container.Position

                window._connections["container_input_ended"] = input.Changed:Connect(function()
                    if input.UserInputState ~= Enum.UserInputState.End then
                        return
                    end
                    window._connections:disconnect("container_input_ended")
                    window._dragging = false
                end)
            end
        end

        local function update_drag(input)
            local delta = input.Position - window._drag_start
            local position = UDim2.new(
                window._container_position.X.Scale,
                window._container_position.X.Offset + delta.X,
                window._container_position.Y.Scale,
                window._container_position.Y.Offset + delta.Y
            )
            TweenService:Create(container, TweenInfo.new(0.2), {Position = position}):Play()
        end

        local function drag(input)
            if not window._dragging then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                update_drag(input)
            end
        end

        window._connections["container_input_began"] = container.InputBegan:Connect(on_drag)
        window._connections["input_changed"] = UserInputService.InputChanged:Connect(drag)

        minimize.MouseButton1Click:Connect(function()
            window._ui_open = not window._ui_open
            window:Toggle(window._ui_open)
        end)

        UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.LeftControl then
                window._ui_open = not window._ui_open
                window:Toggle(window._ui_open)
            end
        end)

        return screen_gui
    end

    function window:Toggle(state)
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

    function window:Notify(settings)
        send_notification(settings)
    end

    function window:UpdateTabs(selected_tab)
        local selected_button = selected_tab._button
        for index, object in self._tabs_frame:GetChildren() do
            if object.Name ~= "Tab" or not object:IsA("TextButton") then
                continue
            end

            if object == selected_button then
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
                        TextColor3 = Color3.fromRGB(255, 183, 197)
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.2,
                        ImageColor3 = Color3.fromRGB(255, 250, 250)
                    }):Play()
                end
            else
                if object.BackgroundTransparency ~= 1 then
                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 1
                    }):Play()

                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0.7,
                        TextColor3 = Color3.fromRGB(255, 183, 197)
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.8,
                        ImageColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                end
            end
        end
    end

    function window:UpdateSections(left_section, right_section)
        for _, object in self._sections_folder:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true
            else
                object.Visible = false
            end
        end
    end

    function window:CreateTab(title, icon)
        local tab = {
            _title = title,
            _icon = icon or "rbxassetid://6031094678",
            _window = window,
            _button = nil,
            _left_section = nil,
            _right_section = nil,
            _modules = {},
            _tab_index = #window._tabs + 1,
            _connections = setmetatable({}, {__index = Connections})
        }

        local font_params = Instance.new("GetTextBoundsParams")
        font_params.Text = title
        font_params.Font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000
        local font_size = TextService:GetTextBoundsAsync(font_params)

        local is_first = #window._tabs == 0

        local button = Instance.new("TextButton")
        button.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        button.TextColor3 = Color3.fromRGB(255, 183, 197)
        button.BorderColor3 = Color3.fromRGB(0, 0, 0)
        button.Text = ""
        button.AutoButtonColor = false
        button.BackgroundTransparency = 1
        button.Name = "Tab"
        button.Size = UDim2.new(0, 129, 0, 38)
        button.BorderSizePixel = 0
        button.TextSize = 14
        button.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
        button.Parent = window._tabs_frame
        button.LayoutOrder = tab._tab_index - 1

        local tab_corner = Instance.new("UICorner")
        tab_corner.CornerRadius = UDim.new(0, 5)
        tab_corner.Parent = button

        local text_label = Instance.new("TextLabel")
        text_label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        text_label.TextColor3 = Color3.fromRGB(255, 183, 197)
        text_label.TextTransparency = 0.7
        text_label.Text = title
        text_label.Size = UDim2.new(0, font_size.X, 0, 16)
        text_label.AnchorPoint = Vector2.new(0, 0.5)
        text_label.Position = UDim2.new(0.24, 0, 0.5, 0)
        text_label.BackgroundTransparency = 1
        text_label.TextXAlignment = Enum.TextXAlignment.Left
        text_label.BorderSizePixel = 0
        text_label.BorderColor3 = Color3.fromRGB(0, 0, 0)
        text_label.TextSize = 13
        text_label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        text_label.Parent = button

        local text_gradient = Instance.new("UIGradient")
        text_gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58))
        })
        text_gradient.Parent = text_label

        local tab_icon = Instance.new("ImageLabel")
        tab_icon.ScaleType = Enum.ScaleType.Fit
        tab_icon.ImageTransparency = 0.8
        tab_icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        tab_icon.AnchorPoint = Vector2.new(0, 0.5)
        tab_icon.BackgroundTransparency = 1
        tab_icon.Position = UDim2.new(0.1, 0, 0.5, 0)
        tab_icon.Name = "Icon"
        tab_icon.Image = icon
        tab_icon.Size = UDim2.new(0, 12, 0, 12)
        tab_icon.BorderSizePixel = 0
        tab_icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        tab_icon.Parent = button

        button.TextLabel = text_label
        button.Icon = tab_icon

        tab._button = button

        local left_section = Instance.new("ScrollingFrame")
        left_section.Name = "LeftSection"
        left_section.AutomaticCanvasSize = Enum.AutomaticSize.XY
        left_section.ScrollBarThickness = 0
        left_section.Size = UDim2.new(0, 243, 0, 445)
        left_section.Selectable = false
        left_section.AnchorPoint = Vector2.new(0, 0.5)
        left_section.ScrollBarImageTransparency = 1
        left_section.BackgroundTransparency = 1
        left_section.Position = UDim2.new(0.2594, 0, 0.5, 0)
        left_section.BorderColor3 = Color3.fromRGB(0, 0, 0)
        left_section.BackgroundColor3 = Color3.fromRGB(48, 54, 70)
        left_section.BorderSizePixel = 0
        left_section.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        left_section.Visible = false
        left_section.Parent = window._sections_folder

        local left_layout = Instance.new("UIListLayout")
        left_layout.Padding = UDim.new(0, 11)
        left_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        left_layout.SortOrder = Enum.SortOrder.LayoutOrder
        left_layout.Parent = left_section

        local left_padding = Instance.new("UIPadding")
        left_padding.PaddingTop = UDim.new(0, 1)
        left_padding.Parent = left_section

        local right_section = Instance.new("ScrollingFrame")
        right_section.Name = "RightSection"
        right_section.AutomaticCanvasSize = Enum.AutomaticSize.XY
        right_section.ScrollBarThickness = 0
        right_section.Size = UDim2.new(0, 243, 0, 445)
        right_section.Selectable = false
        right_section.AnchorPoint = Vector2.new(0, 0.5)
        right_section.ScrollBarImageTransparency = 1
        right_section.BackgroundTransparency = 1
        right_section.Position = UDim2.new(0.629, 0, 0.5, 0)
        right_section.BorderColor3 = Color3.fromRGB(0, 0, 0)
        right_section.BackgroundColor3 = Color3.fromRGB(48, 54, 70)
        right_section.BorderSizePixel = 0
        right_section.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        right_section.Visible = false
        right_section.Parent = window._sections_folder

        local right_layout = Instance.new("UIListLayout")
        right_layout.Padding = UDim.new(0, 11)
        right_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        right_layout.SortOrder = Enum.SortOrder.LayoutOrder
        right_layout.Parent = right_section

        local right_padding = Instance.new("UIPadding")
        right_padding.PaddingTop = UDim.new(0, 1)
        right_padding.Parent = right_section

        tab._left_section = left_section
        tab._right_section = right_section

        if is_first then
            window:UpdateTabs(tab)
            window:UpdateSections(left_section, right_section)
        end

        button.MouseButton1Click:Connect(function()
            window:UpdateTabs(tab)
            window:UpdateSections(left_section, right_section)
        end)

        function tab:CreateModule(settings)
            local module = {
                _tab = tab,
                _title = settings.title or "Module",
                _description = settings.description or "",
                _flag = settings.flag or "",
                _section = settings.section or "left",
                _state = false,
                _size = 0,
                _multiplier = 0,
                _module_frame = nil,
                _options_frame = nil,
                _toggle_frame = nil,
                _circle_frame = nil,
                _header = nil,
                _connections = setmetatable({}, {__index = Connections}),
                _layout_order = 0
            }

            local parent_section = module._section == "right" and tab._right_section or tab._left_section

            local module_frame = Instance.new("Frame")
            module_frame.ClipsDescendants = true
            module_frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            module_frame.BackgroundTransparency = 0.5
            module_frame.Position = UDim2.new(0.0041, 0, 0, 0)
            module_frame.Name = "Module"
            module_frame.Size = UDim2.new(0, 241, 0, 93)
            module_frame.BorderSizePixel = 0
            module_frame.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
            module_frame.Parent = parent_section

            local module_layout = Instance.new("UIListLayout")
            module_layout.SortOrder = Enum.SortOrder.LayoutOrder
            module_layout.Parent = module_frame

            local module_corner = Instance.new("UICorner")
            module_corner.CornerRadius = UDim.new(0, 5)
            module_corner.Parent = module_frame

            local module_stroke = Instance.new("UIStroke")
            module_stroke.Color = Color3.fromRGB(52, 66, 89)
            module_stroke.Transparency = 0.5
            module_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            module_stroke.Parent = module_frame

            local header = Instance.new("TextButton")
            header.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            header.TextColor3 = Color3.fromRGB(255, 183, 197)
            header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            header.Text = ""
            header.AutoButtonColor = false
            header.BackgroundTransparency = 1
            header.Name = "Header"
            header.Size = UDim2.new(0, 241, 0, 93)
            header.BorderSizePixel = 0
            header.TextSize = 14
            header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            header.Parent = module_frame

            local icon = Instance.new("ImageLabel")
            icon.ImageColor3 = Color3.fromRGB(255, 250, 250)
            icon.ScaleType = Enum.ScaleType.Fit
            icon.ImageTransparency = 0.7
            icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
            icon.AnchorPoint = Vector2.new(0, 0.5)
            icon.Image = "rbxassetid://79095934438045"
            icon.BackgroundTransparency = 1
            icon.Position = UDim2.new(0.071, 0, 0.82, 0)
            icon.Name = "Icon"
            icon.Size = UDim2.new(0, 15, 0, 15)
            icon.BorderSizePixel = 0
            icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            icon.Parent = header

            local module_name = Instance.new("TextLabel")
            module_name.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            module_name.TextColor3 = Color3.fromRGB(255, 183, 197)
            module_name.TextTransparency = 0.2
            module_name.Text = module._title
            module_name.Name = "ModuleName"
            module_name.Size = UDim2.new(0, 205, 0, 13)
            module_name.AnchorPoint = Vector2.new(0, 0.5)
            module_name.Position = UDim2.new(0.073, 0, 0.24, 0)
            module_name.BackgroundTransparency = 1
            module_name.TextXAlignment = Enum.TextXAlignment.Left
            module_name.BorderSizePixel = 0
            module_name.BorderColor3 = Color3.fromRGB(0, 0, 0)
            module_name.TextSize = 13
            module_name.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            module_name.Parent = header

            local description = Instance.new("TextLabel")
            description.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            description.TextColor3 = Color3.fromRGB(255, 183, 197)
            description.TextTransparency = 0.7
            description.Text = module._description
            description.Name = "Description"
            description.Size = UDim2.new(0, 205, 0, 13)
            description.AnchorPoint = Vector2.new(0, 0.5)
            description.Position = UDim2.new(0.073, 0, 0.42, 0)
            description.BackgroundTransparency = 1
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.BorderSizePixel = 0
            description.BorderColor3 = Color3.fromRGB(0, 0, 0)
            description.TextSize = 10
            description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            description.Parent = header

            local toggle = Instance.new("Frame")
            toggle.Name = "Toggle"
            toggle.BackgroundTransparency = 0.7
            toggle.Position = UDim2.new(0.82, 0, 0.757, 0)
            toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            toggle.Size = UDim2.new(0, 25, 0, 12)
            toggle.BorderSizePixel = 0
            toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            toggle.Parent = header

            local toggle_corner = Instance.new("UICorner")
            toggle_corner.CornerRadius = UDim.new(1, 0)
            toggle_corner.Parent = toggle

            local circle = Instance.new("Frame")
            circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            circle.AnchorPoint = Vector2.new(0, 0.5)
            circle.BackgroundTransparency = 0.2
            circle.Position = UDim2.new(0, 0, 0.5, 0)
            circle.Name = "Circle"
            circle.Size = UDim2.new(0, 12, 0, 12)
            circle.BorderSizePixel = 0
            circle.BackgroundColor3 = Color3.fromRGB(66, 80, 115)
            circle.Parent = toggle

            local circle_corner = Instance.new("UICorner")
            circle_corner.CornerRadius = UDim.new(1, 0)
            circle_corner.Parent = circle

            local divider_top = Instance.new("Frame")
            divider_top.BorderColor3 = Color3.fromRGB(0, 0, 0)
            divider_top.AnchorPoint = Vector2.new(0.5, 0)
            divider_top.BackgroundTransparency = 0.5
            divider_top.Position = UDim2.new(0.5, 0, 0.62, 0)
            divider_top.Name = "Divider"
            divider_top.Size = UDim2.new(0, 241, 0, 1)
            divider_top.BorderSizePixel = 0
            divider_top.BackgroundColor3 = Color3.fromRGB(52, 66, 89)
            divider_top.Parent = header

            local divider_bottom = Instance.new("Frame")
            divider_bottom.BorderColor3 = Color3.fromRGB(0, 0, 0)
            divider_bottom.AnchorPoint = Vector2.new(0.5, 0)
            divider_bottom.BackgroundTransparency = 0.5
            divider_bottom.Position = UDim2.new(0.5, 0, 1, 0)
            divider_bottom.Name = "Divider"
            divider_bottom.Size = UDim2.new(0, 241, 0, 1)
            divider_bottom.BorderSizePixel = 0
            divider_bottom.BackgroundColor3 = Color3.fromRGB(52, 66, 89)
            divider_bottom.Parent = header

            local options = Instance.new("Frame")
            options.Name = "Options"
            options.BackgroundTransparency = 1
            options.Position = UDim2.new(0, 0, 1, 0)
            options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            options.Size = UDim2.new(0, 241, 0, 8)
            options.BorderSizePixel = 0
            options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            options.Parent = module_frame

            local options_padding = Instance.new("UIPadding")
            options_padding.PaddingTop = UDim.new(0, 8)
            options_padding.Parent = options

            local options_layout = Instance.new("UIListLayout")
            options_layout.Padding = UDim.new(0, 5)
            options_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            options_layout.SortOrder = Enum.SortOrder.LayoutOrder
            options_layout.Parent = options

            module._module_frame = module_frame
            module._options_frame = options
            module._toggle_frame = toggle
            module._circle_frame = circle
            module._header = header

            function module:Toggle(state)
                module._state = state
                if state then
                    TweenService:Create(module_frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + module._size + module._multiplier)
                    }):Play()

                    TweenService:Create(toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(255, 250, 250)
                    }):Play()

                    TweenService:Create(circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(255, 250, 250),
                        Position = UDim2.fromScale(0.53, 0.5)
                    }):Play()
                else
                    TweenService:Create(module_frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()

                    TweenService:Create(toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    }):Play()

                    TweenService:Create(circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(66, 80, 115),
                        Position = UDim2.fromScale(0, 0.5)
                    }):Play()
                end

                if settings.callback then
                    settings.callback(state)
                end
            end

            header.MouseButton1Click:Connect(function()
                module:Toggle(not module._state)
            end)

            function module:CreateDivider(settings)
                module._layout_order = module._layout_order + 1

                if module._size == 0 then
                    module._size = 11
                end

                local divider_height = 20
                module._size = module._size + divider_height

                if module._state then
                    module_frame.Size = UDim2.fromOffset(241, 93 + module._size)
                end
                options.Size = UDim2.fromOffset(241, module._size)

                local outer = Instance.new("Frame")
                outer.Size = UDim2.new(0, 207, 0, divider_height)
                outer.BackgroundTransparency = 1
                outer.Name = "OuterFrame"
                outer.Parent = options
                outer.LayoutOrder = module._layout_order

                if settings and settings.title then
                    local label = Instance.new("TextLabel")
                    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    label.TextColor3 = Color3.fromRGB(255, 183, 197)
                    label.TextTransparency = 0
                    label.Text = settings.title
                    label.Size = UDim2.new(0, 153, 0, 13)
                    label.Position = UDim2.new(0.5, 0, 0.5, 0)
                    label.BackgroundTransparency = 1
                    label.TextXAlignment = Enum.TextXAlignment.Center
                    label.BorderSizePixel = 0
                    label.AnchorPoint = Vector2.new(0.5, 0.5)
                    label.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    label.TextSize = 11
                    label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    label.ZIndex = 3
                    label.TextStrokeTransparency = 0
                    label.Parent = outer
                end

                if not settings or not settings.disableline then
                    local divider = Instance.new("Frame")
                    divider.Size = UDim2.new(1, 0, 0, 1)
                    divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    divider.BorderSizePixel = 0
                    divider.Name = "Divider"
                    divider.Parent = outer
                    divider.ZIndex = 2
                    divider.Position = UDim2.new(0, 0, 0.5, -0.5)

                    local gradient = Instance.new("UIGradient")
                    gradient.Parent = divider
                    gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255, 0))
                    })
                    gradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    gradient.Rotation = 0

                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 2)
                    corner.Parent = divider
                end

                return true
            end

            function module:CreateCheckbox(settings)
                module._layout_order = module._layout_order + 1

                if module._size == 0 then
                    module._size = 11
                end
                module._size = module._size + 20

                if module._state then
                    module_frame.Size = UDim2.fromOffset(241, 93 + module._size)
                end
                options.Size = UDim2.fromOffset(241, module._size)

                local checkbox = Instance.new("TextButton")
                checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                checkbox.TextColor3 = Color3.fromRGB(255, 183, 197)
                checkbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                checkbox.Text = ""
                checkbox.AutoButtonColor = false
                checkbox.BackgroundTransparency = 1
                checkbox.Name = "Checkbox"
                checkbox.Size = UDim2.new(0, 207, 0, 15)
                checkbox.BorderSizePixel = 0
                checkbox.TextSize = 14
                checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                checkbox.Parent = options
                checkbox.LayoutOrder = module._layout_order

                local title_label = Instance.new("TextLabel")
                title_label.Name = "TitleLabel"
                title_label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                title_label.TextSize = 11
                title_label.TextColor3 = Color3.fromRGB(255, 183, 197)
                title_label.TextTransparency = 0.2
                title_label.Text = settings.title or "Checkbox"
                title_label.Size = UDim2.new(0, 142, 0, 13)
                title_label.AnchorPoint = Vector2.new(0, 0.5)
                title_label.Position = UDim2.new(0, 0, 0.5, 0)
                title_label.BackgroundTransparency = 1
                title_label.TextXAlignment = Enum.TextXAlignment.Left
                title_label.Parent = checkbox

                local box = Instance.new("Frame")
                box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                box.AnchorPoint = Vector2.new(1, 0.5)
                box.BackgroundTransparency = 0.9
                box.Position = UDim2.new(1, 0, 0.5, 0)
                box.Name = "Box"
                box.Size = UDim2.new(0, 15, 0, 15)
                box.BorderSizePixel = 0
                box.BackgroundColor3 = Color3.fromRGB(255, 250, 250)
                box.Parent = checkbox

                local box_corner = Instance.new("UICorner")
                box_corner.CornerRadius = UDim.new(0, 4)
                box_corner.Parent = box

                local fill = Instance.new("Frame")
                fill.AnchorPoint = Vector2.new(0.5, 0.5)
                fill.BackgroundTransparency = 0.2
                fill.Position = UDim2.new(0.5, 0, 0.5, 0)
                fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                fill.Name = "Fill"
                fill.BorderSizePixel = 0
                fill.BackgroundColor3 = Color3.fromRGB(255, 250, 250)
                fill.Parent = box

                local fill_corner = Instance.new("UICorner")
                fill_corner.CornerRadius = UDim.new(0, 3)
                fill_corner.Parent = fill

                local checkbox_state = false

                local function toggle_checkbox()
                    checkbox_state = not checkbox_state
                    if checkbox_state then
                        TweenService:Create(box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.7
                        }):Play()
                        TweenService:Create(fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(9, 9)
                        }):Play()
                    else
                        TweenService:Create(box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.9
                        }):Play()
                        TweenService:Create(fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(0, 0)
                        }):Play()
                    end
                    if settings.callback then
                        settings.callback(checkbox_state)
                    end
                end

                checkbox.MouseButton1Click:Connect(toggle_checkbox)

                return {
                    Toggle = toggle_checkbox,
                    SetState = function(state)
                        if checkbox_state ~= state then
                            toggle_checkbox()
                        end
                    end,
                    GetState = function()
                        return checkbox_state
                    end
                }
            end

            function module:CreateButton(settings)
                module._layout_order = module._layout_order + 1

                if module._size == 0 then
                    module._size = 11
                end
                module._size = module._size + 20

                if module._state then
                    module_frame.Size = UDim2.fromOffset(241, 93 + module._size)
                end
                options.Size = UDim2.fromOffset(241, module._size)

                local button = Instance.new("TextButton")
                button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                button.TextColor3 = Color3.fromRGB(255, 183, 197)
                button.TextTransparency = 0.2
                button.Text = settings.title or "Button"
                button.AutoButtonColor = true
                button.BackgroundTransparency = 0.2
                button.BackgroundColor3 = Color3.fromRGB(41, 49, 62)
                button.Name = "Button"
                button.Size = UDim2.new(0, 207, 0, 20)
                button.BorderSizePixel = 0
                button.TextSize = 11
                button.Parent = options
                button.LayoutOrder = module._layout_order

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 4)
                corner.Parent = button

                button.MouseButton1Click:Connect(function()
                    if settings.callback then
                        settings.callback()
                    end
                end)

                return button
            end

            function module:CreateSlider(settings)
                module._layout_order = module._layout_order + 1

                if module._size == 0 then
                    module._size = 11
                end
                module._size = module._size + 27

                if module._state then
                    module_frame.Size = UDim2.fromOffset(241, 93 + module._size)
                end
                options.Size = UDim2.fromOffset(241, module._size)

                local slider = Instance.new("TextButton")
                slider.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                slider.TextSize = 14
                slider.TextColor3 = Color3.fromRGB(255, 183, 197)
                slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                slider.Text = ""
                slider.AutoButtonColor = false
                slider.BackgroundTransparency = 1
                slider.Name = "Slider"
                slider.Size = UDim2.new(0, 207, 0, 22)
                slider.BorderSizePixel = 0
                slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                slider.Parent = options
                slider.LayoutOrder = module._layout_order

                local title_label = Instance.new("TextLabel")
                title_label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                title_label.TextSize = 11
                title_label.TextColor3 = Color3.fromRGB(255, 183, 197)
                title_label.TextTransparency = 0.2
                title_label.Text = settings.title or "Slider"
                title_label.Size = UDim2.new(0, 153, 0, 13)
                title_label.Position = UDim2.new(0, 0, 0.05, 0)
                title_label.BackgroundTransparency = 1
                title_label.TextXAlignment = Enum.TextXAlignment.Left
                title_label.BorderSizePixel = 0
                title_label.BorderColor3 = Color3.fromRGB(0, 0, 0)
                title_label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                title_label.Parent = slider

                local drag = Instance.new("Frame")
                drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
                drag.AnchorPoint = Vector2.new(0.5, 1)
                drag.BackgroundTransparency = 0.9
                drag.Position = UDim2.new(0.5, 0, 0.95, 0)
                drag.Name = "Drag"
                drag.Size = UDim2.new(0, 207, 0, 4)
                drag.BorderSizePixel = 0
                drag.BackgroundColor3 = Color3.fromRGB(255, 250, 250)
                drag.Parent = slider

                local drag_corner = Instance.new("UICorner")
                drag_corner.CornerRadius = UDim.new(1, 0)
                drag_corner.Parent = drag

                local fill = Instance.new("Frame")
                fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                fill.AnchorPoint = Vector2.new(0, 0.5)
                fill.BackgroundTransparency = 0.5
                fill.Position = UDim2.new(0, 0, 0.5, 0)
                fill.Name = "Fill"
                fill.Size = UDim2.new(0, 103, 0, 4)
                fill.BorderSizePixel = 0
                fill.BackgroundColor3 = Color3.fromRGB(255, 250, 250)
                fill.Parent = drag

                local fill_corner = Instance.new("UICorner")
                fill_corner.CornerRadius = UDim.new(0, 3)
                fill_corner.Parent = fill

                local fill_gradient = Instance.new("UIGradient")
                fill_gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(79, 79, 79))
                })
                fill_gradient.Parent = fill

                local circle = Instance.new("Frame")
                circle.AnchorPoint = Vector2.new(1, 0.5)
                circle.Name = "Circle"
                circle.Position = UDim2.new(1, 0, 0.5, 0)
                circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                circle.Size = UDim2.new(0, 6, 0, 6)
                circle.BorderSizePixel = 0
                circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                circle.Parent = fill

                local circle_corner = Instance.new("UICorner")
                circle_corner.CornerRadius = UDim.new(1, 0)
                circle_corner.Parent = circle

                local value_label = Instance.new("TextLabel")
                value_label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                value_label.TextColor3 = Color3.fromRGB(255, 183, 197)
                value_label.TextTransparency = 0.2
                value_label.Text = "50"
                value_label.Name = "Value"
                value_label.Size = UDim2.new(0, 42, 0, 13)
                value_label.AnchorPoint = Vector2.new(1, 0)
                value_label.Position = UDim2.new(1, 0, 0, 0)
                value_label.BackgroundTransparency = 1
                value_label.TextXAlignment = Enum.TextXAlignment.Right
                value_label.BorderSizePixel = 0
                value_label.BorderColor3 = Color3.fromRGB(0, 0, 0)
                value_label.TextSize = 10
                value_label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                value_label.Parent = slider

                local min_val = settings.minimum_value or 0
                local max_val = settings.maximum_value or 100
                local current_val = settings.value or 50
                local round_num = settings.round_number or false

                local function set_value(percentage)
                    local value = min_val + (max_val - min_val) * percentage
                    if round_num then
                        value = math.floor(value)
                    else
                        value = math.floor(value * 10) / 10
                    end
                    value = math.clamp(value, min_val, max_val)
                    local clamped_percentage = (value - min_val) / (max_val - min_val)
                    local slider_size = math.clamp(clamped_percentage, 0.02, 1) * 207

                    value_label.Text = tostring(value)
                    TweenService:Create(fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, 4)
                    }):Play()

                    if settings.callback then
                        settings.callback(value)
                    end
                end

                local function update_slider()
                    local success, mouse_pos = pcall(function()
                        return UserInputService:GetMouseLocation()
                    end)
                    if not success then
                        return
                    end
                    local drag_width = drag.AbsoluteSize.X
                    if drag_width == 0 then
                        drag_width = 207
                    end
                    local rel_x = (mouse_pos.X - drag.AbsolutePosition.X) / drag_width
                    set_value(math.clamp(rel_x, 0, 1))
                end

                slider.MouseButton1Down:Connect(function()
                    update_slider()
                    local change_conn = UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                            update_slider()
                        end
                    end)
                    local end_conn = UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            change_conn:Disconnect()
                            end_conn:Disconnect()
                        end
                    end)
                end)

                -- Set initial value
                local init_pct = (current_val - min_val) / (max_val - min_val)
                set_value(math.clamp(init_pct, 0, 1))

                return {
                    SetValue = set_value,
                    GetValue = function()
                        return tonumber(value_label.Text) or current_val
                    end
                }
            end

            function module:CreateTextbox(settings)
                module._layout_order = module._layout_order + 1

                if module._size == 0 then
                    module._size = 11
                end
                module._size = module._size + 32

                if module._state then
                    module_frame.Size = UDim2.fromOffset(241, 93 + module._size)
                end
                options.Size = UDim2.fromOffset(241, module._size)

                local label = Instance.new("TextLabel")
                label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                label.TextColor3 = Color3.fromRGB(255, 183, 197)
                label.TextTransparency = 0.2
                label.Text = settings.title or "Enter text"
                label.Size = UDim2.new(0, 207, 0, 13)
                label.AnchorPoint = Vector2.new(0, 0)
                label.Position = UDim2.new(0, 0, 0, 0)
                label.BackgroundTransparency = 1
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BorderSizePixel = 0
                label.Parent = options
                label.TextSize = 10
                label.LayoutOrder = module._layout_order

                local textbox = Instance.new("TextBox")
                textbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                textbox.TextColor3 = Color3.fromRGB(255, 183, 197)
                textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                textbox.PlaceholderText = settings.placeholder or "Enter text..."
                textbox.Text = ""
                textbox.Name = "Textbox"
                textbox.Size = UDim2.new(0, 207, 0, 15)
                textbox.BorderSizePixel = 0
                textbox.TextSize = 10
                textbox.BackgroundColor3 = Color3.fromRGB(255, 250, 250)
                textbox.BackgroundTransparency = 0.9
                textbox.ClearTextOnFocus = false
                textbox.Parent = options
                textbox.LayoutOrder = module._layout_order

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 4)
                corner.Parent = textbox

                textbox.FocusLost:Connect(function()
                    if settings.callback then
                        settings.callback(textbox.Text)
                    end
                end)

                return {
                    SetText = function(text)
                        textbox.Text = text
                    end,
                    GetText = function()
                        return textbox.Text
                    end
                }
            end

            function module:CreateDropdown(settings)
                module._layout_order = module._layout_order + 1

                if module._size == 0 then
                    module._size = 11
                end
                module._size = module._size + 44

                if module._state then
                    module_frame.Size = UDim2.fromOffset(241, 93 + module._size)
                end
                options.Size = UDim2.fromOffset(241, module._size)

                local dropdown = Instance.new("TextButton")
                dropdown.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                dropdown.TextColor3 = Color3.fromRGB(255, 183, 197)
                dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                dropdown.Text = ""
                dropdown.AutoButtonColor = false
                dropdown.BackgroundTransparency = 1
                dropdown.Name = "Dropdown"
                dropdown.Size = UDim2.new(0, 207, 0, 39)
                dropdown.BorderSizePixel = 0
                dropdown.TextSize = 14
                dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                dropdown.Parent = options
                dropdown.LayoutOrder = module._layout_order

                local title_label = Instance.new("TextLabel")
                title_label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                title_label.TextSize = 11
                title_label.TextColor3 = Color3.fromRGB(255, 183, 197)
                title_label.TextTransparency = 0.2
                title_label.Text = settings.title or "Dropdown"
                title_label.Size = UDim2.new(0, 207, 0, 13)
                title_label.BackgroundTransparency = 1
                title_label.TextXAlignment = Enum.TextXAlignment.Left
                title_label.BorderSizePixel = 0
                title_label.BorderColor3 = Color3.fromRGB(0, 0, 0)
                title_label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                title_label.Parent = dropdown

                local box = Instance.new("Frame")
                box.ClipsDescendants = true
                box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                box.AnchorPoint = Vector2.new(0.5, 0)
                box.BackgroundTransparency = 0.9
                box.Position = UDim2.new(0.5, 0, 1.2, 0)
                box.Name = "Box"
                box.Size = UDim2.new(0, 207, 0, 22)
                box.BorderSizePixel = 0
                box.BackgroundColor3 = Color3.fromRGB(255, 250, 250)
                box.Parent = title_label

                local box_corner = Instance.new("UICorner")
                box_corner.CornerRadius = UDim.new(0, 4)
                box_corner.Parent = box

                local header = Instance.new("Frame")
                header.BorderColor3 = Color3.fromRGB(0, 0, 0)
                header.AnchorPoint = Vector2.new(0.5, 0)
                header.BackgroundTransparency = 1
                header.Position = UDim2.new(0.5, 0, 0, 0)
                header.Name = "Header"
                header.Size = UDim2.new(0, 207, 0, 22)
                header.BorderSizePixel = 0
                header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                header.Parent = box

                local current = Instance.new("TextLabel")
                current.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                current.TextColor3 = Color3.fromRGB(255, 183, 197)
                current.TextTransparency = 0.2
                current.Name = "CurrentOption"
                current.Size = UDim2.new(0, 161, 0, 13)
                current.AnchorPoint = Vector2.new(0, 0.5)
                current.Position = UDim2.new(0.05, 0, 0.5, 0)
                current.BackgroundTransparency = 1
                current.TextXAlignment = Enum.TextXAlignment.Left
                current.BorderSizePixel = 0
                current.BorderColor3 = Color3.fromRGB(0, 0, 0)
                current.TextSize = 10
                current.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                current.Parent = header

                local arrow = Instance.new("ImageLabel")
                arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                arrow.AnchorPoint = Vector2.new(0, 0.5)
                arrow.Image = "rbxassetid://84232453189324"
                arrow.BackgroundTransparency = 1
                arrow.Position = UDim2.new(0.91, 0, 0.5, 0)
                arrow.Name = "Arrow"
                arrow.Size = UDim2.new(0, 8, 0, 8)
                arrow.BorderSizePixel = 0
                arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                arrow.Parent = header

                local options_list = Instance.new("ScrollingFrame")
                options_list.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
                options_list.Active = true
                options_list.ScrollBarImageTransparency = 1
                options_list.AutomaticCanvasSize = Enum.AutomaticSize.XY
                options_list.ScrollBarThickness = 0
                options_list.Name = "Options"
                options_list.Size = UDim2.new(0, 207, 0, 0)
                options_list.BackgroundTransparency = 1
                options_list.Position = UDim2.new(0, 0, 1, 0)
                options_list.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                options_list.BorderColor3 = Color3.fromRGB(0, 0, 0)
                options_list.BorderSizePixel = 0
                options_list.CanvasSize = UDim2.new(0, 0, 0.5, 0)
                options_list.Parent = box

                local opt_layout = Instance.new("UIListLayout")
                opt_layout.SortOrder = Enum.SortOrder.LayoutOrder
                opt_layout.Parent = options_list

                local opt_padding = Instance.new("UIPadding")
                opt_padding.PaddingTop = UDim.new(0, -1)
                opt_padding.PaddingLeft = UDim.new(0, 10)
                opt_padding.Parent = options_list

                local is_open = false
                local drop_size = 0

                local function toggle_dropdown()
                    is_open = not is_open
                    if is_open then
                        module._multiplier = module._multiplier + drop_size
                        TweenService:Create(module_frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + module._size + module._multiplier)
                        }):Play()
                        TweenService:Create(options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, module._size + module._multiplier)
                        }):Play()
                        TweenService:Create(dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39 + drop_size)
                        }):Play()
                        TweenService:Create(box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22 + drop_size)
                        }):Play()
                        TweenService:Create(arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 180
                        }):Play()
                    else
                        module._multiplier = module._multiplier - drop_size
                        TweenService:Create(module_frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + module._size + module._multiplier)
                        }):Play()
                        TweenService:Create(options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, module._size + module._multiplier)
                        }):Play()
                        TweenService:Create(dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39)
                        }):Play()
                        TweenService:Create(box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22)
                        }):Play()
                        TweenService:Create(arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 0
                        }):Play()
                    end
                end

                local options_data = settings.options or {"Option 1", "Option 2", "Option 3"}
                local selected = options_data[1]

                for i, opt in ipairs(options_data) do
                    local opt_btn = Instance.new("TextButton")
                    opt_btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    opt_btn.Active = false
                    opt_btn.TextTransparency = 0.6
                    opt_btn.AnchorPoint = Vector2.new(0, 0.5)
                    opt_btn.TextSize = 10
                    opt_btn.Size = UDim2.new(0, 186, 0, 16)
                    opt_btn.TextColor3 = Color3.fromRGB(255, 183, 197)
                    opt_btn.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    opt_btn.Text = opt
                    opt_btn.AutoButtonColor = false
                    opt_btn.Name = "Option"
                    opt_btn.BackgroundTransparency = 1
                    opt_btn.TextXAlignment = Enum.TextXAlignment.Left
                    opt_btn.Selectable = false
                    opt_btn.Position = UDim2.new(0.05, 0, 0.342, 0)
                    opt_btn.BorderSizePixel = 0
                    opt_btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    opt_btn.Parent = options_list

                    drop_size = drop_size + 16
                    options_list.Size = UDim2.fromOffset(207, drop_size)

                    opt_btn.MouseButton1Click:Connect(function()
                        selected = opt
                        current.Text = opt
                        for _, child in options_list:GetChildren() do
                            if child.Name == "Option" and child:IsA("TextButton") then
                                if child.Text == opt then
                                    child.TextTransparency = 0.2
                                else
                                    child.TextTransparency = 0.6
                                end
                            end
                        end
                        if settings.callback then
                            settings.callback(opt)
                        end
                        toggle_dropdown()
                    end)
                end

                current.Text = selected

                dropdown.MouseButton1Click:Connect(toggle_dropdown)

                return {
                    SetValue = function(value)
                        for _, child in options_list:GetChildren() do
                            if child.Name == "Option" and child:IsA("TextButton") and child.Text == value then
                                selected = value
                                current.Text = value
                                for _, c in options_list:GetChildren() do
                                    if c.Name == "Option" and c:IsA("TextButton") then
                                        c.TextTransparency = (c.Text == value) and 0.2 or 0.6
                                    end
                                end
                                if settings.callback then
                                    settings.callback(value)
                                end
                                break
                            end
                        end
                    end,
                    GetValue = function()
                        return selected
                    end
                }
            end

            -- Return the module
            return module
        end

        table.insert(window._tabs, tab)
        return tab
    end

    function window:Open()
        if self._ui then
            self._ui.Enabled = true
        end
    end

    function window:Close()
        if self._ui then
            self._ui.Enabled = false
        end
    end

    function window:Destroy()
        if self._ui then
            self._ui:Destroy()
        end
        self._connections:disconnect_all()
        for _, tab in ipairs(self._tabs) do
            tab._connections:disconnect_all()
        end
    end

    create_ui()
    table.insert(self._windows, window) -- Use self._windows instead of Library._windows
    return window
end

function Library:Destroy()
    for _, window in ipairs(self._windows) do
        window:Destroy()
    end
    self._windows = {}
    self._connections:disconnect_all()
end

-- Return the library
return Library
