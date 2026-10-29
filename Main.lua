--[[
EPIC PLANETS | MOBILE COMPLETE BUILD
Main.lua | Roblox / touch-friendly executor UI
Build: 2026-10-29

IMPORTANT:
- This is a rebuilt integrated edition, not a byte-for-byte copy of the old repository file.
- Many actions are client-side only. Roblox server permissions determine what replicates.
- Friend joining and teleport queue functions depend on executor support and Roblox APIs.
- Use responsibly and only where permitted by the game.
]]

local ENV = (type(getgenv) == "function" and getgenv()) or _G
if ENV.__EPIC_PLANETS_CLEANUP then
    pcall(ENV.__EPIC_PLANETS_CLEANUP)
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Connections, Drawings, Highlights = {}, {}, {}
local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}
local State = {
    Speed = 16, Jump = 50, InfiniteJump = false, Noclip = false,
    Fullbright = false, ESP = false, RainbowWalk = false,
    Fly = false, WalkOnAir = false, ZeroGravity = false,
    Spectating = false, Freecam = false, AutoRejoin = false,
    BubbleColor = Color3.fromRGB(80, 170, 255), FOV = 70,
}
local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(Connections, c)
    return c
end
local function notify(title, message, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "EPIC PLANETS",
            Text = message or "",
            Duration = duration or 3
        })
    end)
end
local function getChar()
    return LocalPlayer.Character
end
local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function safeDestroy(obj)
    pcall(function() if obj then obj:Destroy() end end)
end
local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        pcall(function() o[k] = v end)
    end
    o.Parent = parent
    return o
end
local function tween(obj, info, props)
    local ok, tw = pcall(function()
        return TweenService:Create(obj, info, props)
    end)
    if ok and tw then tw:Play() end
    return tw
end

-- Remove a previous copy and restore client settings.
ENV.__EPIC_PLANETS_CLEANUP = function()
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    for _, d in ipairs(Drawings) do safeDestroy(d) end
    for _, h in ipairs(Highlights) do safeDestroy(h) end
    safeDestroy(ENV.__EPIC_PLANETS_GUI)
    pcall(function()
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end)
end

-- Theme
local C = {
    bg = Color3.fromRGB(12, 13, 21),
    panel = Color3.fromRGB(20, 22, 34),
    panel2 = Color3.fromRGB(28, 31, 47),
    text = Color3.fromRGB(238, 241, 255),
    muted = Color3.fromRGB(147, 154, 180),
    blue = Color3.fromRGB(88, 110, 255),
    purple = Color3.fromRGB(171, 92, 255),
    green = Color3.fromRGB(66, 218, 158),
    red = Color3.fromRGB(255, 91, 119),
}
local gui = make("ScreenGui", {
    Name = "EPIC_PLANETS",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, (gethui and gethui()) or game:GetService("CoreGui"))
ENV.__EPIC_PLANETS_GUI = gui

local root = make("Frame", {
    Name = "Window", Size = UDim2.fromOffset(640, 430),
    Position = UDim2.new(0.5, -320, 0.5, -215),
    BackgroundColor3 = C.bg, BorderSizePixel = 0,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 13)}, root)
make("UIStroke", {Color = C.blue, Thickness = 1.4, Transparency = 0.15}, root)
local scale = make("UIScale", {Scale = 1}, root)
local function fitScale()
    local cam = Workspace.CurrentCamera
    if cam then
        local v = cam.ViewportSize
        scale.Scale = math.clamp(math.min(v.X / 700, v.Y / 490), 0.58, 1)
    end
end
fitScale()
if Workspace.CurrentCamera then connect(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), fitScale) end

local top = make("Frame", {
    Size = UDim2.new(1, 0, 0, 47), BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, root)
make("UICorner", {CornerRadius = UDim.new(0, 13)}, top)
make("Frame", {Position = UDim2.new(0, 0, 1, -13), Size = UDim2.new(1, 0, 0, 13),
    BackgroundColor3 = C.panel, BorderSizePixel = 0}, top)
local title = make("TextLabel", {
    Position = UDim2.fromOffset(15, 0), Size = UDim2.new(1, -115, 1, 0),
    BackgroundTransparency = 1, Text = "✦  EPIC PLANETS  /  MOBILE",
    Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C.text,
}, top)
local minimize = make("TextButton", {
    Position = UDim2.new(1, -78, 0, 8), Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = C.panel2, Text = "–", TextColor3 = C.text,
    Font = Enum.Font.GothamBold, TextSize = 20, BorderSizePixel = 0,
}, top)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, minimize)
local close = make("TextButton", {
    Position = UDim2.new(1, -41, 0, 8), Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = C.red, Text = "×", TextColor3 = C.text,
    Font = Enum.Font.GothamBold, TextSize = 20, BorderSizePixel = 0,
}, top)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, close)

