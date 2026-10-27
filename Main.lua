--[[
    EPIC PLANETS
    Main.lua + BuiltinModules
    Delta / Android

    BuiltinModules:
      UI
      Audio
      Animations
      Settings
      ModuleLoader
]]

local ENV = (type(getgenv) == "function" and getgenv()) or _G

----------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------

if type(ENV.__EPIC_PLANETS_CONNECTIONS) == "table" then
    for _, connection in ipairs(ENV.__EPIC_PLANETS_CONNECTIONS) do
        pcall(function()
            connection:Disconnect()
        end)
    end
end

if ENV.__EPIC_PLANETS_GUI then
    pcall(function()
        ENV.__EPIC_PLANETS_GUI:Destroy()
    end)
end

if ENV.__EPIC_PLANETS_FLASH_SOUND then
    pcall(function()
        ENV.__EPIC_PLANETS_FLASH_SOUND:Stop()
        ENV.__EPIC_PLANETS_FLASH_SOUND:Destroy()
    end)
end

if type(ENV.__EPIC_PLANETS_PERSONAL_AUDIO_SOUNDS) == "table" then
    for _, oldSound in pairs(ENV.__EPIC_PLANETS_PERSONAL_AUDIO_SOUNDS) do
        pcall(function()
            oldSound:Stop()
            oldSound:Destroy()
        end)
    end
end
ENV.__EPIC_PLANETS_PERSONAL_AUDIO_SOUNDS = {}

if type(ENV.__EPIC_PLANETS_MODELS) == "table" then
    for _, model in ipairs(ENV.__EPIC_PLANETS_MODELS) do
        pcall(function()
            model:Destroy()
        end)
    end
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

local Player = Players.LocalPlayer

if not Player then
    error("[EPIC PLANETS] LocalPlayer not found.")
end

local PlayerGui = Player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- BUILTINMODULES: CORE
----------------------------------------------------------------

local BuiltinModules = {}

BuiltinModules.Version = "1.0.0"
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

BuiltinModules.Settings = {
    Rainbow = true,
    Intro = true,
    FlashAudio = true,
    AudioVolume = 1,
}

BuiltinModules.Titles = {
    "EPIC PLANETS",
    "don't touch In builtinmodules",
    "BLUEEEEEE",
    "F up",
    "April!",
    "Dont kill the script",
}

math.randomseed(os.time() + math.floor(os.clock() * 100000))

local Title = BuiltinModules.Titles[
    math.random(1, #BuiltinModules.Titles)
]

----------------------------------------------------------------
-- BUILTINMODULES: EXECUTOR
----------------------------------------------------------------

BuiltinModules.Executor = {}

function BuiltinModules.Executor.Get(name)
    local fn

    pcall(function()
        fn = ENV[name]
    end)

    if type(fn) ~= "function" then
        pcall(function()
            fn = _G[name]
        end)
    end

    return type(fn) == "function" and fn or nil
end

function BuiltinModules.Executor.Call(name, ...)
    local fn = BuiltinModules.Executor.Get(name)

    if not fn then
        return false, "Executor API unavailable: " .. name
    end

    return pcall(fn, ...)
end

----------------------------------------------------------------
-- COMMON HELPERS
----------------------------------------------------------------

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent
    return object
end

local function tween(object, duration, properties, style)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(
            duration,
            style or Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        properties
    )

    animation:Play()
    return animation
end

-- Runtime log buffer. It is bounded so the UI cannot grow forever.
local RuntimeLogs = {}
local refreshLogsPage
local MAX_RUNTIME_LOGS = 100

local function addLog(level, message)
    local stamp = "--:--:--"
    pcall(function()
        stamp = os.date("%H:%M:%S")
    end)

    local entry = {
        time = stamp,
        level = tostring(level or "INFO"),
        message = tostring(message or ""),
    }

    if #entry.message > 220 then
        entry.message = string.sub(entry.message, 1, 217) .. "..."
    end

    table.insert(RuntimeLogs, entry)
    while #RuntimeLogs > MAX_RUNTIME_LOGS do
        table.remove(RuntimeLogs, 1)
    end

    if refreshLogsPage then
        task.defer(function()
            if refreshLogsPage then
                pcall(refreshLogsPage)
            end
        end)
    end
end

local function setStatus(message)
    local value = tostring(message)
    addLog("INFO", value)

    local status = ENV.__EPIC_PLANETS_STATUS
    if status and status.Parent then
        status.Text = "Status: " .. value
    end
end

----------------------------------------------------------------
-- BUILTINMODULES: AUDIO
----------------------------------------------------------------

BuiltinModules.Audio = {}

BuiltinModules.Audio.URL =
    "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/Screenrecorder-2026-09-18-20-34-50-385.mp3"

BuiltinModules.Audio.Folder = "EpicPlanets"

BuiltinModules.Audio.File =
    BuiltinModules.Audio.Folder
    .. "/Screenrecorder-2026-09-18-20-34-50-385.mp3"

function BuiltinModules.Audio.Prepare()
    local executor = BuiltinModules.Executor

    local folderOK, folderExists = executor.Call(
        "isfolder",
        BuiltinModules.Audio.Folder
    )

    if not folderOK or folderExists ~= true then
        executor.Call("makefolder", BuiltinModules.Audio.Folder)
    end

    local checkOK, fileExists = executor.Call(
        "isfile",
        BuiltinModules.Audio.File
    )

    if not checkOK or fileExists ~= true then
        local downloadOK, data = pcall(function()
            return game:HttpGet(BuiltinModules.Audio.URL)
        end)

        if not downloadOK or type(data) ~= "string" or #data == 0 then
            warn("[EPIC PLANETS AUDIO] MP3 download failed.")
            return nil
        end

        local writeOK, writeError = executor.Call(
            "writefile",
            BuiltinModules.Audio.File,
            data
        )

        if not writeOK then
            warn(
                "[EPIC PLANETS AUDIO] Could not save MP3: "
                .. tostring(writeError)
            )

            return nil
        end
    end

    local assetOK, assetId = executor.Call(
        "getcustomasset",
        BuiltinModules.Audio.File
    )

    if not assetOK or type(assetId) ~= "string" then
        warn("[EPIC PLANETS AUDIO] Could not load audio asset.")
        return nil
    end

    local sound = Instance.new("Sound")
    sound.Name = "EPIC_PLANETS_FLASH_AUDIO"
    sound.SoundId = assetId
    sound.Volume = BuiltinModules.Settings.AudioVolume
    sound.Looped = false
    sound.Parent = SoundService

    ENV.__EPIC_PLANETS_FLASH_SOUND = sound

    print("[EPIC PLANETS AUDIO] MP3 prepared.")

    return sound
end

function BuiltinModules.Audio.PlayFlash()
    if not BuiltinModules.Settings.FlashAudio then
        return
    end

    local sound = ENV.__EPIC_PLANETS_FLASH_SOUND

    if not sound or not sound.Parent then
        return
    end

    pcall(function()
        sound:Stop()
        sound.TimePosition = 0
        sound:Play()
    end)
end

----------------------------------------------------------------
-- BUILTINMODULES: UI
----------------------------------------------------------------

BuiltinModules.UI = {}

function BuiltinModules.UI.Round(object, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
    }, object)
end

function BuiltinModules.UI.Stroke(object, color, transparency)
    local stroke = create("UIStroke", {
        Color = color or BuiltinModules.Colors.Blue,
        Thickness = 1,
        Transparency = transparency or 0.15,
    }, object)

    return stroke
end

