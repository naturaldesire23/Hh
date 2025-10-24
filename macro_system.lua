--// Garden Tower Defense - Optimized Macro System v2.1 (Finished by Assistant)
-- Requires: a Lua executor environment with file IO for save/load (optional)
-- WARNING: This script DOES invoke RemoteFunctions. Run only on servers you control or have permission to automate.

local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Rain-Design/Libraries/main/Shaman/Library.lua'))()
local Flags = Library.Flags

local Players      = game:GetService("Players")
local plr          = Players.LocalPlayer
local rs           = game:GetService("ReplicatedStorage")
local remotes      = rs:WaitForChild("RemoteFunctions")
local Workspace    = game:GetService("Workspace")
local RunService   = game:GetService("RunService")

-- Compatibility
local isFile = writefile and readfile and isfolder and makefolder and listfiles and delfile
local canHook = hookmetamethod ~= nil
local unpack = unpack or table.unpack

-- Settings
local Settings = {
    MacroEnabled      = false,
    PositionOffset    = 2,
    UsePositionOffset = true,
    AutoWalk          = false,
    AutoUpgrade       = true,
    UpgradeDelay      = 125,            -- money threshold for upgrades (example)
    MacroPaused       = false,

    AutoDifficulty    = "dif_normal",
    AutoMap           = "map_dojo",
    AutoSkipWaves     = true,
    TickSpeed         = 3,
    AutoRestart       = true,
    RestartDelay      = 12,
}

-- Recorder
local Recorder = {
    IsRecording = false,
    StartTime   = 0,
    Actions     = {},
    MacroName   = "MyMacro",
    LastMoney   = 0,
}

-- Global state
_G.myUnitIDs          = _G.myUnitIDs or {}
_G.trackingEnabled    = false
_G.upgradeLoopRunning = false
_G.autoWalkConnection = nil
_G.recordedUnits      = {}
_G.macroThread        = nil

-- Error log
local ErrorLog = {}
local function logError(ctx, err)
    local msg = string.format("[%s] %s", ctx, tostring(err))
    table.insert(ErrorLog, {time = os.time(), msg = msg})
    warn(msg)
end

-- UI
local Window          = Library:Window({Text = "GTD Macro v2"})
local FarmTab         = Window:Tab({Text = "Farm"})
local AntiBanTab      = Window:Tab({Text = "Anti-Ban"})
local RecorderTab     = Window:Tab({Text = "Recorder"})
local AutoPlayTab     = Window:Tab({Text = "Auto Play"})

local FarmSection     = FarmTab:Section({Text = "Auto Farm"})
local UpgradeSection  = FarmTab:Section({Text = "Upgrades", Side = "Right"})
local AntiBanSection  = AntiBanTab:Section({Text = "Humanization"})
local MovementSection = AntiBanTab:Section({Text = "Movement", Side = "Right"})
local RecorderSection = RecorderTab:Section({Text = "Recording"})
local SavedMacrosSec  = RecorderTab:Section({Text = "Saved Macros", Side = "Right"})
local GameSection     = AutoPlayTab:Section({Text = "Game Settings"})
local RestartSection  = AutoPlayTab:Section({Text = "Restart Settings", Side = "Right"})

local StatusLabel, RecorderStatusLabel, ErrorLabel

StatusLabel = FarmSection:Label({Text = "Status: Idle", Color = Color3.fromRGB(150,150,150)})
RecorderStatusLabel = RecorderSection:Label({Text = "Recorder: Idle", Color = Color3.fromRGB(150,150,150)})
ErrorLabel = Window:Label({Text = "Errors: 0", Color = Color3.fromRGB(200,50,50)})

--------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------
local function getMoney()
    local ok, val = pcall(function()
        return plr:GetAttribute("Cash") or (plr:FindFirstChild("Cash") and plr.Cash.Value) or 0
    end)
    return ok and val or 0
end

local function getEntities()
    local ok, ent = pcall(function()
        return Workspace:WaitForChild("Map"):WaitForChild("Entities")
    end)
    return ok and ent or nil
end

