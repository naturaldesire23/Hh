-- ============================================================
-- NexUI_Lib.lua  v1.0
-- Merged from PortalVisuals_Lib + UwU Premium AP
-- Structure: Portal Visuals | Visuals/Toasts: UwU Premium
-- Fixed window position (no drag). Init sequence: custom.
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Stats             = game:GetService("Stats")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

if _G._NexUI and _G._NexUI._cleanup then
    pcall(_G._NexUI._cleanup)
end
_G._NexUI = {}
local _lib = _G._NexUI

-- ─────────────────────────────────────────────────────────────
-- THEMES
-- ─────────────────────────────────────────────────────────────
local Themes = {
    Dark = {
        GlassBg   = Color3.fromRGB(14, 16, 22),
        GlassLeft = Color3.fromRGB(20, 22, 32),
        GlassCard = Color3.fromRGB(28, 31, 44),
        Accent    = Color3.fromRGB(120, 80, 255),
        Accent2   = Color3.fromRGB(170, 110, 255),
        Text      = Color3.fromRGB(240, 245, 255),
        TextSoft  = Color3.fromRGB(160, 170, 200),
        TextMuted = Color3.fromRGB(90, 100, 130),
        Online    = Color3.fromRGB(50, 220, 120),
        TrackOff  = Color3.fromRGB(45, 50, 72),
        TrackOn   = Color3.fromRGB(120, 80, 255),
        Stroke    = Color3.fromRGB(50, 55, 80),
        Shine     = Color3.fromRGB(255, 255, 255),
        Warn      = Color3.fromRGB(200, 140, 25),
        Danger    = Color3.fromRGB(215, 65, 65),
    },
    Midnight = {
        GlassBg   = Color3.fromRGB(6, 8, 18),
        GlassLeft = Color3.fromRGB(10, 12, 26),
        GlassCard = Color3.fromRGB(18, 20, 36),
        Accent    = Color3.fromRGB(0, 180, 255),
        Accent2   = Color3.fromRGB(60, 220, 255),
        Text      = Color3.fromRGB(220, 235, 255),
        TextSoft  = Color3.fromRGB(130, 155, 200),
        TextMuted = Color3.fromRGB(70, 90, 140),
        Online    = Color3.fromRGB(60, 230, 150),
        TrackOff  = Color3.fromRGB(30, 36, 60),
        TrackOn   = Color3.fromRGB(0, 180, 255),
        Stroke    = Color3.fromRGB(35, 45, 90),
        Shine     = Color3.fromRGB(200, 225, 255),
        Warn      = Color3.fromRGB(200, 140, 25),
        Danger    = Color3.fromRGB(215, 65, 65),
    },
    Amethyst = {
        GlassBg   = Color3.fromRGB(16, 12, 28),
        GlassLeft = Color3.fromRGB(22, 16, 40),
        GlassCard = Color3.fromRGB(34, 24, 60),
        Accent    = Color3.fromRGB(160, 80, 230),
        Accent2   = Color3.fromRGB(210, 130, 255),
        Text      = Color3.fromRGB(240, 230, 255),
        TextSoft  = Color3.fromRGB(155, 130, 195),
        TextMuted = Color3.fromRGB(100, 80, 145),
        Online    = Color3.fromRGB(100, 220, 150),
        TrackOff  = Color3.fromRGB(50, 35, 85),
        TrackOn   = Color3.fromRGB(160, 80, 230),
        Stroke    = Color3.fromRGB(60, 40, 100),
        Shine     = Color3.fromRGB(220, 190, 255),
        Warn      = Color3.fromRGB(200, 140, 25),
        Danger    = Color3.fromRGB(215, 65, 65),
    },
}

-- ─────────────────────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────────────────────
local function Create(Class, Props)
    local obj = Instance.new(Class)
    for k, v in pairs(Props) do
        if k ~= "Parent" then obj[k] = v end
    end
    if Props.Parent then obj.Parent = Props.Parent end
    return obj
end

local function Tween(obj, props, dur, style, dir)
    if typeof(props) == "TweenInfo" then
        props, dur = dur, props
    end
    local info = (typeof(dur) == "TweenInfo") and dur or TweenInfo.new(dur or 0.5, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play(); return t
end

local function Corner(parent, r)
    return Create("UICorner", {Parent = parent, CornerRadius = UDim.new(0, r or 10)})
end

local function Stroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Parent = parent, Color = color, Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
end

local function Ripple(parent, x, y)
    local r = Create("Frame", {
        Parent = parent,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, x, 0, y),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = 40,
    })
    Corner(r, 300)
    local d = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 1.8
    Tween(r, {Size = UDim2.new(0, d, 0, d), BackgroundTransparency = 1}, 0.55, Enum.EasingStyle.Quad)
    task.delay(0.6, function() if r and r.Parent then r:Destroy() end end)
end

local function ClickRipple(el)
    el.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            pcall(function()
                Ripple(el, input.Position.X - el.AbsolutePosition.X, input.Position.Y - el.AbsolutePosition.Y)
            end)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────
-- NEXUI CLASS
-- ─────────────────────────────────────────────────────────────
local NexUI = {}
NexUI.__index = NexUI
NexUI.Themes = Themes

function NexUI.new(title, options)
    options = options or {}
    local self = setmetatable({}, NexUI)

    self._theme       = Themes[options.theme or "Dark"] or Themes.Dark
    self._themeReg    = {}
    self._keybinds    = {}
    self._tabs        = {}
    self._currentTab  = nil
    self._isOpen      = true
    self._flags       = {}
    self._stars       = {}
    self._W           = (options.size and options.size[1]) or 740
    self._H           = (options.size and options.size[2]) or 580
    self._accent      = self._theme.Accent
    self._accent2     = self._theme.Accent2
    self._accentLinks = {}
    self._rainbowMode = false
    self._toastCount  = 0

    -- Root GUI
    self._gui = Create("ScreenGui", {
        Name             = "NexUI_" .. title,
        Parent           = CoreGui,
        ResetOnSpawn     = false,
        ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
        DisplayOrder     = 999,
        IgnoreGuiInset   = true,
    })

    self._blur = Create("BlurEffect", {Size = 0, Parent = Lighting})

    -- Layers
    self:_buildToastLayer()
    self:_buildWatermark(title)
    self:_buildMainWindow(title, options.subtitle or "")
    self:_buildAtmosphere()
    self:_buildInitSequence(title)

    -- Keybind input
    local menuKey = options.menuKey or Enum.KeyCode.K
    self._menuKey = menuKey
    self:Bind(menuKey, "$$menu$$", function() self:Toggle() end)

    self._inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local entry = self._keybinds[input.KeyCode]
        if entry then
            for _, cb in pairs(entry.callbacks) do task.spawn(cb) end
        end
    end)

    _lib._cleanup = function() self:Destroy() end
    return self
end

-- ─── KEYBIND ENGINE ──────────────────────────────────────────
function NexUI:Bind(key, id, fn)
    if not self._keybinds[key] then self._keybinds[key] = {callbacks = {}} end
    self._keybinds[key].callbacks[id] = fn
end

function NexUI:Unbind(key, id)
    local entry = self._keybinds[key]
    if entry then entry.callbacks[id] = nil end
end

-- ─── THEME REGISTRY ──────────────────────────────────────────
function NexUI:_reg(obj, prop, key)
    table.insert(self._themeReg, {Object = obj, Property = prop, Key = key})
end

function NexUI:_regAccent(obj, prop, useAccent2)
    table.insert(self._accentLinks, {o = obj, p = prop, alt = useAccent2 and true or false})
end

function NexUI:_applyAccent(c1, c2)
    self._accent  = c1
    self._accent2 = c2 or c1
    for _, l in ipairs(self._accentLinks) do
        pcall(function()
            local val = l.alt and self._accent2 or self._accent
            Tween(l.o, {[l.p] = val}, 0.35)
        end)
    end
