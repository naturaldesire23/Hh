-- [[ BYTE LITE - ALLUSIVE FIXED ]] --
-- UI: Allusive library (naturaldesire23)
-- All features work. Keybinds: click checkbox label → press key → binds instantly.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Alive = workspace:FindFirstChild("Alive") or workspace:WaitForChild("Alive")
local Runtime = workspace:FindFirstChild("Runtime")

-- ===== CONFIG =====
local ConfigFile = "ByteLite_Config.json"
local Settings = {}

local function LoadSettings()
    pcall(function()
        if isfile and isfile(ConfigFile) then
            local d = readfile(ConfigFile)
            if d and d ~= "" then Settings = HttpService:JSONDecode(d) end
        end
    end)
    local defaults = {
        AutoParry=false, ParryMode="Remote", CurveType="Camera", ParryAccuracy=50,
        AntiCurve=false, RandomAccuracy=false, GrabParry=false,
        ManualSpam=false, ManualSpamCPS=60,
        AutoSpam=false, AutoSpamMode="Remote", AutoSpamModeType="Distance", DistanceMultiplier=0.15,
        InfinityDetection=false, DeathSlashDetection=false, TimeHoleDetection=false,
        SlashesofFuryDetection=false, ForcefieldDetection=false, PhantomDetection=false,
        SingularityDetection=false, DribbleDetection=false, PullDetection=false,
        PulseDetection=false, AbilityActiveDetection=false, TornadoDetection=false,
        HellHookDetection=false,
        BallStylingEnabled=false, KillSoundEnabled=false, SelectedKillSound="Fahhhh",
        KB_ManualSpam="E", KB_AutoParry="V", KB_AutoSpam="G", KB_ChromaBall="B",
    }
    for k,v in pairs(defaults) do if Settings[k] == nil then Settings[k] = v end end
end

local function SaveSettings()
    pcall(function() if writefile then writefile(ConfigFile, HttpService:JSONEncode(Settings)) end end)
end
LoadSettings()

-- ===== PING =====
getgenv()._ZX_PingCache = getgenv()._ZX_PingCache or 50
if not getgenv()._ZX_PingUpdater then
    getgenv()._ZX_PingUpdater = true
    task.spawn(function()
        local net = Stats:WaitForChild("Network",30); if not net then return end
        local ss = net:WaitForChild("ServerStatsItem",30); if not ss then return end
        local dp = ss:WaitForChild("Data Ping",30); if not dp then return end
        while true do getgenv()._ZX_PingCache = dp:GetValue(); task.wait(0.1) end
    end)
end
local function getPing() return math.floor(getgenv()._ZX_PingCache or 0) end

-- ===== PARRY PATCH =====
local _PARRY_PATCH = {
    keyTable=nil, transformFn=nil, netModule=nil,
    remoteId=nil, parryHash=nil, parryRemote=nil,
    ready=false, _lastSig=nil,
}
local original_debug_info = getrenv().debug.info
local original_getfenv = getrenv().getfenv

task.spawn(function()
    repeat task.wait(1) until game:IsLoaded()
    task.wait(2)
    local old_dinfo
    old_dinfo = hookfunction(getrenv().debug.info, function(f,t)
        if type(f)=="function" then return "[C]"
        elseif f==4 and t=="s" then return "ReplicatedStorage.Controllers.SwordsController " end
        return old_dinfo(f,t)
    end)
    local old_gfenv
    old_gfenv = hookfunction(getrenv().getfenv, function(l)
        if l ~= nil and type(l)=="number" then
            if l>=1 and l<=10 then return old_gfenv(10) end
        end
        return old_gfenv(l)
    end)
    pcall(function()
        local Controllers = ReplicatedStorage:WaitForChild("Controllers",5)
        if not Controllers then return end
        local SC_mod
        for _,child in ipairs(Controllers:GetChildren()) do
            if child.Name:sub(1,16)=="SwordsController" then SC_mod=child; break end
        end
        if not SC_mod then return end
        local PRY = SC_mod:FindFirstChild("PRY")
        if not PRY then return end
        local Parry_Function = require(PRY)
        local getupvals = debug.getupvalues or getupvals
        if not getupvals then return end
        local ups = getupvals(Parry_Function)
        if not ups or #ups < 8 then return end
        _PARRY_PATCH.keyTable = ups[3]
        _PARRY_PATCH.transformFn = ups[4]
        _PARRY_PATCH.netModule = ups[6]
        _PARRY_PATCH.remoteId = ups[7]
        _PARRY_PATCH.parryHash = ups[8]
        pcall(function() _PARRY_PATCH.parryRemote = _PARRY_PATCH.netModule:RemoteEvent(_PARRY_PATCH.remoteId) end)
        if _PARRY_PATCH.parryRemote then _PARRY_PATCH.ready = true end
    end)
    pcall(function()
        hookfunction(getrenv().debug.info, original_debug_info)
        hookfunction(getrenv().getfenv, original_getfenv)
    end)
    print("[Byte Lite] Bypass captured")
end)

function _PARRY_PATCH.fire(curveCFrame, screenPositions, mouseLocation)
    if not _PARRY_PATCH.ready then return false end
    local kt = _PARRY_PATCH.keyTable; if not kt then return false end
    local keyIndex = kt[3]
    local currentKey = kt[1] and kt[1][keyIndex]; if not currentKey then return false end
    local tok, transformed = pcall(_PARRY_PATCH.transformFn, currentKey, "TIME")
    if not tok or not transformed then
        tok, transformed = pcall(_PARRY_PATCH.transformFn, currentKey)
        if not tok or not transformed then return false end
    end
    local serverTime = workspace:GetServerTimeNow()*100
    local timeStr = tostring(math.floor(serverTime))
    local sig = tostring(currentKey).."|"..timeStr
    if _PARRY_PATCH._lastSig == sig then return true end
    _PARRY_PATCH._lastSig = sig
    local tc={}
    for i=1,#timeStr do
        local ki=(i-1)%#transformed+1
        local kb=string.byte(transformed,ki)
        local tb=(string.byte(timeStr,i)+i)%256
        tc[i]=string.char(bit32.bxor(tb,kb))
    end
    local token=table.concat(tc)
    pcall(function()
        _PARRY_PATCH.parryRemote:FireServer(
            _PARRY_PATCH.parryHash, currentKey, token,
            0.5, curveCFrame, screenPositions, mouseLocation, false
        )
    end)
    return true
end

-- ===== ABILITY FLAGS =====
local AbilityFlags = {
    InfinityBall=false, DeathSlashBall=false, TimeHole=false,
    SlashesofFury=false, Forcefield=false, Phantom=false,
    Singularity=false, Dribble=false, Pull=false, Pulse=false,
    AbilityActive=false, Tornado=false, HellHook=false,
}

-- ===== SYSTEM =====
local System = {
    __properties = {
        __autoparry_enabled = Settings.AutoParry,
        __accuracy = Settings.ParryAccuracy,
        __first_parry_done = false,
        __manual_spam_enabled = false,
        __auto_spam_enabled = false,
        __connections = {},
        __parried = false,
        __parries = 0,
        __curve_mode = Settings.CurveType,
        __grab_parry_enabled = Settings.GrabParry,
        __random_accuracy = Settings.RandomAccuracy,
        __fake_body_enabled = false,
    },
    ball={}, player={}, parry={}, autoparry={}, manual_spam={}, auto_spam={},
}

local _parryExecuting = false
local _parryLockTime = 0.15
local LastParryTime = 0

local Speed_Divisor_Multiplier = 1.1
local function update_divisor()
    Speed_Divisor_Multiplier = 0.7 + (System.__properties.__accuracy - 1) * (0.35/99)
end
update_divisor()