-- Dragging works with mouse and touch.
do
    local dragging, dragInput, dragStart, startPos
    connect(top.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, root.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    connect(top.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    connect(UIS.InputChanged, function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local sidebar = make("ScrollingFrame", {
    Position = UDim2.fromOffset(10, 57), Size = UDim2.new(0, 158, 1, -68),
    BackgroundColor3 = C.panel, BorderSizePixel = 0, ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.blue, CanvasSize = UDim2.new(),
}, root)
make("UICorner", {CornerRadius = UDim.new(0, 10)}, sidebar)
local sideLayout = make("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
make("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 7),
    PaddingRight = UDim.new(0, 7), PaddingBottom = UDim.new(0, 8)}, sidebar)
connect(sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
    sidebar.CanvasSize = UDim2.fromOffset(0, sideLayout.AbsoluteContentSize.Y + 18)
end)

local content = make("Frame", {
    Position = UDim2.fromOffset(178, 57), Size = UDim2.new(1, -188, 1, -68),
    BackgroundColor3 = C.panel, BorderSizePixel = 0,
}, root)
make("UICorner", {CornerRadius = UDim.new(0, 10)}, content)
local pages, tabButtons = {}, {}
local activePage
local function showPage(name)
    for n, p in pairs(pages) do p.Visible = n == name end
    for n, b in pairs(tabButtons) do
        tween(b, TweenInfo.new(0.13), {BackgroundColor3 = n == name and C.blue or C.panel2})
    end
    activePage = name
end
local function addTab(name, icon)
    local b = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 31), BackgroundColor3 = C.panel2,
        Text = (icon or "•") .. "  " .. name, TextColor3 = C.text,
        Font = Enum.Font.GothamMedium, TextSize = 11, BorderSizePixel = 0,
        TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = true,
    }, sidebar)
    make("UICorner", {CornerRadius = UDim.new(0, 7)}, b)
    make("UIPadding", {PaddingLeft = UDim.new(0, 9)}, b)
    local page = make("ScrollingFrame", {
        Name = name, Size = UDim2.new(1, -14, 1, -14), Position = UDim2.fromOffset(7, 7),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.blue, CanvasSize = UDim2.new(),
        Visible = false,
    }, content)
    local layout = make("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    make("UIPadding", {PaddingBottom = UDim.new(0, 10), PaddingRight = UDim.new(0, 4)}, page)
    connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 15)
    end)
    pages[name], tabButtons[name] = page, b
    connect(b.Activated, function() showPage(name) end)
    return page
end

local function section(page, text)
    return make("TextLabel", {
        Size = UDim2.new(1, -2, 0, 24), BackgroundTransparency = 1,
        Text = "  " .. string.upper(text), TextColor3 = C.purple,
        Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    }, page)
end
local function label(page, text, height)
    return make("TextLabel", {
        Size = UDim2.new(1, -2, 0, height or 30), BackgroundColor3 = C.panel2,
        Text = text, TextColor3 = C.muted, Font = Enum.Font.Gotham,
        TextSize = 11, TextWrapped = true, BorderSizePixel = 0,
    }, page)
end
local function button(page, text, callback, color)
    local b = make("TextButton", {
        Size = UDim2.new(1, -2, 0, 34), BackgroundColor3 = color or C.panel2,
        Text = text, TextColor3 = C.text, Font = Enum.Font.GothamMedium,
        TextSize = 12, BorderSizePixel = 0, AutoButtonColor = true,
    }, page)
    make("UICorner", {CornerRadius = UDim.new(0, 8)}, b)
    connect(b.Activated, function()
        local ok, err = pcall(callback)
        if not ok then notify("EPIC PLANETS", tostring(err), 4) end
    end)
    return b
end
local function toggle(page, text, initial, callback)
    local value = initial or false
    local b = button(page, text .. "  [" .. (value and "ON" or "OFF") .. "]", function()
        value = not value
        b.Text = text .. "  [" .. (value and "ON" or "OFF") .. "]"
        b.BackgroundColor3 = value and C.blue or C.panel2
        callback(value)
    end, value and C.blue or C.panel2)
    return b
end
local function textbox(page, hint, callback)
    local t = make("TextBox", {
        Size = UDim2.new(1, -2, 0, 35), BackgroundColor3 = C.panel2,
        PlaceholderText = hint, Text = "", TextColor3 = C.text,
        PlaceholderColor3 = C.muted, Font = Enum.Font.Gotham, TextSize = 12,
        ClearTextOnFocus = false, BorderSizePixel = 0,
    }, page)
    make("UICorner", {CornerRadius = UDim.new(0, 8)}, t)
    connect(t.FocusLost, function(enter)
        if enter then callback(t.Text) end
    end)
    return t