function BuiltinModules.UI.Label(parent, text, height, size, color)
    return create("TextLabel", {
        Size = UDim2.new(1, -4, 0, height or 30),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or BuiltinModules.Colors.Text,
        TextSize = size or 12,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, parent)
end

function BuiltinModules.UI.Button(parent, text, callback, height)
    local button = create("TextButton", {
        Size = UDim2.new(1, -4, 0, height or 38),
        BackgroundColor3 = BuiltinModules.Colors.PanelAlt,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = BuiltinModules.Colors.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextWrapped = true,
        AutoButtonColor = true,
    }, parent)

    BuiltinModules.UI.Round(button, 7)
    BuiltinModules.UI.Stroke(button, nil, 0.4)

    connect(button.Activated, function()
        local ok, err = pcall(callback, button)

        if not ok then
            local message = "Button error: " .. tostring(err)
            addLog("ERROR", message)
            warn("[EPIC PLANETS] " .. message)
        end
    end)

    return button
end

----------------------------------------------------------------
-- BUILTINMODULES: MODULE LOADER
----------------------------------------------------------------

BuiltinModules.ModuleLoader = {}

BuiltinModules.ModuleLoader.Folder = "EpicPlanets/Modules"

function BuiltinModules.ModuleLoader.EnsureFolders()
    local executor = BuiltinModules.Executor

    local folders = {
        "EpicPlanets",
        BuiltinModules.ModuleLoader.Folder,
    }

    for _, folder in ipairs(folders) do
        local ok, exists = executor.Call("isfolder", folder)

        if not ok or exists ~= true then
            executor.Call("makefolder", folder)
        end
    end
end

function BuiltinModules.ModuleLoader.List()
    BuiltinModules.ModuleLoader.EnsureFolders()

    local listFunction =
        BuiltinModules.Executor.Get("listfiles")

    if not listFunction then
        return nil, "listfiles unavailable"
    end

    local ok, result = pcall(
        listFunction,
        BuiltinModules.ModuleLoader.Folder
    )

    if not ok or type(result) ~= "table" then
        return nil, "Could not read Modules folder"
    end

    return result
end

function BuiltinModules.ModuleLoader.Run(path)
    local executor = BuiltinModules.Executor
    local readOK, source = executor.Call("readfile", path)

    if not readOK or type(source) ~= "string" then
        return false, "Could not read module file"
    end

    local loadFunction = executor.Get("loadstring")

    if not loadFunction then
        return false, "loadstring unavailable"
    end

    local compileOK, chunk = pcall(loadFunction, source)

    if not compileOK or type(chunk) ~= "function" then
        return false, tostring(chunk)
    end

    local runOK, result = pcall(chunk)

    if not runOK then
        return false, tostring(result)
    end

    return true, "Module executed"
end

----------------------------------------------------------------
-- PREPARE AUDIO BEFORE INTRO
----------------------------------------------------------------

BuiltinModules.ModuleLoader.EnsureFolders()

local flashSound = BuiltinModules.Audio.Prepare()

----------------------------------------------------------------
-- GUI ROOT
----------------------------------------------------------------

local C = BuiltinModules.Colors
local UI = BuiltinModules.UI

local GUI = create("ScreenGui", {
    Name = "EPIC_PLANETS_GUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

ENV.__EPIC_PLANETS_GUI = GUI

----------------------------------------------------------------
-- INTRO
----------------------------------------------------------------

local Intro = create("Frame", {
    Name = "IntroScreen",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.Background,
    BorderSizePixel = 0,
}, GUI)

for i = 1, 65 do
    local star = create("Frame", {
        Position = UDim2.fromScale(
            math.random(1, 99) / 100,
            math.random(1, 99) / 100
        ),
        Size = UDim2.fromOffset(
            math.random(1, 3),
            math.random(1, 3)
        ),
        BackgroundColor3 = i % 5 == 0 and C.Blue or C.Text,
        BackgroundTransparency = math.random(25, 75) / 100,
        BorderSizePixel = 0,
    }, Intro)

    UI.Round(star, 4)
end

local IntroTitle = create("TextLabel", {
    Position = UDim2.new(0, 8, 0, 17),
    Size = UDim2.new(1, -16, 0, 34),
    BackgroundTransparency = 1,
    Text = Title,
    TextColor3 = C.Text,
    TextSize = 20,
    Font = Enum.Font.GothamBlack,
    TextWrapped = true,
}, Intro)

local IntroPanel = create("Frame", {
    Name = "IntroPanel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.53),
    Size = UDim2.new(0.86, 0, 0.66, 0),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
}, Intro)

local introConstraint = Instance.new("UISizeConstraint")
introConstraint.MinSize = Vector2.new(275, 350)
introConstraint.MaxSize = Vector2.new(480, 530)
introConstraint.Parent = IntroPanel

UI.Round(IntroPanel, 12)
UI.Stroke(IntroPanel, C.Blue, 0.08)

local IntroStatus = create("TextLabel", {
    Position = UDim2.new(0, 12, 0, 9),
    Size = UDim2.new(1, -24, 0, 23),
    BackgroundTransparency = 1,
    Text = "ASSEMBLING 321 FRAGMENTS",
    TextColor3 = C.Text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, IntroPanel)

local Orbit = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 37),
    Size = UDim2.fromOffset(150, 108),
    BackgroundTransparency = 1,
}, IntroPanel)

local Core = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(24, 24),
    BackgroundColor3 = C.Text,
    BorderSizePixel = 0,
}, Orbit)

UI.Round(Core, 20)
UI.Stroke(Core, C.Blue, 0.1)

local PlanetColors = {
    C.Blue,
    C.Purple,
    C.Green,
    Color3.fromRGB(255, 170, 65),
}

local Planets = {}

for i = 1, 4 do
    local planet = create("Frame", {
        Name = "Planet" .. i,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(i % 2 == 0 and 16 or 12,
                               i % 2 == 0 and 16 or 12),
        BackgroundColor3 = PlanetColors[i],
        BorderSizePixel = 0,
    }, Orbit)

    UI.Round(planet, 20)
    Planets[i] = planet
end

local Ring = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(92, 72),
    BackgroundTransparency = 1,
}, Orbit)

UI.Round(Ring, 40)
UI.Stroke(Ring, C.Blue, 0.55)

local FragmentArea = create("Frame", {
    Position = UDim2.new(0, 10, 0, 151),
    Size = UDim2.new(1, -20, 0, 105),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, IntroPanel)

local Fragments = {}

for i = 1, 321 do
    local fragmentSize = math.random(2, 5)

    local fragment = create("Frame", {
        Name = "Fragment" .. i,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(math.random(), math.random()),
        Size = UDim2.fromOffset(fragmentSize, fragmentSize),
        BackgroundColor3 = i % 6 == 0 and C.Purple or C.Blue,
        BorderSizePixel = 0,
    }, FragmentArea)

    UI.Round(fragment, 4)
    Fragments[i] = fragment
end

local ProgressBack = create("Frame", {
    Position = UDim2.new(0, 14, 1, -43),
    Size = UDim2.new(1, -28, 0, 5),
    BackgroundColor3 = C.PanelAlt,
    BorderSizePixel = 0,
}, IntroPanel)

UI.Round(ProgressBack, 4)

local Progress = create("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C.Blue,
    BorderSizePixel = 0,
}, ProgressBack)

UI.Round(Progress, 4)

local FragmentCount = create("TextLabel", {
    Position = UDim2.new(0, 0, 1, -32),
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "0 / 321",
    TextColor3 = C.Muted,
    TextSize = 10,
    Font = Enum.Font.Code,
}, IntroPanel)

local TapIn = create("TextButton", {
    Name = "TapIn",
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -50),
    Size = UDim2.new(0.7, 0, 0, 40),
    BackgroundColor3 = C.PanelAlt,
    BorderSizePixel = 0,
    Text = "T A P   I N",
    TextColor3 = C.Text,
    TextSize = 14,
    Font = Enum.Font.GothamBlack,
    Visible = false,
}, IntroPanel)

UI.Round(TapIn, 7)
UI.Stroke(TapIn, C.Blue, 0.08)

----------------------------------------------------------------
-- MAIN HUB
----------------------------------------------------------------

local Hub = create("Frame", {
    Name = "MainHub",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.51),
    Size = UDim2.new(0.91, 0, 0.74, 0),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Visible = false,
}, GUI)

local hubConstraint = Instance.new("UISizeConstraint")
hubConstraint.MinSize = Vector2.new(300, 370)
hubConstraint.MaxSize = Vector2.new(640, 590)
hubConstraint.Parent = Hub

UI.Round(Hub, 11)
UI.Stroke(Hub, C.Blue, 0.05)