local _cached_balls, _cached_balls_time = {}, 0
function System.ball.get_all()
    local now = tick()
    if now - _cached_balls_time < 0.016 then return _cached_balls end
    local t={}
    local balls = workspace:FindFirstChild('Balls')
    if balls then
        for _,b in ipairs(balls:GetChildren()) do
            if b:GetAttribute('realBall') then table.insert(t,b) end
        end
    end
    _cached_balls=t; _cached_balls_time=now
    return t
end
function System.ball.get() return System.ball.get_all()[1] end

function System.player.get_closest()
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return nil end
    local best,result = math.huge, nil
    for _,entity in ipairs(Alive:GetChildren()) do
        if entity ~= LocalPlayer.Character and entity:FindFirstChild("HumanoidRootPart") then
            local d = (entity.HumanoidRootPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
            if d < best then best=d; result=entity end
        end
    end
    return result
end

local function get_curve_cframe(mode)
    local camera = workspace.CurrentCamera
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not root then return camera.CFrame end
    local ok,mouse = pcall(function() return UserInputService:GetMouseLocation() end)
    local mouseV2 = ok and Vector2.new(mouse.X,mouse.Y) or Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
    local closest,closestDist = nil, math.huge
    for _,p in ipairs(Alive:GetChildren()) do
        if p ~= LocalPlayer.Character and p.PrimaryPart then
            local sp,onScreen = camera:WorldToScreenPoint(p.PrimaryPart.Position)
            if onScreen then
                local d=(mouseV2-Vector2.new(sp.X,sp.Y)).Magnitude
                if d<closestDist then closestDist=d; closest=p end
            end
        end
    end
    if mode=="Camera" then return camera.CFrame end
    if mode=="Mouse" then return CFrame.new(root.Position, root.Position+camera:ScreenPointToRay(mouseV2.X,mouseV2.Y).Direction) end
    if mode=="Players" then return closest and CFrame.new(root.Position,closest.PrimaryPart.Position) or camera.CFrame end
    if mode=="Normal" then return CFrame.new(root.Position, root.Position+Vector3.new(0,0,-1)) end
    if mode=="Up" then return CFrame.new(root.Position, root.Position+Vector3.new(0,1,0)) end
    if mode=="Down" then return CFrame.new(root.Position, root.Position+Vector3.new(0,-1,0)) end
    if mode=="Left" then return CFrame.new(root.Position, root.Position-camera.CFrame.RightVector) end
    if mode=="Right" then return CFrame.new(root.Position, root.Position+camera.CFrame.RightVector) end
    if mode=="Behind" then return CFrame.new(root.Position, root.Position-camera.CFrame.LookVector) end
    if mode=="Random" then return CFrame.new(root.Position, root.Position+Vector3.new(math.random(-100,100),math.random(-100,100),math.random(-100,100)).Unit) end
    if mode=="FrontLeft" then return CFrame.new(root.Position, root.Position+(camera.CFrame.LookVector-camera.CFrame.RightVector).Unit) end
    if mode=="FrontRight" then return CFrame.new(root.Position, root.Position+(camera.CFrame.LookVector+camera.CFrame.RightVector).Unit) end
    if mode=="BackLeft" then return CFrame.new(root.Position, root.Position+(-camera.CFrame.LookVector-camera.CFrame.RightVector).Unit) end
    if mode=="BackRight" then return CFrame.new(root.Position, root.Position+(-camera.CFrame.LookVector+camera.CFrame.RightVector).Unit) end
    if mode=="Spin" then
        local angle=math.rad(tick()*360%360)
        return CFrame.new(root.Position, root.Position+Vector3.new(math.cos(angle),0,math.sin(angle)))
    end
    if mode=="TargetHead" then return (closest and closest:FindFirstChild("Head")) and CFrame.new(root.Position,closest.Head.Position) or camera.CFrame end
    if mode=="High" then return CFrame.new(root.Position, root.Position+camera.CFrame.UpVector*100) end
    if mode=="RandomTarget" then
        local candidates={}
        for _,p in ipairs(Alive:GetChildren()) do
            if p ~= LocalPlayer.Character and p.PrimaryPart then
                local sp,onScreen=camera:WorldToScreenPoint(p.PrimaryPart.Position)
                if onScreen then table.insert(candidates,p) end
            end
        end
        if #candidates>0 then
            local pick=candidates[math.random(1,#candidates)]
            return CFrame.new(root.Position,pick.PrimaryPart.Position)
        end
        return camera.CFrame
    end
    return camera.CFrame
end

local _event_data_cache, _event_data_fire_count = {}, 0

function System.parry.execute(isManual)
    if not LocalPlayer.Character then return false end
    local now = tick()
    if isManual then
        if (now - LastParryTime) < 0.05 then return false end
    else
        if _parryExecuting then return false end
        if (now - LastParryTime) < _parryLockTime then return false end
        _parryExecuting = true
        task.delay(_parryLockTime, function() _parryExecuting = false end)
    end
    LastParryTime = now
    if not System.__properties.__first_parry_done then
        pcall(function()
            for _,conn in pairs(getconnections(LocalPlayer.PlayerGui.Hotbar.Block.Activated)) do conn:Fire() end
        end)
        System.__properties.__first_parry_done = true
        _parryExecuting = false
        return true
    end
    local camera = workspace.CurrentCamera
    local ok,mouse = pcall(function() return UserInputService:GetMouseLocation() end)
    if not ok then _parryExecuting=false; return false end
    _event_data_fire_count = _event_data_fire_count + 1
    if _event_data_fire_count % 3 == 1 then
        _event_data_cache = {}
        if Alive then
            for _,ent in ipairs(Alive:GetChildren()) do
                if ent.PrimaryPart then
                    local s,sp = pcall(function() return camera:WorldToScreenPoint(ent.PrimaryPart.Position) end)
                    if s then _event_data_cache[ent.Name] = sp end
                end
            end
        end
    end
    local cframe = get_curve_cframe(System.__properties.__curve_mode)
    local fired = _PARRY_PATCH.fire(cframe, _event_data_cache, {mouse.X, mouse.Y})
    if fired then
        System.__properties.__parries = System.__properties.__parries + 1
        task.delay(0.5, function()
            if System.__properties.__parries > 0 then System.__properties.__parries = System.__properties.__parries - 1 end
        end)
        return true
    end
    return false
end

function System.parry.keypress()
    if not LocalPlayer.Character then return end
    pcall(function()
        for _,conn in pairs(getconnections(LocalPlayer.PlayerGui.Hotbar.Block.Activated)) do conn:Fire() end
    end)
end

local Lerp_Radians = 0
local Last_Warping = tick()
local Curving = tick()
local Previous_Velocity = {}

function System.is_curved()
    local ball = System.ball.get(); if not ball then return false end
    local zoomies = ball:FindFirstChild('zoomies'); if not zoomies then return false end
    local velocity = zoomies.VectorVelocity
    local speed = velocity.Magnitude; if speed < 1 then return false end
    local ball_dir = velocity.Unit
    local char = LocalPlayer.Character; if not char or not char.PrimaryPart then return false end
    local pos = char.PrimaryPart.Position
    local direction = (pos - ball.Position).Unit
    local dot = direction:Dot(ball_dir)
    local ping = getgenv()._ZX_PingCache
    local distance = (pos - ball.Position).Magnitude
    local reach_time = distance / speed - ping / 1000
    local speed_threshold = math.min(speed/100, 40)
    local ball_distance_threshold = 15 - math.min(distance/1000, 15) + speed_threshold
    table.insert(Previous_Velocity, velocity)
    if #Previous_Velocity > 4 then table.remove(Previous_Velocity, 1) end
    if ball:FindFirstChild('AeroDynamicSlashVFX') then
        if ball.AeroDynamicSlashVFX then Debris:AddItem(ball.AeroDynamicSlashVFX, 0) end
        Curving = tick()
    end
    if Runtime and Runtime:FindFirstChild('Tornado') then
        if (tick()-Curving) < (Runtime.Tornado:GetAttribute("TornadoTime") or 1)+0.314159 then return true end
    end
    local enough_speed = speed > 160
    if enough_speed and reach_time > ping/10 + 0.03 then
        if speed < 300 then ball_distance_threshold = math.max(ball_distance_threshold-15, 15)
        elseif speed < 600 then ball_distance_threshold = math.max(ball_distance_threshold-17, 17)
        elseif speed < 1000 then ball_distance_threshold = math.max(ball_distance_threshold-19, 19)
        else ball_distance_threshold = math.max(ball_distance_threshold-20, 20) end
    end
    if distance < ball_distance_threshold then return false end
    local b = reach_time + 0.03
    local curve_divisor = 1.2
    if speed >= 300 and speed < 450 then curve_divisor=1.21
    elseif speed >= 450 and speed < 600 then curve_divisor=1.335
    elseif speed >= 600 then curve_divisor=1.5 end
    if (tick()-Curving) < (b/curve_divisor) then return true end
    local dot_threshold = 0 - ping/1000
    local direction_difference = ball_dir - velocity.Unit
    local direction_similarity = direction:Dot(direction_difference.Unit)
    if dot - direction_similarity < dot_threshold then return true end
    local clamped_dot = math.clamp(dot, -1, 1)
    local radians = math.deg(math.asin(clamped_dot))
    Lerp_Radians = Lerp_Radians + (radians - Lerp_Radians) * 0.8
    local lerp_threshold = speed < 300 and 0.02 or 0.018
    local warp_divisor = speed < 300 and 1.19 or 1.5
    if Lerp_Radians < lerp_threshold then Last_Warping = tick() end
    if (tick()-Last_Warping) < (b/warp_divisor) then return true end
    if #Previous_Velocity == 4 then
        for i=1,2 do
            local intended = (ball_dir - Previous_Velocity[i].Unit).Unit
            local intended_dot = direction:Dot(intended)
            if dot - intended_dot < dot_threshold then return true end
        end
    end
    local horizDir = Vector3.new(pos.X-ball.Position.X, 0, pos.Z-ball.Position.Z)
    if horizDir.Magnitude > 0 then horizDir = horizDir.Unit end
    local horizBallDir = Vector3.new(ball_dir.X, 0, ball_dir.Z)
    if horizBallDir.Magnitude > 0 then
        horizBallDir = horizBallDir.Unit
        local backwardsAngle = math.deg(math.acos(math.clamp((-horizDir):Dot(horizBallDir), -1, 1)))
        if backwardsAngle < 60 then return true end
    end
    return dot < dot_threshold
end

-- GRAB PARRY
ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, root)
    if not System.__properties.__grab_parry_enabled then return end
    if root.Parent and root.Parent ~= LocalPlayer.Character then
        if not Alive or root.Parent.Parent ~= Alive then return end
    end
    if _parryExecuting then return end
    if (tick()-LastParryTime) < _parryLockTime then return end
    local closest = System.player.get_closest()
    local ball = System.ball.get()
    if not ball or not closest then return end
    local target_distance = (LocalPlayer.Character.PrimaryPart.Position - closest.PrimaryPart.Position).Magnitude
    local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local dot = direction:Dot(ball.AssemblyLinearVelocity.Unit)
    if System.is_curved() and target_distance < 15 and distance < 15 and dot > 0 then
        System.parry.execute()
    end
end)

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(a, b)
    local primary = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
    local ball = System.ball.get()
    if not ball or not primary then return end
    local zoomies = ball:FindFirstChild('zoomies'); if not zoomies then return end
    local speed = zoomies.VectorVelocity.Magnitude
    local distance = (primary.Position - ball.Position).Magnitude
    local ping = getgenv()._ZX_PingCache
    local speed_threshold = math.min(speed/100, 40)
    local reach_time = distance/speed - ping/1000
    local ball_distance_threshold = 15 - math.min(distance/1000, 15) + speed_threshold
    if speed > 100 and reach_time > ping/10 then
        ball_distance_threshold = math.max(ball_distance_threshold-15, 15)
    end
    if b ~= primary and distance > ball_distance_threshold then Curving = tick() end
end)