end
local function slider(page, text, min, max, start, callback)
    local holder = make("Frame", {Size = UDim2.new(1, -2, 0, 52), BackgroundColor3 = C.panel2, BorderSizePixel = 0}, page)
    make("UICorner", {CornerRadius = UDim.new(0, 8)}, holder)
    local l = make("TextLabel", {Position = UDim2.fromOffset(9, 3), Size = UDim2.new(1, -18, 0, 20),
        BackgroundTransparency = 1, Text = text .. ": " .. tostring(start), TextColor3 = C.text,
        Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, holder)
    local bar = make("Frame", {Position = UDim2.new(0, 9, 0, 30), Size = UDim2.new(1, -18, 0, 8),
        BackgroundColor3 = C.bg, BorderSizePixel = 0}, holder)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, bar)
    local fill = make("Frame", {Size = UDim2.new((start-min)/(max-min), 0, 1, 0),
        BackgroundColor3 = C.blue, BorderSizePixel = 0}, bar)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
    local knob = make("TextButton", {Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(.5,.5),
        Position = UDim2.new((start-min)/(max-min), 0, .5, 0), BackgroundColor3 = C.text,
        Text = "", BorderSizePixel = 0}, bar)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    local sliding = false
    local function setFromX(x)
        local pct = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max-min)*pct + 0.5)
        fill.Size, knob.Position = UDim2.new(pct,0,1,0), UDim2.new(pct,0,.5,0)
        l.Text = text .. ": " .. tostring(val)
        callback(val)
    end
    connect(knob.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = true end
    end)
    connect(UIS.InputChanged, function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then setFromX(i.Position.X) end
    end)
    connect(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end)
end

-- Player utilities
local function setFullbright(on)
    State.Fullbright = on
    if on then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
    else
        for k,v in pairs(OriginalLighting) do pcall(function() Lighting[k] = v end) end
    end
end
local function clearESP()
    for _, h in ipairs(Highlights) do safeDestroy(h) end
    table.clear(Highlights)
end
local function refreshESP()
    clearESP()
    if not State.ESP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = make("Highlight", {Name = "EP_ESP", FillColor = C.purple,
                OutlineColor = C.blue, FillTransparency = .68, OutlineTransparency = .05,
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop}, p.Character)
            table.insert(Highlights, h)
        end
    end
end
local function setNoclip(on)
    State.Noclip = on