end

function NexUI:SetTheme(name)
    local new = Themes[name]
    if not new then return end
    self._theme = new
    for _, e in ipairs(self._themeReg) do
        if e.Object and e.Object.Parent then
            Tween(e.Object, {[e.Property] = new[e.Key]}, 0.5)
        end
    end
    self:_applyAccent(new.Accent, new.Accent2)
    self:Toast("Theme", name .. " applied", 2)
end

-- ─── WATERMARK ───────────────────────────────────────────────
function NexUI:_buildWatermark(title)
    local T = self._theme
    local wmGui = Create("ScreenGui", {
        Name = "NexUI_WM_" .. title, Parent = CoreGui,
        ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100000,
    })
    self._wmGui = wmGui

    local card = Create("Frame", {
        Parent = wmGui, AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0, 8, 0, 6), Size = UDim2.new(0, 240, 0, 30),
        BackgroundColor3 = T.GlassBg, BackgroundTransparency = 0.18,
        BorderSizePixel = 0, ZIndex = 100,
    })
    self:_reg(card, "BackgroundColor3", "GlassBg")
    Corner(card, 10)
    local wStroke = Stroke(card, T.Stroke, 1, 0.5)
    self:_reg(wStroke, "Color", "Stroke")

    -- Pulse dot
    local dot = Create("Frame", {
        Parent = card, BackgroundColor3 = T.Online,
        BorderSizePixel = 0, Position = UDim2.new(0, 10, 0.5, -3),
        Size = UDim2.new(0, 6, 0, 6), ZIndex = 103,
    })
    Corner(dot, 300)
    self:_reg(dot, "BackgroundColor3", "Online")
    task.spawn(function()
        while dot and dot.Parent do
            Tween(dot, {BackgroundTransparency = 0.5, Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 9, 0.5, -4)}, 0.7, Enum.EasingStyle.Sine)
            task.wait(0.7)
            Tween(dot, {BackgroundTransparency = 0, Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(0, 10, 0.5, -3)}, 0.7, Enum.EasingStyle.Sine)
            task.wait(0.7)
        end
    end)

    local logo = Create("TextLabel", {
        Parent = card, BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(0, 72, 1, 0),
        Font = Enum.Font.GothamBold, Text = title,
        TextColor3 = T.Text, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102,
    })
    self:_reg(logo, "TextColor3", "Text")

    local sep = Create("TextLabel", {
        Parent = card, BackgroundTransparency = 1,
        Position = UDim2.new(0, 94, 0, 0), Size = UDim2.new(0, 10, 1, 0),
        Font = Enum.Font.Gotham, Text = "|",
        TextColor3 = T.TextMuted, TextSize = 12, ZIndex = 102,
    })
    self:_reg(sep, "TextColor3", "TextMuted")

    local stats = Create("TextLabel", {
        Parent = card, BackgroundTransparency = 1,
        Position = UDim2.new(0, 104, 0, 0), Size = UDim2.new(1, -112, 1, 0),
        Font = Enum.Font.Gotham, Text = "--- ms | --- FPS",
        TextColor3 = T.TextSoft, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102,
    })
    self:_reg(stats, "TextColor3", "TextSoft")

    task.spawn(function()
        local fps, frames, last = 0, 0, tick()
        while wmGui and wmGui.Parent do
            RunService.RenderStepped:Wait()
            frames = frames + 1
            local now = tick()
            if now - last >= 1 then
                fps = frames; frames = 0; last = now
                local ok, val = pcall(function() return Stats.PerformanceStats.Ping:GetValue() end)
                stats.Text = (ok and math.floor(val) or 0) .. " ms | " .. fps .. " FPS"
            end
        end
    end)
end

-- ─── TOAST LAYER (UwU-style) ──────────────────────────────────
function NexUI:_buildToastLayer()
    local toastGui = Create("ScreenGui", {
        Name = "NexUI_Toast", Parent = CoreGui,
        ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 99999,
    })
    self._toastGui = toastGui

    local holder = Create("Frame", {
        Parent = toastGui, BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 330, 1, -32),
        ClipsDescendants = true, ZIndex = 200,
    })
    self._toastHolder = holder

    Create("UIListLayout", {
        Parent = holder, Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        FillDirection = Enum.FillDirection.Vertical,
    })
end