-- AUTO PARRY
local _lastParriedBallTarget = ""

function System.autoparry.start()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
    end
    _lastParriedBallTarget = ""
    System.__properties.__connections.__autoparry = RunService.PreSimulation:Connect(function()
        if not System.__properties.__autoparry_enabled then return end
        if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
        local balls = System.ball.get_all()
        local one_ball = System.ball.get()
        if not one_ball then return end
        for _, ball in ipairs(balls) do
            local zoomies = ball:FindFirstChild('zoomies'); if not zoomies then continue end
            ball:GetAttributeChangedSignal('target'):Once(function()
                System.__properties.__parried = false
                _lastParriedBallTarget = ""
            end)
            if System.__properties.__parried then continue end
            local ball_target = ball:GetAttribute('target')
            local vel = zoomies.VectorVelocity
            local dist = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
            local ping = getgenv()._ZX_PingCache / 10
            local ping_thresh = math.clamp(ping/10, 5, 17)
            local speed = vel.Magnitude
            local skip = false
            if Settings.InfinityDetection and AbilityFlags.InfinityBall then skip=true end
            if Settings.DeathSlashDetection and AbilityFlags.DeathSlashBall then skip=true end
            if Settings.TimeHoleDetection and AbilityFlags.TimeHole then skip=true end
            if Settings.SlashesofFuryDetection and AbilityFlags.SlashesofFury then skip=true end
            if Settings.ForcefieldDetection and AbilityFlags.Forcefield then skip=true end
            if Settings.PhantomDetection and AbilityFlags.Phantom then skip=true end
            if Settings.SingularityDetection and AbilityFlags.Singularity then skip=true end
            if Settings.DribbleDetection and AbilityFlags.Dribble then skip=true end
            if Settings.PullDetection and AbilityFlags.Pull then skip=true end
            if Settings.PulseDetection and AbilityFlags.Pulse then skip=true end
            if Settings.AbilityActiveDetection and AbilityFlags.AbilityActive then skip=true end
            if Settings.TornadoDetection and AbilityFlags.Tornado then skip=true end
            if Settings.HellHookDetection and AbilityFlags.HellHook then skip=true end
            if skip then continue end
            local capped_speed = math.min(math.max(speed-9.5, 0), 650)
            local speed_divisor_base = 2.4 + capped_speed * 0.002
            local effective_multiplier = Speed_Divisor_Multiplier
            if System.__properties.__random_accuracy then
                if speed < 200 then effective_multiplier = 0.7+(math.random(40,100)-1)*(0.35/99)
                else effective_multiplier = 0.7+(math.random(1,100)-1)*(0.35/99) end
            end
            local parry_acc = ping_thresh + math.max(speed/(speed_divisor_base*effective_multiplier), 9.5)
            if Settings.AntiCurve and one_ball:GetAttribute('target')==LocalPlayer.Name then
                if System.is_curved() then continue end
            end
            if LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then continue end
            if ball_target == LocalPlayer.Name and dist <= parry_acc then
                local fireKey = tostring(ball).."|"..(ball_target or "")
                if _lastParriedBallTarget == fireKey then continue end
                _lastParriedBallTarget = fireKey
                if Settings.ParryMode == "Keypress" then
                    System.parry.keypress()
                else
                    System.parry.execute()
                end
                System.__properties.__parried = true
                task.delay(0.3, function()
                    System.__properties.__parried = false
                end)
            end
        end
    end)
end

function System.autoparry.stop()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
        System.__properties.__connections.__autoparry = nil
    end
    System.__properties.__parried = false
    _lastParriedBallTarget = ""
end