local Header = create("TextButton", {
    Name = "DragHeader",
    Active = true,
    AutoButtonColor = false,
    Position = UDim2.new(0, 12, 0, 7),
    Size = UDim2.new(1, -92, 0, 28),
    BackgroundTransparency = 1,
    Text = Title,
    TextColor3 = C.Text,
    TextSize = 17,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, Hub)

local Minimize = create("TextButton", {
    Position = UDim2.new(1, -42, 0, 8),
    Size = UDim2.fromOffset(30, 28),
    BackgroundColor3 = C.PanelAlt,
    BorderSizePixel = 0,
    Text = "×",
    TextColor3 = C.Text,
    TextSize = 19,
    Font = Enum.Font.GothamBold,
}, Hub)

UI.Round(Minimize, 6)
UI.Stroke(Minimize, C.Blue, 0.3)

local Sidebar = create("ScrollingFrame", {
    Name = "Sidebar",
    Position = UDim2.new(0, 10, 0, 48),
    Size = UDim2.new(0, 102, 1, -81),
    BackgroundColor3 = C.Background,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = C.Blue,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
}, Hub)

UI.Round(Sidebar, 7)
UI.Stroke(Sidebar, C.Blue, 0.55)

local sidePadding = Instance.new("UIPadding")
sidePadding.PaddingTop = UDim.new(0, 7)
sidePadding.PaddingLeft = UDim.new(0, 6)
sidePadding.PaddingRight = UDim.new(0, 6)
sidePadding.Parent = Sidebar

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 6)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Parent = Sidebar

local PageHost = create("Frame", {
    Name = "PageHost",
    Position = UDim2.new(0, 120, 0, 48),
    Size = UDim2.new(1, -130, 1, -81),
    BackgroundColor3 = C.Background,
    BorderSizePixel = 0,
}, Hub)

UI.Round(PageHost, 7)
UI.Stroke(PageHost, C.Blue, 0.55)

local Status = create("TextLabel", {
    Position = UDim2.new(0, 12, 1, -25),
    Size = UDim2.new(1, -24, 0, 17),
    BackgroundTransparency = 1,
    Text = "Status: Ready",
    TextColor3 = C.Muted,
    TextSize = 9,
    Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, Hub)

ENV.__EPIC_PLANETS_STATUS = Status

local Mini = create("TextButton", {
    Name = "EP_MiniIcon",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 12, 0.56, 0),
    Size = UDim2.fromOffset(42, 42),
    BackgroundColor3 = C.Background,
    BorderSizePixel = 0,
    Text = "EP",
    TextColor3 = C.Text,
    TextSize = 13,
    Font = Enum.Font.GothamBlack,
    Visible = false,
    ZIndex = 100,
}, GUI)

UI.Round(Mini, 10)
UI.Stroke(Mini, C.Blue, 0.02)

----------------------------------------------------------------
-- PAGE SYSTEM
----------------------------------------------------------------

local Pages = {}
local Tabs = {}

local function makePage(name)
    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Blue,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
    }, PageHost)

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    Pages[name] = page
    return page
end

local function info(parent, text, height, color)
    return UI.Label(
        parent,
        text,
        height or 42,
        11,
        color or C.Muted
    )
end

local function showPage(name)
    if not Pages[name] then
        return
    end

    for pageName, page in pairs(Pages) do
        page.Visible = pageName == name
    end

    for tabName, button in pairs(Tabs) do
        button.BackgroundColor3 =
            tabName == name and C.PanelHover or C.PanelAlt

        button.TextColor3 =
            tabName == name and C.Text or C.Muted
    end

    setStatus("Opened " .. name)
end

local function addTab(name, label, order)
    local button = create("TextButton", {
        Name = "Tab_" .. name,
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = C.PanelAlt,
        BorderSizePixel = 0,
        Text = label,
        TextColor3 = C.Muted,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextWrapped = true,
    }, Sidebar)

    UI.Round(button, 6)
    UI.Stroke(button, C.Blue, 0.65)

    Tabs[name] = button

    connect(button.Activated, function()
        showPage(name)
    end)
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

addTab("Home", "HOME", 1)
addTab("Player", "PLAYER", 2)
addTab("BuiltinModules", "BUILTINS", 3)
addTab("Movesets", "MOVESETS", 4)
addTab("Models", "MODEL STORE", 5)
addTab("Settings", "SETTINGS", 6)
addTab("Personalization", "PERSONAL", 7)
addTab("ScriptBlox", "SCRIPTBLOX", 8)
addTab("Logs", "LOGS", 9)

----------------------------------------------------------------
-- SCRIPTBLOX STORE
----------------------------------------------------------------

local HttpService = game:GetService("HttpService")
local ScriptBloxBase = "https://scriptblox.com"
local ScriptResultCards = {}
local storeQuery = ""
local storePage = 1
local storeRequestId = 0
local storeBusy = false

UI.Label(ScriptBloxPage, "SCRIPTBLOX STORE", 29, 14, C.Text).Font = Enum.Font.GothamBlack
info(ScriptBloxPage, "Search community scripts. Review source before using it; this store copies source but never auto-executes it.", 55, C.Muted)
info(ScriptBloxPage, "Powered by ScriptBlox.com", 22, C.Blue)