function NexUI:Toast(title, body, duration, color)
    duration = duration or 3
    local T  = self._theme
    local col = color or self._accent
    self._toastCount = self._toastCount + 1

    local wrapper = Create("Frame", {
        Parent = self._toastHolder, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 52), LayoutOrder = self._toastCount,
        ClipsDescendants = true,
    })

    local pill = Create("Frame", {
        Parent = wrapper,
        BackgroundColor3 = T.GlassCard, BackgroundTransparency = 0.04,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 340, 0, 0),
        ClipsDescendants = true, ZIndex = 210,
    })
    Corner(pill, 14)
    Stroke(pill, T.Stroke, 1, 0.4)

    -- Left accent stripe
    local stripe = Create("Frame", {
        Parent = pill, BackgroundColor3 = col,
        BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 3, 1, 0), ZIndex = 211,
    })
    Corner(stripe, 14)

    -- Icon circle
    local ic = Create("Frame", {
        Parent = pill, BackgroundColor3 = col,
        BorderSizePixel = 0, Position = UDim2.new(0, 12, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24), ZIndex = 212,
    })
    Corner(ic, 300)
    Create("TextLabel", {
        Parent = ic, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = tostring(title):sub(1, 1):upper(),
        Font = Enum.Font.GothamBlack, TextSize = 12,
        TextColor3 = Color3.new(1, 1, 1), ZIndex = 213,
    })

    local titleLbl = Create("TextLabel", {
        Parent = pill, BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 9), Size = UDim2.new(1, -70, 0, 15),
        Font = Enum.Font.GothamBold, Text = title,
        TextColor3 = T.Text, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 212,
    })

    local bodyLbl = Create("TextLabel", {
        Parent = pill, BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 27), Size = UDim2.new(1, -70, 0, 13),
        Font = Enum.Font.Gotham, Text = body,
        TextColor3 = T.TextSoft, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 212,
    })

    -- Close button
    local closeBtn = Create("TextButton", {
        Parent = pill, BackgroundTransparency = 1,
        Position = UDim2.new(1, -24, 0, 0), Size = UDim2.new(0, 24, 1, 0),
        Font = Enum.Font.GothamBold, Text = "×",
        TextColor3 = T.TextMuted, TextSize = 16,
        AutoButtonColor = false, ZIndex = 213,
    })

    -- Progress bar
    local pgBg = Create("Frame", {
        Parent = pill, BackgroundColor3 = T.TrackOff,
        BackgroundTransparency = 0.5, BorderSizePixel = 0,
        Position = UDim2.new(0, 4, 1, -3), Size = UDim2.new(1, -8, 0, 2), ZIndex = 213,
    })
    Corner(pgBg, 300)
    local pgFill = Create("Frame", {
        Parent = pgBg, BackgroundColor3 = col,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), ZIndex = 214,
    })
    Corner(pgFill, 300)

    Tween(pill, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Quint)
    Tween(pgFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)

    local dismissed = false
    local function dismiss()
        if dismissed then return end; dismissed = true
        Tween(pill, {Position = UDim2.new(0, 340, 0, 0), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tween(titleLbl, {TextTransparency = 1}, 0.2)
        Tween(bodyLbl,  {TextTransparency = 1}, 0.2)
        task.delay(0.3, function()
            Tween(wrapper, {Size = UDim2.new(1, 0, 0, 0)}, 0.22, Enum.EasingStyle.Quint)
            task.delay(0.25, function()
                if wrapper and wrapper.Parent then wrapper:Destroy() end
            end)
        end)
    end

    closeBtn.MouseButton1Click:Connect(dismiss)
    pill.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then dismiss() end
    end)
    task.delay(duration, dismiss)
end

-- ─── ATMOSPHERE (UwU orbs + cursor trail + shooting stars) ────
function NexUI:_buildAtmosphere()
    if not self._win then return end
    local T = self._theme

    -- Depth layers
    local depthFar  = Create("Frame", {Parent = self._win, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ZIndex = 2})
    local depthNear = Create("Frame", {Parent = self._win, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ZIndex = 2})

    local function MakeGlow(parent, x, y, size, baseT)
        local holder = Create("Frame", {
            Parent = parent,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, x, 0, y),
            Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1,
        })
        local c1 = Create("Frame", {
            Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = T.Accent, BackgroundTransparency = baseT, BorderSizePixel = 0,
        })
        Corner(c1, 300)
        local c2 = Create("Frame", {
            Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0.55, 0, 0.55, 0),
            BackgroundColor3 = T.Accent2, BackgroundTransparency = math.max(baseT - 0.06, 0), BorderSizePixel = 0,
        })
        Corner(c2, 300)
        self:_reg(c1, "BackgroundColor3", "Accent")
        self:_reg(c2, "BackgroundColor3", "Accent2")
        return holder
    end

    local function Drift(el, x1, y1, x2, y2, dur)
        task.spawn(function()
            while el and el.Parent do
                local t1 = TweenService:Create(el, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0, x1, 0, y1)})
                t1:Play(); t1.Completed:Wait()
                if not (el and el.Parent) then break end
                local t2 = TweenService:Create(el, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0, x2, 0, y2)})
                t2:Play(); t2.Completed:Wait()
            end
        end)
    end

    local AB1 = MakeGlow(depthFar, 120, 100, 280, 0.92)
    local AB2 = MakeGlow(depthFar, 600, 130, 240, 0.93)
    local AB3 = MakeGlow(depthFar, 360, 420, 300, 0.93)
    Drift(AB1, 160, 130, 80, 60, 9)
    Drift(AB2, 560, 95, 630, 165, 12)
    Drift(AB3, 400, 460, 300, 380, 10)

    -- Shooting stars
    task.spawn(function()
        while self._win and self._win.Parent do
            task.wait(3 + math.random() * 5)
            pcall(function()
                local fl = math.random() > 0.5
                local sx, sy = fl and -30 or self._W + 30, math.random(10, math.floor(self._H * 0.5))
                local ex, ey = fl and self._W + 30 or -30, sy + 80 + math.random(0, 80)
                local head = Create("Frame", {
                    Parent = self._win,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, sx, 0, sy),
                    Size = UDim2.new(0, 4, 0, 4),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BackgroundTransparency = 0.1,
                    BorderSizePixel = 0, ZIndex = 44,
                })
                Corner(head, 3)
                local tail = Create("Frame", {
                    Parent = self._win,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, sx, 0, sy),
                    Size = UDim2.new(0, 28, 0, 2),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                    Rotation = math.deg(math.atan2(ey - sy, ex - sx)),
                    ZIndex = 43,
                })
                Corner(tail, 2)
                local dur = 0.65 + math.random() * 0.4
                Tween(head, {Position = UDim2.new(0, ex, 0, ey), BackgroundTransparency = 1}, dur, Enum.EasingStyle.Sine)
                Tween(tail, {Position = UDim2.new(0, ex, 0, ey), Size = UDim2.new(0, 5, 0, 2), BackgroundTransparency = 1}, dur, Enum.EasingStyle.Sine)
                task.delay(dur + 0.1, function()
                    if head then head:Destroy() end
                    if tail then tail:Destroy() end
                end)
            end)
        end
    end)

    -- Cursor trail (relative to window)
    task.spawn(function()
        local lastT, lastP = 0, Vector2.new(0, 0)
        while self._win and self._win.Parent do
            pcall(function()
                local m = UserInputService:GetMouseLocation()
                local wp = self._win.AbsolutePosition
                local lp = Vector2.new(m.X - wp.X, m.Y - wp.Y)
                if lp.X > 0 and lp.X < self._win.AbsoluteSize.X and
                   lp.Y > 0 and lp.Y < self._win.AbsoluteSize.Y then
                    local now = os.clock()
                    if now - lastT > 0.055 and (lp - lastP).Magnitude > 7 then
                        lastT = now; lastP = lp
                        local dot = Create("Frame", {
                            Parent = self._win,
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.new(0, lp.X, 0, lp.Y),
                            Size = UDim2.new(0, 7, 0, 7),
                            BackgroundColor3 = T.Accent,
                            BackgroundTransparency = 0.35,
                            BorderSizePixel = 0, ZIndex = 42,
                        })
                        Corner(dot, 300)
                        Tween(dot, {
                            Size = UDim2.new(0, 1, 0, 1),
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, lp.X, 0, lp.Y - 4),
                        }, 0.45, Enum.EasingStyle.Quad)
                        task.delay(0.5, function()
                            if dot and dot.Parent then dot:Destroy() end
                        end)
                    end
                end
            end)
            RunService.RenderStepped:Wait()
        end
    end)

    -- Twinkle particles
    task.spawn(function()
        while self._win and self._win.Parent do
            task.wait(1.8 + math.random() * 3)
            pcall(function()
                local h = Create("Frame", {
                    Parent = self._win,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, math.random(30, self._W - 30), 0, math.random(30, self._H - 30)),
                    Size = UDim2.new(0, 12, 0, 12),
                    BackgroundTransparency = 1, ZIndex = 43,
                })
                local sc = Create("UIScale", {Scale = 0, Parent = h})
                local hb = Create("Frame", {
                    Parent = h, AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 0, 2),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BackgroundTransparency = 0.2, BorderSizePixel = 0,
                })
                Corner(hb, 1)
                local vb = Create("Frame", {
                    Parent = h, AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 2, 1, 0),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BackgroundTransparency = 0.2, BorderSizePixel = 0,
                })
                Corner(vb, 1)
                Tween(sc, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
                task.delay(0.32, function()
                    pcall(function()
                        Tween(sc, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0})
                        Tween(hb, TweenInfo.new(0.3), {BackgroundTransparency = 1})
                        Tween(vb, TweenInfo.new(0.3), {BackgroundTransparency = 1})
                    end)
                end)
                task.delay(0.75, function() if h then h:Destroy() end end)
            end)
        end
    end)
end