-- MANUAL SPAM
local MSAccumulator = 0
function System.manual_spam.start()
    if System.__properties.__connections.__manual_spam then
        System.__properties.__connections.__manual_spam:Disconnect()
    end
    System.__properties.__manual_spam_enabled = true
    MSAccumulator = 0
    System.__properties.__connections.__manual_spam = RunService.Heartbeat:Connect(function(dt)
        if not System.__properties.__manual_spam_enabled then return end
        if not LocalPlayer.Character then return end
        MSAccumulator = MSAccumulator + dt
        local interval = 1 / math.max(1, Settings.ManualSpamCPS)
        if MSAccumulator < interval then return end
        MSAccumulator = 0
        System.parry.execute(true)
    end)
end
function System.manual_spam.stop()
    System.__properties.__manual_spam_enabled = false
    if System.__properties.__connections.__manual_spam then
        System.__properties.__connections.__manual_spam:Disconnect()
        System.__properties.__connections.__manual_spam = nil
    end
end

-- AUTO SPAM
local AutoSpamState = { lastFireTime=0 }
function System.auto_spam.start()
    if System.__properties.__connections.__auto_spam then
        System.__properties.__connections.__auto_spam:Disconnect()
    end
    System.__properties.__auto_spam_enabled = true
    System.__properties.__connections.__auto_spam = RunService.Heartbeat:Connect(function()
        if not System.__properties.__auto_spam_enabled then return end
        local ball = System.ball.get(); if not ball then return end
        local zoomies = ball:FindFirstChild('zoomies'); if not zoomies then return end
        local vel = zoomies.VectorVelocity
        local speed = vel.Magnitude; if speed < 30 then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dist = (hrp.Position - ball.Position).Magnitude
        local target = ball:GetAttribute('target')
        local dot = (hrp.Position - ball.Position).Unit:Dot(vel.Unit)
        local maxDist
        if Settings.AutoSpamModeType == "Distance" then
            maxDist = math.clamp(Settings.DistanceMultiplier*100, 5, 28)
        else
            local speedFactor = math.clamp(speed/150, 0.5, 2.5)
            local baseDist = Settings.DistanceMultiplier*100
            maxDist = speed > 400 and math.clamp(baseDist*speedFactor, 8, 35) or baseDist
        end
        if target == LocalPlayer.Name and dist <= maxDist and dot > 0.3 then
            if (tick()-AutoSpamState.lastFireTime) >= 0.05 then
                AutoSpamState.lastFireTime = tick()
                if Settings.AutoSpamMode == "Keypress" then System.parry.keypress()
                else System.parry.execute(true) end
            end
        end
    end)
end
function System.auto_spam.stop()
    System.__properties.__auto_spam_enabled = false
    if System.__properties.__connections.__auto_spam then
        System.__properties.__connections.__auto_spam:Disconnect()
        System.__properties.__connections.__auto_spam = nil
    end
end

-- ===== SKIN CHANGER =====
getgenv().SkinChangerEnabled = false
getgenv().SwordModel = ""
getgenv().SwordAnimation = ""
getgenv().SwordFX = ""
local swordInstances = nil
local skinChangerController = nil

local function getSwordModule()
    if swordInstances then return swordInstances end
    pcall(function()
        local shared = ReplicatedStorage:FindFirstChild("Shared"); if not shared then return end
        local instances = shared:FindFirstChild("ReplicatedInstances"); if not instances then return end
        local swords = instances:FindFirstChild("Swords"); if not swords then return end
        swordInstances = require(swords)
    end)
    return swordInstances
end

local function getSwordsController()
    if skinChangerController then return skinChangerController end
    local controllers = ReplicatedStorage:FindFirstChild("Controllers")
    if controllers then
        for _,child in ipairs(controllers:GetChildren()) do
            if child.Name:match("SwordsController") then
                local ok,module = pcall(require, child)
                if ok and type(module)=="table" then skinChangerController=module; return module end
            end
        end
    end
    return skinChangerController
end

local function setSword()
    if not getgenv().SkinChangerEnabled then return end
    if not LocalPlayer.Character then return end
    if getgenv().SwordModel == "" then return end
    local mod = getSwordModule(); if not mod then return end
    pcall(function()
        local f = rawget(mod, "EquipSwordTo")
        if type(f)=="function" then
            local ups = getupvalues(f)
            for i=1,#ups do
                if type(ups[i])=="boolean" then setupvalue(f,i,false); break end
            end
        end
    end)
    pcall(function() mod:EquipSwordTo(LocalPlayer.Character, getgenv().SwordModel) end)
    task.spawn(function()
        local controller = getSwordsController()
        if controller then
            pcall(function()
                if controller.SetSword then
                    controller:SetSword(getgenv().SwordAnimation ~= "" and getgenv().SwordAnimation or getgenv().SwordModel)
                end
            end)
        end
    end)
    pcall(function()
        local remote = ReplicatedStorage.Remotes:FindFirstChild("FireSwordInfo")
        if remote then
            remote:FireServer(getgenv().SwordFX ~= "" and getgenv().SwordFX or getgenv().SwordModel)
        end
    end)
end

local function startSkinMonitor()
    if System.__properties.__connections.__skin_monitor then return end
    System.__properties.__connections.__skin_monitor = RunService.Heartbeat:Connect(function()
        if not getgenv().SkinChangerEnabled then return end
        local char = LocalPlayer.Character; if not char then return end
        local currentSword = LocalPlayer:GetAttribute("CurrentlyEquippedSword")
        local targetSword = getgenv().SwordModel
        if currentSword ~= targetSword and targetSword ~= "" then setSword() end
    end)
end

getgenv().EnableSkinChanger = function() getgenv().SkinChangerEnabled=true; setSword(); startSkinMonitor() end
getgenv().DisableSkinChanger = function()
    getgenv().SkinChangerEnabled = false
    if System.__properties.__connections.__skin_monitor then
        System.__properties.__connections.__skin_monitor:Disconnect()
        System.__properties.__connections.__skin_monitor = nil
    end
end
getgenv().SetSword = function(model, animation, fx)
    getgenv().SwordModel = model or ""
    getgenv().SwordAnimation = animation or model or ""
    getgenv().SwordFX = fx or model or ""
    if getgenv().SkinChangerEnabled then setSword() end
end

-- ===== FAKE BODY =====
local KORBLOX_MESH = "rbxassetid://101851696"
local KORBLOX_TEX = "rbxassetid://101851254"
local HEADLESS_MESH = "rbxassetid://134082579"

local function applyFakeBody(char)
    if not System.__properties.__fake_body_enabled then return end
    if not char then return end
    task.spawn(function()
        local rleg = char:FindFirstChild("Right Leg") or char:WaitForChild("RightLowerLeg",5)
        if rleg then
            local fake = char:FindFirstChild("FakeKorbloxLeg"); if fake then fake:Destroy() end
            local p = Instance.new("Part")
            p.Name="FakeKorbloxLeg"; p.Size=rleg.Size; p.CFrame=rleg.CFrame
            p.Anchored=false; p.CanCollide=false; p.BrickColor=BrickColor.new("Really black")
            local m = Instance.new("SpecialMesh"); m.MeshType=Enum.MeshType.FileMesh
            m.MeshId=KORBLOX_MESH; m.TextureId=KORBLOX_TEX; m.Parent=p
            p.Parent=char
            local w = Instance.new("WeldConstraint"); w.Part0=rleg; w.Part1=p; w.Parent=rleg
            rleg.Transparency=1
        end
        local head = char:FindFirstChild("Head")
        if head then
            for _,v in ipairs(head:GetChildren()) do if v:IsA("Decal") then v:Destroy() end end
            local m = Instance.new("SpecialMesh"); m.MeshType=Enum.MeshType.FileMesh
            m.MeshId=HEADLESS_MESH; m.Scale=Vector3.new(1.25,1.25,1.25); m.Parent=head
            head.Transparency=0.1; head.BrickColor=BrickColor.new("Really black")
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(2)
    swordInstances=nil; skinChangerController=nil
    if getgenv().SkinChangerEnabled then task.wait(0.5); setSword() end
    if System.__properties.__fake_body_enabled then task.wait(0.5); applyFakeBody(char) end
end)

