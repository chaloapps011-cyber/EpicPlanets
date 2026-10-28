--[[
    EPIC PLANETS
    Main.lua + BuiltinModules + Tetris + Credits + Mini Effects + Game Blur + Back Animation
    Delta / Android
]]

local ENV = (type(getgenv) == "function" and getgenv()) or _G

----------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------
if type(ENV.__EPIC_PLANETS_CONNECTIONS) == "table" then
    for _, connection in ipairs(ENV.__EPIC_PLANETS_CONNECTIONS) do pcall(function() connection:Disconnect() end) end
end
if ENV.__EPIC_PLANETS_GUI then pcall(function() ENV.__EPIC_PLANETS_GUI:Destroy() end) end
if ENV.__EPIC_PLANETS_TETRIS_GUI then pcall(function() ENV.__EPIC_PLANETS_TETRIS_GUI:Destroy() end) end
if ENV.__EPIC_PLANETS_FLASH_SOUND then pcall(function() ENV.__EPIC_PLANETS_FLASH_SOUND:Stop() ENV.__EPIC_PLANETS_FLASH_SOUND:Destroy() end) end
if type(ENV.__EPIC_PLANETS_PERSONAL_AUDIO_SOUNDS) == "table" then
    for _, oldSound in pairs(ENV.__EPIC_PLANETS_PERSONAL_AUDIO_SOUNDS) do pcall(function() oldSound:Stop() oldSound:Destroy() end) end
end
ENV.__EPIC_PLANETS_PERSONAL_AUDIO_SOUNDS = {}
if type(ENV.__EPIC_PLANETS_MODELS) == "table" then
    for _, model in ipairs(ENV.__EPIC_PLANETS_MODELS) do pcall(function() model:Destroy() end) end
end

ENV.__EPIC_PLANETS_CONNECTIONS = {}
ENV.__EPIC_PLANETS_MODELS = {}
ENV.__EPIC_PLANETS_RUNNING = true
local Connections = ENV.__EPIC_PLANETS_CONNECTIONS

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

if Lighting:FindFirstChild("EpicPlanetsBlur") then Lighting.EpicPlanetsBlur:Destroy() end

local Player = Players.LocalPlayer
if not Player then error("[EPIC PLANETS] LocalPlayer not found.") end
local PlayerGui = Player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- BUILTINMODULES: CORE
----------------------------------------------------------------
local BuiltinModules = {}
BuiltinModules.Version = "1.3.1"
BuiltinModules.Initialized = false

BuiltinModules.Colors = {
    Background = Color3.fromRGB(8, 8, 11),
    Panel = Color3.fromRGB(17, 17, 22),
    PanelAlt = Color3.fromRGB(26, 26, 33),
    PanelHover = Color3.fromRGB(38, 38, 47),
    Text = Color3.fromRGB(240, 240, 245),
    Muted = Color3.fromRGB(157, 157, 170),
    Blue = Color3.fromRGB(55, 145, 255),
    Purple = Color3.fromRGB(173, 96, 255),
    Green = Color3.fromRGB(72, 220, 145),
    Red = Color3.fromRGB(245, 65, 75),
}