-- ─── INIT SEQUENCE ────────────────────────────────────────────
function NexUI:_buildInitSequence(title)
    local T  = self._theme
    local W, H = self._W, self._H

    local loader = Create("Frame", {
        Parent = self._win, Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = T.GlassBg, BackgroundTransparency = 0,
        BorderSizePixel = 0, ZIndex = 80,
    })
    Corner(loader, 22)

    -- Hex grid background effect (rings expanding from center)
    local ringContainer = Create("Frame", {
        Parent = loader, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, ZIndex = 81,
    })
    for i = 1, 5 do
        local ring = Create("Frame", {
            Parent = ringContainer,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.42, 0),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 81,
        })
        Corner(ring, 300)
        local rStroke = Stroke(ring, T.Accent, 1.5, 0.3)
        task.delay(i * 0.18, function()
            if not (ring and ring.Parent) then return end
            local sz = i * 120
            Tween(ring, {Size = UDim2.new(0, sz, 0, sz)}, 1.8, Enum.EasingStyle.Quart)
            Tween(rStroke, {Transparency = 1}, 1.8, Enum.EasingStyle.Quart)
        end)
    end

    -- Center logo
    local logoHolder = Create("Frame", {
        Parent = loader, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.38, 0),
        Size = UDim2.new(0, 68, 0, 68),
        BackgroundTransparency = 1, ZIndex = 83,
    })
    local logoScale = Create("UIScale", {Scale = 0, Parent = logoHolder})

    local logoGlow = Create("Frame", {
        Parent = logoHolder, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(2.2, 0, 2.2, 0),
        BackgroundColor3 = T.Accent, BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
    })
    Corner(logoGlow, 300)
    TweenService:Create(logoGlow, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.82}):Play()

    local logoBg = Create("Frame", {
        Parent = logoHolder, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 84,
    })
    Corner(logoBg, 18)

    -- Spinning ring
    local spinRing = Create("Frame", {
        Parent = logoHolder, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1.4, 0, 1.4, 0),
        BackgroundTransparency = 1, ZIndex = 82,
    })
    Corner(spinRing, 300)
    local spinStroke = Stroke(spinRing, T.Accent, 2, 0)
    Create("UIGradient", {
        Parent = spinStroke,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.45, 0.85),
            NumberSequenceKeypoint.new(1, 0.4),
        }),
    })
    TweenService:Create(spinRing, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = 360}):Play()

    Create("TextLabel", {
        Parent = logoBg, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = title:sub(1, 1):upper(),
        Font = Enum.Font.GothamBlack,
        TextSize = 30, TextColor3 = Color3.new(1, 1, 1), ZIndex = 85,
    })

    -- Title text
    local titleLbl = Create("TextLabel", {
        Parent = loader, AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.55, 0),
        Size = UDim2.new(0, 320, 0, 26),
        BackgroundTransparency = 1,
        Text = title, Font = Enum.Font.GothamBlack,
        TextSize = 22, TextColor3 = T.Text,
        TextTransparency = 1, ZIndex = 83,
    })
    local subtitleLbl = Create("TextLabel", {
        Parent = loader, AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.615, 0),
        Size = UDim2.new(0, 320, 0, 16),
        BackgroundTransparency = 1,
        Text = "nexui  ·  loading",
        Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = T.TextMuted, TextTransparency = 1, ZIndex = 83,
    })

    -- Progress bar
    local progArea = Create("Frame", {
        Parent = loader, AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.72, 0),
        Size = UDim2.new(0, 280, 0, 54),
        BackgroundTransparency = 1, ZIndex = 83,
    })
    local statusLbl = Create("TextLabel", {
        Parent = progArea, Size = UDim2.new(0.62, 0, 0, 16),
        BackgroundTransparency = 1, Text = "Waking up",
        Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = T.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
    })
    local pctLbl = Create("TextLabel", {
        Parent = progArea, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 90, 0, 16),
        BackgroundTransparency = 1, Text = "0%",
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Right,
    })
    local barBg = Create("Frame", {
        Parent = progArea, Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 0, 5),
        BackgroundColor3 = T.TrackOff, BorderSizePixel = 0,
    })
    Corner(barBg, 3)
    local barFill = Create("Frame", {
        Parent = barBg, Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.Accent, BorderSizePixel = 0,
    })
    Corner(barFill, 3)
    Create("TextLabel", {
        Parent = progArea, AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1, Text = "click to skip",
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.TextMuted,
    })

    -- Skip on click
    local loaderDone = false
    local function finishLoader()
        if loaderDone then return end; loaderDone = true
        Tween(barFill, {Size = UDim2.new(1, 0, 1, 0)}, 0.15)
        pctLbl.Text = "100%"
        statusLbl.Text = "Ready"
        task.delay(0.3, function()
            Tween(loader, {BackgroundTransparency = 1}, 0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            task.delay(0.5, function()
                if loader and loader.Parent then loader:Destroy() end
                -- Reveal main window
                self._win.Size = UDim2.new(0, self._W, 0, 0)
                self._win.Visible = true
                Tween(self._win, {Size = UDim2.new(0, self._W, 0, self._H)}, 1.1, Enum.EasingStyle.Quint)
                Tween(self._blur, {Size = 18}, 1.1)
                task.delay(0.5, function()
                    self:Toast(title, "Ready. " .. (self._menuKey and ("Press " .. tostring(self._menuKey.Name) .. " to toggle") or ""), 4)
                end)
            end)
        end)
    end

    loader.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then finishLoader() end
    end)

    -- Init animation sequence
    task.spawn(function()
        task.wait(0.1)
        Tween(logoScale, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
        task.wait(0.45)
        Tween(titleLbl, {TextTransparency = 0, Position = UDim2.new(0.5, 0, 0.54, 0)}, 0.5, Enum.EasingStyle.Quint)
        task.wait(0.1)
        Tween(subtitleLbl, {TextTransparency = 0}, 0.4)

        local steps = {
            {0, "Waking up"},
            {0.2, "Building interface"},
            {0.45, "Wiring keybinds"},
            {0.68, "Applying theme"},
            {0.88, "Final checks"},
        }
        local dur, t0 = 2.2, os.clock()
        while not loaderDone do
            local a = math.clamp((os.clock() - t0) / dur, 0, 1)
            local e = 1 - math.pow(1 - a, 3)
            pctLbl.Text = math.floor(e * 100 + 0.5) .. "%"
            Tween(barFill, {Size = UDim2.new(e, 0, 1, 0)}, 0.06)
            for _, s in ipairs(steps) do
                if a >= s[1] then statusLbl.Text = s[2] end
            end
            if a >= 1 then break end
            task.wait(0.03)
        end
        task.wait(0.3)
        finishLoader()
    end)
end

-- ─── MAIN WINDOW ──────────────────────────────────────────────
function NexUI:_buildMainWindow(title, subtitle)
    local T = self._theme
    local W, H = self._W, self._H

    local win = Create("Frame", {
        Name = "NexWin", Parent = self._gui,
        BackgroundColor3 = T.GlassBg, BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, W, 0, H),
        Visible = false, ClipsDescendants = true, ZIndex = 1,
    })
    Corner(win, 22)
    local winStroke = Stroke(win, T.Stroke, 2, 0.4)
    self:_reg(winStroke, "Color", "Stroke")
    self:_reg(win, "BackgroundColor3", "GlassBg")
    self._win = win

    -- Glass shine
    local shine = Create("Frame", {
        Parent = win, BackgroundColor3 = T.Shine,
        BackgroundTransparency = 0.93, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0.42, 0), ZIndex = 3,
    })
    Create("UIGradient", {
        Parent = shine, Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.45),
            NumberSequenceKeypoint.new(0.4, 0.82),
            NumberSequenceKeypoint.new(1, 1),
        }),
    })

    -- Left sidebar
    local left = Create("Frame", {
        Parent = win, BackgroundColor3 = T.GlassLeft,
        BackgroundTransparency = 0.85, BorderSizePixel = 0,
        Size = UDim2.new(0, 228, 1, 0), ZIndex = 5,
    })
    self:_reg(left, "BackgroundColor3", "GlassLeft")

    local sep = Create("Frame", {
        Parent = left, BackgroundColor3 = T.Stroke,
        BackgroundTransparency = 0.3, BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), ZIndex = 6,
    })
    self:_reg(sep, "BackgroundColor3", "Stroke")

    local titleLbl = Create("TextLabel", {
        Parent = left, BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 26), Size = UDim2.new(1, -34, 0, 30),
        Font = Enum.Font.GothamBlack, Text = title,
        TextColor3 = T.Text, TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    })
    self:_reg(titleLbl, "TextColor3", "Text")

    local subLbl = Create("TextLabel", {
        Parent = left, BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 56), Size = UDim2.new(1, -34, 0, 14),
        Font = Enum.Font.Gotham, Text = subtitle:upper(),
        TextColor3 = T.TextMuted, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    })
    self:_reg(subLbl, "TextColor3", "TextMuted")

    -- Top accent line under header
    local accentLine = Create("Frame", {
        Parent = left, BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 22, 0, 72), Size = UDim2.new(0, 32, 0, 2), ZIndex = 7,
    })
    Corner(accentLine, 1)
    self:_reg(accentLine, "BackgroundColor3", "Accent")

    local tabsHolder = Create("Frame", {
        Parent = left, BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 90), Size = UDim2.new(1, -24, 1, -190),
        ZIndex = 7, ClipsDescendants = true,
    })
    self._tabsHolder = tabsHolder
    Create("UIListLayout", {
        Parent = tabsHolder, Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    self:_buildProfile(left)

    -- Content area
    local contentArea = Create("Frame", {
        Parent = win, BackgroundTransparency = 1,
        Position = UDim2.new(0, 228, 0, 0),
        Size = UDim2.new(1, -228, 1, 0),
        ClipsDescendants = true, ZIndex = 5,
    })
    self._contentArea = contentArea
end

-- ─── PROFILE SECTION ──────────────────────────────────────────
function NexUI:_buildProfile(parent)
    local T = self._theme
    local c = Create("Frame", {
        Parent = parent, BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 1, -74),
        Size = UDim2.new(1, -24, 0, 58), ZIndex = 7,
    })

    local aBg = Create("Frame", {
        Parent = c, BackgroundColor3 = T.GlassCard,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 0, 0.5, -20),
        Size = UDim2.new(0, 40, 0, 40), ZIndex = 8,
    })
    self:_reg(aBg, "BackgroundColor3", "GlassCard")
    Corner(aBg, 300)
    local aStroke = Stroke(aBg, T.Stroke, 1.5, 0.5)
    self:_reg(aStroke, "Color", "Stroke")

    local aImg = Create("ImageLabel", {
        Parent = aBg, BackgroundTransparency = 1,
        Position = UDim2.new(0, 2, 0, 2), Size = UDim2.new(1, -4, 1, -4),
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png",
        ZIndex = 9,
    })
    Corner(aImg, 300)

    local nLbl = Create("TextLabel", {
        Parent = c, BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0, 8),
        Size = UDim2.new(1, -50, 0, 20),
        Font = Enum.Font.GothamBold, Text = "@" .. LocalPlayer.Name,
        TextColor3 = T.Text, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
    })
    self:_reg(nLbl, "TextColor3", "Text")

    local sRow = Create("Frame", {
        Parent = c, BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0, 30),
        Size = UDim2.new(1, -50, 0, 14), ZIndex = 8,
    })
    local sDot = Create("Frame", {
        Parent = sRow, BackgroundColor3 = T.Online,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, -3), Size = UDim2.new(0, 6, 0, 6), ZIndex = 9,
    })
    Corner(sDot, 300)
    self:_reg(sDot, "BackgroundColor3", "Online")
    Create("TextLabel", {
        Parent = sRow, BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -10, 1, 0),
        Font = Enum.Font.Gotham, Text = "Online",
        TextColor3 = T.Online, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9,
    })