-- ===== BALL STYLING =====
local BallStyling = { Enabled=false, Connections={} }

function BallStyling:StyleBall(ball)
    if not ball:GetAttribute("realBall") then return end
    for _,child in pairs(ball:GetChildren()) do
        if child:IsA("SpecialMesh") or child:IsA("BlockMesh") or child:IsA("Decal") or child:IsA("Texture") then child:Destroy() end
    end
    local bm = Instance.new("BlockMesh"); bm.Parent=ball
    ball.Material = Enum.Material.Neon
    for _,n in ipairs({"RainbowTrail","RainbowAtt0","RainbowAtt1"}) do
        local e=ball:FindFirstChild(n); if e then e:Destroy() end
    end
    local att0=Instance.new("Attachment"); att0.Name="RainbowAtt0"; att0.Position=Vector3.new(0,0,-0.6); att0.Parent=ball
    local att1=Instance.new("Attachment"); att1.Name="RainbowAtt1"; att1.Position=Vector3.new(0,0,0.6); att1.Parent=ball
    local trail=Instance.new("Trail"); trail.Name="RainbowTrail"
    trail.Attachment0=att0; trail.Attachment1=att1; trail.Lifetime=1.0
    trail.MinLength=0.01; trail.FaceCamera=true; trail.LightEmission=0.8; trail.LightInfluence=0.3
    trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.5,0.3),NumberSequenceKeypoint.new(1,1)})
    trail.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1.5),NumberSequenceKeypoint.new(0.6,0.8),NumberSequenceKeypoint.new(1,0)})
    trail.Parent=ball
    local hueOffset=math.random()*10
    local conn
    conn=RunService.RenderStepped:Connect(function()
        if not ball or not ball.Parent then conn:Disconnect(); return end
        local hue=((tick()+hueOffset)%4)/4
        local c=Color3.fromHSV(hue,1,1); ball.Color=c
        trail.Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(hue,1,1)),
            ColorSequenceKeypoint.new(0.25, Color3.fromHSV((hue+0.15)%1,1,1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV((hue+0.30)%1,1,1)),
            ColorSequenceKeypoint.new(0.75, Color3.fromHSV((hue+0.45)%1,1,1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV((hue+0.60)%1,1,1)),
        })
        for _,obj in pairs(ball:GetDescendants()) do
            if obj:IsA("Highlight") then obj.FillColor=c; obj.OutlineColor=c
            elseif obj:IsA("ParticleEmitter") then obj.Color=ColorSequence.new(c) end
        end
    end)
    table.insert(self.Connections, conn)
end

function BallStyling:ScanExisting()
    for _,folder in ipairs({"Balls","TrainingBalls"}) do
        local f=workspace:FindFirstChild(folder)
        if f then for _,ball in pairs(f:GetChildren()) do task.spawn(function() self:StyleBall(ball) end) end end
    end
end

function BallStyling:MonitorSpawn()
    for _,folder in ipairs({"Balls","TrainingBalls"}) do
        local f=workspace:FindFirstChild(folder)
        if f then
            f.ChildAdded:Connect(function(c) task.spawn(function() self:StyleBall(c) end) end)
        end
    end
end

function BallStyling:Toggle(state)
    self.Enabled=state
    for _,c in pairs(self.Connections) do c:Disconnect() end
    self.Connections={}
    if state then self:ScanExisting(); self:MonitorSpawn()
    else
        local balls=workspace:FindFirstChild("Balls")
        if balls then
            for _,ball in pairs(balls:GetChildren()) do
                pcall(function()
                    ball.Material=Enum.Material.Plastic
                    for _,n in ipairs({"RainbowTrail","RainbowAtt0","RainbowAtt1"}) do
                        local e=ball:FindFirstChild(n); if e then e:Destroy() end
                    end
                end)
            end
        end
    end
end

-- ===== KILL SOUND =====
local KillSoundSystem = {
    Enabled=false,
    Sounds={
        {id="92076037937225", name="Fahhhh"},
        {id="96664488756631", name="Very angry"},
        {id="116957716755028", name="Leave me alone"},
        {id="8643750815", name="Get over here"},
        {id="93779555057888", name="HEHEHE HA"},
        {id="84233173598772", name="Head shot"},
        {id="8097518145", name="Lesgoo"},
    },
    SelectedSound="Fahhhh",
    Connections={},
}

function KillSoundSystem:Play(position)
    if not self.Enabled then return end
    local data; for _,s in ipairs(self.Sounds) do if s.name==self.SelectedSound then data=s; break end end
    if not data then return end
    local part=Instance.new("Part"); part.Anchored=true; part.CanCollide=false; part.Transparency=1
    part.Size=Vector3.new(0.1,0.1,0.1); part.Position=position; part.Parent=workspace
    local sound=Instance.new("Sound"); sound.SoundId="rbxassetid://"..data.id
    sound.Volume=0.7; sound.RollOffMode=Enum.RollOffMode.Linear; sound.MaxDistance=500
    sound.Parent=part; sound:Play()
    Debris:AddItem(part,4.5)
end

function KillSoundSystem:Toggle(state)
    self.Enabled=state
    for _,c in pairs(self.Connections) do c:Disconnect() end
    self.Connections={}
    if not state then return end
    local function onChar(p, char)
        local hum=char:WaitForChild("Humanoid",5)
        if hum then hum.Died:Connect(function()
            local pos=char.PrimaryPart and char.PrimaryPart.Position or workspace.CurrentCamera.CFrame.Position
            self:Play(pos)
        end) end
    end
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if p.Character then task.spawn(onChar, p, p.Character) end
            table.insert(self.Connections, p.CharacterAdded:Connect(function(c) onChar(p,c) end))
        end
    end
    table.insert(self.Connections, Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then
            table.insert(self.Connections, p.CharacterAdded:Connect(function(c) onChar(p,c) end))
        end
    end))
end

-- ===== BALL STATS =====
local BallStats = { Enabled=false, Gui=nil, SpeedLabel=nil, UpdateConn=nil }

function BallStats:Toggle(state)
    self.Enabled=state
    if self.UpdateConn then self.UpdateConn:Disconnect(); self.UpdateConn=nil end
    if self.Gui then self.Gui:Destroy(); self.Gui=nil; self.SpeedLabel=nil end
    if not state then return end
    local sg=Instance.new("ScreenGui"); sg.Name="BLBallStats"; sg.ResetOnSpawn=false; sg.Parent=CoreGui
    pcall(function() protect_gui(sg) end)
    self.Gui=sg
    local frame=Instance.new("Frame"); frame.Size=UDim2.new(0,180,0,60)
    frame.Position=UDim2.new(1,-195,0,55); frame.AnchorPoint=Vector2.new(0,0)
    frame.BackgroundColor3=Color3.fromRGB(8,10,20); frame.BorderSizePixel=0
    frame.Active=true; frame.Draggable=true; frame.Parent=sg
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
    local stroke=Instance.new("UIStroke",frame); stroke.Color=Color3.fromRGB(0,80,160); stroke.Thickness=1.5
    local title=Instance.new("TextLabel",frame); title.Size=UDim2.new(1,0,0,20)
    title.Text="⚡ BALL STATS"; title.TextColor3=Color3.fromRGB(100,180,255)
    title.BackgroundTransparency=1; title.TextSize=12; title.Font=Enum.Font.GothamBold
    local speedLbl=Instance.new("TextLabel",frame); speedLbl.Size=UDim2.new(1,-10,0,18)
    speedLbl.Position=UDim2.new(0,5,0,22); speedLbl.Text="Speed: 0 studs/s"
    speedLbl.TextColor3=Color3.fromRGB(255,200,0); speedLbl.BackgroundTransparency=1
    speedLbl.TextSize=12; speedLbl.Font=Enum.Font.GothamBold
    speedLbl.TextXAlignment=Enum.TextXAlignment.Left
    self.SpeedLabel=speedLbl
    local velLbl=Instance.new("TextLabel",frame); velLbl.Size=UDim2.new(1,-10,0,18)
    velLbl.Position=UDim2.new(0,5,0,40); velLbl.Text="Velocity: 0,0,0"
    velLbl.TextColor3=Color3.fromRGB(0,200,255); velLbl.BackgroundTransparency=1
    velLbl.TextSize=11; velLbl.Font=Enum.Font.Gotham
    velLbl.TextXAlignment=Enum.TextXAlignment.Left
    self.VelLabel=velLbl
    self.UpdateConn=RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        local ball=System.ball.get()
        if ball and ball:FindFirstChild("zoomies") then
            local vel=ball.zoomies.VectorVelocity
            local spd=vel.Magnitude
            speedLbl.Text=string.format("Speed: %.1f studs/s", spd)
            velLbl.Text=string.format("Dir: %.1f, %.1f, %.1f", vel.X, vel.Y, vel.Z)
        else
            speedLbl.Text="Speed: 0 studs/s"; velLbl.Text="Dir: —"
        end
    end)