end
connect(RunService.Stepped, function()
    if State.Noclip then
        local ch = getChar()
        if ch then for _, part in ipairs(ch:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end end
    end
    local hum = getHumanoid()
    if hum then
        if State.Speed then hum.WalkSpeed = State.Speed end
        if State.Jump then
            pcall(function() hum.UseJumpPower = true; hum.JumpPower = State.Jump end)
        end
    end
end)
connect(Players.PlayerAdded, function() task.wait(1); refreshESP() end)
connect(Players.PlayerRemoving, function() task.wait(.2); refreshESP() end)
connect(LocalPlayer.CharacterAdded, function()
    task.wait(1)
    if State.ESP then refreshESP() end
end)

local home = addTab("HOME", "✦")
section(home, "Welcome back")
label(home, "EPIC PLANETS • Mobile build\nTouch-friendly UI • Dark / rainbow theme", 48)
button(home, "Refresh character", function()
    if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end
end, C.red)
button(home, "Hide / show UI (RightShift)", function() root.Visible = not root.Visible end)
label(home, "Some features depend on the game server. Local visual effects may not be visible to other players.", 44)

local playerPage = addTab("PLAYER", "◈")
section(playerPage, "Movement")
slider(playerPage, "WalkSpeed", 16, 150, 16, function(v) State.Speed = v end)
slider(playerPage, "JumpPower", 50, 200, 50, function(v) State.Jump = v end)
toggle(playerPage, "Infinite Jump", false, function(v)
    State.InfiniteJump = v
end)
connect(UIS.JumpRequest, function()
    if State.InfiniteJump then
        local h = getHumanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
toggle(playerPage, "Noclip", false, setNoclip)
toggle(playerPage, "Fullbright", false, setFullbright)
toggle(playerPage, "Fly (basic)", false, function(v)
    State.Fly = v
    notify("Fly", v and "Fly enabled. Use the movement controls." or "Fly disabled.")
end)
label(playerPage, "Fly is a basic local toggle; executor and game physics may affect results.", 34)

local friends = addTab("FRIENDS", "♧")
section(friends, "Roblox friends")
label(friends, "The friend list API may be blocked in some executors. Join buttons only work when Roblox permits the destination.", 43)
local friendList = make("Frame", {Size = UDim2.new(1,-2,0,1), BackgroundTransparency = 1}, friends)
local function loadFriends()
    for _, child in ipairs(friends:GetChildren()) do
        if child.Name == "FriendRow" then child:Destroy() end
    end
    local ok, data = pcall(function()
        local url = "https://friends.roblox.com/v1/users/" .. LocalPlayer.UserId .. "/friends"
        local req = (syn and syn.request) or (http and http.request) or request
        if req then
            local r = req({Url=url, Method="GET"})
            return HttpService:JSONDecode(r.Body)
        end
        return nil
    end)
    if not ok or not data or not data.data then
        label(friends, "Could not retrieve friends automatically. Roblox API / executor request support is required.", 42).Name = "FriendRow"
        return
    end
    for _, f in ipairs(data.data) do
        local row = make("Frame", {Name="FriendRow", Size=UDim2.new(1,-2,0,38), BackgroundColor3=C.panel2, BorderSizePixel=0}, friends)
        make("UICorner", {CornerRadius=UDim.new(0,7)}, row)
        make("TextLabel", {Position=UDim2.fromOffset(8,0), Size=UDim2.new(1,-90,1,0), BackgroundTransparency=1,
            Text=f.displayName .. "  @" .. f.name, TextColor3=C.text, Font=Enum.Font.Gotham, TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Left}, row)
        local play = make("TextButton", {Position=UDim2.new(1,-70,0,5), Size=UDim2.fromOffset(62,28),
            Text="Profile", BackgroundColor3=C.blue, TextColor3=C.text, Font=Enum.Font.GothamBold, TextSize=10,
            BorderSizePixel=0}, row)
        connect(play.Activated, function()
            local url = "https://www.roblox.com/users/" .. tostring(f.id) .. "/profile"
            if setclipboard then pcall(setclipboard, url) end
            notify("Friend profile", "Profile link copied when clipboard is supported.")
        end)
    end
end
button(friends, "Load / refresh friends", loadFriends, C.blue)
textbox(friends, "Friend username or UserId", function(value)
    local id = tonumber(value)
    if not id then
        pcall(function() id = Players:GetUserIdFromNameAsync(value) end)
    end
    if id then
        local url = "https://www.roblox.com/users/" .. tostring(id) .. "/profile"
        if setclipboard then pcall(setclipboard, url) end
        notify("Friend", "Profile link prepared. Direct joining requires a valid place/server.")
    else notify("Friend", "Username not found.") end
end)
button(friends, "Copy current place + job info", function()
    local s = "PlaceId="..game.PlaceId.."\nJobId="..game.JobId
    if setclipboard then pcall(setclipboard,s) end
    notify("Server", "Server info copied if clipboard API exists.")
end)

local visuals = addTab("VISUALS", "◉")
section(visuals, "Player ESP")
toggle(visuals, "Highlight players through walls", false, function(v) State.ESP = v; refreshESP() end)
button(visuals, "Refresh ESP", refreshESP)
button(visuals, "Clear ESP", function() State.ESP=false; clearESP() end)
label(visuals, "ESP is a local Highlight effect. It does not reveal server-hidden information.", 36)

local troll = addTab("TROLL", "⚡")
section(troll, "Visual / harmless effects")
toggle(troll, "Rainbow Walk trail", false, function(v) State.RainbowWalk = v end)
button(troll, "Rainbow character colors (local)", function()
    local ch = getChar()
    if not ch then return end
    for _, p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            pcall(function() p.Color = Color3.fromHSV(math.random(), .8, 1) end)
        end
    end
end, C.purple)
label(troll, "Flinging other players is not included: client-only physics cannot reliably move other players and can disrupt their game.", 52)

local server = addTab("SERVER", "▦")
section(server, "Server tools")
button(server, "Show server info", function()
    local cam = Workspace.CurrentCamera
    local ping = "n/a"
    pcall(function() ping = tostring(math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())).." ms" end)
    notify("Server info", "Place: "..game.PlaceId.." | Players: "..#Players:GetPlayers().."/"..Players.MaxPlayers.." | Ping: "..ping, 6)
end)
button(server, "Rejoin current server", function()
    if #Players:GetPlayers() <= 1 then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end, C.blue)
button(server, "Server Hop (public server list)", function()
    notify("Server Hop", "Requires an allowed HTTP request API and a public server endpoint. Use Roblox's own server browser if unavailable.", 5)
end)
toggle(server, "Auto-Rejoin on disconnect (best effort)", false, function(v)
    State.AutoRejoin = v
    notify("Auto-Rejoin", v and "Enabled where the executor keeps scripts running." or "Disabled.")
end)
label(server, "Auto-execute after teleport requires queue_on_teleport and a hosted script URL. No private URL is assumed.", 43)

local teleport = addTab("TELEPORT", "➤")
section(teleport, "Teleport")
textbox(teleport, "Player username", function(name)
    local target
    for _, p in ipairs(Players:GetPlayers()) do
        if string.lower(p.Name) == string.lower(name) or string.lower(p.DisplayName) == string.lower(name) then target=p; break end
    end
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and getRoot() then
        getRoot().CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(2,0,2)
    else notify("Teleport", "Player not found or character unavailable.") end
end)
button(teleport, "TP to Spawn", function()
    local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if spawn and getRoot() then getRoot().CFrame = spawn.CFrame + Vector3.new(0,4,0)
    else notify("Teleport", "No SpawnLocation found in this map.") end
end)
button(teleport, "TP to camera direction", function()
    local cam, r = Workspace.CurrentCamera, getRoot()
    if cam and r then r.CFrame = CFrame.new(cam.CFrame.Position + cam.CFrame.LookVector * 25 + Vector3.new(0,3,0)) end
end)
label(teleport, "Teleporting locally may be corrected by the server or blocked by the game.", 36)

local character = addTab("CHARACTER", "♟")
section(character, "Character appearance")
slider(character, "Local scale", 5, 20, 10, function(v)
    local hum = getHumanoid()
    if not hum then return end
    local s = v / 10
    for _, n in ipairs({"BodyHeightScale","BodyWidthScale","BodyDepthScale","HeadScale"}) do
        local obj = hum:FindFirstChild(n)
        if obj and obj:IsA("NumberValue") then obj.Value = s end
    end
end)
button(character, "Invisible (local transparency)", function()
    local ch = getChar()
    if not ch then return end
    for _, p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.LocalTransparencyModifier = 1 end
    end
    notify("Character", "Local transparency applied. Server and other clients may still see you.")
end)
button(character, "Restore visibility", function()
    local ch = getChar()
    if ch then for _, p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.LocalTransparencyModifier=0 end end end
end)
toggle(character, "Walk on Air (local platform)", false, function(v)
    State.WalkOnAir = v
    if not v then safeDestroy(ENV.__EP_AIR_PLATFORM); ENV.__EP_AIR_PLATFORM=nil end
end)
connect(RunService.Heartbeat, function()
    if State.WalkOnAir then
        local r = getRoot()
        if r then
            local p = ENV.__EP_AIR_PLATFORM
            if not p or not p.Parent then
                p = make("Part", {Name="EP_AirPlatform", Size=Vector3.new(7,.5,7), Anchored=true,
                    Transparency=.45, CanCollide=true, Material=Enum.Material.Neon, Color=C.blue}, Workspace)
                ENV.__EP_AIR_PLATFORM=p
            end
            p.CFrame = CFrame.new(r.Position.X, r.Position.Y-3.6, r.Position.Z)
        end
    end
end)

local cameraPage = addTab("CAMERA", "◎")
section(cameraPage, "Camera controls")
slider(cameraPage, "Field of View", 40, 120, 70, function(v)
    State.FOV=v
    if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView=v end
end)
button(cameraPage, "Reset FOV", function()
    State.FOV=70
    if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView=70 end
end)
toggle(cameraPage, "Freecam (basic camera detach)", false, function(v)
    State.Freecam=v
    local cam=Workspace.CurrentCamera
    if cam then
        cam.CameraType = v and Enum.CameraType.Scriptable or Enum.CameraType.Custom
        if not v then local h=getHumanoid(); if h then cam.CameraSubject=h end end
    end
    notify("Freecam", v and "Camera detached. Use game camera controls if available." or "Camera restored.")
end)
button(cameraPage, "Reset camera", function()
    State.Freecam=false
    local cam=Workspace.CurrentCamera
    if cam then cam.CameraType=Enum.CameraType.Custom; local h=getHumanoid(); if h then cam.CameraSubject=h end end
end)

local chat = addTab("CHAT / TAGS", "☷")
section(chat, "Chat utilities")
textbox(chat, "Custom local tag / prefix", function(value)
    ENV.__EP_CHAT_TAG = string.sub(value,1,24)
    notify("Chat tag", "Saved locally as: "..ENV.__EP_CHAT_TAG)
end)
textbox(chat, "Message to send once", function(value)
    if value == "" then return end
    local ok = pcall(function()
        local channel = game:GetService("TextChatService"):FindFirstChild("TextChannels")
        local general = channel and (channel:FindFirstChild("RBXGeneral") or channel:FindFirstChildWhichIsA("TextChannel"))
        if general then general:SendAsync(value) else error("New chat channel unavailable") end
    end)
    notify("Chat", ok and "Message sent once." or "Chat sending is unavailable in this game.")
end)
button(chat, "Bubble color: blue", function()
    State.BubbleColor=Color3.fromRGB(80,170,255)
    notify("Chat", "Color preference saved locally. Other players' bubbles may not be changeable.")
end)
button(chat, "Bubble color: purple", function()
    State.BubbleColor=Color3.fromRGB(180,90,255)
    notify("Chat", "Color preference saved locally.")
end)
label(chat, "Custom tags are local preferences only. Roblox does not let a client grant itself a server-authoritative chat tag. Chat spam is intentionally not included.", 53)

local animations = addTab("ANIMATIONS", "♫")
section(animations, "Emotes")
local function playEmote(id)
    local hum=getHumanoid()
    if not hum then return end
    local animator=hum:FindFirstChildOfClass("Animator") or make("Animator",{},hum)
    local anim=make("Animation",{AnimationId="rbxassetid://"..tostring(id)},Workspace)
    local ok, track=pcall(function() return animator:LoadAnimation(anim) end)
    if ok and track then track:Play(); task.delay(10,function() safeDestroy(anim) end)
    else safeDestroy(anim); notify("Animation","This emote may not be permitted in this game.") end
end
button(animations, "Wave (built-in emote)", function()
    local hum=getHumanoid()
    if hum then pcall(function() hum:PlayEmote("wave") end) end
end)
button(animations, "Point (built-in emote)", function()
    local hum=getHumanoid()
    if hum then pcall(function() hum:PlayEmote("point") end) end
end)
button(animations, "Dance (built-in emote)", function()
    local hum=getHumanoid()
    if hum then pcall(function() hum:PlayEmote("dance") end) end
end)
label(animations, "Gangnam Style, Floss and Macarena need animation IDs that work in this experience. The built-in emotes above are safer fallbacks.", 46)

local environment = addTab("ENVIRONMENT", "☼")
section(environment, "Local world settings")
button(environment, "Day", function() Lighting.ClockTime=14 end)
button(environment, "Night", function() Lighting.ClockTime=0 end)
button(environment, "Zero Gravity (local physics best effort)", function()
    State.ZeroGravity = not State.ZeroGravity
    Workspace.Gravity = State.ZeroGravity and 0 or 196.2
    notify("Gravity", State.ZeroGravity and "Local workspace gravity set to zero." or "Gravity reset to default.")
end)
button(environment, "Normal Gravity", function()
    State.ZeroGravity=false
    Workspace.Gravity=196.2
end)
button(environment, "Restore lighting", function() setFullbright(false) end)
label(environment, "Gravity and lighting changes may affect only your client or be overwritten by the game.", 37)

local spectate = addTab("SPECTATE", "◉")
section(spectate, "Watch players")
button(spectate, "Spectate closest player", function()
    local r=getRoot()
    if not r then return end
    local closest, dist=nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d=(p.Character.HumanoidRootPart.Position-r.Position).Magnitude
            if d<dist then closest,dist=p,d end
        end
    end
    if closest then
        local h=closest.Character:FindFirstChildOfClass("Humanoid")
        if h and Workspace.CurrentCamera then Workspace.CurrentCamera.CameraSubject=h; State.Spectating=true end
    else notify("Spectate","No other player found.") end
end)
textbox(spectate, "Username to spectate", function(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and (string.lower(p.Name)==string.lower(name) or string.lower(p.DisplayName)==string.lower(name)) then
            local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if h and Workspace.CurrentCamera then Workspace.CurrentCamera.CameraSubject=h; State.Spectating=true end
            return
        end
    end
    notify("Spectate","Player not found.")
end)
button(spectate, "Unspectate / return to self", function()
    State.Spectating=false
    local h=getHumanoid()
    if Workspace.CurrentCamera then Workspace.CurrentCamera.CameraSubject=h; Workspace.CurrentCamera.CameraType=Enum.CameraType.Custom end
end)

local sounds = addTab("SOUNDS", "♫")
section(sounds, "Sound effects")
button(sounds, "Play local beep", function()
    local s=make("Sound",{SoundId="rbxasset://sounds/electronicpingshort.wav",Volume=.5},Workspace)
    s:Play()
    task.delay(3,function() safeDestroy(s) end)
end)
button(sounds, "Stop local sounds", function()
    for _, s in ipairs(Workspace:GetDescendants()) do
        if s:IsA("Sound") and s.Name=="EP_LocalSound" then s:Stop() end
    end
end)
label(sounds, "Client scripts cannot force arbitrary sounds to play for other players unless the game exposes a permitted remote. Earrape-to-others is not included.", 48)

local movesets = addTab("MOVESETS", "⌘")
section(movesets, "Local modules")
label(movesets, "Place your own trusted Lua modules in EpicPlanets/Modules if your executor supports file access. Never run unknown scripts blindly.", 45)
button(movesets, "Check file API", function()
    local has = type(isfile)=="function" and type(readfile)=="function"
    notify("Modules", has and "File APIs detected." or "File APIs unavailable in this executor.")
end)

local models = addTab("MODELS", "◇")
section(models, "Visual models")
button(models, "Create orbiting neon sphere", function()
    safeDestroy(ENV.__EP_ORBIT)
    local part=make("Part",{Name="EP_OrbitSphere",Shape=Enum.PartType.Ball,Size=Vector3.new(1.2,1.2,1.2),
        Material=Enum.Material.Neon,Color=C.purple,Anchored=true,CanCollide=false},Workspace)
    ENV.__EP_ORBIT=part
    local angle=0
    local c
    c=RunService.RenderStepped:Connect(function(dt)
        if not part.Parent then c:Disconnect(); return end
        local r=getRoot()
        if r then angle+=dt*1.8; part.Position=r.Position+Vector3.new(math.cos(angle)*3,1.5,math.sin(angle)*3) end
    end)
    table.insert(Connections,c)
end)
button(models, "Remove visual models", function()
    safeDestroy(ENV.__EP_ORBIT); ENV.__EP_ORBIT=nil
    safeDestroy(ENV.__EP_AIR_PLATFORM); ENV.__EP_AIR_PLATFORM=nil
end)

local settings = addTab("SETTINGS", "⚙")
section(settings, "Preferences")
button(settings, "Reset WalkSpeed / JumpPower", function()
    State.Speed,State.Jump=16,50
    local h=getHumanoid()
    if h then h.WalkSpeed=16; h.UseJumpPower=true; h.JumpPower=50 end
    notify("Settings","Movement values reset.")
end)
button(settings, "Restore all lighting", function() setFullbright(false); Lighting.ClockTime=OriginalLighting.ClockTime end)
button(settings, "Rebuild ESP", refreshESP)
button(settings, "Cleanup and close", function() ENV.__EPIC_PLANETS_CLEANUP() end, C.red)

local personalization = addTab("PERSONALIZATION", "✧")
section(personalization, "Appearance")
button(personalization, "Blue theme", function()
    C.blue=Color3.fromRGB(88,110,255)
    for _, b in pairs(tabButtons) do if b.BackgroundColor3==C.blue then b.BackgroundColor3=C.blue end end
    notify("Theme","Blue accent selected.")
end)
button(personalization, "Purple theme", function()
    C.blue=Color3.fromRGB(170,90,255)
    notify("Theme","Purple accent selected for new effects.")
end)
toggle(personalization, "Rainbow title", false, function(v)
    State.RainbowTitle=v
end)
connect(RunService.RenderStepped, function()
    if State.RainbowTitle then title.TextColor3=Color3.fromHSV((tick()%5)/5, .65, 1) end
    if State.RainbowWalk then
        local ch=getChar()
        if ch then
            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
                    p.Color=Color3.fromHSV((tick()%5)/5,.8,1)
                end
            end
        end
    end
end)

local scriptBlox = addTab("SCRIPTBLOX", "⌕")
section(scriptBlox, "Script search")
label(scriptBlox, "External script catalogs change frequently. Search results are not verified or guaranteed safe.", 40)
textbox(scriptBlox, "Search term (opens browser if supported)", function(term)
    local url="https://scriptblox.com/?q="..HttpService:UrlEncode(term)
    if setclipboard then pcall(setclipboard,url) end
    notify("ScriptBlox","Search link copied if clipboard support exists.")
end)
button(scriptBlox, "Copy ScriptBlox homepage", function()
    if setclipboard then pcall(setclipboard,"https://scriptblox.com/") end
    notify("ScriptBlox","Homepage link copied if supported.")
end)

local logs = addTab("LOGS", "≡")
section(logs, "Runtime log")
label(logs, "EPIC PLANETS started successfully.\nLoaded mobile UI, player tools, camera, visuals and utility pages.", 58)
button(logs, "Copy diagnostic info", function()
    local info="EPIC PLANETS Mobile Build\nPlaceId: "..game.PlaceId.."\nPlayers: "..#Players:GetPlayers()
    if setclipboard then pcall(setclipboard,info) end
    notify("Logs","Diagnostic info copied if clipboard API exists.")
end)

local executor = addTab("EXECUTOR", "⌘")
section(executor, "Local code runner")
label(executor, "Only run code you understand. Arbitrary scripts can steal data or damage your session.", 39)
local codeBox = make("TextBox", {
    Size=UDim2.new(1,-2,0,130), BackgroundColor3=C.bg, TextColor3=C.text,
    PlaceholderColor3=C.muted, PlaceholderText="-- paste trusted Lua here",
    Text="", ClearTextOnFocus=false, MultiLine=true, TextWrapped=false,
    TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
    Font=Enum.Font.Code, TextSize=11, BorderSizePixel=0,
}, executor)
make("UICorner",{CornerRadius=UDim.new(0,8)},codeBox)
button(executor, "Run code in this client", function()
    local compiler=loadstring
    if type(compiler)~="function" then notify("Executor","loadstring is unavailable."); return end
    local fn,err=compiler(codeBox.Text)
    if not fn then notify("Compile error",tostring(err),5); return end
    local ok,res=pcall(fn)
    notify("Executor",ok and "Code executed." or tostring(res),5)
end,C.red)

local tetris = addTab("TETRIS", "▦")
section(tetris, "Compact Tetris")
label(tetris, "A lightweight playable grid is included in the Tetris tab. Controls: Left / Right / Rotate / Drop.", 40)
local boardFrame = make("Frame",{Size=UDim2.new(1,-2,0,240),BackgroundColor3=C.bg,BorderSizePixel=0},tetris)
make("UICorner",{CornerRadius=UDim.new(0,8)},boardFrame)
local boardLabel=make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="TETRIS  •  Score: 0",
    TextColor3=C.text,Font=Enum.Font.GothamBold,TextSize=12},boardFrame)
local boardArea=make("Frame",{Position=UDim2.fromOffset(8,32),Size=UDim2.new(1,-16,0,155),BackgroundColor3=Color3.fromRGB(7,8,14),BorderSizePixel=0},boardFrame)
make("UICorner",{CornerRadius=UDim.new(0,5)},boardArea)
local gridCells={}
for y=1,10 do
    gridCells[y]={}
    for x=1,10 do
        gridCells[y][x]=make("Frame",{Position=UDim2.new((x-1)/10,1,(y-1)/10,1),
            Size=UDim2.new(.1,-2,.1,-2),BackgroundColor3=C.panel2,BorderSizePixel=0},boardArea)
    end
end
local score, tetrisRunning, tetrisX, tetrisY = 0, false, 5, 1
local piece={{0,0},{1,0},{0,1},{1,1}}
local settled={}
local function drawBoard()
    for y=1,10 do for x=1,10 do
        local occupied=settled[y] and settled[y][x]
        for _, cell in ipairs(piece) do
            if tetrisX+cell[1]==x and tetrisY+cell[2]==y then occupied=true end
        end
        gridCells[y][x].BackgroundColor3=occupied and C.purple or C.panel2
    end end
    boardLabel.Text="TETRIS  •  Score: "..score
end
local function newPiece()
    local pieces={
        {{0,0},{1,0},{0,1},{1,1}},
        {{0,0},{1,0},{2,0},{3,0}},
        {{0,0},{0,1},{1,1},{2,1}},
        {{2,0},{0,1},{1,1},{2,1}},
        {{1,0},{2,0},{0,1},{1,1}},
        {{1,0},{0,1},{1,1},{2,1}},
        {{0,0},{1,0},{1,1},{2,1}},
    }
    piece=pieces[math.random(1,#pieces)]
    tetrisX,tetrisY=4,1
end
local function lockPiece()
    for _, cell in ipairs(piece) do
        local x,y=tetrisX+cell[1],tetrisY+cell[2]
        if y>=1 and y<=10 and x>=1 and x<=10 then
            settled[y]=settled[y] or {}; settled[y][x]=true
        end
    end
    for y=10,1,-1 do
        local full=true
        for x=1,10 do if not (settled[y] and settled[y][x]) then full=false; break end end
        if full then
            table.remove(settled,y)
            table.insert(settled,1,{})
            score+=100
        end
    end
    newPiece()
end
local controls=make("Frame",{Position=UDim2.new(0,8,1,-44),Size=UDim2.new(1,-16,0,34),BackgroundTransparency=1},boardFrame)
local function tBtn(txt,x,cb)
    local b=make("TextButton",{Position=UDim2.new(x,0,0,0),Size=UDim2.new(.24,-3,1,0),
        BackgroundColor3=C.panel2,Text=txt,TextColor3=C.text,Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0},controls)
    make("UICorner",{CornerRadius=UDim.new(0,6)},b)
    connect(b.Activated,cb)
end
tBtn("◀",0,function() tetrisX=math.max(1,tetrisX-1); drawBoard() end)
tBtn("ROT",.25,function()
    local maxX=0; for _,c in ipairs(piece) do maxX=math.max(maxX,c[1]) end
    for _,c in ipairs(piece) do c[1],c[2]=c[2],maxX-c[1] end
    drawBoard()
end)
tBtn("▶",.5,function() tetrisX=math.min(7,tetrisX+1); drawBoard() end)
tBtn("DROP",.75,function()
    tetrisY=math.min(9,tetrisY+1); score+=1
    if tetrisY>=9 then lockPiece() end
    drawBoard()
end)
button(tetris,"Start / restart Tetris",function()
    score=0; settled={}; for y=1,10 do settled[y]={} end
    newPiece(); drawBoard(); notify("Tetris","Game ready. Use the touch controls.")
end,C.blue)
connect(UIS.InputBegan,function(input,processed)
    if processed or not pages.TETRIS or not pages.TETRIS.Visible then return end
    if input.KeyCode==Enum.KeyCode.Left then tetrisX=math.max(1,tetrisX-1)
    elseif input.KeyCode==Enum.KeyCode.Right then tetrisX=math.min(7,tetrisX+1)
    elseif input.KeyCode==Enum.KeyCode.Up then
        local maxX=0; for _,c in ipairs(piece) do maxX=math.max(maxX,c[1]) end
        for _,c in ipairs(piece) do c[1],c[2]=c[2],maxX-c[1] end
    elseif input.KeyCode==Enum.KeyCode.Down then tetrisY=math.min(9,tetrisY+1); score+=1; if tetrisY>=9 then lockPiece() end
    end
    drawBoard()
end)
newPiece(); drawBoard()

local credits = addTab("CREDITS", "✦")
section(credits, "Credits")
label(credits, "EPIC PLANETS\nMobile interface rebuild\nOriginal concept and project: chaloapps011-cyber\nBuilt for touch controls and compact screens.", 85)
button(credits, "Open project on GitHub", function()
    local url="https://github.com/chaloapps011-cyber/EpicPlanets"
    if setclipboard then pcall(setclipboard,url) end
    notify("GitHub","Project URL copied if clipboard API exists.")
end)

-- Keyboard shortcuts and initial animation.
connect(UIS.InputBegan,function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.RightShift then root.Visible=not root.Visible end
end)
connect(close.Activated,function() ENV.__EPIC_PLANETS_CLEANUP() end)
connect(minimize.Activated,function()
    local hide=content.Visible
    content.Visible=not hide
    sidebar.Visible=not hide
    root.Size=hide and UDim2.fromOffset(640,47) or UDim2.fromOffset(640,430)
end)
showPage("HOME")
title.TextColor3=C.text
notify("EPIC PLANETS","Mobile build loaded. Tap a tab to begin.",4)
print("[EPIC PLANETS] Mobile Complete Build loaded.")