end

-- ─── TOGGLE ───────────────────────────────────────────────────
function NexUI:Toggle()
    self._isOpen = not self._isOpen
    if self._isOpen then
        self._win.Visible = true
        Tween(self._blur, {Size = 18}, 0.8)
        Tween(self._win, {Size = UDim2.new(0, self._W, 0, self._H)}, 0.8)
    else
        Tween(self._blur, {Size = 0}, 0.6)
        local t = Tween(self._win, {Size = UDim2.new(0, self._W, 0, 0)}, 0.6)
        t.Completed:Connect(function()
            if not self._isOpen then self._win.Visible = false end
        end)
    end
end

-- ─── TAB ──────────────────────────────────────────────────────
function NexUI:Tab(name, iconId)
    local T = self._theme

    local page = Create("ScrollingFrame", {
        Parent = self._contentArea, Name = name .. "Page",
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Accent,
        ScrollBarImageTransparency = 0.5,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false, ZIndex = 6, ClipsDescendants = true,
    })
    self:_reg(page, "ScrollBarImageColor3", "Accent")
    local pageLayout = Create("UIListLayout", {
        Parent = page, Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    Create("UIPadding", {
        Parent = page,
        PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18),
        PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18),
    })
    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 36)
    end)

    local idx = #self._tabs
    local btn = Create("TextButton", {
        Parent = self._tabsHolder, Name = name,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 42), Font = Enum.Font.GothamBold,
        Text = "", TextColor3 = T.TextSoft, TextSize = 14,
        AutoButtonColor = false, LayoutOrder = idx,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
        ClipsDescendants = true,
    })

    local iconPad = iconId and 28 or 0
    local btnText = Create("TextLabel", {
        Parent = btn, BackgroundTransparency = 1,
        Size = UDim2.new(1, -iconPad, 1, 0),
        Position = UDim2.new(0, iconPad, 0, 0),
        Text = name, Font = Enum.Font.GothamBold,
        TextColor3 = T.TextSoft, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9,
    })
    self:_reg(btnText, "TextColor3", "TextSoft")

    if iconId then
        local icon = Create("ImageLabel", {
            Parent = btn, BackgroundTransparency = 1,
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 8, 0.5, -9),
            Image = iconId, ImageColor3 = T.TextSoft, ZIndex = 9,
        })
        self:_reg(icon, "ImageColor3", "TextSoft")
    end

    -- Active indicator bar
    local ind = Create("Frame", {
        Parent = btn, BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, -3, 0.5, -6),
        Size = UDim2.new(0, 4, 0, 12),
        BackgroundTransparency = 1, ZIndex = 9,
    })
    Corner(ind, 300)
    self:_reg(ind, "BackgroundColor3", "Accent")

    local hBg = Create("Frame", {
        Parent = btn, BackgroundColor3 = T.GlassCard,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 7,
    })
    Corner(hBg, 11)

    local tabData = {Name = name, Button = btn, Text = btnText, Indicator = ind, Page = page, HoverBg = hBg}
    table.insert(self._tabs, tabData)
    local win = self

    local function activate()
        if win._currentTab == name then return end
        for _, t in ipairs(win._tabs) do
            if t.Name == win._currentTab then
                Tween(t.Text, {TextColor3 = win._theme.TextSoft}, 0.35)
                Tween(t.Indicator, {BackgroundTransparency = 1}, 0.28)
                Tween(t.HoverBg, {BackgroundTransparency = 1}, 0.28)
                t.Page.Visible = false
            end
        end
        win._currentTab = name
        Tween(btnText, {TextColor3 = win._theme.Text}, 0.35)
        Tween(ind, {BackgroundTransparency = 0}, 0.28)
        Tween(hBg, {BackgroundTransparency = 0.86}, 0.28)
        page.CanvasPosition = Vector2.new(0, 0)
        page.Visible = true
        page.Position = UDim2.new(0, 20, 0, 0)
        Tween(page, {Position = UDim2.new(0, 0, 0, 0)}, 0.38)
    end

    btn.MouseEnter:Connect(function()
        if win._currentTab ~= name then
            Tween(btnText, {TextColor3 = win._theme.Text}, 0.18, Enum.EasingStyle.Sine)
            Tween(hBg, {BackgroundTransparency = 0.92}, 0.18, Enum.EasingStyle.Sine)
        end
    end)
    btn.MouseLeave:Connect(function()
        if win._currentTab ~= name then
            Tween(btnText, {TextColor3 = win._theme.TextSoft}, 0.18, Enum.EasingStyle.Sine)
            Tween(hBg, {BackgroundTransparency = 1}, 0.18, Enum.EasingStyle.Sine)
        end
    end)
    btn.MouseButton1Click:Connect(activate)
    ClickRipple(btn)

    if #self._tabs == 1 then
        win._currentTab = name
        btnText.TextColor3 = T.Text
        ind.BackgroundTransparency = 0
        hBg.BackgroundTransparency = 0.86
        page.Visible = true
    end

    local Tab = {}; Tab._page = page; Tab._win = win
    function Tab:Section(sectionTitle) return win:_buildSection(page, sectionTitle) end
    return Tab