end

-- ===== ABILITY DETECTION =====
task.spawn(function()
    pcall(function() ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(_,v) AbilityFlags.DeathSlashBall=v end) end)
    pcall(function() ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(_,v) AbilityFlags.InfinityBall=v end) end)
    pcall(function() ReplicatedStorage.Remotes.TimeHoleHoldBall.OnClientEvent:Connect(function(_,v) AbilityFlags.TimeHole=v end) end)
    pcall(function()
        ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryActivate"].OnClientEvent:Connect(function(player)
            if player==LocalPlayer or (player and player.Name==LocalPlayer.Name) then
                AbilityFlags.SlashesofFury=true
                task.delay(3, function() AbilityFlags.SlashesofFury=false end)
            end
        end)
    end)
    pcall(function()
        ReplicatedStorage.Remotes.Phantom.OnClientEvent:Connect(function(a,b)
            if b and b.Name==LocalPlayer.Name then
                AbilityFlags.Phantom=true
                task.delay(2, function() AbilityFlags.Phantom=false end)
            end
        end)
    end)
    pcall(function()
        RunService.PreSimulation:Connect(function()
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            AbilityFlags.Singularity=(hrp and hrp:FindFirstChild("SingularityCape")) and true or false
        end)
    end)
    pcall(function()
        if Runtime then
            Runtime.ChildAdded:Connect(function(child)
                if child.Name=="Tornado" then
                    AbilityFlags.Tornado=true
                    task.delay(child:GetAttribute("TornadoTime") or 1.5, function() AbilityFlags.Tornado=false end)
                end
            end)
        end
    end)
    pcall(function() ReplicatedStorage.Remotes.PlrPulled.OnClientEvent:Connect(function() AbilityFlags.Pull=true; task.delay(1.5,function() AbilityFlags.Pull=false end) end) end)
    pcall(function() ReplicatedStorage.Remotes.PlrPulsed.OnClientEvent:Connect(function() AbilityFlags.Pulse=true; task.delay(1.5,function() AbilityFlags.Pulse=false end) end) end)
    pcall(function()
        RunService.PreSimulation:Connect(function()
            local red=LocalPlayer.PlayerGui:FindFirstChild("Hotbar") and
                      LocalPlayer.PlayerGui.Hotbar:FindFirstChild("Ability") and
                      LocalPlayer.PlayerGui.Hotbar.Ability:FindFirstChild("Red")
            if red then AbilityFlags.Forcefield=red.Visible end
        end)
    end)
    pcall(function()
        local abilityCD=LocalPlayer.PlayerGui.Hotbar.Ability.Duration.Fill.UIGradient
        abilityCD:GetPropertyChangedSignal("Offset"):Connect(function()
            if abilityCD.Offset.Y >= 0.985 then AbilityFlags.AbilityActive=false
            else
                local char=LocalPlayer.Character
                if char and char:FindFirstChild("Abilities") then
                    local any=false
                    for _,ab in ipairs(char.Abilities:GetChildren()) do if ab:IsA("BoolValue") and ab.Enabled then any=true; break end end
                    AbilityFlags.AbilityActive=any
                end
            end
        end)
    end)
    pcall(function() ReplicatedStorage.Remotes.Dribble.OnClientEvent:Connect(function(v) AbilityFlags.Dribble=v end) end)
    pcall(function()
        ReplicatedStorage.Remotes.PlrHellHooked.OnClientEvent:Connect(function(a,b)
            if b and b.Name==LocalPlayer.Name then AbilityFlags.HellHook=true; task.delay(2,function() AbilityFlags.HellHook=false end) end
        end)
    end)
end)

-- ===== KEYBIND ENGINE =====
local Keybinds = {}
local WaitingForKey = nil

local function fireKeybind(keyName)
    local bind = Keybinds[keyName]
    if not bind then return end
    bind.enabled = not bind.enabled
    if bind.callback then bind.callback(bind.enabled) end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local keyName = input.KeyCode.Name
    if WaitingForKey then
        local slot = WaitingForKey
        for k,v in pairs(Keybinds) do
            if v.slot == slot.name then Keybinds[k]=nil; break end
        end
        Keybinds[keyName] = { name=slot.name, slot=slot.name, callback=slot.callback, enabled=false }
        Settings["KB_"..slot.name:gsub(" ","_")] = keyName
        SaveSettings()
        if slot.uiCallback then slot.uiCallback(keyName) end
        WaitingForKey = nil
        return
    end
    fireKeybind(keyName)
end)

local function RegisterKeybind(name, defaultKey, callback)
    local savedKey = Settings["KB_"..name:gsub(" ","_")] or defaultKey
    Keybinds[savedKey] = { name=name, slot=name, callback=callback, enabled=false }
    return savedKey
end

-- ===== BOOT SYSTEMS =====
getgenv().AutoParryMode = Settings.ParryMode
getgenv().AutoSpamMode = Settings.AutoSpamMode
if Settings.AutoParry then System.autoparry.start() end
if Settings.ManualSpam then System.manual_spam.start() end
if Settings.AutoSpam then System.auto_spam.start() end
if Settings.BallStylingEnabled then BallStyling:Toggle(true) end
if Settings.KillSoundEnabled then
    KillSoundSystem.SelectedSound = Settings.SelectedKillSound or "Fahhhh"
    KillSoundSystem:Toggle(true)
end

-- ===== ALLUSIVE UI =====
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/naturaldesire23/gtddd/refs/heads/main/mm2sa.lua"))()

local UI = Library.new({
    title = "BYTE LITE",
    PrimaryColor = Color3.fromRGB(150, 150, 150),
})
UI:load()

local CombatTab = UI:create_tab('Combat', 'rbxassetid://76499042599127')
local SpamTab = UI:create_tab('Spam', 'rbxassetid://132243429647479')
local DetectionTab = UI:create_tab('Detections', 'rbxassetid://10723346959')
local SkinTab = UI:create_tab('Skin', 'rbxassetid://10734966248')
local VisualsTab = UI:create_tab('Visuals', 'rbxassetid://76499042599127')
local FunctionsTab = UI:create_tab('Functions', 'rbxassetid://10723346959')
local KeybindsTab = UI:create_tab('Keybinds', 'rbxassetid://81598136527047')

-- ===== COMBAT TAB =====
local AutoParryMod = CombatTab:create_module({
    title = 'Auto Parry',
    flag = 'Auto_Parry',
    description = 'Distance-based auto parry',
    section = 'left',
    callback = function(value)
        Settings.AutoParry = value
        System.__properties.__autoparry_enabled = value
        if value then System.autoparry.start() else System.autoparry.stop() end
        SaveSettings()
    end
})