BuiltinModules.Settings = { Rainbow = true, Intro = true, FlashAudio = true, AudioVolume = 1 }
BuiltinModules.Titles = { "EPIC PLANETS", "don't touch In builtinmodules", "BLUEEEEEE", "F up", "April!", "Dont kill the script" }
math.randomseed(os.time() + math.floor(os.clock() * 100000))
local Title = BuiltinModules.Titles[math.random(1, #BuiltinModules.Titles)]

----------------------------------------------------------------
-- EXECUTOR & HELPERS
----------------------------------------------------------------
BuiltinModules.Executor = {}
function BuiltinModules.Executor.Get(name)
    local fn; pcall(function() fn = ENV[name] end)
    if type(fn) ~= "function" then pcall(function() fn = _G[name] end) end
    return type(fn) == "function" and fn or nil
end
function BuiltinModules.Executor.Call(name, ...)
    local fn = BuiltinModules.Executor.Get(name)
    if not fn then return false, "Executor API unavailable: " .. name end
    return pcall(fn, ...)
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end
local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do object[property] = value end
    object.Parent = parent
    return object
end
local function tween(object, duration, properties, style)
    local animation = TweenService:Create(object, TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    animation:Play()
    return animation
end

local RuntimeLogs = {}
local refreshLogsPage
local MAX_RUNTIME_LOGS = 100
local function addLog(level, message)
    local stamp = "--:--:--"; pcall(function() stamp = os.date("%H:%M:%S") end)
    local entry = { time = stamp, level = tostring(level or "INFO"), message = tostring(message or "") }
    if #entry.message > 220 then entry.message = string.sub(entry.message, 1, 217) .. "..." end
    table.insert(RuntimeLogs, entry)
    while #RuntimeLogs > MAX_RUNTIME_LOGS do table.remove(RuntimeLogs, 1) end
    if refreshLogsPage then task.defer(function() if refreshLogsPage then pcall(refreshLogsPage) end end) end
end
local function setStatus(message)
    local value = tostring(message)
    addLog("INFO", value)
    local status = ENV.__EPIC_PLANETS_STATUS
    if status and status.Parent then status.Text = "Status: " .. value end
end

----------------------------------------------------------------
-- AUDIO & UI
----------------------------------------------------------------
BuiltinModules.Audio = {}
BuiltinModules.Audio.URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/Screenrecorder-2026-09-18-20-34-50-385.mp3"
BuiltinModules.Audio.Folder = "EpicPlanets"
BuiltinModules.Audio.File = BuiltinModules.Audio.Folder .. "/Screenrecorder-2026-09-18-20-34-50-385.mp3"

function BuiltinModules.Audio.Prepare()
    local executor = BuiltinModules.Executor
    local folderOK, folderExists = executor.Call("isfolder", BuiltinModules.Audio.Folder)
    if not folderOK or folderExists ~= true then executor.Call("makefolder", BuiltinModules.Audio.Folder) end
    local checkOK, fileExists = executor.Call("isfile", BuiltinModules.Audio.File)
    if not checkOK or fileExists ~= true then
        local downloadOK, data = pcall(function() return game:HttpGet(BuiltinModules.Audio.URL) end)
        if not downloadOK or type(data) ~= "string" or #data == 0 then return nil end
        executor.Call("writefile", BuiltinModules.Audio.File, data)
    end
    local assetOK, assetId = executor.Call("getcustomasset", BuiltinModules.Audio.File)
    if not assetOK or type(assetId) ~= "string" then return nil end
    local sound = Instance.new("Sound")
    sound.Name = "EPIC_PLANETS_FLASH_AUDIO"
    sound.SoundId = assetId; sound.Volume = BuiltinModules.Settings.AudioVolume; sound.Looped = false; sound.Parent = SoundService
    ENV.__EPIC_PLANETS_FLASH_SOUND = sound
    return sound
end
function BuiltinModules.Audio.PlayFlash()
    if not BuiltinModules.Settings.FlashAudio then return end
    local sound = ENV.__EPIC_PLANETS_FLASH_SOUND
    if sound and sound.Parent then pcall(function() sound:Stop() sound.TimePosition = 0 sound:Play() end) end
end

BuiltinModules.UI = {}
function BuiltinModules.UI.Round(object, radius) create("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, object) end
function BuiltinModules.UI.Stroke(object, color, transparency)
    return create("UIStroke", { Color = color or BuiltinModules.Colors.Blue, Thickness = 1, Transparency = transparency or 0.15 }, object)
end
function BuiltinModules.UI.Label(parent, text, height, size, color)
    return create("TextLabel", { Size = UDim2.new(1, -4, 0, height or 30), BackgroundTransparency = 1, Text = text, TextColor3 = color or BuiltinModules.Colors.Text, TextSize = size or 12, Font = Enum.Font.Gotham, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }, parent)
end
function BuiltinModules.UI.Button(parent, text, callback, height)
    local button = create("TextButton", { Size = UDim2.new(1, -4, 0, height or 38), BackgroundColor3 = BuiltinModules.Colors.PanelAlt, BorderSizePixel = 0, Text = text, TextColor3 = BuiltinModules.Colors.Text, TextSize = 11, Font = Enum.Font.GothamBold, TextWrapped = true, AutoButtonColor = true }, parent)
    BuiltinModules.UI.Round(button, 7); BuiltinModules.UI.Stroke(button, nil, 0.4)
    connect(button.Activated, function() local ok, err = pcall(callback, button); if not ok then addLog("ERROR", "Button error: " .. tostring(err)) end end)
    return button
end

----------------------------------------------------------------
-- MODULE LOADER
----------------------------------------------------------------
BuiltinModules.ModuleLoader = {}
BuiltinModules.ModuleLoader.Folder = "EpicPlanets/Modules"
function BuiltinModules.ModuleLoader.EnsureFolders()
    local makefolder = BuiltinModules.Executor.Get("makefolder")
    if type(makefolder) ~= "function" then return false end
    for _, folder in ipairs({"EpicPlanets", BuiltinModules.ModuleLoader.Folder}) do pcall(makefolder, folder) end
    return true
end
function BuiltinModules.ModuleLoader.List()
    BuiltinModules.ModuleLoader.EnsureFolders()
    local listFunction = BuiltinModules.Executor.Get("listfiles")
    if type(listFunction) ~= "function" then return nil, "Unavailable." end
    local ok, result = pcall(listFunction, BuiltinModules.ModuleLoader.Folder)
    if not ok or type(result) ~= "table" then return nil, "Cannot scan." end
    return result
end
function BuiltinModules.ModuleLoader.Run(path)
    local readOK, source = BuiltinModules.Executor.Call("readfile", path)
    if not readOK or type(source) ~= "string" then return false, "Could not read" end
    local loadFunction = BuiltinModules.Executor.Get("loadstring")
    if not loadFunction then return false, "loadstring unavailable" end
    local compileOK, chunk = pcall(loadFunction, source)
    if not compileOK or type(chunk) ~= "function" then return false, tostring(chunk) end
    local runOK, result = pcall(chunk)
    if not runOK then return false, tostring(result) end
    return true, "Executed"
end

pcall(function() BuiltinModules.ModuleLoader.EnsureFolders() end)
local flashSound = BuiltinModules.Audio.Prepare()
local C = BuiltinModules.Colors
local UI = BuiltinModules.UI

----------------------------------------------------------------
-- GAME BLUR EFFECT
----------------------------------------------------------------
local BlurEffect = Instance.new("BlurEffect")
BlurEffect.Name = "EpicPlanetsBlur"
BlurEffect.Size = 0
BlurEffect.Parent = Lighting
local function updateGameBlur(isVisible)
    local targetSize = isVisible and 15 or 0
    tween(BlurEffect, 0.4, { Size = targetSize }, Enum.EasingStyle.Quad)
end

----------------------------------------------------------------
-- GUI ROOT & INTRO
----------------------------------------------------------------
local GUI = create("ScreenGui", { Name = "EPIC_PLANETS_GUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, PlayerGui)
ENV.__EPIC_PLANETS_GUI = GUI

local Intro = create("Frame", { Name = "IntroScreen", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Background, BorderSizePixel = 0 }, GUI)
for i = 1, 65 do
    local star = create("Frame", { Position = UDim2.fromScale(math.random(1, 99) / 100, math.random(1, 99) / 100), Size = UDim2.fromOffset(math.random(1, 3), math.random(1, 3)), BackgroundColor3 = i % 5 == 0 and C.Blue or C.Text, BackgroundTransparency = math.random(25, 75) / 100, BorderSizePixel = 0 }, Intro)
    UI.Round(star, 4)
end
local IntroTitle = create("TextLabel", { Position = UDim2.new(0, 8, 0, 17), Size = UDim2.new(1, -16, 0, 34), BackgroundTransparency = 1, Text = Title, TextColor3 = C.Text, TextSize = 20, Font = Enum.Font.GothamBlack, TextWrapped = true }, Intro)
local IntroPanel = create("Frame", { Name = "IntroPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.new(0.86, 0, 0.66, 0), BackgroundColor3 = C.Panel, BorderSizePixel = 0 }, Intro)
local introConstraint = Instance.new("UISizeConstraint"); introConstraint.MinSize = Vector2.new(275, 350); introConstraint.MaxSize = Vector2.new(480, 530); introConstraint.Parent = IntroPanel
UI.Round(IntroPanel, 12); UI.Stroke(IntroPanel, C.Blue, 0.08)

local IntroStatus = create("TextLabel", { Position = UDim2.new(0, 12, 0, 9), Size = UDim2.new(1, -24, 0, 23), BackgroundTransparency = 1, Text = "ASSEMBLING 321 FRAGMENTS", TextColor3 = C.Text, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, IntroPanel)
local Orbit = create("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 37), Size = UDim2.fromOffset(150, 108), BackgroundTransparency = 1 }, IntroPanel)
local Core = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = C.Text, BorderSizePixel = 0 }, Orbit)
UI.Round(Core, 20); UI.Stroke(Core, C.Blue, 0.1)

local PlanetColors = { C.Blue, C.Purple, C.Green, Color3.fromRGB(255, 170, 65) }
local Planets = {}
for i = 1, 4 do
    local planet = create("Frame", { Name = "Planet" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(i % 2 == 0 and 16 or 12, i % 2 == 0 and 16 or 12), BackgroundColor3 = PlanetColors[i], BorderSizePixel = 0 }, Orbit)
    UI.Round(planet, 20); Planets[i] = planet
end
local Ring = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(92, 72), BackgroundTransparency = 1 }, Orbit)
UI.Round(Ring, 40); UI.Stroke(Ring, C.Blue, 0.55)

local FragmentArea = create("Frame", { Position = UDim2.new(0, 10, 0, 151), Size = UDim2.new(1, -20, 0, 105), BackgroundTransparency = 1, ClipsDescendants = true }, IntroPanel)
local Fragments = {}
for i = 1, 321 do
    local fragment = create("Frame", { Name = "Fragment" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(math.random(), math.random()), Size = UDim2.fromOffset(math.random(2, 5), math.random(2, 5)), BackgroundColor3 = i % 6 == 0 and C.Purple or C.Blue, BorderSizePixel = 0 }, FragmentArea)
    UI.Round(fragment, 4); Fragments[i] = fragment
end
local ProgressBack = create("Frame", { Position = UDim2.new(0, 14, 1, -43), Size = UDim2.new(1, -28, 0, 5), BackgroundColor3 = C.PanelAlt, BorderSizePixel = 0 }, IntroPanel); UI.Round(ProgressBack, 4)
local Progress = create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.Blue, BorderSizePixel = 0 }, ProgressBack); UI.Round(Progress, 4)
local FragmentCount = create("TextLabel", { Position = UDim2.new(0, 0, 1, -32), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "0 / 321", TextColor3 = C.Muted, TextSize = 10, Font = Enum.Font.Code }, IntroPanel)
local TapIn = create("TextButton", { Name = "TapIn", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -50), Size = UDim2.new(0.7, 0, 0, 40), BackgroundColor3 = C.PanelAlt, BorderSizePixel = 0, Text = "T A P   I N", TextColor3 = C.Text, TextSize = 14, Font = Enum.Font.GothamBlack, Visible = false }, IntroPanel)
UI.Round(TapIn, 7); UI.Stroke(TapIn, C.Blue, 0.08)

----------------------------------------------------------------
-- MAIN HUB
----------------------------------------------------------------
local Hub = create("Frame", { Name = "MainHub", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.51), Size = UDim2.new(0.91, 0, 0.74, 0), BackgroundColor3 = C.Panel, BorderSizePixel = 0, Visible = false, ClipsDescendants = true }, GUI)
local hubConstraint = Instance.new("UISizeConstraint"); hubConstraint.MinSize = Vector2.new(300, 370); hubConstraint.MaxSize = Vector2.new(640, 590); hubConstraint.Parent = Hub
UI.Round(Hub, 11); UI.Stroke(Hub, C.Blue, 0.05)

local StarContainer = create("Frame", { Name = "StarContainer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0 }, Hub)
local HubStars = {}
for i = 1, 40 do
    local star = create("Frame", { Size = UDim2.fromOffset(math.random(1, 3), math.random(1, 3)), Position = UDim2.new(math.random(), 0, math.random(), 0), BackgroundColor3 = C.Text, BorderSizePixel = 0, ZIndex = 0 }, StarContainer)
    UI.Round(star, 5)
    table.insert(HubStars, { frame = star, speed = math.random(15, 40) / 1000, offset = math.random(1, 100) })
end

local Header = create("TextButton", { Name = "DragHeader", Active = true, AutoButtonColor = false, Position = UDim2.new(0, 12, 0, 7), Size = UDim2.new(1, -92, 0, 28), BackgroundTransparency = 1, Text = Title, TextColor3 = C.Text, TextSize = 17, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, Hub)
local Minimize = create("TextButton", { Position = UDim2.new(1, -42, 0, 8), Size = UDim2.fromOffset(30, 28), BackgroundColor3 = C.PanelAlt, BorderSizePixel = 0, Text = "×", TextColor3 = C.Text, TextSize = 19, Font = Enum.Font.GothamBold }, Hub)
UI.Round(Minimize, 6); UI.Stroke(Minimize, C.Blue, 0.3)

local Sidebar = create("ScrollingFrame", { Name = "Sidebar", Position = UDim2.new(0, 10, 0, 48), Size = UDim2.new(0, 102, 1, -81), BackgroundColor3 = C.Background, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = C.Blue, ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0) }, Hub)
UI.Round(Sidebar, 7); UI.Stroke(Sidebar, C.Blue, 0.55)
local sidePadding = Instance.new("UIPadding"); sidePadding.PaddingTop = UDim.new(0, 7); sidePadding.PaddingLeft = UDim.new(0, 6); sidePadding.PaddingRight = UDim.new(0, 6); sidePadding.Parent = Sidebar
local sideLayout = Instance.new("UIListLayout"); sideLayout.Padding = UDim.new(0, 6); sideLayout.SortOrder = Enum.SortOrder.LayoutOrder; sideLayout.Parent = Sidebar

local PageHost = create("Frame", { Name = "PageHost", Position = UDim2.new(0, 120, 0, 48), Size = UDim2.new(1, -130, 1, -81), BackgroundColor3 = C.Background, BorderSizePixel = 0 }, Hub)
UI.Round(PageHost, 7); UI.Stroke(PageHost, C.Blue, 0.55)

local Status = create("TextLabel", { Position = UDim2.new(0, 12, 1, -25), Size = UDim2.new(1, -24, 0, 17), BackgroundTransparency = 1, Text = "Status: Ready", TextColor3 = C.Muted, TextSize = 9, Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, Hub)
ENV.__EPIC_PLANETS_STATUS = Status

----------------------------------------------------------------
-- MINI CONTAINER (EP ICON + EFEITOS)
----------------------------------------------------------------
local MiniContainer = create("Frame", { Name = "EP_MiniContainer", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 35, 0.5, 0), Size = UDim2.fromOffset(50, 50), BackgroundTransparency = 1, Visible = false, ZIndex = 100 }, GUI)
local MiniBlur = create("Frame", { Size = UDim2.fromOffset(50, 50), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5, ZIndex = 99 }, MiniContainer)
UI.Round(MiniBlur, 15)
local BlurStroke = UI.Stroke(MiniBlur, C.Red, 0.5); BlurStroke.Thickness = 2
local Mini = create("TextButton", { Name = "EP_MiniIcon", Size = UDim2.fromOffset(42, 42), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.Background, BorderSizePixel = 0, Text = "EP", TextColor3 = C.Text, TextSize = 13, Font = Enum.Font.GothamBlack, ZIndex = 101 }, MiniContainer)
UI.Round(Mini, 10)
local MiniStroke = UI.Stroke(Mini, C.Blue, 0.02)

local function spawnMiniSpark()
    if not MiniContainer.Visible then return end
    local spark = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4)), BackgroundColor3 = C.Text, BorderSizePixel = 0, ZIndex = 102 }, MiniContainer)
    UI.Round(spark, 5)
    local angle = math.random() * math.pi * 2
    local distance = math.random(35, 55)
    local targetX = 0.5 + math.cos(angle) * (distance / 50)
    local targetY = 0.5 + math.sin(angle) * (distance / 50)
    tween(spark, 0.5, { Position = UDim2.fromScale(targetX, targetY), BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quad)
    task.delay(0.5, function() if spark then spark:Destroy() end end)
end

----------------------------------------------------------------
-- PAGE SYSTEM
----------------------------------------------------------------
local Pages, Tabs = {}, {}
local function makePage(name)
    local page = create("ScrollingFrame", { Name = name .. "Page", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Blue, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false }, PageHost)
    local padding = Instance.new("UIPadding"); padding.PaddingTop = UDim.new(0, 8); padding.PaddingBottom = UDim.new(0, 8); padding.PaddingLeft = UDim.new(0, 8); padding.PaddingRight = UDim.new(0, 8); padding.Parent = page
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 7); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = page
    Pages[name] = page; return page