local StoreSearchBox = create("TextBox", {
    Name = "ScriptBloxSearchBox",
    Size = UDim2.new(1, -4, 0, 38),
    BackgroundColor3 = C.PanelAlt,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    PlaceholderText = "Search scripts...",
    PlaceholderColor3 = C.Muted,
    Text = "",
    TextColor3 = C.Text,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, ScriptBloxPage)
UI.Round(StoreSearchBox, 7)
UI.Stroke(StoreSearchBox, C.Blue, 0.45)
local storeSearchPadding = Instance.new("UIPadding")
storeSearchPadding.PaddingLeft = UDim.new(0, 10)
storeSearchPadding.PaddingRight = UDim.new(0, 8)
storeSearchPadding.Parent = StoreSearchBox

local StoreStatus = UI.Label(ScriptBloxPage, "Enter a search term or tap TRENDING.", 30, 10, C.Muted)
StoreStatus.Name = "ScriptBloxStatus"
StoreStatus.TextWrapped = true

local function urlEncode(value)
    return (string.gsub(tostring(value or ""), "([^%w%-_%.~])", function(char)
        return string.format("%%%02X", string.byte(char))
    end))
end

local function clearStoreCards()
    for _, card in ipairs(ScriptResultCards) do
        pcall(function()
            card:Destroy()
        end)
    end
    table.clear(ScriptResultCards)
end

local function copyToClipboard(value)
    local clipboardNames = {"setclipboard", "toclipboard", "setrbxclipboard"}
    for _, name in ipairs(clipboardNames) do
        local ok = BuiltinModules.Executor.Call(name, value)
        if ok then
            return true
        end
    end
    return false, "Clipboard API unavailable in this executor"
end

local function makeScriptCard(scriptData)
    local title = tostring(scriptData.title or "Untitled script")
    local gameName = "Unknown game"
    if type(scriptData.game) == "table" and scriptData.game.name then
        gameName = tostring(scriptData.game.name)
    end

    local flags = {}
    if scriptData.verified == true then table.insert(flags, "Verified") end
    if scriptData.key == true then table.insert(flags, "Key system") end
    if scriptData.isUniversal == true then table.insert(flags, "Universal") end
    if scriptData.isPatched == true then table.insert(flags, "Marked patched") end
    if #flags == 0 then table.insert(flags, "No special flags reported") end

    local card = create("Frame", {
        Name = "ScriptResultCard",
        Size = UDim2.new(1, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.Panel,
        BorderSizePixel = 0,
    }, ScriptBloxPage)
    table.insert(ScriptResultCards, card)
    UI.Round(card, 7)
    UI.Stroke(card, C.Blue, 0.55)

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 7)
    padding.PaddingBottom = UDim.new(0, 7)
    padding.PaddingLeft = UDim.new(0, 7)
    padding.PaddingRight = UDim.new(0, 7)
    padding.Parent = card

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = card

    local titleLabel = UI.Label(card, title, 34, 11, C.Text)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.LayoutOrder = 1

    local views = tonumber(scriptData.views) or 0
    local meta = "Game: " .. gameName .. "\nViews: " .. tostring(views) .. " | " .. table.concat(flags, ", ")
    local metaLabel = UI.Label(card, meta, 42, 9, C.Muted)
    metaLabel.LayoutOrder = 2

    local scriptIdentifier = tostring(scriptData.slug or scriptData._id or "")
    local pageURL = ScriptBloxBase .. "/script/" .. urlEncode(scriptIdentifier)
    local rawURL = ScriptBloxBase .. "/api/script/raw/" .. urlEncode(scriptIdentifier)

    local copySourceButton = UI.Button(card, "COPY SCRIPT SOURCE", function()
        if scriptIdentifier == "" then
            StoreStatus.Text = "This result has no script identifier."
            addLog("WARN", "ScriptBlox result missing script identifier")
            return
        end

        StoreStatus.Text = "Fetching source..."
        addLog("INFO", "Fetching source for " .. title)
        task.spawn(function()
            local ok, source = pcall(function()
                return game:HttpGet(rawURL)
            end)
            if not ok or type(source) ~= "string" or #source == 0 then
                StoreStatus.Text = "Could not fetch source. Check connection/executor support."
                addLog("ERROR", "ScriptBlox source request failed: " .. tostring(source))
                return
            end

            local copied, copyError = copyToClipboard(source)
            if copied then
                StoreStatus.Text = "Source copied. Review it before running."
                addLog("INFO", "Copied source: " .. title)
            else
                StoreStatus.Text = tostring(copyError) .. ". Open the ScriptBlox page instead."
                addLog("WARN", tostring(copyError))
            end
        end)
    end, 31)
    copySourceButton.LayoutOrder = 3

    local copyLinkButton = UI.Button(card, "COPY SCRIPTBLOX LINK", function()
        local copied, copyError = copyToClipboard(pageURL)
        if copied then
            StoreStatus.Text = "ScriptBlox link copied."
            addLog("INFO", "Copied ScriptBlox link: " .. title)
        else
            StoreStatus.Text = tostring(copyError)
            addLog("WARN", tostring(copyError))
        end
    end, 31)
    copyLinkButton.LayoutOrder = 4
end

local function fetchScriptBlox(endpoint, appendResults, description)
    if storeBusy then
        StoreStatus.Text = "A request is already running. Please wait for it to finish."
        return
    end

    storeRequestId = storeRequestId + 1
    local requestId = storeRequestId
    storeBusy = true
    StoreStatus.Text = description or "Loading ScriptBlox results..."

    if not appendResults then
        clearStoreCards()
    end

    addLog("INFO", "ScriptBlox request: " .. tostring(description or "load"))
    task.spawn(function()
        local requestOK, body = pcall(function()
            return game:HttpGet(endpoint)
        end)
        if requestId ~= storeRequestId then return end

        if not requestOK or type(body) ~= "string" or #body == 0 then
            storeBusy = false
            StoreStatus.Text = "Request failed. Check internet and executor HTTP support."
            addLog("ERROR", "ScriptBlox HTTP request failed: " .. tostring(body))
            return
        end

        local decodeOK, payload = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if requestId ~= storeRequestId then return end

        if not decodeOK or type(payload) ~= "table" then
            storeBusy = false
            StoreStatus.Text = "ScriptBlox returned invalid JSON."
            addLog("ERROR", "Could not decode ScriptBlox response: " .. tostring(payload))
            return
        end

        if payload.message then
            storeBusy = false
            StoreStatus.Text = "ScriptBlox: " .. tostring(payload.message)
            addLog("WARN", "ScriptBlox API: " .. tostring(payload.message))
            return
        end

        local result = payload.result
        local scripts = type(result) == "table" and result.scripts or nil
        if type(scripts) ~= "table" then
            storeBusy = false
            StoreStatus.Text = "No script results were returned by the API."
            addLog("WARN", "ScriptBlox response did not contain result.scripts")
            return
        end

        local count = 0
        for _, scriptData in ipairs(scripts) do
            if type(scriptData) == "table" then
                local safeData = scriptData
                local okCard, cardError = pcall(function()
                    makeScriptCard(safeData)
                end)
                if okCard then
                    count = count + 1
                else
                    addLog("ERROR", "Could not create ScriptBlox result card: " .. tostring(cardError))
                end
            end
        end

        storeBusy = false
        StoreStatus.Text = tostring(count) .. " result(s) loaded. Source is copied, not executed."
        addLog("INFO", "ScriptBlox loaded " .. tostring(count) .. " result(s)")
        if count == 0 then
            StoreStatus.Text = "No results in this batch. Try another search term."
        end
    end)
end

UI.Button(ScriptBloxPage, "SEARCH SCRIPTS", function()
    local query = string.gsub(StoreSearchBox.Text or "", "^%s*(.-)%s*$", "%1")
    if query == "" then
        StoreStatus.Text = "Type a search term first."
        return
    end
    storeQuery = query
    storePage = 1
    local endpoint = ScriptBloxBase .. "/api/script/search?q=" .. urlEncode(query) .. "&max=10&page=1&strict=false"
    fetchScriptBlox(endpoint, false, "Searching ScriptBlox for: " .. query)
end)

UI.Button(ScriptBloxPage, "TRENDING SCRIPTS", function()
    storeQuery = ""
    storePage = 1
    fetchScriptBlox(ScriptBloxBase .. "/api/script/trending?max=10", false, "Loading trending scripts...")
end)

UI.Button(ScriptBloxPage, "LOAD MORE SEARCH RESULTS", function()
    if storeBusy then
        StoreStatus.Text = "A request is already running. Please wait for it to finish."
        return
    end
    if storeQuery == "" then
        StoreStatus.Text = "Run a search first. Trending results do not use search pagination here."
        return
    end
    storePage = storePage + 1
    local endpoint = ScriptBloxBase .. "/api/script/search?q=" .. urlEncode(storeQuery) .. "&max=10&page=" .. tostring(storePage) .. "&strict=false"
    fetchScriptBlox(endpoint, true, "Loading page " .. tostring(storePage) .. "...")
end)

----------------------------------------------------------------
-- LOGS PAGE
----------------------------------------------------------------

UI.Label(LogsPage, "RUNTIME LOGS", 29, 14, C.Text).Font = Enum.Font.GothamBlack
info(LogsPage, "Shows status changes, ScriptBlox requests and errors captured by EPIC PLANETS.", 43, C.Muted)

local LogsOutput

refreshLogsPage = function()
    if not LogsOutput or not LogsOutput.Parent then return end
    if #RuntimeLogs == 0 then
        LogsOutput.Text = "No log entries yet."
        return
    end

    local lines = {}
    local first = math.max(1, #RuntimeLogs - 59)
    for i = first, #RuntimeLogs do
        local entry = RuntimeLogs[i]
        table.insert(lines, "[" .. entry.time .. "] " .. entry.level .. " | " .. entry.message)
    end
    LogsOutput.Text = table.concat(lines, "\n")
end

UI.Button(LogsPage, "REFRESH LOGS", function()
    refreshLogsPage()
    setStatus("Logs refreshed")
end)

UI.Button(LogsPage, "CLEAR LOGS", function()
    table.clear(RuntimeLogs)
    refreshLogsPage()
    addLog("INFO", "Log history cleared")
    setStatus("Logs cleared")
end)

UI.Button(LogsPage, "COPY LOGS", function()
    local lines = {}
    for _, entry in ipairs(RuntimeLogs) do
        table.insert(lines, "[" .. entry.time .. "] " .. entry.level .. " | " .. entry.message)
    end
    local copied, copyError = copyToClipboard(table.concat(lines, "\n"))
    if copied then
        setStatus("Logs copied to clipboard")
    else
        setStatus(tostring(copyError))
        addLog("WARN", tostring(copyError))
    end
end)


LogsOutput = UI.Label(LogsPage, "No log entries yet.", 40, 10, C.Text)
LogsOutput.Name = "RuntimeLogOutput"
LogsOutput.Size = UDim2.new(1, -4, 0, 0)
LogsOutput.AutomaticSize = Enum.AutomaticSize.Y
LogsOutput.TextWrapped = true
LogsOutput.TextXAlignment = Enum.TextXAlignment.Left
LogsOutput.TextYAlignment = Enum.TextYAlignment.Top
LogsOutput.Font = Enum.Font.Code
refreshLogsPage()

----------------------------------------------------------------
-- PERSONALIZATION: MUSIC AND TOUCH SOUNDS
----------------------------------------------------------------

local MusicTracks = {
    ["DM iostesso"] = {
        URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/dm_iostesso.ft2.mp3",
        File = "EpicPlanets/EP_Music_DM_iostesso.mp3",
    },
    ["Screenrecorder"] = {
        URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/Screenrecorder-2026-09-18-20-34-50-385.mp3",
        File = "EpicPlanets/Screenrecorder-2026-09-18-20-34-50-385.mp3",
    },
    ["Madness Combat 2"] = {
        URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/Madness%20Combat%202%20Sheriff%20Town%20%5BHigh%20Quality%20%20Mono-like%5D%20-%20Demirgon%20%F0%9F%87%B7%F0%9F%87%BA%20%28youtube%29.mp3",
        File = "EpicPlanets/EP_Music_Madness_Combat_2.mp3",
    },
    ["Heads Will Roll"] = {
        URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/Heads%20Will%20Roll%20%28A-Trak%20Remix%20Radio%20Edit%29%20-%20Yeah%20Yeah%20Yeahs%20%28youtube%29.mp3",
        File = "EpicPlanets/EP_Music_Heads_Will_Roll.mp3",
    },
}

local TouchTracks = {
    ["Maro Jump"] = {
        URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/maro-jump-sound-effect_1.mp3",
        File = "EpicPlanets/EP_Touch_Maro_Jump.mp3",
    },
    ["ULTRAKILL Parry"] = {
        URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/parry-ultrakill.mp3",
        File = "EpicPlanets/EP_Touch_ULTRAKILL_Parry.mp3",
    },
    ["Sonic Spindash"] = {
        URL = "https://raw.githubusercontent.com/chaloapps011-cyber/EpicPlanets/main/sonic-spindash.mp3",
        File = "EpicPlanets/EP_Touch_Sonic_Spindash.mp3",
    },
}

local MusicOrder = {
    "Screenrecorder",
    "None",
    "DM iostesso",
    "Madness Combat 2",
    "Heads Will Roll",
}

local TouchOrder = {
    "None",
    "Maro Jump",
    "ULTRAKILL Parry",
    "Sonic Spindash",
}

local selectedMusic = "Screenrecorder"
local selectedTouch = "None"
local personalAudioCache = ENV.__EPIC_PLANETS_PERSONAL_AUDIO_SOUNDS
local introFlashHappened = false

local function stopPersonalMusic()
    for key, sound in pairs(personalAudioCache) do
        if string.sub(tostring(key), 1, 6) == "Music:" then
            pcall(function()
                sound:Stop()
            end)
        end
    end
end

local function preparePersonalAudio(kind, name)
    if name == "None" then
        return nil, "None selected"
    end

    local tracks = kind == "Music" and MusicTracks or TouchTracks
    local track = tracks[name]
    if not track then
        return nil, "Unknown audio: " .. tostring(name)
    end

    local cacheKey = kind .. ":" .. name
    local cached = personalAudioCache[cacheKey]
    if cached and cached.Parent then
        cached.Looped = kind == "Music"
        cached.Volume = BuiltinModules.Settings.AudioVolume
        return cached
    end

    -- Reuse the original Screenrecorder sound already prepared by Main.lua.
    if kind == "Music" and name == "Screenrecorder" then
        local original = ENV.__EPIC_PLANETS_FLASH_SOUND
        if original and original.Parent then
            original.Name = "EPIC_PLANETS_MUSIC_SCREENRECORDER"
            original.Looped = true
            original.Volume = BuiltinModules.Settings.AudioVolume
            personalAudioCache[cacheKey] = original
            return original
        end
    end

    local folderOK, folderExists = BuiltinModules.Executor.Call("isfolder", "EpicPlanets")
    if not folderOK or folderExists ~= true then
        BuiltinModules.Executor.Call("makefolder", "EpicPlanets")
    end

    local fileOK, fileExists = BuiltinModules.Executor.Call("isfile", track.File)
    if not fileOK or fileExists ~= true then
        local downloadOK, data = pcall(function()
            return game:HttpGet(track.URL)
        end)
        if not downloadOK or type(data) ~= "string" or #data == 0 then
            return nil, "Download failed for " .. name
        end

        local writeOK, writeError = BuiltinModules.Executor.Call("writefile", track.File, data)
        if not writeOK then
            return nil, "Could not save " .. name .. ": " .. tostring(writeError)
        end
    end

    local assetOK, assetId = BuiltinModules.Executor.Call("getcustomasset", track.File)
    if not assetOK or type(assetId) ~= "string" then
        assetOK, assetId = BuiltinModules.Executor.Call("getsynasset", track.File)
    end
    if not assetOK or type(assetId) ~= "string" then
        return nil, "Audio asset API unavailable for " .. name
    end

    local sound = Instance.new("Sound")
    sound.Name = "EPIC_PLANETS_" .. kind .. "_" .. name:gsub("%W", "_")
    sound.SoundId = assetId
    sound.Volume = BuiltinModules.Settings.AudioVolume
    sound.Looped = kind == "Music"
    sound.Parent = SoundService
    personalAudioCache[cacheKey] = sound
    return sound
end

local function playPersonalMusic(name, restart)
    stopPersonalMusic()
    if name == "None" then
        setStatus("Music disabled (None)")
        return false
    end

    local sound, err = preparePersonalAudio("Music", name)
    if not sound then
        setStatus("Music error: " .. tostring(err))
        warn("[EPIC PLANETS AUDIO] " .. tostring(err))
        return false
    end

    sound.Looped = true
    sound.Volume = BuiltinModules.Settings.AudioVolume
    local ok, playError = pcall(function()
        if restart then
            sound.TimePosition = 0
        end
        sound:Play()
    end)
    if not ok then
        setStatus("Could not play music: " .. tostring(playError))
        return false
    end

    setStatus("Music: " .. name)
    return true
end

local function playPersonalTouch()
    if selectedTouch == "None" then
        return
    end

    local sound, err = preparePersonalAudio("Touch", selectedTouch)
    if not sound then
        warn("[EPIC PLANETS TOUCH AUDIO] " .. tostring(err))
        setStatus("Touch sound error")
        return
    end

    pcall(function()
        sound.Looped = false
        sound.Volume = BuiltinModules.Settings.AudioVolume
        sound:Stop()
        sound.TimePosition = 0
        sound:Play()
    end)
end

-- The selected music starts at the original intro flash.
BuiltinModules.Audio.PlayFlash = function()
    introFlashHappened = true
    if not BuiltinModules.Settings.FlashAudio then
        stopPersonalMusic()
        return
    end
    playPersonalMusic(selectedMusic, true)
end

UI.Label(PersonalizationPage, "PERSONALIZATION", 28, 15, C.Text).Font =
    Enum.Font.GothamBlack
info(PersonalizationPage, "Choose the intro music and the sound played when you tap interface buttons.", 42)

local musicChoiceButton
local touchChoiceButton

local function refreshMusicChoice()
    if musicChoiceButton and musicChoiceButton.Parent then
        musicChoiceButton.Text = "MUSIC: " .. selectedMusic .. "  [TAP TO CHANGE]"
    end
end

local function refreshTouchChoice()
    if touchChoiceButton and touchChoiceButton.Parent then
        touchChoiceButton.Text = "TOUCH SOUND: " .. selectedTouch .. "  [TAP TO CHANGE]"
    end
end

musicChoiceButton = UI.Button(PersonalizationPage, "MUSIC: Screenrecorder  [TAP TO CHANGE]", function()
    local index = table.find(MusicOrder, selectedMusic) or 1
    index = (index % #MusicOrder) + 1
    selectedMusic = MusicOrder[index]
    refreshMusicChoice()

    if selectedMusic == "None" then
        stopPersonalMusic()
        setStatus("Music disabled (None)")
    elseif introFlashHappened then
        playPersonalMusic(selectedMusic, true)
    else
        task.spawn(function()
            local _, err = preparePersonalAudio("Music", selectedMusic)
            if err then
                warn("[EPIC PLANETS AUDIO] " .. tostring(err))
                setStatus("Music preload error")
            else
                setStatus("Music selected: " .. selectedMusic .. " (starts at intro flash)")
            end
        end)
    end
end, 43)

UI.Button(PersonalizationPage, "PLAY MUSIC PREVIEW", function()
    if selectedMusic == "None" then
        stopPersonalMusic()
        setStatus("Music preview disabled (None)")
        return
    end
    task.spawn(function()
        playPersonalMusic(selectedMusic, true)
    end)
end, 38)

UI.Button(PersonalizationPage, "STOP MUSIC", function()
    stopPersonalMusic()
    setStatus("Music stopped")
end, 38)

UI.Label(PersonalizationPage, "TOUCH SOUND", 22, 12, C.Text).Font =
    Enum.Font.GothamBold

touchChoiceButton = UI.Button(PersonalizationPage, "TOUCH SOUND: None  [TAP TO CHANGE]", function()
    local index = table.find(TouchOrder, selectedTouch) or 1
    index = (index % #TouchOrder) + 1
    selectedTouch = TouchOrder[index]
    refreshTouchChoice()

    if selectedTouch == "None" then
        setStatus("Touch sound disabled (None)")
    else
        task.spawn(function()
            local _, err = preparePersonalAudio("Touch", selectedTouch)
            if err then
                warn("[EPIC PLANETS TOUCH AUDIO] " .. tostring(err))
                setStatus("Touch sound preload error")
            else
                setStatus("Touch sound selected: " .. selectedTouch)
            end
        end)
    end
end, 43)

UI.Button(PersonalizationPage, "PLAY TOUCH SOUND PREVIEW", function()
    if selectedTouch == "None" then
        setStatus("Touch preview disabled (None)")
        return
    end
    task.spawn(playPersonalTouch)
end, 38)

info(PersonalizationPage, "Defaults: Screenrecorder music, None touch sound.", 32, C.Blue)
info(PersonalizationPage, "If an MP3 fails to load, check the GitHub file URL and executor file/asset support.", 45)

-- Play the selected touch sound when tapping interface buttons.
local function hookPersonalTouch(object)
    if not object or not (object:IsA("TextButton") or object:IsA("ImageButton")) then
        return
    end
    if object:GetAttribute("EP_PersonalTouchHooked") then
        return
    end
    object:SetAttribute("EP_PersonalTouchHooked", true)
    connect(object.Activated, function()
        playPersonalTouch()
    end)
end

for _, object in ipairs(GUI:GetDescendants()) do
    hookPersonalTouch(object)
end

connect(GUI.DescendantAdded, function(object)
    task.defer(function()
        if GUI.Parent then
            hookPersonalTouch(object)
        end
    end)
end)

-- Preload the default track, without starting it before the intro flash.
task.spawn(function()
    local _, err = preparePersonalAudio("Music", selectedMusic)
    if err then
        warn("[EPIC PLANETS AUDIO] Default music preload issue: " .. tostring(err))
    end
end)

----------------------------------------------------------------
-- HOME
----------------------------------------------------------------

local homeTitle = UI.Label(
    HomePage,
    "EPIC PLANETS",
    28,
    16,
    C.Text
)

homeTitle.Font = Enum.Font.GothamBlack

info(
    HomePage,
    "Dark modular interface with a 321-fragment intro, planets, audio and built-in components.",
    54
)

info(HomePage, "Player: " .. Player.Name, 24, C.Text)
info(HomePage, "Place ID: " .. tostring(game.PlaceId), 24)
info(HomePage, "BuiltinModules: " .. BuiltinModules.Version, 24, C.Blue)

UI.Button(HomePage, "OPEN BUILTINMODULES", function()
    showPage("BuiltinModules")
end)

UI.Button(HomePage, "MINIMIZE TO EP ICON", function()
    Hub.Visible = false
    Mini.Visible = true
    setStatus("Minimized")
end)

----------------------------------------------------------------
-- PLAYER
----------------------------------------------------------------

UI.Label(PlayerPage, "PLAYER CONTROLS", 27, 14, C.Text).Font =
    Enum.Font.GothamBold

info(
    PlayerPage,
    "Client-side movement controls. A game can override these values.",
    44
)

local speedEnabled = false
local jumpEnabled = false
local flyEnabled = false

local oldSpeed
local oldJumpPower
local oldJumpHeight

local flyVelocity
local flyGyro
local vertical = 0

local function getCharacterParts()
    local character = Player.Character

    if not character then
        return nil, nil
    end

    return character:FindFirstChildOfClass("Humanoid"),
        character:FindFirstChild("HumanoidRootPart")
end

UI.Button(PlayerPage, "TOGGLE SPEED", function(button)
    local humanoid = getCharacterParts()

    if not humanoid then
        setStatus("Character not ready")
        return
    end

    if not speedEnabled then
        oldSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = 32
        speedEnabled = true
        button.Text = "SPEED: ON"
    else
        if oldSpeed then
            humanoid.WalkSpeed = oldSpeed
        end

        speedEnabled = false
        button.Text = "TOGGLE SPEED"
    end

    setStatus(speedEnabled and "Speed enabled" or "Speed restored")
end)

UI.Button(PlayerPage, "TOGGLE HIGH JUMP", function(button)
    local humanoid = getCharacterParts()

    if not humanoid then
        setStatus("Character not ready")
        return
    end

    if not jumpEnabled then
        oldJumpPower = humanoid.JumpPower
        oldJumpHeight = humanoid.JumpHeight

        if humanoid.UseJumpPower then
            humanoid.JumpPower = 100
        else
            humanoid.JumpHeight = 50
        end

        jumpEnabled = true
        button.Text = "HIGH JUMP: ON"
    else
        if humanoid.UseJumpPower then
            if oldJumpPower then
                humanoid.JumpPower = oldJumpPower
            end
        elseif oldJumpHeight then
            humanoid.JumpHeight = oldJumpHeight
        end

        jumpEnabled = false
        button.Text = "TOGGLE HIGH JUMP"
    end

    setStatus(jumpEnabled and "High jump enabled" or "Jump restored")
end)

local function setFly(enabled)
    local humanoid, root = getCharacterParts()

    if enabled and (not humanoid or not root) then
        setStatus("Character not ready")
        return
    end

    if enabled then
        if flyVelocity then
            flyVelocity:Destroy()
        end

        if flyGyro then
            flyGyro:Destroy()
        end

        flyVelocity = create("BodyVelocity", {
            Name = "EP_FlyVelocity",
            MaxForce = Vector3.new(1e9, 1e9, 1e9),
            P = 12000,
            Velocity = Vector3.zero,
        }, root)

        flyGyro = create("BodyGyro", {
            Name = "EP_FlyGyro",
            MaxTorque = Vector3.new(1e9, 1e9, 1e9),
            P = 9000,
            CFrame = root.CFrame,
        }, root)

        humanoid.AutoRotate = false
        flyEnabled = true
        vertical = 0
    else
        flyEnabled = false
        vertical = 0

        if flyVelocity then
            flyVelocity:Destroy()
        end

        if flyGyro then
            flyGyro:Destroy()
        end

        flyVelocity = nil
        flyGyro = nil

        if humanoid then
            humanoid.AutoRotate = true
        end
    end

    setStatus(flyEnabled and "Fly enabled" or "Fly disabled")
end

UI.Button(PlayerPage, "TOGGLE FLY", function(button)
    setFly(not flyEnabled)
    button.Text = flyEnabled and "FLY: ON" or "TOGGLE FLY"
end)

local verticalRow = create("Frame", {
    Size = UDim2.new(1, -4, 0, 42),
    BackgroundTransparency = 1,
}, PlayerPage)

local upButton = create("TextButton", {
    Size = UDim2.new(0.49, 0, 1, 0),
    BackgroundColor3 = C.PanelAlt,
    BorderSizePixel = 0,
    Text = "HOLD UP",
    TextColor3 = C.Text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
}, verticalRow)

UI.Round(upButton, 6)

local downButton = create("TextButton", {
    Position = UDim2.new(0.51, 0, 0, 0),
    Size = UDim2.new(0.49, 0, 1, 0),
    BackgroundColor3 = C.PanelAlt,
    BorderSizePixel = 0,
    Text = "HOLD DOWN",
    TextColor3 = C.Text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
}, verticalRow)

UI.Round(downButton, 6)

local function holdAltitude(button, value)
    connect(button.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then

            if flyEnabled then
                vertical = value
            else
                setStatus("Activate Fly first")
            end
        end
    end)

    connect(button.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then

            if vertical == value then
                vertical = 0
            end
        end
    end)
end

holdAltitude(upButton, 1)
holdAltitude(downButton, -1)

info(
    PlayerPage,
    "Activate Fly, steer with the movement joystick, and hold UP or DOWN for altitude.",
    48
)

----------------------------------------------------------------
-- BUILTINMODULES PAGE
----------------------------------------------------------------

UI.Label(BuiltinPage, "BUILTINMODULES", 27, 14, C.Text).Font =
    Enum.Font.GothamBlack

info(
    BuiltinPage,
    "Internal components that run inside Main.lua.",
    32
)

local function componentInfo(name, description)
    UI.Button(BuiltinPage, name, function()
        setStatus(description)
    end, 36)
end

componentInfo("UI", "UI module: buttons, labels, frames and animations.")
componentInfo("Audio", "Audio module: MP3 preparation and flash playback.")
componentInfo("ModuleLoader", "ModuleLoader: scans local Lua module files.")
componentInfo("Settings", "Settings: audio, intro and visual options.")
componentInfo("Animations", "Animations: intro fragments and orbital effects.")

UI.Button(BuiltinPage, "REPLAY FLASH AUDIO", function()
    BuiltinModules.Audio.PlayFlash()
    setStatus("Flash audio requested")
end)

info(
    BuiltinPage,
    "The title 'don't touch In builtinmodules' is one of the random titles.",
    42,
    C.Blue
)

----------------------------------------------------------------
-- MOVESETS / LOCAL LUA MODULES
----------------------------------------------------------------

UI.Label(MovesetsPage, "MOVESETS / MODULES", 27, 14, C.Text).Font =
    Enum.Font.GothamBold

info(
    MovesetsPage,
    "Place your local .lua modules in this folder:",
    32
)

info(
    MovesetsPage,
    BuiltinModules.ModuleLoader.Folder,
    30,
    C.Blue
)

local moduleList = create("Frame", {
    Name = "ModuleList",
    Size = UDim2.new(1, -4, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
}, MovesetsPage)

local moduleLayout = Instance.new("UIListLayout")
moduleLayout.Padding = UDim.new(0, 6)
moduleLayout.SortOrder = Enum.SortOrder.LayoutOrder
moduleLayout.Parent = moduleList

local function refreshModules()
    for _, child in ipairs(moduleList:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    local files, message = BuiltinModules.ModuleLoader.List()

    if not files then
        info(moduleList, message or "Could not scan folder.", 44, C.Red)
        setStatus("Module scan failed")
        return
    end

    local count = 0

    for _, path in ipairs(files) do
        if type(path) == "string"
            and path:lower():sub(-4) == ".lua" then

            count = count + 1

            local filePath = path
            local fileName = path:match("[^/\\]+$") or path

            UI.Button(moduleList, "RUN  " .. fileName, function()
                local ok, result =
                    BuiltinModules.ModuleLoader.Run(filePath)

                setStatus(ok and result or ("Error: " .. tostring(result)))
            end, 38)
        end
    end

    if count == 0 then
        info(
            moduleList,
            "No .lua files found. Add one to the folder above.",
            45
        )
    end

    setStatus("Found " .. tostring(count) .. " module(s)")
end

UI.Button(MovesetsPage, "REFRESH MODULES", refreshModules)

----------------------------------------------------------------
-- MODEL STORE
----------------------------------------------------------------

UI.Label(ModelsPage, "MODEL STORE", 27, 14, C.Text).Font =
    Enum.Font.GothamBold

info(
    ModelsPage,
    "Install client-side visual models that follow your character.",
    42
)

local installedModels = ENV.__EPIC_PLANETS_MODELS

local function createOrbitalCore()
    local character = Player.Character
    local root = character
        and character:FindFirstChild("HumanoidRootPart")

    if not root then
        setStatus("Character root not ready")
        return
    end

    local model = Instance.new("Model")
    model.Name = "EP_OrbitalCore"
    model.Parent = Workspace

    local center = Instance.new("Part")
    center.Name = "Core"
    center.Shape = Enum.PartType.Ball
    center.Size = Vector3.new(1.7, 1.7, 1.7)
    center.Anchored = true
    center.CanCollide = false
    center.Material = Enum.Material.Neon
    center.Color = C.Blue
    center.Parent = model

    local planets = {}

    for i = 1, 4 do
        local planet = Instance.new("Part")
        planet.Name = "Planet" .. i
        planet.Shape = Enum.PartType.Ball
        planet.Size = Vector3.new(0.55, 0.55, 0.55)
        planet.Anchored = true
        planet.CanCollide = false
        planet.Material = Enum.Material.Neon
        planet.Color = PlanetColors[i]
        planet.Parent = model

        planets[i] = planet
    end

    model.PrimaryPart = center

    table.insert(installedModels, {
        model = model,
        center = center,
        planets = planets,
    })

    setStatus("Orbital Core installed")
end

local function removeModels()
    for _, entry in ipairs(installedModels) do
        if typeof(entry) == "Instance" then
            pcall(function()
                entry:Destroy()
            end)
        elseif type(entry) == "table" and entry.model then
            pcall(function()
                entry.model:Destroy()
            end)
        end
    end

    table.clear(installedModels)
    setStatus("Removed installed models")
end

UI.Button(ModelsPage, "INSTALL ORBITAL CORE", createOrbitalCore)
UI.Button(ModelsPage, "REMOVE INSTALLED MODELS", removeModels)

----------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------

UI.Label(SettingsPage, "SETTINGS", 27, 14, C.Text).Font =
    Enum.Font.GothamBold

info(
    SettingsPage,
    "Configure the internal features of EPIC PLANETS.",
    36
)

UI.Button(SettingsPage, "RANDOMIZE TITLE", function()
    local oldTitle = Title

    repeat
        Title = BuiltinModules.Titles[
            math.random(1, #BuiltinModules.Titles)
        ]
    until #BuiltinModules.Titles == 1 or Title ~= oldTitle

    Header.Text = Title
    IntroTitle.Text = Title

    setStatus("Title changed: " .. Title)
end)

UI.Button(SettingsPage, "TOGGLE FLASH AUDIO", function(button)
    BuiltinModules.Settings.FlashAudio =
        not BuiltinModules.Settings.FlashAudio

    button.Text = BuiltinModules.Settings.FlashAudio
        and "FLASH AUDIO: ON"
        or "FLASH AUDIO: OFF"

    setStatus("Flash audio updated")
end)

UI.Button(SettingsPage, "PLAY TEST AUDIO", function()
    BuiltinModules.Audio.PlayFlash()
    setStatus("Audio test requested")
end)

UI.Button(SettingsPage, "MINIMIZE WINDOW", function()
    Hub.Visible = false
    Mini.Visible = true
    setStatus("Minimized")
end)

info(
    SettingsPage,
    "The MP3 is prepared locally before the intro flash.",
    38
)

----------------------------------------------------------------
-- WINDOW CONTROLS
----------------------------------------------------------------

connect(Minimize.Activated, function()
    Hub.Visible = false
    Mini.Visible = true
end)

connect(Mini.Activated, function()
    Mini.Visible = false
    Hub.Visible = true
end)

connect(TapIn.Activated, function()
    IntroStatus.Text = "SYSTEMS READY"

    tween(IntroPanel, 0.22, {
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.48),
    })

    task.wait(0.23)

    Intro.Visible = false
    Hub.Visible = true
    Hub.Size = UDim2.new(0.84, 0, 0.68, 0)
    Hub.BackgroundTransparency = 1

    tween(Hub, 0.28, {
        Size = UDim2.new(0.91, 0, 0.74, 0),
        BackgroundTransparency = 0,
    }, Enum.EasingStyle.Back)

    showPage("Home")
end)

----------------------------------------------------------------
-- DRAG WINDOW: MOUSE + TOUCH, WITH VIEWPORT CLAMPING
----------------------------------------------------------------

local dragging = false
local dragStart
local startPosition
local activeTouch
local dragInput

local function stopDragging()
    dragging = false
    dragStart = nil
    startPosition = nil
    activeTouch = nil
    dragInput = nil
end

local function applyDrag(input)
    if not dragging or not dragStart or not startPosition then
        return
    end

    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize
    if not viewport then
        return
    end

    local delta = input.Position - dragStart
    local startCenterX = viewport.X * startPosition.X.Scale + startPosition.X.Offset
    local startCenterY = viewport.Y * startPosition.Y.Scale + startPosition.Y.Offset
    local centerX = startCenterX + delta.X
    local centerY = startCenterY + delta.Y

    local halfW = Hub.AbsoluteSize.X / 2
    local halfH = Hub.AbsoluteSize.Y / 2
    local marginX = 40
    local marginY = 28

    -- Keep the whole window visible when possible; otherwise keep a grab area visible.
    local minX, maxX
    if Hub.AbsoluteSize.X <= viewport.X then
        minX, maxX = halfW, viewport.X - halfW
    else
        minX, maxX = marginX - halfW, viewport.X - marginX + halfW
    end

    local minY, maxY
    if Hub.AbsoluteSize.Y <= viewport.Y then
        minY, maxY = halfH, viewport.Y - halfH
    else
        minY, maxY = marginY - halfH, viewport.Y - marginY + halfH
    end

    centerX = math.clamp(centerX, minX, maxX)
    centerY = math.clamp(centerY, minY, maxY)

    Hub.Position = UDim2.new(
        startPosition.X.Scale,
        centerX - viewport.X * startPosition.X.Scale,
        startPosition.Y.Scale,
        centerY - viewport.Y * startPosition.Y.Scale
    )
end

connect(Header.InputBegan, function(input)
    local inputType = input.UserInputType
    if inputType ~= Enum.UserInputType.Touch
        and inputType ~= Enum.UserInputType.MouseButton1 then
        return
    end

    dragging = true
    dragStart = input.Position
    startPosition = Hub.Position
    activeTouch = inputType == Enum.UserInputType.Touch and input or nil
end)

connect(Header.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

connect(UserInputService.InputChanged, function(input)
    if dragging and dragInput and input == dragInput then
        applyDrag(input)
    elseif dragging and input.UserInputType == Enum.UserInputType.MouseMovement
        and activeTouch == nil then
        -- Fallback for executors/devices where Header.InputChanged is not forwarded.
        applyDrag(input)
    end
end)

connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        stopDragging()
    elseif activeTouch and input == activeTouch then
        stopDragging()
    end
end)

----------------------------------------------------------------
-- BUILTINMODULES: ANIMATIONS
----------------------------------------------------------------

BuiltinModules.Animations = {}

function BuiltinModules.Animations.PlayIntro()
    local total = #Fragments

    for i, fragment in ipairs(Fragments) do
        if not GUI.Parent then
            return
        end

        local x = ((i - 1) % 29) / 28
        local y = math.floor((i - 1) / 29) / 11

        tween(fragment, 0.38 + math.random() * 0.42, {
            Position = UDim2.fromScale(x, math.clamp(y, 0, 1)),
        }, Enum.EasingStyle.Quint)

        if i % 5 == 0 or i == total then
            tween(Progress, 0.12, {
                Size = UDim2.new(i / total, 0, 1, 0),
            })

            FragmentCount.Text = i .. " / " .. total
        end

        task.wait(0.002)
    end

    task.wait(0.55)

    IntroStatus.Text = "ALL FRAGMENTS CONNECTED"

    for _, fragment in ipairs(Fragments) do
        fragment.BackgroundColor3 = C.Text
    end

    ------------------------------------------------------------
    -- AUDIO STARTS AT THE FLASH.
    ------------------------------------------------------------

    BuiltinModules.Audio.PlayFlash()

    tween(IntroPanel, 0.08, {
        BackgroundColor3 = Color3.fromRGB(90, 95, 115),
    })

    task.wait(0.1)

    tween(IntroPanel, 0.16, {
        BackgroundColor3 = C.Panel,
    })

    for _, fragment in ipairs(Fragments) do
        tween(fragment, 1.45, {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 0),
        }, Enum.EasingStyle.Sine)
    end

    tween(Progress, 1.45, {
        BackgroundTransparency = 1,
    })

    tween(FragmentCount, 1.45, {
        TextTransparency = 1,
    })

    task.wait(1.55)

    if not GUI.Parent then
        return
    end

    FragmentArea.Visible = false
    IntroStatus.Text = "ALL SYSTEMS READY"
    TapIn.Visible = true
    TapIn.BackgroundTransparency = 1
    TapIn.TextTransparency = 1

    tween(TapIn, 0.45, {
        BackgroundTransparency = 0,
        TextTransparency = 0,
    })
end

----------------------------------------------------------------
-- RENDER LOOP
----------------------------------------------------------------

local rainbowObjects = {}

for _, object in ipairs(GUI:GetDescendants()) do
    if object:IsA("UIStroke") then
        table.insert(rainbowObjects, object)
    end
end

connect(RunService.RenderStepped, function()
    local now = os.clock()
    local hue = (now * 0.12) % 1

    if BuiltinModules.Settings.Rainbow then
        for _, stroke in ipairs(rainbowObjects) do
            if stroke and stroke.Parent then
                stroke.Color = Color3.fromHSV(
                    (hue + 0.025) % 1,
                    0.88,
                    1
                )
            end
        end
    end

    if Intro.Visible then
        for i, planet in ipairs(Planets) do
            local angle =
                now * (0.75 + i * 0.12)
                + (i - 1) * math.pi / 2

            planet.Position = UDim2.fromOffset(
                75 + math.cos(angle) * 42,
                54 + math.sin(angle) * 32
            )
        end

        Core.Rotation = (now * 35) % 360
    end

    if flyEnabled then
        local humanoid, root = getCharacterParts()

        if not humanoid or not root
            or not flyVelocity or not flyVelocity.Parent then

            setFly(false)
        else
            local direction = humanoid.MoveDirection

            flyVelocity.Velocity =
                direction * 48 + Vector3.new(0, vertical * 38, 0)

            local camera = Workspace.CurrentCamera

            if camera and flyGyro and flyGyro.Parent then
                flyGyro.CFrame = CFrame.new(
                    root.Position,
                    root.Position + camera.CFrame.LookVector
                )
            end
        end
    end

    for i = #installedModels, 1, -1 do
        local entry = installedModels[i]

        if type(entry) ~= "table"
            or not entry.model
            or not entry.model.Parent then

            table.remove(installedModels, i)
        else
            local character = Player.Character
            local root = character
                and character:FindFirstChild("HumanoidRootPart")

            if root and entry.center and entry.center.Parent then
                local base = root.CFrame * CFrame.new(0, 4.5, -6)

                entry.center.CFrame = base

                for index, planet in ipairs(entry.planets) do
                    local angle =
                        now * 1.1 + (index - 1) * math.pi / 2

                    local offset = Vector3.new(
                        math.cos(angle) * 2.7,
                        math.sin(angle * 1.4) * 0.6,
                        math.sin(angle) * 2.7
                    )

                    planet.CFrame = CFrame.new(base.Position + offset)
                end
            end
        end
    end
end)

----------------------------------------------------------------
-- CHARACTER RESPAWN
----------------------------------------------------------------

connect(Player.CharacterAdded, function()
    task.wait(0.8)

    local humanoid = getCharacterParts()

    if humanoid then
        if speedEnabled then
            oldSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = 32
        end

        if jumpEnabled then
            oldJumpPower = humanoid.JumpPower
            oldJumpHeight = humanoid.JumpHeight

            if humanoid.UseJumpPower then
                humanoid.JumpPower = 100
            else
                humanoid.JumpHeight = 50
            end
        end
    end

    if flyEnabled then
        setFly(false)
    end
end)

----------------------------------------------------------------
-- INITIALIZE
----------------------------------------------------------------

BuiltinModules.Initialized = true
ENV.__EPIC_PLANETS_BUILTINMODULES = BuiltinModules

addLog("INFO", "EPIC PLANETS initialized; ScriptBlox store and Logs pages registered")
refreshLogsPage()
showPage("Home")
setStatus("Loading intro")

print("[EPIC PLANETS] Main.lua loaded.")
print("[EPIC PLANETS] BuiltinModules " .. BuiltinModules.Version)

if flashSound then
    print("[EPIC PLANETS AUDIO] Ready for intro flash.")
else
    addLog("WARN", "Audio unavailable; interface will still load.")
    warn("[EPIC PLANETS AUDIO] Audio unavailable; interface will still load.")
end

task.spawn(function()
    local ok, err = pcall(function()
        BuiltinModules.Animations.PlayIntro()
    end)

    if not ok then
        addLog("ERROR", "Intro error: " .. tostring(err))
        warn("[EPIC PLANETS] Intro error: " .. tostring(err))
    end
end)