AutoParryMod:create_slider({
    title = 'Accuracy',
    flag = 'Parry_Accuracy',
    minimum_value = 1,
    maximum_value = 100,
    value = Settings.ParryAccuracy,
    round_number = true,
    callback = function(value)
        System.__properties.__accuracy = value
        Settings.ParryAccuracy = value; update_divisor(); SaveSettings()
    end
})

AutoParryMod:create_dropdown({
    title = 'Parry Mode',
    flag = 'Parry_Mode',
    options = {'Remote','Keypress'},
    multi_dropdown = false,
    maximum_options = 2,
    callback = function(value)
        getgenv().AutoParryMode = value
        Settings.ParryMode = value; SaveSettings()
    end
})

AutoParryMod:create_dropdown({
    title = 'Curve Type',
    flag = 'Curve_Type',
    options = {'Camera','Mouse','Players','Normal','Up','Down','Left','Right','Behind','Random','FrontLeft','FrontRight','BackLeft','BackRight','Spin','TargetHead','High','RandomTarget'},
    multi_dropdown = false,
    maximum_options = 18,
    callback = function(value)
        System.__properties.__curve_mode = value
        Settings.CurveType = value; SaveSettings()
    end
})

AutoParryMod:create_checkbox({
    title = 'Anti-Curve',
    flag = 'Anti_Curve',
    callback = function(value) Settings.AntiCurve=value; SaveSettings() end
})

AutoParryMod:create_checkbox({
    title = 'Random Accuracy',
    flag = 'Random_Accuracy',
    callback = function(value)
        System.__properties.__random_accuracy=value; Settings.RandomAccuracy=value; SaveSettings()
    end
})

AutoParryMod:create_checkbox({
    title = 'Grab Parry',
    flag = 'Grab_Parry',
    callback = function(value)
        System.__properties.__grab_parry_enabled=value; Settings.GrabParry=value; SaveSettings()
    end
})

local AutoSpamMod = CombatTab:create_module({
    title = 'Auto Spam',
    flag = 'Auto_Spam',
    description = 'Spams parry at close range',
    section = 'right',
    callback = function(value)
        Settings.AutoSpam = value
        if value then System.auto_spam.start() else System.auto_spam.stop() end
        SaveSettings()
    end
})

AutoSpamMod:create_dropdown({
    title = 'Spam Mode',
    flag = 'Spam_Mode',
    options = {'Remote','Keypress'},
    multi_dropdown = false,
    maximum_options = 2,
    callback = function(value)
        getgenv().AutoSpamMode=value; Settings.AutoSpamMode=value; SaveSettings()
    end
})

AutoSpamMod:create_dropdown({
    title = 'Detection Mode',
    flag = 'Spam_Detection_Mode',
    options = {'Distance','Hybrid'},
    multi_dropdown = false,
    maximum_options = 2,
    callback = function(value) Settings.AutoSpamModeType=value; SaveSettings() end
})

AutoSpamMod:create_slider({
    title = 'Distance Gate',
    flag = 'Distance_Gate',
    minimum_value = 5,
    maximum_value = 35,
    value = math.floor(Settings.DistanceMultiplier*100),
    round_number = true,
    callback = function(value) Settings.DistanceMultiplier=value/100; SaveSettings() end
})

-- ===== SPAM TAB =====
local ManualSpamMod = SpamTab:create_module({
    title = 'Manual Spam',
    flag = 'Manual_Spam',
    description = 'Toggle spams parry at set CPS',
    section = 'left',
    callback = function(value)
        Settings.ManualSpam = value
        if value then System.manual_spam.start() else System.manual_spam.stop() end
        SaveSettings()
    end
})

ManualSpamMod:create_slider({
    title = 'CPS',
    flag = 'Manual_CPS',
    minimum_value = 1,
    maximum_value = 2000,
    value = Settings.ManualSpamCPS,
    round_number = true,
    callback = function(value) Settings.ManualSpamCPS=value; SaveSettings() end
})

-- ===== DETECTIONS TAB =====
local DetMod = DetectionTab:create_module({
    title = 'Ability Detections',
    flag = 'Det_Module',
    description = 'Skip auto parry on these abilities',
    section = 'left',
    callback = function() end
})

local detList = {
    {'Infinity Ball', 'InfinityDetection'},
    {'Death Slash', 'DeathSlashDetection'},
    {'Time Hole', 'TimeHoleDetection'},
    {'Slashes of Fury', 'SlashesofFuryDetection'},
    {'Forcefield', 'ForcefieldDetection'},
    {'Phantom', 'PhantomDetection'},
    {'Singularity', 'SingularityDetection'},
    {'Dribble', 'DribbleDetection'},
    {'Pull', 'PullDetection'},
    {'Pulse', 'PulseDetection'},
    {'Ability Active', 'AbilityActiveDetection'},
    {'Tornado', 'TornadoDetection'},
    {'Hell Hook', 'HellHookDetection'},
}
for _,d in ipairs(detList) do
    DetMod:create_checkbox({
        title = d[1],
        flag = d[2],
        callback = function(value) Settings[d[2]]=value; SaveSettings() end
    })
end

-- ===== SKIN TAB =====
local SkinMod = SkinTab:create_module({
    title = 'Skin Changer',
    flag = 'Skin_Module',
    description = 'Textbox-based sword skin',
    section = 'left',
    callback = function(value)
        if value then getgenv().EnableSkinChanger()
        else getgenv().DisableSkinChanger() end
    end
})

SkinMod:create_checkbox({
    title = 'Enable Skin Changer',
    flag = 'Skin_Enable',
    callback = function(value)
        if value then getgenv().EnableSkinChanger()
        else getgenv().DisableSkinChanger() end
    end
})

SkinMod:create_textbox({
    title = 'Sword Model Name',
    placeholder = 'e.g. Witch\'s Curse',
    flag = 'Sword_Model',
    callback = function(text)
        if text ~= "" then
            getgenv().SwordModel = text
            if getgenv().SwordAnimation == "" then getgenv().SwordAnimation = text end
            if getgenv().SwordFX == "" then getgenv().SwordFX = text end
            if getgenv().SkinChangerEnabled then setSword() end
        end
    end
})

SkinMod:create_textbox({
    title = 'Animation Override',
    placeholder = 'Leave blank = same as model',
    flag = 'Sword_Animation',
    callback = function(text)
        getgenv().SwordAnimation = text ~= "" and text or getgenv().SwordModel
        if getgenv().SkinChangerEnabled then setSword() end
    end
})

SkinMod:create_textbox({
    title = 'FX Override',
    placeholder = 'Leave blank = same as model',
    flag = 'Sword_FX',
    callback = function(text)
        getgenv().SwordFX = text ~= "" and text or getgenv().SwordModel
        if getgenv().SkinChangerEnabled then setSword() end
    end
})

local FakeBodyMod = SkinTab:create_module({
    title = 'Fake Body',
    flag = 'Fake_Body_Module',
    description = 'Headless + Korblox cosmetics',
    section = 'right',
    callback = function(value)
        System.__properties.__fake_body_enabled = value
        if value and LocalPlayer.Character then applyFakeBody(LocalPlayer.Character) end
    end
})

FakeBodyMod:create_checkbox({
    title = 'Headless & Korblox',
    flag = 'Fake_Body_Enable',
    callback = function(value)
        System.__properties.__fake_body_enabled = value
        if value and LocalPlayer.Character then applyFakeBody(LocalPlayer.Character) end
    end
})