end
local function info(parent, text, height, color) return UI.Label(parent, text, height or 42, 11, color or C.Muted) end
local function showPage(name)
    if not Pages[name] then return end
    for p, page in pairs(Pages) do page.Visible = p == name end
    for t, button in pairs(Tabs) do button.BackgroundColor3 = t == name and C.PanelHover or C.PanelAlt; button.TextColor3 = t == name and C.Text or C.Muted end
    setStatus("Opened " .. name)
end
local function addTab(name, label, order)
    local button = create("TextButton", { Name = "Tab_" .. name, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = C.PanelAlt, BorderSizePixel = 0, Text = label, TextColor3 = C.Muted, TextSize = 10, Font = Enum.Font.GothamBold, TextWrapped = true }, Sidebar)
    UI.Round(button, 6); UI.Stroke(button, C.Blue, 0.65)
    Tabs[name] = button
    connect(button.Activated, function() showPage(name) end)
end

local HomePage = makePage("Home")
local PlayerPage = makePage("Player")
local BuiltinPage = makePage("BuiltinModules")
local MovesetsPage = makePage("Movesets")
local ModelsPage = makePage("Models")
local SettingsPage = makePage("Settings")
local PersonalizationPage = makePage("Personalization")
local ScriptBloxPage = makePage("ScriptBlox")
local LogsPage = makePage("Logs")
local ExecutorPage = makePage("Executor")
local TetrisPage = makePage("Tetris")

addTab("Home", "HOME", 1); addTab("Player", "PLAYER", 2); addTab("BuiltinModules", "BUILTINS", 3); addTab("Movesets", "MOVESETS", 4); addTab("Models", "MODEL STORE", 5); addTab("Settings", "SETTINGS", 6); addTab("Personalization", "PERSONAL", 7); addTab("ScriptBlox", "SCRIPTBLOX", 8); addTab("Logs", "LOGS", 9); addTab("Executor", "EXECUTOR", 10); addTab("Tetris", "TETRIS", 11)

----------------------------------------------------------------
-- SCRIPTBLOX STORE & LOGS & EXECUTOR
----------------------------------------------------------------
local ScriptBloxBase = "https://scriptblox.com"
local ScriptResultCards = {}
local storeQuery, storePage, storeRequestId, storeBusy, storeStrictMatch = "", 1, 0, false, false
UI.Label(ScriptBloxPage, "SCRIPTBLOX STORE", 29, 14, C.Text).Font = Enum.Font.GothamBlack
info(ScriptBloxPage, "Search community scripts. Review source before using it.", 55, C.Muted)
info(ScriptBloxPage, "Powered by ScriptBlox.com", 22, C.Blue)
local StoreSearchBox = create("TextBox", { Name = "ScriptBloxSearchBox", Size = UDim2.new(1, -4, 0, 38), BackgroundColor3 = C.PanelAlt, BorderSizePixel = 0, ClearTextOnFocus = false, PlaceholderText = "Search scripts...", PlaceholderColor3 = C.Muted, Text = "", TextColor3 = C.Text, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left }, ScriptBloxPage)
UI.Round(StoreSearchBox, 7); UI.Stroke(StoreSearchBox, C.Blue, 0.45)
local StoreStatus = UI.Label(ScriptBloxPage, "Enter a search term or tap TRENDING.", 30, 10, C.Muted)
StoreStatus.TextWrapped = true
local function urlEncode(v) return (string.gsub(tostring(v or ""), "([^%w%-_%.~])", function(c) return string.format("%%%02X", string.byte(c)) end)) end
local function clearStoreCards() for _, c in ipairs(ScriptResultCards) do pcall(function() c:Destroy() end) end table.clear(ScriptResultCards) end
local function copyToClipboard(v) for _, n in ipairs({"setclipboard", "toclipboard", "setrbxclipboard"}) do if BuiltinModules.Executor.Call(n, v) then return true end end return false end
local function makeScriptCard(s)
    local card = create("Frame", { Size = UDim2.new(1, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Panel, BorderSizePixel = 0 }, ScriptBloxPage)
    table.insert(ScriptResultCards, card); UI.Round(card, 7); UI.Stroke(card, C.Blue, 0.55)
    local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 7); pad.PaddingBottom = UDim.new(0, 7); pad.PaddingLeft = UDim.new(0, 7); pad.PaddingRight = UDim.new(0, 7); pad.Parent = card
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 5); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = card
    local title = UI.Label(card, tostring(s.title or "Untitled"), 34, 11, C.Text); title.Font = Enum.Font.GothamBold; title.LayoutOrder = 1
    local gameName = (type(s.game) == "table" and s.game.name) and tostring(s.game.name) or "Unknown game"
    local meta = UI.Label(card, "Game: " .. gameName .. "\nViews: " .. tostring(s.views or 0), 42, 9, C.Muted); meta.LayoutOrder = 2
    local id = tostring(s.slug or s._id or "")
    local btn = UI.Button(card, "COPY SCRIPT SOURCE", function()
        task.spawn(function()
            local ok, src = pcall(function() return game:HttpGet(ScriptBloxBase .. "/api/script/raw/" .. urlEncode(id)) end)
            if ok and type(src) == "string" and #src > 0 then StoreStatus.Text = copyToClipboard(src) and "Source copied." or "Clipboard unavailable."
            else StoreStatus.Text = "Could not fetch source." end
        end)
    end, 31); btn.LayoutOrder = 3
end
local function fetchScriptBlox(endpoint, append, desc)
    if storeBusy then return end
    storeRequestId += 1; local reqId = storeRequestId; storeBusy = true; StoreStatus.Text = desc or "Loading..."
    if not append then clearStoreCards() end
    task.spawn(function()
        local ok, body = pcall(function() return game:HttpGet(endpoint) end)
        if reqId ~= storeRequestId then return end
        if not ok or type(body) ~= "string" or #body == 0 then storeBusy = false; StoreStatus.Text = "Request failed."; return end
        local decodeOK, payload = pcall(function() return HttpService:JSONDecode(body) end)
        if not decodeOK or type(payload) ~= "table" then storeBusy = false; StoreStatus.Text = "Invalid JSON."; return end
        local scripts = (type(payload.result) == "table" and payload.result.scripts) or nil
        if type(scripts) ~= "table" then storeBusy = false; StoreStatus.Text = "No results."; return end
        local count = 0
        for _, s in ipairs(scripts) do if type(s) == "table" then pcall(function() makeScriptCard(s) end); count += 1 end end
        storeBusy = false; StoreStatus.Text = tostring(count) .. " result(s)."
    end)
end
UI.Button(ScriptBloxPage, "SEARCH SCRIPTS", function()
    local q = string.gsub(StoreSearchBox.Text or "", "^%s*(.-)%s*$", "%1")
    if q == "" then StoreStatus.Text = "Type a search first." return end
    storeQuery = q; storePage = 1
    fetchScriptBlox(ScriptBloxBase .. "/api/script/search?q=" .. urlEncode(q) .. "&max=10&page=1&strict=" .. tostring(storeStrictMatch), false, "Searching...")
end)
UI.Button(ScriptBloxPage, "TRENDING SCRIPTS", function() fetchScriptBlox(ScriptBloxBase .. "/api/script/trending?max=10", false, "Loading trending...") end)