end

-- ─── SECTION ──────────────────────────────────────────────────
function NexUI:_buildSection(parent, sectionTitle)
    local T = self._theme

    local section = Create("Frame", {
        Parent = parent, BackgroundColor3 = T.GlassCard,
        BackgroundTransparency = 0.72, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #parent:GetChildren() + 1,
        ZIndex = 7, ClipsDescendants = false,
    })
    self:_reg(section, "BackgroundColor3", "GlassCard")
    Corner(section, 18)
    local sStroke = Stroke(section, T.Stroke, 1, 0.5)
    self:_reg(sStroke, "Color", "Stroke")

    local accentBar = Create("Frame", {
        Parent = section, BackgroundColor3 = T.Accent,
        Position = UDim2.new(0, 16, 0, 14),
        Size = UDim2.new(0, 3, 0, 18), ZIndex = 9,
    })
    self:_reg(accentBar, "BackgroundColor3", "Accent")
    Corner(accentBar, 300)

    local headerLbl = Create("TextLabel", {
        Parent = section, BackgroundTransparency = 1,
        Position = UDim2.new(0, 28, 0, 0),
        Size = UDim2.new(1, -42, 0, 46),
        Font = Enum.Font.GothamBold, Text = sectionTitle,
        TextColor3 = T.Text, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9,
    })
    self:_reg(headerLbl, "TextColor3", "Text")

    -- Divider
    local div = Create("Frame", {
        Parent = section, BackgroundColor3 = T.Stroke,
        BackgroundTransparency = 0.65, BorderSizePixel = 0,
        Position = UDim2.new(0, 16, 0, 44), Size = UDim2.new(1, -32, 0, 1), ZIndex = 8,
    })
    self:_reg(div, "BackgroundColor3", "Stroke")

    local content = Create("Frame", {
        Parent = section, BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 50),
        Size = UDim2.new(1, -24, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 9, ClipsDescendants = false,
    })
    Create("UIListLayout", {
        Parent = content, Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    Create("UIPadding", {Parent = content, PaddingBottom = UDim.new(0, 14)})

    local Sec = {}; Sec._content = content
    local win = self

    -- ── Toggle ──
    function Sec:Toggle(label, flagName, default, callback, bindKey)
        local T2 = win._theme
        local frame = Create("Frame", {
            Parent = content, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 38),
            LayoutOrder = #content:GetChildren() + 1,
        })
        local lbl = Create("TextLabel", {
            Parent = frame, BackgroundTransparency = 1,
            Size = UDim2.new(1, bindKey and -108 or -60, 1, 0),
            Font = Enum.Font.Gotham, Text = label,
            TextColor3 = T2.Text, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10,
        })
        win:_reg(lbl, "TextColor3", "Text")

        local enabled = default or false
        win._flags[flagName] = enabled

        local track = Create("Frame", {
            Parent = frame, BackgroundColor3 = enabled and T2.TrackOn or T2.TrackOff,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -52, 0.5, -12), Size = UDim2.new(0, 48, 0, 24), ZIndex = 10,
        })
        Corner(track, 300)
        local thumb = Create("Frame", {
            Parent = track, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Position = enabled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
            Size = UDim2.new(0, 20, 0, 20), ZIndex = 11,
        })
        Corner(thumb, 300)

        local function setEnabled(v)
            enabled = v; win._flags[flagName] = v
            Tween(track, {BackgroundColor3 = v and win._theme.TrackOn or win._theme.TrackOff}, 0.38, Enum.EasingStyle.Quart)
            Tween(thumb, {Position = v and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}, 0.38, Enum.EasingStyle.Quart)
            if callback then task.spawn(callback, v) end
        end

        -- Keybind chip (optional)
        local BIND_ID = "$$kb_" .. flagName .. "$$"
        if bindKey then
            local kChip = Create("TextButton", {
                Parent = frame, BackgroundColor3 = T2.GlassCard,
                BackgroundTransparency = 0.4, BorderSizePixel = 0,
                Position = UDim2.new(1, -106, 0.5, -12),
                Size = UDim2.new(0, 40, 0, 24),
                Font = Enum.Font.GothamBold,
                Text = tostring(bindKey.Name):sub(1, 6),
                TextColor3 = T2.TextSoft, TextSize = 10,
                AutoButtonColor = false, ZIndex = 11,
            })
            Corner(kChip, 7)
            Stroke(kChip, T2.Stroke, 1, 0.4)
            local waiting = false
            kChip.MouseButton1Click:Connect(function()
                if waiting then return end; waiting = true
                kChip.Text = "..."
                local conn
                conn = UserInputService.InputBegan:Connect(function(inp, gpe)
                    if gpe then return end
                    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    win:Unbind(bindKey, BIND_ID)
                    bindKey = inp.KeyCode
                    kChip.Text = tostring(bindKey.Name):sub(1, 6)
                    win:Bind(bindKey, BIND_ID, function()
                        enabled = not enabled
                        win._flags[flagName] = enabled
                        setEnabled(enabled)
                    end)
                    conn:Disconnect(); waiting = false
                end)
            end)
            win:Bind(bindKey, BIND_ID, function()
                enabled = not enabled
                win._flags[flagName] = enabled
                setEnabled(enabled)
            end)
        end

        local debounce = false
        local clickBtn = Create("TextButton", {
            Parent = frame, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0), Text = "", ZIndex = 12,
            AutoButtonColor = false,
        })
        clickBtn.MouseButton1Click:Connect(function()
            if debounce then return end; debounce = true
            setEnabled(not enabled)
            task.wait(0.4); debounce = false
        end)
        ClickRipple(clickBtn)

        return {
            Set = setEnabled,
            Get = function() return enabled end,
        }
    end

    -- ── Slider ──
    function Sec:Slider(label, min, max, default, callback)
        local T2 = win._theme
        local frame = Create("Frame", {
            Parent = content, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 54),
            LayoutOrder = #content:GetChildren() + 1,
        })
        local nameLbl = Create("TextLabel", {
            Parent = frame, BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0.62, -4, 0, 20),
            Font = Enum.Font.Gotham, Text = label,
            TextColor3 = T2.TextMuted, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10,
        })
        win:_reg(nameLbl, "TextColor3", "TextMuted")
        local valLbl = Create("TextLabel", {
            Parent = frame, BackgroundTransparency = 1,
            Position = UDim2.new(0.62, 0, 0, 0), Size = UDim2.new(0.38, 0, 0, 20),
            Font = Enum.Font.GothamBold,
            Text = string.format("%.2f", default),
            TextColor3 = T2.Text, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 10,
        })
        win:_reg(valLbl, "TextColor3", "Text")

        local trackF = Create("Frame", {
            Parent = frame, BackgroundColor3 = T2.TrackOff,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(1, 0, 0, 6), ZIndex = 10,
        })
        win:_reg(trackF, "BackgroundColor3", "TrackOff")
        Corner(trackF, 300)
        local fillF = Create("Frame", {
            Parent = trackF, BackgroundColor3 = T2.TrackOn,
            BorderSizePixel = 0,
            Size = UDim2.new((default - min) / (max - min), 0, 1, 0), ZIndex = 11,
        })
        win:_reg(fillF, "BackgroundColor3", "TrackOn")
        Corner(fillF, 300)
        local thumbF = Create("Frame", {
            Parent = trackF, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8),
            Size = UDim2.new(0, 16, 0, 16), ZIndex = 12,
        })
        Corner(thumbF, 300)
        Stroke(thumbF, T2.Accent, 2, 0.3)

        local dragging = false
        local function update(val)
            local v = math.clamp(val, min, max)
            local a = (v - min) / (max - min)
            Tween(fillF, {Size = UDim2.new(a, 0, 1, 0)}, 0.05)
            thumbF.Position = UDim2.new(a, -8, 0.5, -8)
            valLbl.Text = string.format("%.2f", v)
            if callback then callback(v) end
        end
        local function inputToVal(i)
            return min + (max - min) * math.clamp(
                (i.Position.X - trackF.AbsolutePosition.X) / math.max(trackF.AbsoluteSize.X, 1), 0, 1)
        end
        trackF.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; update(inputToVal(i))
            end
        end)
        thumbF.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                update(inputToVal(i))
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        return {Set = update}
    end

    -- ── TextBox ──
    function Sec:TextBox(label, placeholder, default, callback)
        local T2 = win._theme
        local frame = Create("Frame", {
            Parent = content, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 38),
            LayoutOrder = #content:GetChildren() + 1,
        })
        local lbl = Create("TextLabel", {
            Parent = frame, BackgroundTransparency = 1,
            Size = UDim2.new(0.4, -6, 1, 0),
            Font = Enum.Font.Gotham, Text = label,
            TextColor3 = T2.Text, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10,
        })
        win:_reg(lbl, "TextColor3", "Text")
        local box = Create("TextBox", {
            Parent = frame, BackgroundColor3 = T2.GlassCard,
            BackgroundTransparency = 0.5, BorderSizePixel = 0,
            Position = UDim2.new(0.4, 0, 0.5, -14),
            Size = UDim2.new(0.6, 0, 0, 28),
            Font = Enum.Font.Gotham,
            PlaceholderText = placeholder,
            PlaceholderColor3 = T2.TextMuted,
            Text = default or "",
            TextColor3 = T2.Text, TextSize = 12,
            ZIndex = 10, ClearTextOnFocus = false,
        })
        win:_reg(box, "BackgroundColor3", "GlassCard")
        win:_reg(box, "TextColor3", "Text")
        Corner(box, 11)
        local bStroke = Stroke(box, T2.Stroke, 1, 0.5)
        box.Focused:Connect(function()
            Tween(box, {BackgroundTransparency = 0.25}, 0.2, Enum.EasingStyle.Sine)
            Tween(bStroke, {Transparency = 0, Color = T2.Accent}, 0.2)
        end)
        box.FocusLost:Connect(function()
            Tween(box, {BackgroundTransparency = 0.5}, 0.2, Enum.EasingStyle.Sine)
            Tween(bStroke, {Transparency = 0.5, Color = T2.Stroke}, 0.2)
            if callback then callback(box.Text) end
        end)
        return {
            Get = function() return box.Text end,
            Set = function(v) box.Text = v end,
        }
    end

    -- ── Keybind ──
    function Sec:Keybind(label, defaultKey, callback)
        local T2 = win._theme
        local frame = Create("Frame", {
            Parent = content, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 38),
            LayoutOrder = #content:GetChildren() + 1,
        })
        local lbl = Create("TextLabel", {
            Parent = frame, BackgroundTransparency = 1,
            Size = UDim2.new(1, -120, 1, 0),
            Font = Enum.Font.Gotham, Text = label,
            TextColor3 = T2.Text, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10,
        })
        win:_reg(lbl, "TextColor3", "Text")
        local currentKey = defaultKey
        local BIND_ID = "$$keybind_elem_" .. label .. "$$"
        if callback then win:Bind(currentKey, BIND_ID, callback) end

        local keyBtn = Create("TextButton", {
            Parent = frame, BackgroundColor3 = T2.GlassCard,
            BackgroundTransparency = 0.4, BorderSizePixel = 0,
            Position = UDim2.new(1, -112, 0.5, -14),
            Size = UDim2.new(0, 100, 0, 28),
            Font = Enum.Font.GothamBold, Text = currentKey.Name,
            TextColor3 = T2.Text, TextSize = 12,
            AutoButtonColor = false, ZIndex = 10,
        })
        win:_reg(keyBtn, "BackgroundColor3", "GlassCard")
        win:_reg(keyBtn, "TextColor3", "Text")
        Corner(keyBtn, 11)
        local kStroke = Stroke(keyBtn, T2.Accent, 1, 0.5)
        ClickRipple(keyBtn)

        local waiting = false
        keyBtn.MouseButton1Click:Connect(function()
            if waiting then return end; waiting = true
            keyBtn.Text = "Press key..."
            Tween(keyBtn, {BackgroundTransparency = 0.1}, 0.2)
            Tween(kStroke, {Transparency = 0}, 0.2)
            local conn
            conn = UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                win:Unbind(currentKey, BIND_ID)
                currentKey = input.KeyCode
                keyBtn.Text = currentKey.Name
                if callback then win:Bind(currentKey, BIND_ID, callback) end
                conn:Disconnect(); waiting = false
                Tween(keyBtn, {BackgroundTransparency = 0.4}, 0.2)
            end)
        end)

        return {
            Get = function() return currentKey end,
            SetCallback = function(fn)
                callback = fn
                if callback then win:Bind(currentKey, BIND_ID, callback) end
            end,
            Clear = function() win:Unbind(currentKey, BIND_ID); callback = nil end,
        }
    end

    -- ── Dropdown ──
    function Sec:Dropdown(label, options, default, callback)
        local T2 = win._theme
        local selected = default or options[1]
        local open = false
        local frame = Create("Frame", {
            Parent = content, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 36),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = #content:GetChildren() + 1,
            ZIndex = 10, ClipsDescendants = false,
        })
        local header = Create("TextButton", {
            Parent = frame, BackgroundColor3 = T2.GlassCard,
            BackgroundTransparency = 0.45, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 34),
            Font = Enum.Font.GothamBold,
            Text = "  ▾  " .. selected,
            TextColor3 = T2.Text, TextSize = 12,
            AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11,
        })
        win:_reg(header, "BackgroundColor3", "GlassCard")
        win:_reg(header, "TextColor3", "Text")
        Corner(header, 16)
        Stroke(header, T2.Stroke, 1, 0.5)

        local dropdown = Create("Frame", {
            Parent = frame, BackgroundColor3 = T2.GlassCard,
            BackgroundTransparency = 0.05, BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 38),
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false, ClipsDescendants = true, ZIndex = 50,
        })
        win:_reg(dropdown, "BackgroundColor3", "GlassCard")
        Corner(dropdown, 16)
        Stroke(dropdown, T2.Stroke, 1, 0.5)
        Create("UIListLayout", {Parent = dropdown, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})
        Create("UIPadding", {Parent = dropdown, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})

        local totalH = 10
        for i, opt in ipairs(options) do
            local isSel = opt == selected
            local ob = Create("TextButton", {
                Parent = dropdown, BackgroundColor3 = T2.GlassCard,
                BackgroundTransparency = isSel and 0.3 or 0.85,
                BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 28),
                Font = Enum.Font.Gotham, Text = "  " .. opt,
                TextColor3 = isSel and T2.Text or T2.TextSoft,
                TextSize = 12, AutoButtonColor = false,
                LayoutOrder = i, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51,
            })
            Corner(ob, 11)
            totalH = totalH + 30
            ob.MouseEnter:Connect(function() Tween(ob, {BackgroundTransparency = 0.5}, 0.12, Enum.EasingStyle.Sine) end)
            ob.MouseLeave:Connect(function() Tween(ob, {BackgroundTransparency = opt == selected and 0.3 or 0.85}, 0.12, Enum.EasingStyle.Sine) end)
            ob.MouseButton1Click:Connect(function()
                selected = opt
                header.Text = "  ▾  " .. selected
                if callback then task.spawn(callback, selected) end
                Tween(dropdown, {Size = UDim2.new(1, 0, 0, 0)}, 0.22)
                task.delay(0.24, function() dropdown.Visible = false end)
                open = false
            end)
        end

        header.MouseButton1Click:Connect(function()
            open = not open
            if open then
                dropdown.Visible = true
                dropdown.Size = UDim2.new(1, 0, 0, 0)
                Tween(dropdown, {Size = UDim2.new(1, 0, 0, totalH)}, 0.28, Enum.EasingStyle.Quint)
            else
                Tween(dropdown, {Size = UDim2.new(1, 0, 0, 0)}, 0.22)
                task.delay(0.24, function() dropdown.Visible = false end)
            end
        end)
        return {Get = function() return selected end}
    end

    -- ── Button ──
    function Sec:Button(label, callback)
        local T2 = win._theme
        local btn = Create("TextButton", {
            Parent = content, BackgroundColor3 = T2.Accent,
            BackgroundTransparency = 0.28, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 34),
            Font = Enum.Font.GothamBold, Text = label,
            TextColor3 = T2.Text, TextSize = 13,
            AutoButtonColor = false,
            LayoutOrder = #content:GetChildren() + 1, ZIndex = 10,
        })
        win:_reg(btn, "BackgroundColor3", "Accent")
        win:_reg(btn, "TextColor3", "Text")
        Corner(btn, 17)
        btn.MouseEnter:Connect(function() Tween(btn, {BackgroundTransparency = 0.08}, 0.16, Enum.EasingStyle.Sine) end)
        btn.MouseLeave:Connect(function() Tween(btn, {BackgroundTransparency = 0.28}, 0.16, Enum.EasingStyle.Sine) end)
        btn.MouseButton1Click:Connect(function()
            Tween(btn, {BackgroundTransparency = 0.6}, 0.07)
            task.delay(0.1, function() Tween(btn, {BackgroundTransparency = 0.28}, 0.16) end)
            if callback then task.spawn(callback) end
        end)
        ClickRipple(btn)
    end

    -- ── Label ──
    function Sec:Label(text)
        local T2 = win._theme
        local lbl = Create("TextLabel", {
            Parent = content, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Font = Enum.Font.Gotham, Text = text,
            TextColor3 = T2.TextMuted, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = #content:GetChildren() + 1,
            ZIndex = 10, TextWrapped = true,
        })
        win:_reg(lbl, "TextColor3", "TextMuted")
        return {Set = function(v) lbl.Text = v end}
    end

    -- ── ColorPicker ──
    function Sec:ColorPicker(label, default, callback)
        local T2 = win._theme
        local current = default or Color3.fromRGB(255, 80, 200)
        local frame = Create("Frame", {
            Parent = content, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 38),
            LayoutOrder = #content:GetChildren() + 1, ZIndex = 10, ClipsDescendants = false,
        })
        local lbl = Create("TextLabel", {
            Parent = frame, BackgroundTransparency = 1,
            Size = UDim2.new(1, -60, 1, 0),
            Font = Enum.Font.Gotham, Text = label,
            TextColor3 = T2.Text, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10,
        })
        win:_reg(lbl, "TextColor3", "Text")
        local swatch = Create("TextButton", {
            Parent = frame, BackgroundColor3 = current,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -50, 0.5, -12),
            Size = UDim2.new(0, 44, 0, 24),
            Text = "", AutoButtonColor = false, ZIndex = 10,
        })
        Corner(swatch, 9)
        Stroke(swatch, T2.Stroke, 1.5, 0.35)

        local pickerOpen = false
        local popup = Create("Frame", {
            Parent = frame, BackgroundColor3 = T2.GlassCard,
            BackgroundTransparency = 0.05, BorderSizePixel = 0,
            Position = UDim2.new(1, -208, 0, 42),
            Size = UDim2.new(0, 198, 0, 0),
            Visible = false, ClipsDescendants = true, ZIndex = 60,
        })
        win:_reg(popup, "BackgroundColor3", "GlassCard")
        Corner(popup, 13)
        Stroke(popup, T2.Stroke, 1, 0.35)

        local hueBar = Create("Frame", {
            Parent = popup, BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(1, -16, 0, 18), ZIndex = 61,
        })
        Corner(hueBar, 9)
        Create("UIGradient", {
            Parent = hueBar,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,     Color3.fromRGB(255, 0,   0)),
                ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0,   255, 0)),
                ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0,   255, 255)),
                ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0,   0,   255)),
                ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0,   255)),
                ColorSequenceKeypoint.new(1,     Color3.fromRGB(255, 0,   0)),
            }),
        })
        local hv, _, _ = Color3.toHSV(current)
        local hueThumb = Create("Frame", {
            Parent = hueBar, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Position = UDim2.new(hv, -5, 0.5, -9),
            Size = UDim2.new(0, 10, 0, 18), ZIndex = 62,
        })
        Corner(hueThumb, 300)
        Stroke(hueThumb, T2.Stroke, 1, 0.3)

        local hexBox = Create("TextBox", {
            Parent = popup, BackgroundColor3 = T2.GlassCard,
            BackgroundTransparency = 0.5, BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 0, 34),
            Size = UDim2.new(1, -16, 0, 26),
            Font = Enum.Font.GothamBold,
            Text = string.format("#%02X%02X%02X", math.floor(current.R * 255), math.floor(current.G * 255), math.floor(current.B * 255)),
            TextColor3 = T2.Text, TextSize = 12,
            ZIndex = 61, ClearTextOnFocus = false,
        })
        win:_reg(hexBox, "BackgroundColor3", "GlassCard")
        win:_reg(hexBox, "TextColor3", "Text")
        Corner(hexBox, 9)

        local function applyColor(c)
            current = c; swatch.BackgroundColor3 = c
            local h2 = Color3.toHSV(c)
            hueThumb.Position = UDim2.new(h2, -5, 0.5, -9)
            hexBox.Text = string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
            if callback then task.spawn(callback, c) end
        end

        local hDrag = false
        hueBar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                hDrag = true
                applyColor(Color3.fromHSV(math.clamp((i.Position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1), 1, 1))
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if hDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                applyColor(Color3.fromHSV(math.clamp((i.Position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1), 1, 1))
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then hDrag = false end
        end)
        hexBox.FocusLost:Connect(function()
            local hex = hexBox.Text:gsub("#", "")
            if #hex == 6 then
                local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
                if r and g and b then applyColor(Color3.fromRGB(r, g, b)) end
            end
        end)
        swatch.MouseButton1Click:Connect(function()
            pickerOpen = not pickerOpen
            if pickerOpen then
                popup.Visible = true; popup.Size = UDim2.new(0, 198, 0, 0)
                Tween(popup, {Size = UDim2.new(0, 198, 0, 72)}, 0.28, Enum.EasingStyle.Quint)
            else
                Tween(popup, {Size = UDim2.new(0, 198, 0, 0)}, 0.22)
                task.delay(0.24, function() popup.Visible = false end)
            end
        end)
        return {Get = function() return current end, Set = applyColor}
    end

    return Sec
end

-- ─── DESTROY ──────────────────────────────────────────────────
function NexUI:Destroy()
    if self._inputConn then self._inputConn:Disconnect() end
    if self._gui       then self._gui:Destroy() end
    if self._wmGui     then self._wmGui:Destroy() end
    if self._toastGui  then self._toastGui:Destroy() end
    if self._blur      then self._blur:Destroy() end
    table.clear(self._keybinds)
    table.clear(self._themeReg)
    table.clear(self._accentLinks)
end

return NexUI