-- ===== VISUALS TAB =====
local BallStyleMod = VisualsTab:create_module({
    title = 'Ball Styling',
    flag = 'Ball_Style_Module',
    description = 'Chroma rainbow ball',
    section = 'left',
    callback = function(value) Settings.BallStylingEnabled=value; BallStyling:Toggle(value); SaveSettings() end
})

BallStyleMod:create_checkbox({
    title = 'Chroma Ball',
    flag = 'Chroma_Ball',
    callback = function(value) Settings.BallStylingEnabled=value; BallStyling:Toggle(value); SaveSettings() end
})

local KillSoundMod = VisualsTab:create_module({
    title = 'Kill Sound',
    flag = 'Kill_Sound_Module',
    description = 'Plays a sound on kill',
    section = 'right',
    callback = function(value)
        Settings.KillSoundEnabled = value; KillSoundSystem:Toggle(value); SaveSettings()
    end
})

KillSoundMod:create_checkbox({
    title = 'Enable Kill Sound',
    flag = 'Kill_Sound_Enable',
    callback = function(value) Settings.KillSoundEnabled=value; KillSoundSystem:Toggle(value); SaveSettings() end
})

local soundNames={}; for _,s in ipairs(KillSoundSystem.Sounds) do table.insert(soundNames, s.name) end
KillSoundMod:create_dropdown({
    title = 'Sound',
    flag = 'Kill_Sound_Select',
    options = soundNames,
    multi_dropdown = false,
    maximum_options = #soundNames,
    callback = function(value)
        Settings.SelectedKillSound=value; KillSoundSystem.SelectedSound=value; SaveSettings()
    end
})

local BallStatsMod = VisualsTab:create_module({
    title = 'Ball Stats',
    flag = 'Ball_Stats_Module',
    description = 'Floating speed/velocity window',
    section = 'left',
    callback = function(value) BallStats:Toggle(value) end
})

BallStatsMod:create_checkbox({
    title = 'Show Ball Stats',
    flag = 'Ball_Stats_Enable',
    callback = function(value) BallStats:Toggle(value) end
})

-- ===== FUNCTIONS TAB =====
local FuncMod = FunctionsTab:create_module({
    title = 'Active Functions',
    flag = 'Func_Module',
    description = 'Live status of all features',
    section = 'left',
    callback = function() end
})

local funcLabels = {
    {label='Auto Parry', getState=function() return Settings.AutoParry end},
    {label='Auto Spam', getState=function() return Settings.AutoSpam end},
    {label='Manual Spam', getState=function() return Settings.ManualSpam end},
    {label='Anti-Curve', getState=function() return Settings.AntiCurve end},
    {label='Grab Parry', getState=function() return Settings.GrabParry end},
    {label='Skin Changer', getState=function() return getgenv().SkinChangerEnabled end},
    {label='Ball Styling', getState=function() return Settings.BallStylingEnabled end},
    {label='Kill Sound', getState=function() return Settings.KillSoundEnabled end},
    {label='Ball Stats', getState=function() return BallStats.Enabled end},
    {label='Fake Body', getState=function() return System.__properties.__fake_body_enabled end},
}

local funcCheckboxCallbacks = {
    ['Auto Parry'] = function(v) Settings.AutoParry=v; System.__properties.__autoparry_enabled=v; if v then System.autoparry.start() else System.autoparry.stop() end; SaveSettings() end,
    ['Auto Spam'] = function(v) Settings.AutoSpam=v; if v then System.auto_spam.start() else System.auto_spam.stop() end; SaveSettings() end,
    ['Manual Spam'] = function(v) Settings.ManualSpam=v; if v then System.manual_spam.start() else System.manual_spam.stop() end; SaveSettings() end,
    ['Anti-Curve'] = function(v) Settings.AntiCurve=v; SaveSettings() end,
    ['Grab Parry'] = function(v) System.__properties.__grab_parry_enabled=v; Settings.GrabParry=v; SaveSettings() end,
    ['Skin Changer'] = function(v) if v then getgenv().EnableSkinChanger() else getgenv().DisableSkinChanger() end end,
    ['Ball Styling'] = function(v) Settings.BallStylingEnabled=v; BallStyling:Toggle(v); SaveSettings() end,
    ['Kill Sound'] = function(v) Settings.KillSoundEnabled=v; KillSoundSystem:Toggle(v); SaveSettings() end,
    ['Ball Stats'] = function(v) BallStats:Toggle(v) end,
    ['Fake Body'] = function(v) System.__properties.__fake_body_enabled=v; if v and LocalPlayer.Character then applyFakeBody(LocalPlayer.Character) end end,
}

for _,f in ipairs(funcLabels) do
    FuncMod:create_checkbox({
        title = f.label,
        flag = 'Func_'..f.label:gsub(' ','_'),
        callback = funcCheckboxCallbacks[f.label] or function() end
    })
end

-- ===== KEYBINDS TAB — fixed with proper click-to-bind =====
local KBMod = KeybindsTab:create_module({
    title = 'Keybinds',
    flag = 'KB_Module',
    description = 'Click a checkbox title, then press any key to bind',
    section = 'left',
    callback = function() end
})

-- Store checkbox instances to update titles
local keybindCheckboxes = {}

local function makeKeybindRow(name, defaultKey, onToggle)
    local currentKey = Settings["KB_"..name:gsub(" ","_")] or defaultKey
    RegisterKeybind(name, currentKey, onToggle)
    
    -- Create the checkbox
    local chk = KBMod:create_checkbox({
        title = name .. ' [' .. currentKey .. ']',
        flag = 'KB_Btn_' .. name:gsub(' ','_'),
        callback = function(val)
            -- Ignore the toggle; instead start rebind
            if WaitingForKey then
                WaitingForKey = nil
                return
            end
            WaitingForKey = {
                name = name,
                callback = onToggle,
                uiCallback = function(newKey)
                    -- Update the checkbox title by finding its label
                    pcall(function()
                        local allButtons = KBMod._instances or {}
                        for _,inst in ipairs(allButtons) do
                            if inst:IsA("Frame") and inst:FindFirstChild("TitleLabel") then
                                local lbl = inst:FindFirstChild("TitleLabel")
                                if lbl and lbl:IsA("TextLabel") and lbl.Text:match(name) then
                                    lbl.Text = name .. ' [' .. newKey .. ']'
                                end
                            end
                        end
                    end)
                    Library.SendNotification({
                        title = "Keybind Set",
                        text = name .. " → " .. newKey,
                        duration = 2
                    })
                end
            }
        end
    })
    table.insert(keybindCheckboxes, chk)
    -- Store reference for title updates
    if not KBMod._instances then KBMod._instances = {} end
    table.insert(KBMod._instances, chk)
end

makeKeybindRow("Manual Spam", Settings.KB_ManualSpam or "E", function(enabled)
    Settings.ManualSpam = enabled
    if enabled then System.manual_spam.start() else System.manual_spam.stop() end
    SaveSettings()
end)

makeKeybindRow("Auto Parry", Settings.KB_AutoParry or "V", function(enabled)
    Settings.AutoParry = enabled
    System.__properties.__autoparry_enabled = enabled
    if enabled then System.autoparry.start() else System.autoparry.stop() end
    SaveSettings()
end)

makeKeybindRow("Auto Spam", Settings.KB_AutoSpam or "G", function(enabled)
    Settings.AutoSpam = enabled
    if enabled then System.auto_spam.start() else System.auto_spam.stop() end
    SaveSettings()
end)

makeKeybindRow("Chroma Ball", Settings.KB_ChromaBall or "B", function(enabled)
    Settings.BallStylingEnabled = enabled
    BallStyling:Toggle(enabled); SaveSettings()
end)

-- ===== STARTUP NOTIFICATION =====
Library.SendNotification({
    title = "BYTE LITE",
    text = "Loaded. Insert = toggle UI.",
    duration = 3
})

print("[Byte Lite] Loaded")
print("[Keybinds] Click a keybind checkbox title, then press a key.")