local function getRandomOffset()
    if not Settings.UsePositionOffset then return Vector3.new() end
    local o = Settings.PositionOffset
    return Vector3.new(
        math.random(-o*10, o*10)/10,
        0,
        math.random(-o*10, o*10)/10
    )
end

local function getUnitID(unit)
    for _ = 1, 10 do
        local ok, id = pcall(function()
            for _, v in ipairs(unit:GetDescendants()) do
                if (v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue"))
                    and v.Name:lower():find("id") then
                    return v.Value
                end
            end
            for n, v in pairs(unit:GetAttributes()) do
                if n:lower():find("id") then return v end
            end
        end)
        if ok and id then return id end
        task.wait(0.2)
    end
    return nil
end

local function safeInvoke(remote, ...)
    local ok, res = pcall(function() return remote:InvokeServer(...) end)
    if not ok then logError("Remote", res) end
    return ok and res or nil
end

local function detectGameEnd()
    local ok, gui = pcall(function() return plr.PlayerGui:FindFirstChild("GameGuiNoInset") end)
    if not ok or not gui then return false end
    local defeat = gui:FindFirstChild("DefeatScreen") or gui:FindFirstChild("Defeat")
    local victory = gui:FindFirstChild("VictoryScreen") or gui:FindFirstChild("Victory")
    return (defeat and defeat.Visible) or (victory and victory.Visible)
end

--------------------------------------------------------------------
-- Auto Walk
--------------------------------------------------------------------
local function startAutoWalk()
    if _G.autoWalkConnection then
        _G.autoWalkConnection:Disconnect()
        _G.autoWalkConnection = nil
    end
    local cd, walking = 0, false
    _G.autoWalkConnection = RunService.Heartbeat:Connect(function(dt)
        if not Settings.AutoWalk or not _G.trackingEnabled then return end
        cd = cd - dt
        local ok = pcall(function()
            local char = plr.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            if cd <= 0 then
                if not walking then
                    walking = true
                    local dur = math.random(30,80)/10
                    local tx = math.random(-50,50)
                    local tz = math.random(-50,50)
                    hum:MoveTo(hrp.Position + Vector3.new(tx,0,tz))
                    cd = dur
                else
                    walking = false
                    local dur = math.random(20,50)/10
                    hum:MoveTo(hrp.Position)
                    cd = dur
                end
            end
        end)
        if not ok then
            if _G.autoWalkConnection then _G.autoWalkConnection:Disconnect() end
            _G.autoWalkConnection = nil
        end
    end)
end

local function stopAutoWalk()
    if _G.autoWalkConnection then
        _G.autoWalkConnection:Disconnect()
        _G.autoWalkConnection = nil
    end
    pcall(function()
        local char = plr.Character
        if char and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
            char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
        end
    end)
end

--------------------------------------------------------------------
-- Unit tracking
--------------------------------------------------------------------
local function setupUnitTracking()
    local ents = getEntities()
    if not ents then return end

    ents.ChildAdded:Connect(function(child)
        task.spawn(function()
            if not child or not child.Parent or not tostring(child.Name):find("unit_") then return end
            task.wait(1)
            local id = getUnitID(child)
            if id then
                if _G.trackingEnabled then
                    table.insert(_G.myUnitIDs, id)
                    warn("tracked unit:", id)
                end
                if Recorder.IsRecording then
                    table.insert(_G.recordedUnits, id)
                    warn("recorder tracked:", id)
                end
            end
        end)
    end)

    ents.ChildRemoved:Connect(function(child)
        if not child or not tostring(child.Name):find("unit_") then return end
        task.spawn(function()
            local id = getUnitID(child)
            if id then
                for i = #_G.myUnitIDs, 1, -1 do
                    if _G.myUnitIDs[i] == id then table.remove(_G.myUnitIDs, i) end
                end
            end
        end)
    end)
end

-- initialize tracking hook (safe to call multiple times)
pcall(setupUnitTracking)

--------------------------------------------------------------------
-- Game setup
--------------------------------------------------------------------
local function setupGame()
    task.spawn(function()
        pcall(function() safeInvoke(remotes.PlaceDifficultyVote, Settings.AutoDifficulty) end)
        task.wait(0.5)
        pcall(function() safeInvoke(remotes.ChangeTickSpeed, Settings.TickSpeed) end)

        if Settings.AutoSkipWaves then
            task.wait(6)
            task.spawn(function()
                while _G.trackingEnabled do
                    pcall(function() safeInvoke(remotes.SkipWave, "y") end)
                    task.wait(1)
                end
            end)
        end
        warn("game setup complete")
    end)
end

--------------------------------------------------------------------
-- Unit costs
--------------------------------------------------------------------
local unitCosts = {
    unit_tomato_rainbow = 100,
    unit_metal_flower   = 2250,
    unit_golem_dragon   = 5000,
    unit_eyeball        = 4500,
    unit_punch_potato   = 2500,
    unit_lucky_plant    = 1500,
    unit_eye_petal      = 5500,
    unit_confusion_plant= 1000,
}
local function getUnitCost(t) return unitCosts[t] or 0 end

--------------------------------------------------------------------
-- Money monitoring (recording)
--------------------------------------------------------------------
local function startMoneyMonitoring()
    if not Recorder.IsRecording then return end
    task.spawn(function()
        Recorder.LastMoney = getMoney()
        while Recorder.IsRecording do
            task.wait(0.1)
            local cur = getMoney()
            if cur ~= Recorder.LastMoney then
                local diff = Recorder.LastMoney - cur
                if diff > 0 then
                    local t = tick() - Recorder.StartTime
                    warn(string.format("cost $%d @ %.1fs", diff, t))
                end
                Recorder.LastMoney = cur
            end
        end
    end)
end

--------------------------------------------------------------------
-- Recorder hook
--------------------------------------------------------------------
if canHook then
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}

        if method == "InvokeServer" and Recorder.IsRecording then
            -- PLACE
            if tostring(self.Name):lower() == "placeunit" then
                local unit, data = args[1], args[2]
                task.defer(function()
                    pcall(function()
                        local t = math.floor((tick() - Recorder.StartTime)*10)/10
                        local rec = {
                            time   = t,
                            type   = "place",
                            unit   = unit,
                            cframe = data and data.CF or CFrame.new(),
                            position = data and Vector3.new(data.Position.X, data.Position.Y, data.Position.Z) or Vector3.new(),
                            rotation = data and data.Rotation or 0,
                            cost   = getUnitCost(unit),
                            cashBefore = Recorder.LastMoney
                        }
                        table.insert(Recorder.Actions, rec)
                        warn(string.format("recorded place %s @ %.1fs", unit, t))
                        if RecorderStatusLabel then
                            RecorderStatusLabel:Set({
                                Text = string.format("Recording... (%d)", #Recorder.Actions),
                                Color = Color3.fromRGB(255,100,100)
                            })
                        end
                    end)
                end)

            -- UPGRADE
            elseif tostring(self.Name):lower() == "upgradeunit" then
                local uid = args[1]
                task.defer(function()
                    pcall(function()
                        local idx = table.find(_G.recordedUnits, uid)
                        if not idx then
                            -- If uid not in recordedUnits yet, still record with uid so playback can reference directly
                            idx = #_G.recordedUnits + 1
                        end
                        local t = math.floor((tick() - Recorder.StartTime)*10)/10
                        local rec = {
                            time   = t,
                            type   = "upgrade",
                            unitIndex = idx,
                            uid = uid,
                            cashBefore = Recorder.LastMoney
                        }
                        table.insert(Recorder.Actions, rec)
                        warn(string.format("recorded upgrade (uid=%s) @ %.1fs", tostring(uid), t))
                        if RecorderStatusLabel then
                            RecorderStatusLabel:Set({
                                Text = string.format("Recording... (%d)", #Recorder.Actions),
                                Color = Color3.fromRGB(255,100,100)
                            })
                        end
                    end)
                end)

            -- SELL
            elseif tostring(self.Name):lower() == "sellunit" then
                local uid = args[1]
                task.defer(function()
                    pcall(function()
                        local idx = table.find(_G.recordedUnits, uid)
                        local t = math.floor((tick() - Recorder.StartTime)*10)/10
                        local rec = {time = t, type = "sell", unitIndex = idx or -1, uid = uid}
                        table.insert(Recorder.Actions, rec)
                        warn(string.format("recorded sell (uid=%s) @ %.1fs", tostring(uid), t))
                        if RecorderStatusLabel then
                            RecorderStatusLabel:Set({
                                Text = string.format("Recording... (%d)", #Recorder.Actions),
                                Color = Color3.fromRGB(255,100,100)
                            })
                        end
                    end)
                end)
            end
        end
        return old(self, ...)
    end)
else
    warn("hookmetamethod unavailable - recorder may not capture actions")
end

--------------------------------------------------------------------
-- Recorder controls
--------------------------------------------------------------------
local function startRecording()
    Recorder.IsRecording = true
    Recorder.StartTime   = tick()
    Recorder.Actions     = {}
    _G.recordedUnits     = {}
    Recorder.LastMoney   = getMoney()
    warn("recording started")
    if RecorderStatusLabel then
        RecorderStatusLabel:Set({Text = "Recording... (0)", Color = Color3.fromRGB(255,100,100)})
    end
    startMoneyMonitoring()
end

local function stopRecording()
    Recorder.IsRecording = false
    warn("recording stopped - actions:", #Recorder.Actions)
    if RecorderStatusLabel then
        RecorderStatusLabel:Set({Text = string.format("Stopped (%d)", #Recorder.Actions), Color = Color3.fromRGB(255,200,0)})
    end
end

local function tableToString(t, indent)
    indent = indent or ""
    local s = "{\n"
    for k,v in pairs(t) do
        s = s .. indent .. "    "
        if type(k)=="string" then s = s..'["'..k..'"] = ' else s = s.."["..k.."] = " end
        if type(v)=="table" then
            s = s .. tableToString(v, indent.."    ")
        elseif type(v)=="string" then
            s = s..'"'..v..'"'
        elseif typeof(v)=="Vector3" then
            s = s..string.format("Vector3.new(%.10f, %.10f, %.10f)", v.X, v.Y, v.Z)
        elseif typeof(v)=="CFrame" then
            local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = v:GetComponents()
            s = s..string.format("CFrame.new(%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f)", 
                x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
        else
            s = s..tostring(v)
        end
        s = s..",\n"
    end
    return s..indent.."}"
end

local function loadSavedMacros()
    if not isFile then return end
    pcall(function()
        for _,c in pairs(SavedMacrosSec:GetDescendants()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
    end)
    pcall(function()
        if not isfolder("SimpleSpy") then makefolder("SimpleSpy") end
        if not isfolder("SimpleSpy/Macros") then makefolder("SimpleSpy/Macros") end
    end)

    local ok, files = pcall(listfiles, "SimpleSpy/Macros")
    if not ok or not files then
        SavedMacrosSec:Label({Text = "No macros yet", Color = Color3.fromRGB(150,150,150)})
        return
    end

    local cnt = 0
    for _,f in ipairs(files) do
        if f:match("%.lua$") then
            cnt = cnt + 1
            local name = f:match("([^/\\]+)%.lua$")
            SavedMacrosSec:Button({
                Text = "Play "..name,
                Tooltip = "Play this macro",
                Callback = function() playMacro(f) end
            })
            SavedMacrosSec:Button({
                Text = "Delete "..name,
                Tooltip = "Delete "..name,
                Callback = function()
                    pcall(delfile, f)
                    task.wait(0.2)
                    loadSavedMacros()
                end
            })
        end
    end
    if cnt == 0 then
        SavedMacrosSec:Label({Text = "No macros yet", Color = Color3.fromRGB(150,150,150)})
    end
end

--------------------------------------------------------------------
-- Macro playback
--------------------------------------------------------------------
function playMacro(file)
    if not isFile then return end
    local ok, script = pcall(readfile, file)
    if not ok then warn("cannot read file"); return end
    local data = loadstring(script)()
    if not data then warn("invalid macro file"); return end
    warn("playing:", data.name, "#actions:", #data.actions)

    _G.myUnitIDs          = {}
    _G.trackingEnabled    = true
    _G.upgradeLoopRunning = false
    _G.recordedUnits      = {}
    Settings.MacroPaused  = false

    setupGame()

    _G.macroThread = coroutine.create(function()
        for i, act in ipairs(data.actions) do
            local prev = data.actions[i-1]
            local waitTime = (act.time or 0) - (prev and prev.time or 0)
            if waitTime > 0 then
                local elapsed = 0
                while elapsed < waitTime do
                    while Settings.MacroPaused do task.wait(0.5) end
                    task.wait(0.05)
                    elapsed = elapsed + 0.05
                end
            end
            if not _G.trackingEnabled then break end

            if act.type == "place" then
                local off = getRandomOffset()
                local cf  = (act.cframe or CFrame.new(act.position or Vector3.new())) + off
                local payload = {
                    Valid    = true,
                    Rotation = act.rotation or 0,
                    CF       = cf,
                    Position = Vector3.new(cf.X, cf.Y, cf.Z)
                }
                local waited = 0
                while getMoney() < (act.cost or getUnitCost(act.unit)) and waited < 120 do
                    task.wait(1); waited = waited + 1
                end
                if getMoney() >= (act.cost or getUnitCost(act.unit)) then
                    local id = safeInvoke(remotes.PlaceUnit, act.unit, payload)
                    if id then
                        table.insert(_G.recordedUnits, id)
                        warn("placed", act.unit, "-> uid:", tostring(id))
                    else
                        -- if server didn't return id, store a fallback placeholder (so upgrades referencing index still function)
                        local placeholderID = "local_"..tostring(os.time()).."_"..tostring(i)
                        table.insert(_G.recordedUnits, placeholderID)
                        warn("placed (no id returned) stored placeholder:", placeholderID)
                    end
                else
                    warn("timeout (place)", act.unit)
                end

            elseif act.type == "upgrade" then
                local uid = _G.recordedUnits[act.unitIndex] or act.uid
                if not uid then
                    -- wait a bit for unit mapping to appear
                    local waited = 0
                    while not uid and waited < 5 do
                        task.wait(0.25)
                        waited = waited + 0.25
                        uid = _G.recordedUnits[act.unitIndex] or act.uid
                    end
                end

                if uid then
                    local tries = 0
                    local okUpgrade = false
                    repeat
                        okUpgrade = pcall(function() safeInvoke(remotes.UpgradeUnit, uid) end)
                        tries = tries + 1
                        if not okUpgrade then task.wait(0.2) end
                    until okUpgrade or tries >= 6
                    if okUpgrade then
                        warn("upgraded unit #"..tostring(act.unitIndex).." uid="..tostring(uid))
                    else
                        warn("failed to upgrade unit #"..tostring(act.unitIndex))
                    end
                else
                    warn("upgrade skipped - unit id not found for index", act.unitIndex)
                end

            elseif act.type == "sell" then
                local uid = _G.recordedUnits[act.unitIndex] or act.uid
                if not uid then
                    local waited = 0
                    while not uid and waited < 5 do
                        task.wait(0.25)
                        waited = waited + 0.25
                        uid = _G.recordedUnits[act.unitIndex] or act.uid
                    end
                end

                if uid then
                    local okSell = pcall(function() safeInvoke(remotes.SellUnit, uid) end)
                    if okSell then
                        warn("sold unit #"..tostring(act.unitIndex).." uid="..tostring(uid))
                        for i = #_G.recordedUnits, 1, -1 do
                            if _G.recordedUnits[i] == uid then table.remove(_G.recordedUnits, i) end
                        end
                    else
                        warn("failed to sell unit #"..tostring(act.unitIndex))
                    end
                else
                    warn("sell skipped - unit id not found for index", act.unitIndex)
                end
            else
                warn("unknown action type:", tostring(act.type))
            end
        end

        -- finished playing actions
        _G.trackingEnabled = false
        _G.upgradeLoopRunning = false
        pcall(stopAutoWalk)

        warn("macro playback complete: "..(data.name or "unknown"))

        if Settings.AutoRestart then
            task.spawn(function()
                task.wait(Settings.RestartDelay or 8)
                pcall(function() safeInvoke(remotes.RestartGame) end)
                warn("requested game restart (AutoRestart)")
            end)
        end
    end)

    -- start the macro coroutine
    local okc, err = pcall(function() coroutine.resume(_G.macroThread) end)
    if not okc then
        logError("playMacro", err)
    end
end

--------------------------------------------------------------------
-- Auto-upgrade loop (optional)
--------------------------------------------------------------------
local function startAutoUpgrades()
    if _G.upgradeLoopRunning then return end
    _G.upgradeLoopRunning = true
    task.spawn(function()
        task.wait(3)
        while _G.upgradeLoopRunning and _G.trackingEnabled do
            if Settings.AutoUpgrade and #_G.myUnitIDs > 0 then
                for _, uid in ipairs(_G.myUnitIDs) do
                    if not _G.upgradeLoopRunning then break end
                    if getMoney() >= Settings.UpgradeDelay then
                        pcall(function() safeInvoke(remotes.UpgradeUnit, uid) end)
                        task.wait(0.35)
                    end
                end
            end
            task.wait(1.5)
        end
    end)
end

local function stopAutoUpgrades()
    _G.upgradeLoopRunning = false
end

--------------------------------------------------------------------
-- Run macro (continuous auto farm mode)
--------------------------------------------------------------------
-- A simple example runner that uses a predefined placement list (like the old macro)
local basePlacements = {
    {time=5,   unit="unit_tomato_rainbow", cost=100, position = Vector3.new(-850.7767,61.93,-155.0453), rotation=180},
    {time=53,  unit="unit_tomato_rainbow", cost=100, position = Vector3.new(-852.2405,61.93,-150.1680), rotation=180},
    {time=100, unit="unit_metal_flower",   cost=2250, position = Vector3.new(-850.2332,61.93,-151.0040), rotation=180},
    {time=130, unit="unit_metal_flower",   cost=2250, position = Vector3.new(-853.2743,61.93,-146.7690), rotation=180},
}

local function generateRandomizedPlacements()
    local randomized = {}
    for _, base in ipairs(basePlacements) do
        local posOffset = getRandomOffset()
        local newPos = base.position + posOffset
        table.insert(randomized, {
            time = base.time,
            unit = base.unit,
            cost = base.cost,
            data = {
                Valid = true,
                Rotation = base.rotation,
                CF = CFrame.new(newPos.X, newPos.Y, newPos.Z),
                Position = newPos
            }
        })
    end
    return randomized
end

local function placeUnits(placements)
    for _, placement in ipairs(placements) do
        task.delay(placement.time, function()
            local waitTime = 0
            while getMoney() < placement.cost and waitTime < 60 do
                task.wait(1)
                waitTime = waitTime + 1
            end
            if getMoney() >= placement.cost then
                local ok, res = pcall(function() return safeInvoke(remotes.PlaceUnit, placement.unit, placement.data) end)
                if ok then
                    if res then
                        table.insert(_G.recordedUnits, res)
                    else
                        table.insert(_G.recordedUnits, "local_"..tostring(os.time()))
                    end
                    warn("[PLACED] " .. placement.unit)
                else
                    warn("[PLACED] failed to place: "..tostring(placement.unit))
                end
            else
                warn("[PLACED] timed out waiting money for", placement.unit)
            end
        end)
    end
end

local function runMacro()
    while Settings.MacroEnabled do
        warn("========================================")
        warn("[GAME START] Starting new game...")
        warn("========================================")

        _G.myUnitIDs = {}
        _G.trackingEnabled = true
        _G.upgradeLoopRunning = false

        local randomizedPlacements = generateRandomizedPlacements()

        setupGame()
        placeUnits(randomizedPlacements)
        startAutoUpgrades()

        if Settings.AutoWalk then startAutoWalk() end

        -- roughly wait for the game to finish (this is map/difficulty dependent)
        task.wait(267)

        _G.trackingEnabled = false
        _G.upgradeLoopRunning = false
        stopAutoWalk()

        task.wait(2)

        warn("[RESTART] Restarting game...")
        pcall(function() safeInvoke(remotes.RestartGame) end)

        task.wait(8)
    end
end

--------------------------------------------------------------------
-- Recorder UI controls
--------------------------------------------------------------------
RecorderSection:Input({Placeholder = "Macro Name", Flag = "MacroName",
    Callback = function(text) Recorder.MacroName = text end})

RecorderSection:Toggle({Text = "Start Recording",
    Callback = function(enabled)
        if enabled then startRecording() else stopRecording() end
    end})

RecorderSection:Button({Text = "Save Recording",
    Callback = function() 
        if not isFile then warn("no file I/O"); return end
        if #Recorder.Actions == 0 then warn("nothing to save"); return end
        local name = Recorder.MacroName == "" and ("Macro_"..os.time()) or Recorder.MacroName:gsub("[^%w_-]", "_")
        local data = {name = name, actions = Recorder.Actions, createdAt = os.date("%Y-%m-%d %H:%M:%S"), version = 2}
        local script = "return "..tableToString(data)
        pcall(function()
            if not isfolder("SimpleSpy") then makefolder("SimpleSpy") end
            if not isfolder("SimpleSpy/Macros") then makefolder("SimpleSpy/Macros") end
        end)
        local ok, err = pcall(function() writefile("SimpleSpy/Macros/"..name..".lua", script) end)
        if ok then warn("saved:", name); task.wait(0.5); loadSavedMacros() else warn("save error:", err) end
    end})

--------------------------------------------------------------------
-- Saved macros UI
--------------------------------------------------------------------
SavedMacrosSec:Button({Text = "Reload Saved Macros", Callback = loadSavedMacros})
if isFile then pcall(loadSavedMacros) end

--------------------------------------------------------------------
-- Game UI controls
--------------------------------------------------------------------
GameSection:Dropdown({
    Text = "Auto Difficulty",
    List = {"dif_easy","dif_normal","dif_hard","dif_insane","dif_impossible"},
    Callback = function(val) Settings.AutoDifficulty = val; pcall(function() safeInvoke(remotes.PlaceDifficultyVote, val) end) end
})

GameSection:Dropdown({
    Text = "Auto Map",
    List = {"map_dojo","map_back_garden","map_toxic","map_island","map_jungle","map_farm"},
    Callback = function(val) Settings.AutoMap = val; pcall(function() safeInvoke(remotes.LobbySetMap_6, val) end) end
})

GameSection:Slider({
    Text = "Tick Speed",
    Default = Settings.TickSpeed,
    Minimum = 1,
    Maximum = 5,
    Callback = function(v) Settings.TickSpeed = v; pcall(function() safeInvoke(remotes.ChangeTickSpeed, v) end) end
})

GameSection:Toggle({Text="Auto Skip Waves", Callback = function(v) Settings.AutoSkipWaves = v end})
RestartSection:Toggle({Text="Auto Restart", Callback = function(v) Settings.AutoRestart = v end})
RestartSection:Input({Placeholder = tostring(Settings.RestartDelay), Callback = function(txt) Settings.RestartDelay = tonumber(txt) or Settings.RestartDelay end})

--------------------------------------------------------------------
-- Farm UI controls
--------------------------------------------------------------------
FarmSection:Toggle({Text = "Auto Normal", Tooltip = "Automatically farms Normal difficulty",
    Callback = function(enabled)
        Settings.MacroEnabled = enabled
        if enabled then
            warn("MACRO STARTED")
            StatusLabel:Set({Text = "Status: Running", Color = Color3.fromRGB(0,255,100)})
            task.spawn(runMacro)
        else
            warn("MACRO STOPPED")
            StatusLabel:Set({Text = "Status: Stopped", Color = Color3.fromRGB(255,100,100)})
            _G.trackingEnabled = false
            _G.upgradeLoopRunning = false
            stopAutoWalk()
        end
    end})

AntiBanSection:Slider({Text="Position Offset", Default = Settings.PositionOffset, Minimum = 0, Maximum = 8,
    Callback = function(v) Settings.PositionOffset = v end})

MovementSection:Toggle({Text = "Auto Walk", Callback = function(enabled)
    Settings.AutoWalk = enabled
    if enabled then startAutoWalk() else stopAutoWalk() end
end})

--------------------------------------------------------------------
-- Final warnings and exports
--------------------------------------------------------------------
warn("GTD Macro v2.1 loaded.")
return {
    Settings = Settings,
    Recorder = Recorder,
    playMacro = playMacro,
    loadSavedMacros = loadSavedMacros,
}