-- LOGS
UI.Label(LogsPage, "RUNTIME LOGS", 29, 14, C.Text).Font = Enum.Font.GothamBlack
info(LogsPage, "Shows status changes and errors.", 43, C.Muted)
local LogsOutput
refreshLogsPage = function()
    if not LogsOutput or not LogsOutput.Parent then return end
    if #RuntimeLogs == 0 then LogsOutput.Text = "No log entries yet." return end
    local lines = {}; local first = math.max(1, #RuntimeLogs - 59)
    for i = first, #RuntimeLogs do local e = RuntimeLogs[i]; table.insert(lines, "[" .. e.time .. "] " .. e.level .. " | " .. e.message) end
    LogsOutput.Text = table.concat(lines, "\n")
end
UI.Button(LogsPage, "REFRESH LOGS", function() refreshLogsPage() end)
UI.Button(LogsPage, "CLEAR LOGS", function() table.clear(RuntimeLogs) refreshLogsPage() end)
LogsOutput = UI.Label(LogsPage, "No log entries yet.", 40, 10, C.Text); LogsOutput.Size = UDim2.new(1, -4, 0, 0); LogsOutput.AutomaticSize = Enum.AutomaticSize.Y; LogsOutput.TextXAlignment = Enum.TextXAlignment.Left; LogsOutput.TextYAlignment = Enum.TextYAlignment.Top; LogsOutput.Font = Enum.Font.Code
refreshLogsPage()

-- EXECUTOR
UI.Label(ExecutorPage, "EXECUTOR HUB", 29, 14, C.Text).Font = Enum.Font.GothamBlack
info(ExecutorPage, "Editor and console for code you trust.", 48, C.Muted)
local ExecutorEditor = create("TextBox", { Size = UDim2.new(1, -4, 0, 190), BackgroundColor3 = C.PanelAlt, BorderSizePixel = 0, ClearTextOnFocus = false, MultiLine = true, Text = "-- EPIC PLANETS editor\nprint('Hello from EPIC PLANETS')", TextColor3 = C.Text, PlaceholderText = "Write Luau here...", PlaceholderColor3 = C.Muted, TextSize = 11, Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = false }, ExecutorPage)
UI.Round(ExecutorEditor, 7); UI.Stroke(ExecutorEditor, C.Blue, 0.45)
local ExecutorStatus = UI.Label(ExecutorPage, "Ready.", 38, 10, C.Muted)
UI.Button(ExecutorPage, "EXECUTE EDITOR CODE", function()
    local src = ExecutorEditor.Text or ""
    if string.gsub(src, "%s", "") == "" then ExecutorStatus.Text = "Editor is empty." return end
    local loadFn = BuiltinModules.Executor.Get("loadstring")
    if not loadFn then ExecutorStatus.Text = "loadstring unavailable." return end
    task.spawn(function()
        local cOK, chunk = pcall(loadFn, src)
        if not cOK or type(chunk) ~= "function" then ExecutorStatus.Text = "Compile failed." return end
        local rOK, res = pcall(chunk)
        ExecutorStatus.Text = rOK and "Execution finished." or ("Runtime error: " .. tostring(res))
    end)
end, 36)
UI.Button(ExecutorPage, "CLEAR EDITOR", function() ExecutorEditor.Text = "" end, 32)

----------------------------------------------------------------
-- PERSONALIZATION, HOME, PLAYER, ETC.
----------------------------------------------------------------
local MusicTracks = {
    ["DM iostesso"] = { URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/dm_iostesso.ft2.mp3", File = "EpicPlanets/EP_Music_DM_iostesso.mp3" },
    ["Screenrecorder"] = { URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/Screenrecorder-2026-09-18-20-34-50-385.mp3", File = "EpicPlanets/Screenrecorder-2026-09-18-20-34-50-385.mp3" },
    ["Madness Combat 2"] = { URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/Madness%20Combat%202%20Sheriff%20Town%20%5BHigh%20Quality%20%20Mono-like%5D%20-%20Demirgon%20%F0%9F%87%B7%F0%9F%87%BA%20%28youtube%29.mp3", File = "EpicPlanets/EP_Music_Madness_Combat_2.mp3" },
    ["Heads Will Roll"] = { URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/Heads%20Will%20Roll%20%28A-Trak%20Remix%20Radio%20Edit%29%20-%20Yeah%20Yeah%20Yeahs%20%28youtube%29.mp3", File = "EpicPlanets/EP_Music_Heads_Will_Roll.mp3" },
    ["Tetris Theme"] = { URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/Classicals.de%2B-%2BTetris%2BTheme%2B-%2BKorobeiniki%2B-%2BRearranged%2B-%2BArranged%2Bfor%2BMusic%2BBox.mp3", File = "EpicPlanets/EP_Music_Tetris_Theme.mp3" },
}
local TouchTracks = {
    ["Maro Jump"] = { URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/maro-jump-sound-effect_1.mp3", File = "EpicPlanets/EP_Touch_Maro_Jump.mp3" },
    ["ULTRAKILL Parry"] = { URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/parry-ultrakill.mp3", File = "EpicPlanets/EP_Touch_ULTRAKILL_Parry.mp3" },
    ["Sonic Spindash"] = { URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/sonic-spindash.mp3", File = "EpicPlanets/EP_Touch_Sonic_Spindash.mp3" },
}
local MusicOrder = { "Screenrecorder", "None", "DM iostesso", "Madness Combat 2", "Heads Will Roll", "Tetris Theme" }
local TouchOrder = { "None", "Maro Jump", "ULTRAKILL Parry", "Sonic Spindash" }
local selectedMusic, selectedTouch = "Screenrecorder", "None"
local personalAudioCache = ENV.__EPIC_PLANETS_PERSONAL_AUDIO_SOUNDS
local introFlashHappened = false

local function stopPersonalMusic() for key, sound in pairs(personalAudioCache) do if string.sub(tostring(key), 1, 6) == "Music:" then pcall(function() sound:Stop() end) end end end
local function preparePersonalAudio(kind, name)
    if name == "None" then return nil, "None selected" end
    local tracks = kind == "Music" and MusicTracks or TouchTracks; local track = tracks[name]
    if not track then return nil, "Unknown audio" end
    local cacheKey = kind .. ":" .. name; local cached = personalAudioCache[cacheKey]
    if cached and cached.Parent then cached.Looped = kind == "Music"; return cached end
    if kind == "Music" and name == "Screenrecorder" then
        local orig = ENV.__EPIC_PLANETS_FLASH_SOUND
        if orig and orig.Parent then orig.Name = "EPIC_PLANETS_MUSIC_SCREENRECORDER"; orig.Looped = true; personalAudioCache[cacheKey] = orig; return orig end
    end
    BuiltinModules.Executor.Call("makefolder", "EpicPlanets")
    local fileOK, fileExists = BuiltinModules.Executor.Call("isfile", track.File)
    if not fileOK or fileExists ~= true then
        local dlOK, data = pcall(function() return game:HttpGet(track.URL) end)
        if not dlOK or type(data) ~= "string" or #data == 0 then return nil, "Download failed" end
        BuiltinModules.Executor.Call("writefile", track.File, data)
    end
    local assetOK, assetId = BuiltinModules.Executor.Call("getcustomasset", track.File)
    if not assetOK or type(assetId) ~= "string" then return nil, "Asset API unavailable" end
    local sound = Instance.new("Sound"); sound.Name = "EPIC_PLANETS_" .. kind .. "_" .. name:gsub("%W", "_"); sound.SoundId = assetId; sound.Looped = kind == "Music"; sound.Parent = SoundService
    personalAudioCache[cacheKey] = sound; return sound
end
local function playPersonalMusic(name, restart)
    stopPersonalMusic(); if name == "None" then setStatus("Music disabled") return false end
    local sound, err = preparePersonalAudio("Music", name); if not sound then setStatus("Music error: " .. tostring(err)) return false end
    sound.Looped = true; pcall(function() if restart then sound.TimePosition = 0 end sound:Play() end); setStatus("Music: " .. name); return true
end
local function playPersonalTouch()
    if selectedTouch == "None" then return end
    local sound = preparePersonalAudio("Touch", selectedTouch); if not sound then return end
    pcall(function() sound.Looped = false; sound:Stop(); sound.TimePosition = 0; sound:Play() end)
end
BuiltinModules.Audio.PlayFlash = function() introFlashHappened = true; if not BuiltinModules.Settings.FlashAudio then stopPersonalMusic() return end; playPersonalMusic(selectedMusic, true) end

UI.Label(PersonalizationPage, "PERSONALIZATION", 28, 15, C.Text).Font = Enum.Font.GothamBlack
info(PersonalizationPage, "Choose music and touch sounds.", 42)
local musicChoiceButton
local function refreshMusicChoice() if musicChoiceButton and musicChoiceButton.Parent then musicChoiceButton.Text = "MUSIC: " .. selectedMusic .. "  [TAP TO CHANGE]" end end
musicChoiceButton = UI.Button(PersonalizationPage, "MUSIC: Screenrecorder  [TAP TO CHANGE]", function()
    local idx = table.find(MusicOrder, selectedMusic) or 1; selectedMusic = MusicOrder[(idx % #MusicOrder) + 1]; refreshMusicChoice()
    if selectedMusic == "None" then stopPersonalMusic() elseif introFlashHappened then playPersonalMusic(selectedMusic, true) end
end, 43)
UI.Button(PersonalizationPage, "PLAY MUSIC PREVIEW", function() task.spawn(function() playPersonalMusic(selectedMusic, true) end) end, 38)
UI.Button(PersonalizationPage, "STOP MUSIC", function() stopPersonalMusic() setStatus("Music stopped") end, 38)
UI.Label(PersonalizationPage, "TOUCH SOUND", 22, 12, C.Text).Font = Enum.Font.GothamBold
local touchChoiceButton
local function refreshTouchChoice() if touchChoiceButton and touchChoiceButton.Parent then touchChoiceButton.Text = "TOUCH SOUND: " .. selectedTouch .. "  [TAP TO CHANGE]" end end
touchChoiceButton = UI.Button(PersonalizationPage, "TOUCH SOUND: None  [TAP TO CHANGE]", function()
    local idx = table.find(TouchOrder, selectedTouch) or 1; selectedTouch = TouchOrder[(idx % #TouchOrder) + 1]; refreshTouchChoice()
end, 43)
UI.Button(PersonalizationPage, "PLAY TOUCH SOUND PREVIEW", function() task.spawn(playPersonalTouch) end, 38)

local function hookPersonalTouch(object)
    if not object or not (object:IsA("TextButton") or object:IsA("ImageButton")) then return end
    if object:GetAttribute("EP_PersonalTouchHooked") then return end
    object:SetAttribute("EP_PersonalTouchHooked", true); connect(object.Activated, function() playPersonalTouch() end)
end
for _, obj in ipairs(GUI:GetDescendants()) do hookPersonalTouch(obj) end
connect(GUI.DescendantAdded, function(obj) task.defer(function() if GUI.Parent then hookPersonalTouch(obj) end end) end)
task.spawn(function() preparePersonalAudio("Music", selectedMusic) end)

-- HOME, PLAYER, BUILTINS, MOVESETS, MODELS, SETTINGS
UI.Label(HomePage, "EPIC PLANETS", 28, 16, C.Text).Font = Enum.Font.GothamBlack
info(HomePage, "Dark modular interface with 321-fragment intro, planets, audio and built-in components.", 54)
info(HomePage, "Player: " .. Player.Name, 24, C.Text)
info(HomePage, "Place ID: " .. tostring(game.PlaceId), 24)
info(HomePage, "BuiltinModules: " .. BuiltinModules.Version, 24, C.Blue)
UI.Button(HomePage, "OPEN BUILTINMODULES", function() showPage("BuiltinModules") end)
UI.Button(HomePage, "MINIMIZE TO EP ICON", function() Hub.Visible = false MiniContainer.Visible = true updateGameBlur(false) end)

UI.Label(PlayerPage, "PLAYER CONTROLS", 27, 14, C.Text).Font = Enum.Font.GothamBold
info(PlayerPage, "Client-side movement controls.", 44)
local speedEnabled, jumpEnabled, flyEnabled = false, false, false
local oldSpeed, oldJumpPower, oldJumpHeight, flyVelocity, flyGyro, vertical = nil, nil, nil, nil, nil, 0
local function getCharacterParts() local c = Player.Character; if not c then return nil, nil end return c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart") end
UI.Button(PlayerPage, "TOGGLE SPEED", function(btn)
    local h = getCharacterParts(); if not h then setStatus("Character not ready") return end
    if not speedEnabled then oldSpeed = h.WalkSpeed; h.WalkSpeed = 32; speedEnabled = true; btn.Text = "SPEED: ON"
    else if oldSpeed then h.WalkSpeed = oldSpeed end; speedEnabled = false; btn.Text = "TOGGLE SPEED" end
end)
UI.Button(PlayerPage, "TOGGLE HIGH JUMP", function(btn)
    local h = getCharacterParts(); if not h then setStatus("Character not ready") return end
    if not jumpEnabled then
        oldJumpPower = h.JumpPower; oldJumpHeight = h.JumpHeight
        if h.UseJumpPower then h.JumpPower = 100 else h.JumpHeight = 50 end
        jumpEnabled = true; btn.Text = "HIGH JUMP: ON"
    else
        if h.UseJumpPower then if oldJumpPower then h.JumpPower = oldJumpPower end else if oldJumpHeight then h.JumpHeight = oldJumpHeight end end
        jumpEnabled = false; btn.Text = "TOGGLE HIGH JUMP"
    end
end)
local function setFly(en)
    local h, r = getCharacterParts(); if en and (not h or not r) then setStatus("Character not ready") return end
    if en then
        if flyVelocity then flyVelocity:Destroy() end; if flyGyro then flyGyro:Destroy() end
        flyVelocity = create("BodyVelocity", { MaxForce = Vector3.new(1e9,1e9,1e9), P = 12000, Velocity = Vector3.zero }, r)
        flyGyro = create("BodyGyro", { MaxTorque = Vector3.new(1e9,1e9,1e9), P = 9000, CFrame = r.CFrame }, r)
        h.AutoRotate = false; flyEnabled = true; vertical = 0
    else
        flyEnabled = false; vertical = 0; if flyVelocity then flyVelocity:Destroy() end; if flyGyro then flyGyro:Destroy() end; flyVelocity = nil; flyGyro = nil; if h then h.AutoRotate = true end
    end
end
UI.Button(PlayerPage, "TOGGLE FLY", function(btn) setFly(not flyEnabled) btn.Text = flyEnabled and "FLY: ON" or "TOGGLE FLY" end)

UI.Label(BuiltinPage, "BUILTINMODULES", 27, 14, C.Text).Font = Enum.Font.GothamBlack
info(BuiltinPage, "Internal components of Main.lua.", 32)
UI.Button(BuiltinPage, "REPLAY FLASH AUDIO", function() BuiltinModules.Audio.PlayFlash() end)
info(BuiltinPage, "The title 'don't touch In builtinmodules' is one of the random titles.", 42, C.Blue)

UI.Label(MovesetsPage, "MOVESETS / MODULES", 27, 14, C.Text).Font = Enum.Font.GothamBold
info(MovesetsPage, "Local .lua modules folder:", 32); info(MovesetsPage, BuiltinModules.ModuleLoader.Folder, 30, C.Blue)
local moduleList = create("Frame", { Size = UDim2.new(1, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, MovesetsPage)
local moduleLayout = Instance.new("UIListLayout"); moduleLayout.Padding = UDim.new(0, 6); moduleLayout.SortOrder = Enum.SortOrder.LayoutOrder; moduleLayout.Parent = moduleList
local function refreshModules()
    for _, c in ipairs(moduleList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    local files, msg = BuiltinModules.ModuleLoader.List(); if not files then info(moduleList, msg or "Could not scan.", 44, C.Red) return end
    local count = 0
    for _, p in ipairs(files) do if type(p) == "string" and p:lower():sub(-4) == ".lua" then
        count += 1; local fp = p; local fn = p:match("[^/\\]+$") or p
        UI.Button(moduleList, "RUN  " .. fn, function() local ok, res = BuiltinModules.ModuleLoader.Run(fp); setStatus(ok and res or ("Error: " .. tostring(res))) end, 38)
    end end
    if count == 0 then info(moduleList, "No .lua files found.", 45) end
end
UI.Button(MovesetsPage, "REFRESH MODULES", refreshModules)

UI.Label(ModelsPage, "MODEL STORE", 27, 14, C.Text).Font = Enum.Font.GothamBold
info(ModelsPage, "Install client-side visual models.", 42)
local installedModels = ENV.__EPIC_PLANETS_MODELS
local function createOrbitalCore()
    local c = Player.Character; local h = c and c:FindFirstChild("Head"); if not h then setStatus("Head not ready") return end
    for _, e in ipairs(installedModels) do if type(e) == "table" and e.model and e.model.Name == "EP_OrbitalCore" then pcall(function() e.model:Destroy() end) end end
    table.clear(installedModels)
    local m = Instance.new("Model", Workspace); m.Name = "EP_OrbitalCore"
    local cPart = Instance.new("Part", m); cPart.Shape = Enum.PartType.Ball; cPart.Size = Vector3.new(1.1,1.1,1.1); cPart.Anchored = true; cPart.CanCollide = false; cPart.Material = Enum.Material.Neon; cPart.Color = C.Blue
    local ps = {}
    for i = 1, 4 do local p = Instance.new("Part", m); p.Shape = Enum.PartType.Ball; p.Size = Vector3.new(0.34,0.34,0.34); p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Neon; p.Color = PlanetColors[i]; ps[i] = p end
    m.PrimaryPart = cPart; table.insert(installedModels, { model = m, center = cPart, planets = ps }); setStatus("Orbital Core installed")
end
UI.Button(ModelsPage, "ADD ORBITAL CORE TO HEAD", createOrbitalCore)
UI.Button(ModelsPage, "REMOVE ALL", function() for _, e in ipairs(installedModels) do if type(e) == "table" and e.model then pcall(function() e.model:Destroy() end) end end table.clear(installedModels) end)
task.spawn(function() for _ = 1, 20 do if Player.Character and Player.Character:FindFirstChild("Head") then createOrbitalCore() return end task.wait(0.25) end end)

UI.Label(SettingsPage, "SETTINGS", 27, 14, C.Text).Font = Enum.Font.GothamBold
info(SettingsPage, "Configure EPIC PLANETS.", 36)
UI.Button(SettingsPage, "RANDOMIZE TITLE", function()
    local old = Title; repeat Title = BuiltinModules.Titles[math.random(1, #BuiltinModules.Titles)] until #BuiltinModules.Titles == 1 or Title ~= old
    Header.Text = Title; IntroTitle.Text = Title
end)
UI.Button(SettingsPage, "TOGGLE FLASH AUDIO", function(btn) BuiltinModules.Settings.FlashAudio = not BuiltinModules.Settings.FlashAudio; btn.Text = BuiltinModules.Settings.FlashAudio and "FLASH AUDIO: ON" or "FLASH AUDIO: OFF" end)

----------------------------------------------------------------
-- WINDOW CONTROLS & DRAG
----------------------------------------------------------------
connect(Minimize.Activated, function() Hub.Visible = false; MiniContainer.Visible = true; updateGameBlur(false) end)
connect(Mini.Activated, function()
    MiniContainer.Visible = false; Hub.Visible = true
    Hub.Size = UDim2.new(0.7, 0, 0.55, 0); Hub.BackgroundTransparency = 1
    tween(Hub, 0.45, { Size = UDim2.new(0.91, 0, 0.74, 0), BackgroundTransparency = 0 }, Enum.EasingStyle.Back)
    updateGameBlur(true)
end)
connect(TapIn.Activated, function()
    IntroStatus.Text = "SYSTEMS READY"
    tween(IntroPanel, 0.22, { BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.48) })
    task.wait(0.23)
    Intro.Visible = false; Hub.Visible = true
    Hub.Size = UDim2.new(0.84, 0, 0.68, 0); Hub.BackgroundTransparency = 1
    tween(Hub, 0.28, { Size = UDim2.new(0.91, 0, 0.74, 0), BackgroundTransparency = 0 }, Enum.EasingStyle.Back)
    showPage("Home"); updateGameBlur(true)
end)

local dragging = false; local dragStart, startPosition, activeTouch, dragInput
local function stopDragging() dragging = false; dragStart = nil; startPosition = nil; activeTouch = nil; dragInput = nil end
local function applyDrag(input)
    if not dragging or not dragStart or not startPosition then return end
    local camera = Workspace.CurrentCamera; local viewport = camera and camera.ViewportSize; if not viewport then return end
    local delta = input.Position - dragStart
    local startCenterX = viewport.X * startPosition.X.Scale + startPosition.X.Offset
    local startCenterY = viewport.Y * startPosition.Y.Scale + startPosition.Y.Offset
    local centerX = startCenterX + delta.X; local centerY = startCenterY + delta.Y
    local halfW = Hub.AbsoluteSize.X / 2; local halfH = Hub.AbsoluteSize.Y / 2
    local marginX, marginY = 40, 28
    local minX, maxX, minY, maxY
    if Hub.AbsoluteSize.X <= viewport.X then minX, maxX = halfW, viewport.X - halfW else minX, maxX = marginX - halfW, viewport.X - marginX + halfW end
    if Hub.AbsoluteSize.Y <= viewport.Y then minY, maxY = halfH, viewport.Y - halfH else minY, maxY = marginY - halfH, viewport.Y - marginY + halfH end
    centerX = math.clamp(centerX, minX, maxX); centerY = math.clamp(centerY, minY, maxY)
    Hub.Position = UDim2.new(startPosition.X.Scale, centerX - viewport.X * startPosition.X.Scale, startPosition.Y.Scale, centerY - viewport.Y * startPosition.Y.Scale)
end
connect(Header.InputBegan, function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    dragging = true; dragStart = input.Position; startPosition = Hub.Position
    activeTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
end)
connect(Header.InputChanged, function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
connect(UserInputService.InputChanged, function(input)
    if dragging and dragInput and input == dragInput then applyDrag(input)
    elseif dragging and input.UserInputType == Enum.UserInputType.MouseMovement and activeTouch == nil then applyDrag(input) end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then stopDragging()
    elseif activeTouch and input == activeTouch then stopDragging() end
end)

local draggingMini = false; local miniDragStart, miniStartPos
connect(Mini.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMini = true; miniDragStart = input.Position; miniStartPos = MiniContainer.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    if draggingMini and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - miniDragStart
        MiniContainer.Position = UDim2.new(miniStartPos.X.Scale, miniStartPos.X.Offset + delta.X, miniStartPos.Y.Scale, miniStartPos.Y.Offset + delta.Y)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingMini = false end
end)

----------------------------------------------------------------
-- ANIMATIONS & RENDER LOOP
----------------------------------------------------------------
BuiltinModules.Animations = {}
function BuiltinModules.Animations.PlayIntro()
    local total = #Fragments
    for i, fragment in ipairs(Fragments) do
        if not GUI.Parent then return end
        local x = ((i - 1) % 29) / 28; local y = math.floor((i - 1) / 29) / 11
        tween(fragment, 0.38 + math.random() * 0.42, { Position = UDim2.fromScale(x, math.clamp(y, 0, 1)) }, Enum.EasingStyle.Quint)
        if i % 5 == 0 or i == total then
            tween(Progress, 0.12, { Size = UDim2.new(i / total, 0, 1, 0) })
            FragmentCount.Text = i .. " / " .. total
        end
        task.wait(0.002)
    end
    task.wait(0.55)
    IntroStatus.Text = "ALL FRAGMENTS CONNECTED"
    for _, fragment in ipairs(Fragments) do fragment.BackgroundColor3 = C.Text end
    BuiltinModules.Audio.PlayFlash()
    tween(IntroPanel, 0.08, { BackgroundColor3 = Color3.fromRGB(90, 95, 115) })
    task.wait(0.1)
    tween(IntroPanel, 0.16, { BackgroundColor3 = C.Panel })
    for _, fragment in ipairs(Fragments) do tween(fragment, 1.45, { BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Sine) end
    tween(Progress, 1.45, { BackgroundTransparency = 1 }); tween(FragmentCount, 1.45, { TextTransparency = 1 })
    task.wait(1.55)
    if not GUI.Parent then return end
    FragmentArea.Visible = false; IntroStatus.Text = "ALL SYSTEMS READY"
    TapIn.Visible = true; TapIn.BackgroundTransparency = 1; TapIn.TextTransparency = 1
    tween(TapIn, 0.45, { BackgroundTransparency = 0, TextTransparency = 0 })
end

local rainbowObjects = {}
for _, object in ipairs(GUI:GetDescendants()) do if object:IsA("UIStroke") then table.insert(rainbowObjects, object) end end

connect(RunService.RenderStepped, function()
    local now = os.clock(); local hue = (now * 0.12) % 1
    if BuiltinModules.Settings.Rainbow then
        for _, stroke in ipairs(rainbowObjects) do
            if stroke and stroke.Parent then stroke.Color = Color3.fromHSV((hue + 0.025) % 1, 0.88, 1) end
        end
    end
    if Intro.Visible then
        for i, planet in ipairs(Planets) do
            local angle = now * (0.75 + i * 0.12) + (i - 1) * math.pi / 2
            planet.Position = UDim2.fromOffset(75 + math.cos(angle) * 42, 54 + math.sin(angle) * 32)
        end
        Core.Rotation = (now * 35) % 360
    end
    if flyEnabled then
        local humanoid, root = getCharacterParts()
        if not humanoid or not root or not flyVelocity or not flyVelocity.Parent then setFly(false)
        else
            flyVelocity.Velocity = humanoid.MoveDirection * 48 + Vector3.new(0, vertical * 38, 0)
            local camera = Workspace.CurrentCamera
            if camera and flyGyro and flyGyro.Parent then flyGyro.CFrame = CFrame.new(root.Position, root.Position + camera.CFrame.LookVector) end
        end
    end
    if Hub.Visible then
        for _, starData in ipairs(HubStars) do
            local star = starData.frame
            if star and star.Parent then
                local newY = star.Position.Y.Scale + starData.speed
                if newY > 1 then newY = 0; star.Position = UDim2.new(math.random(), 0, 0, 0)
                else local xOscillation = math.sin(now * 2 + starData.offset) * 0.02; star.Position = UDim2.new(star.Position.X.Scale + xOscillation, 0, newY, 0) end
                star.BackgroundColor3 = Color3.fromHSV(hue, 0.6, 1)
            end
        end
    end
    if MiniContainer.Visible then
        local rColor = Color3.fromHSV(hue, 0.9, 1)
        MiniStroke.Color = rColor; BlurStroke.Color = rColor
        if math.random(1, 8) == 1 then spawnMiniSpark() end
    end
end)

connect(Player.CharacterAdded, function()
    task.wait(0.8); local humanoid = getCharacterParts()
    if humanoid then
        if speedEnabled then oldSpeed = humanoid.WalkSpeed; humanoid.WalkSpeed = 32 end
        if jumpEnabled then oldJumpPower = humanoid.JumpPower; oldJumpHeight = humanoid.JumpHeight; if humanoid.UseJumpPower then humanoid.JumpPower = 100 else humanoid.JumpHeight = 50 end end
    end
    if flyEnabled then setFly(false) end
end)

----------------------------------------------------------------
-- TETRIS
----------------------------------------------------------------
UI.Label(TetrisPage, "TETRIS", 29, 16, C.Text).Font = Enum.Font.GothamBlack
info(TetrisPage, "Play classic Tetris in a separate window with themed music.", 44)
info(TetrisPage, "PC: ← → move · ↑/W rotate · ↓/S soft drop · Space = hard drop", 32, C.Blue)
info(TetrisPage, "Mobile: use the on-screen buttons", 24)

local TetrisGUI = create("ScreenGui", { Name = "EPIC_PLANETS_TETRIS", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false }, PlayerGui)
ENV.__EPIC_PLANETS_TETRIS_GUI = TetrisGUI
local TCOLS, TROWS, TCELL = 10, 20, 18
local SHAPES = { I = {{0,0,0,0},{1,1,1,1},{0,0,0,0},{0,0,0,0}}, O = {{1,1},{1,1}}, T = {{0,1,0},{1,1,1},{0,0,0}}, S = {{0,1,1},{1,1,0},{0,0,0}}, Z = {{1,1,0},{0,1,1},{0,0,0}}, J = {{1,0,0},{1,1,1},{0,0,0}}, L = {{0,0,1},{1,1,1},{0,0,0}} }
local SHAPE_COLORS = { I = Color3.fromRGB(0,240,240), O = Color3.fromRGB(240,240,0), T = Color3.fromRGB(170,0,240), S = Color3.fromRGB(0,240,0), Z = Color3.fromRGB(240,0,0), J = Color3.fromRGB(0,80,240), L = Color3.fromRGB(240,160,0) }

local TWin = create("Frame", { Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(400, 580), BackgroundColor3 = C.Panel, BorderSizePixel = 0 }, TetrisGUI)
UI.Round(TWin, 12); UI.Stroke(TWin, C.Purple, 0.05)
local TScale = Instance.new("UIScale"); TScale.Parent = TWin
local TNATIVE_W, TNATIVE_H = 400, 580
local function updateTetrisScale()
    local camera = Workspace.CurrentCamera; if not camera then return end
    local vp = camera.ViewportSize
    local sx = (vp.X * 0.92) / TNATIVE_W; local sy = (vp.Y * 0.92) / TNATIVE_H
    local scale = math.clamp(math.min(1, sx, sy), 0.45, 1)
    TScale.Scale = scale; TWin.Position = UDim2.new(0.5, TNATIVE_W * (1 - scale) / 2, 0.5, TNATIVE_H * (1 - scale) / 2)
end
updateTetrisScale()

local THeader = create("TextButton", { Active = true, AutoButtonColor = false, Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -90, 0, 28), BackgroundTransparency = 1, Text = "TETRIS  ♪", TextColor3 = C.Text, TextSize = 18, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left }, TWin)
local TClose = create("TextButton", { Position = UDim2.new(1, -42, 0, 8), Size = UDim2.fromOffset(30, 28), BackgroundColor3 = C.PanelAlt, BorderSizePixel = 0, Text = "×", TextColor3 = C.Text, TextSize = 19, Font = Enum.Font.GothamBold }, TWin)
UI.Round(TClose, 6); UI.Stroke(TClose, C.Purple, 0.3)

local TBoard = create("Frame", { Position = UDim2.fromOffset(15, 55), Size = UDim2.fromOffset(TCOLS * TCELL, TROWS * TCELL), BackgroundColor3 = C.Background, BorderSizePixel = 0 }, TWin)
UI.Round(TBoard, 4); UI.Stroke(TBoard, C.Purple, 0.35)
local TCells = {}
for r = 1, TROWS do
    TCells[r] = {}
    for c = 1, TCOLS do
        local cell = create("Frame", { Position = UDim2.fromOffset((c-1)*TCELL, (r-1)*TCELL), Size = UDim2.fromOffset(TCELL-1, TCELL-1), BackgroundColor3 = C.PanelAlt, BackgroundTransparency = 0.75, BorderSizePixel = 0 }, TBoard)
        UI.Round(cell, 2); TCells[r][c] = cell
    end
end

local TNextFrame = create("Frame", { Position = UDim2.fromOffset(210, 55), Size = UDim2.fromOffset(175, 130), BackgroundColor3 = C.Background, BorderSizePixel = 0 }, TWin)
UI.Round(TNextFrame, 6); UI.Stroke(TNextFrame, C.Purple, 0.35)
create("TextLabel", { Position = UDim2.new(0,0,0,4), Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, Text = "NEXT", TextColor3 = C.Muted, TextSize = 10, Font = Enum.Font.GothamBold }, TNextFrame)
local NCELL = 20
local TNextGrid = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 8), Size = UDim2.fromOffset(4*NCELL, 4*NCELL), BackgroundTransparency = 1 }, TNextFrame)
local TNextCells = {}
for r = 1, 4 do
    TNextCells[r] = {}
    for c = 1, 4 do
        local cell = create("Frame", { Position = UDim2.fromOffset((c-1)*NCELL, (r-1)*NCELL), Size = UDim2.fromOffset(NCELL-2, NCELL-2), BackgroundTransparency = 1, BorderSizePixel = 0 }, TNextGrid)
        UI.Round(cell, 2); TNextCells[r][c] = cell
    end
end

local TStats = create("Frame", { Position = UDim2.fromOffset(210, 195), Size = UDim2.fromOffset(175, 130), BackgroundColor3 = C.Background, BorderSizePixel = 0 }, TWin)
UI.Round(TStats, 6); UI.Stroke(TStats, C.Purple, 0.35)
local function makeStat(parent, order, label)
    create("TextLabel", { Position = UDim2.new(0,8,0,order), Size = UDim2.new(1,-16,0,20), BackgroundTransparency = 1, Text = label, TextColor3 = C.Muted, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, parent)
    return create("TextLabel", { Position = UDim2.new(0,8,0,order), Size = UDim2.new(1,-16,0,20), BackgroundTransparency = 1, Text = "0", TextColor3 = C.Text, TextSize = 13, Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Right }, parent)
end
local TScoreLbl = makeStat(TStats, 4, "SCORE"); local TLinesLbl = makeStat(TStats, 30, "LINES"); local TLevelLbl = makeStat(TStats, 56, "LEVEL"); local TBestLbl  = makeStat(TStats, 82, "BEST")

local TCtrl = create("Frame", { Position = UDim2.fromOffset(15, 430), Size = UDim2.new(1, -30, 0, 130), BackgroundTransparency = 1 }, TWin)
local function tbtn(x, y, w, h, txt, col)
    local b = create("TextButton", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = col or C.PanelAlt, BorderSizePixel = 0, Text = txt, TextColor3 = C.Text, TextSize = 18, Font = Enum.Font.GothamBlack }, TCtrl)
    UI.Round(b, 8); UI.Stroke(b, C.Purple, 0.4); return b
end
local BtnLeft  = tbtn(0, 40, 60, 55, "◀"); local BtnDown  = tbtn(65, 40, 60, 55, "▼"); local BtnRight = tbtn(130, 40, 60, 55, "▶"); local BtnRot   = tbtn(200, 40, 60, 55, "↻", C.Blue); local BtnDrop  = tbtn(265, 40, 55, 55, "⤓", C.Purple)

local GameOverOverlay = create("Frame", { Position = UDim2.fromOffset(15, 55), Size = UDim2.fromOffset(TCOLS*TCELL, TROWS*TCELL), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.35, Visible = false, ZIndex = 5 }, TWin)
UI.Round(GameOverOverlay, 4)
create("TextLabel", { Position = UDim2.new(0,0,0.35,0), Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1, Text = "GAME OVER", TextColor3 = C.Red, TextSize = 22, Font = Enum.Font.GothamBlack }, GameOverOverlay)
local RestartBtn = create("TextButton", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromOffset(120, 36), BackgroundColor3 = C.Blue, BorderSizePixel = 0, Text = "RESTART", TextColor3 = C.Text, TextSize = 13, Font = Enum.Font.GothamBold, ZIndex = 6 }, GameOverOverlay)
UI.Round(RestartBtn, 6)

local board, curPiece, nxtPiece; local running, over = false, false; local score, lines, level, best = 0, 0, 1, 0; local dropAcc, dropInt = 0, 0.8; local gameConn
local function initBoard() board = {}; for r = 1, TROWS do board[r] = {}; for c = 1, TCOLS do board[r][c] = nil end end end
local function randomPiece() local names = {"I","O","T","S","Z","J","L"}; local n = names[math.random(1, #names)]; return { name = n, shape = SHAPES[n], x = 4, y = 1 } end
local function rotateMatrix(m) local rows, cols = #m, #m[1]; local out = {}; for i = 1, cols do out[i] = {}; for j = 1, rows do out[i][j] = m[rows - j + 1][i] end end; return out end
local function fits(shape, x, y)
    for py = 1, #shape do for px = 1, #shape[py] do if shape[py][px] == 1 then local bx, by = x + px - 1, y + py - 1; if bx < 1 or bx > TCOLS or by > TROWS then return false end; if by >= 1 and board[by][bx] then return false end end end end
    return true
end
local function lockPiece()
    local p = curPiece
    for py = 1, #p.shape do for px = 1, #p.shape[py] do if p.shape[py][px] == 1 then local bx, by = p.x + px - 1, p.y + py - 1; if by >= 1 and by <= TROWS and bx >= 1 and bx <= TCOLS then board[by][bx] = SHAPE_COLORS[p.name] end end end end
    local cleared = 0
    for r = TROWS, 1, -1 do local full = true; for c = 1, TCOLS do if not board[r][c] then full = false; break end end; if full then cleared += 1; table.remove(board, r); table.insert(board, 1, {}); for c = 1, TCOLS do board[1][c] = nil end end end
    if cleared > 0 then local pts = {0, 100, 300, 500, 800}; score += pts[cleared] * level; lines += cleared; level = math.floor(lines / 10) + 1; dropInt = math.max(0.1, 0.8 - (level - 1) * 0.06); if score > best then best = score end end
    curPiece = nxtPiece; curPiece.x, curPiece.y = 4, 1; nxtPiece = randomPiece()
    if not fits(curPiece.shape, curPiece.x, curPiece.y) then over = true; running = false; GameOverOverlay.Visible = true end
end
local function moveDown() if not curPiece then return end; if fits(curPiece.shape, curPiece.x, curPiece.y + 1) then curPiece.y += 1 else lockPiece() end end
local function moveLeft() if curPiece and fits(curPiece.shape, curPiece.x - 1, curPiece.y) then curPiece.x -= 1 end end
local function moveRight() if curPiece and fits(curPiece.shape, curPiece.x + 1, curPiece.y) then curPiece.x += 1 end end
local function rotatePiece() if not curPiece then return end; local rot = rotateMatrix(curPiece.shape); if fits(rot, curPiece.x, curPiece.y) then curPiece.shape = rot end end
local function hardDrop() if not curPiece then return end; while fits(curPiece.shape, curPiece.x, curPiece.y + 1) do curPiece.y += 1 end; lockPiece() end
local function renderTetris()
    for r = 1, TROWS do for c = 1, TCOLS do local cell = TCells[r][c]; if board[r][c] then cell.BackgroundColor3 = board[r][c]; cell.BackgroundTransparency = 0 else cell.BackgroundColor3 = C.PanelAlt; cell.BackgroundTransparency = 0.75 end end end
    if curPiece then for py = 1, #curPiece.shape do for px = 1, #curPiece.shape[py] do if curPiece.shape[py][px] == 1 then local bx, by = curPiece.x + px - 1, curPiece.y + py - 1; if bx >= 1 and bx <= TCOLS and by >= 1 and by <= TROWS then TCells[by][bx].BackgroundColor3 = SHAPE_COLORS[curPiece.name]; TCells[by][bx].BackgroundTransparency = 0 end end end end end
    for r = 1, 4 do for c = 1, 4 do TNextCells[r][c].BackgroundTransparency = 1 end end
    if nxtPiece then local s = nxtPiece.shape; local ox = math.floor((4 - #s[1]) / 2); local oy = math.floor((4 - #s) / 2); for py = 1, #s do for px = 1, #s[py] do if s[py][px] == 1 then local nx, ny = px + ox, py + oy; if nx >= 1 and nx <= 4 and ny >= 1 and ny <= 4 then TNextCells[ny][nx].BackgroundColor3 = SHAPE_COLORS[nxtPiece.name]; TNextCells[ny][nx].BackgroundTransparency = 0 end end end end end
    TScoreLbl.Text = tostring(score); TLinesLbl.Text = tostring(lines); TLevelLbl.Text = tostring(level); TBestLbl.Text  = tostring(best)
end
local lastTick = 0
local function startGame() initBoard(); curPiece = randomPiece(); nxtPiece = randomPiece(); score, lines, level = 0, 0, 1; dropInt = 0.8; dropAcc = 0; over = false; running = true; GameOverOverlay.Visible = false; lastTick = os.clock(); renderTetris() end
if gameConn then gameConn:Disconnect() end
gameConn = RunService.Heartbeat:Connect(function() if not running or over then return end; local now = os.clock(); dropAcc += (now - lastTick); lastTick = now; if dropAcc >= dropInt then dropAcc = 0; moveDown() end; renderTetris() end)
table.insert(Connections, gameConn)

local function openTetris() TetrisGUI.Enabled = true; updateTetrisScale(); if not running then startGame() end; stopPersonalMusic(); task.spawn(function() playPersonalMusic("Tetris Theme", true) end) end
local function closeTetris() TetrisGUI.Enabled = false; running = false; stopPersonalMusic(); if selectedMusic and selectedMusic ~= "None" then task.spawn(function() playPersonalMusic(selectedMusic, false) end) end end
UI.Button(TetrisPage, "🎮  OPEN TETRIS GAME", function() openTetris() end, 50)
UI.Button(HomePage, "🎮  PLAY TETRIS", function() openTetris() end, 42)
connect(TClose.Activated, closeTetris); connect(RestartBtn.Activated, function() startGame() end)

local function holdBtn(btn, action)
    local holding = false
    connect(btn.InputBegan, function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then holding = true; action(); task.spawn(function() task.wait(0.28); while holding do action(); task.wait(0.075) end end) end end)
    connect(btn.InputEnded, function() holding = false end)
end
holdBtn(BtnLeft, moveLeft); holdBtn(BtnRight, moveRight); holdBtn(BtnDown, moveDown); connect(BtnRot.Activated, rotatePiece); connect(BtnDrop.Activated, hardDrop)
connect(UserInputService.InputBegan, function(input, processed)
    if processed or not TetrisGUI.Enabled or not running then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.Left or k == Enum.KeyCode.A then moveLeft()
    elseif k == Enum.KeyCode.Right or k == Enum.KeyCode.D then moveRight()
    elseif k == Enum.KeyCode.Down or k == Enum.KeyCode.S then moveDown()
    elseif k == Enum.KeyCode.Up or k == Enum.KeyCode.W then rotatePiece()
    elseif k == Enum.KeyCode.Space or k == Enum.KeyCode.R then hardDrop() end
end)
local tDrag, tStart, tStartPos = false, nil, nil
connect(THeader.InputBegan, function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then tDrag = true; tStart = input.Position; tStartPos = TWin.Position end end)
connect(UserInputService.InputChanged, function(input) if tDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local d = input.Position - tStart; TWin.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + d.X, tStartPos.Y.Scale, tStartPos.Y.Offset + d.Y) end end)
connect(UserInputService.InputEnded, function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then tDrag = false end end)
task.spawn(function() preparePersonalAudio("Music", "Tetris Theme") end)

----------------------------------------------------------------
-- CREDITS
----------------------------------------------------------------
local function fetchRobloxUser(username)
    local ok, response = pcall(function() return HttpService:PostAsync("https://users.roblox.com/v1/usernames/users", HttpService:JSONEncode({ usernames = { username } }), Enum.HttpContentType.ApplicationJson) end)
    if not ok or type(response) ~= "string" then return nil, "HTTP failed" end
    local decodeOk, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not decodeOk or not data.data or #data.data == 0 then return nil, "User not found" end
    local user = data.data[1]; local userId = user.id; local displayName = user.displayName or user.name
    local thumbOk, thumbResponse = pcall(function() return game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. tostring(userId) .. "&size=150x150&format=Png&isCircular=false") end)
    local avatarUrl = nil
    if thumbOk and type(thumbResponse) == "string" then local thumbDecodeOk, thumbData = pcall(function() return HttpService:JSONDecode(thumbResponse) end); if thumbDecodeOk and thumbData.data and #thumbData.data > 0 then avatarUrl = thumbData.data[1].imageUrl end end
    return { id = userId, username = user.name, displayName = displayName, avatar = avatarUrl }
end
local CREDITS_DIRECTION = "down"; local CREDITS_SPEED = 30
local SponsorsData = { { username = "catblue", role = "Sponsor" }, { username = "sorvetepro", role = "Sponsor" } }
local AdminsData = { { username = "sorvetepro", role = "Administrator / Creator" } }
local CreditsCache = { sponsors = {}, admins = {} }
local function loadCreditsCache()
    local function enrich(list, out)
        for _, entry in ipairs(list) do
            local data = fetchRobloxUser(entry.username)
            if data then table.insert(out, { data = data, role = entry.role })
            else table.insert(out, { data = { username = entry.username, displayName = entry.username, avatar = nil }, role = entry.role .. " (offline)" }) end
        end
    end
    enrich(SponsorsData, CreditsCache.sponsors); enrich(AdminsData, CreditsCache.admins)
end

local CreditsPage = create("Frame", { Name = "CreditsPage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ClipsDescendants = true }, PageHost)
Pages["Credits"] = CreditsPage; addTab("Credits", "CREDITS", 12)
local CreditsScroll = create("Frame", { Name = "ScrollContent", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 0) }, CreditsPage)

local function renderUserCard(parent, userData, roleLabel, layoutOrder)
    local card = create("Frame", { Size = UDim2.new(1, -10, 0, 68), BackgroundColor3 = C.PanelAlt, BorderSizePixel = 0, LayoutOrder = layoutOrder }, parent)
    UI.Round(card, 8); UI.Stroke(card, C.Purple, 0.5)
    local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 5); pad.PaddingBottom = UDim.new(0, 5); pad.PaddingLeft = UDim.new(0, 7); pad.PaddingRight = UDim.new(0, 7); pad.Parent = card
    local avatarFrame = create("Frame", { Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(56, 56), BackgroundColor3 = C.Background, BorderSizePixel = 0 }, card)
    UI.Round(avatarFrame, 6); UI.Stroke(avatarFrame, C.Blue, 0.3)
    if userData.avatar then local img = create("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = userData.avatar }, avatarFrame); UI.Round(img, 6)
    else create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "?", TextColor3 = C.Muted, TextSize = 20, Font = Enum.Font.GothamBold }, avatarFrame) end
    create("TextLabel", { Position = UDim2.fromOffset(66, 4), Size = UDim2.new(1, -72, 0, 22), BackgroundTransparency = 1, Text = userData.displayName or userData.username, TextColor3 = C.Text, TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, card)
    create("TextLabel", { Position = UDim2.fromOffset(66, 22), Size = UDim2.new(1, -72, 0, 15), BackgroundTransparency = 1, Text = "@" .. userData.username, TextColor3 = C.Muted, TextSize = 10, Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Left }, card)
    create("TextLabel", { Position = UDim2.fromOffset(66, 38), Size = UDim2.new(1, -72, 0, 18), BackgroundTransparency = 1, Text = roleLabel or "", TextColor3 = C.Purple, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, card)
end

local creditsOrderBase = 0
local function renderCreditsCopy()
    creditsOrderBase += 1000; local base = creditsOrderBase
    local copy = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = base }, CreditsScroll)
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 10); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; layout.Parent = copy
    local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 50); pad.PaddingBottom = UDim.new(0, 50); pad.PaddingLeft = UDim.new(0, 6); pad.PaddingRight = UDim.new(0, 6); pad.Parent = copy
    create("TextLabel", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Text = "★  EPIC PLANETS  ★", TextColor3 = C.Purple, TextSize = 22, Font = Enum.Font.GothamBlack, LayoutOrder = base + 1 }, copy)
    create("TextLabel", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "— Credits —", TextColor3 = C.Muted, TextSize = 12, Font = Enum.Font.Gotham, LayoutOrder = base + 2 }, copy)
    create("TextLabel", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "SPONSORS", TextColor3 = C.Blue, TextSize = 15, Font = Enum.Font.GothamBlack, LayoutOrder = base + 10 }, copy)
    local o = base + 20
    for _, entry in ipairs(CreditsCache.sponsors) do renderUserCard(copy, entry.data, entry.role, o); o += 1 end
    create("TextLabel", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "ADMINISTRATORS", TextColor3 = C.Red, TextSize = 15, Font = Enum.Font.GothamBlack, LayoutOrder = base + 200 }, copy)
    o = base + 210
    for _, entry in ipairs(CreditsCache.admins) do renderUserCard(copy, entry.data, entry.role, o); o += 1 end
    create("TextLabel", { Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1, Text = "Thanks for using Epic Planets!\n♥", TextColor3 = C.Muted, TextSize = 12, Font = Enum.Font.Gotham, TextWrapped = true, LayoutOrder = base + 500 }, copy)
    return copy
end

task.spawn(function()
    local loadingLabel = create("TextLabel", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0.5, -20), BackgroundTransparency = 1, Text = "Loading credits...", TextColor3 = C.Muted, TextSize = 13, Font = Enum.Font.Gotham }, CreditsPage)
    loadCreditsCache(); loadingLabel:Destroy()
    local copies = {}; for i = 1, 2 do table.insert(copies, renderCreditsCopy()) end
    task.wait(0.25)
    local function startLoop()
        local copyHeight = copies[1] and copies[1].AbsoluteSize.Y or 0
        if copyHeight <= 0 then task.wait(0.4); startLoop(); return end
        local duration = copyHeight / CREDITS_SPEED
        while CreditsPage.Parent and ENV.__EPIC_PLANETS_RUNNING do
            local fromPos, toPos
            if CREDITS_DIRECTION == "down" then fromPos = UDim2.new(0, 0, 0, -copyHeight); toPos = UDim2.new(0, 0, 0, 0)
            else fromPos = UDim2.new(0, 0, 0, 0); toPos = UDim2.new(0, 0, 0, -copyHeight) end
            CreditsScroll.Position = fromPos
            local tw = TweenService:Create(CreditsScroll, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Position = toPos })
            tw:Play(); tw.Completed:Wait()
        end
    end
    startLoop()
end)

----------------------------------------------------------------
-- INITIALIZE
----------------------------------------------------------------
BuiltinModules.Initialized = true
ENV.__EPIC_PLANETS_BUILTINMODULES = BuiltinModules
addLog("INFO", "EPIC PLANETS initialized; Mini Effects + Game Blur + Back Animation registered")
refreshLogsPage(); showPage("Home"); setStatus("Loading intro")

print("[EPIC PLANETS] Main.lua loaded.")
print("[EPIC PLANETS] BuiltinModules " .. BuiltinModules.Version)

if flashSound then print("[EPIC PLANETS AUDIO] Ready.") else addLog("WARN", "Audio unavailable.") end

task.spawn(function()
    local ok, err = pcall(function() BuiltinModules.Animations.PlayIntro() end)
    if not ok then addLog("ERROR", "Intro error: " .. tostring(err)) end
end)
