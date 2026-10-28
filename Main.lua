
--[[
    EPIC PLANETS
    Main.lua
    PARTE 1 - CORE + UI BASE
    Roblox / Delta / Mobile

    Próximas partes:
      2. Interface principal e navegação
      3. ANIMATIONS
      4. ENVIRONMENT
      5. Player e Movesets
      6. BuiltinModules e ModuleLoader
      7. Models e Personalization
      8. ScriptBlox, Executor e Logs
      9. Tetris e Credits

    Aviso:
    Este bloco é a base inicial. Não execute junto de outra
    cópia completa do EPIC PLANETS, pois criaria duas interfaces.
]]

----------------------------------------------------------------
-- 01. ENVIRONMENT
----------------------------------------------------------------

local ENV = (type(getgenv) == "function" and getgenv()) or _G

----------------------------------------------------------------
-- 02. CLEANUP
----------------------------------------------------------------

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return false
    end

    local ok, result = pcall(callback, ...)
    return ok, result
end

local function disconnectAll(list)
    if type(list) ~= "table" then
        return
    end

    for index = #list, 1, -1 do
        local connection = list[index]

        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end

        list[index] = nil
    end
end

local function destroySafely(object)
    if not object then
        return
    end

    pcall(function()
        object:Destroy()
    end)
end

if type(ENV.__EPIC_PLANETS_CONNECTIONS) == "table" then
    disconnectAll(ENV.__EPIC_PLANETS_CONNECTIONS)
end

if type(ENV.__EPIC_PLANETS_INSTANCES) == "table" then
    for _, object in ipairs(ENV.__EPIC_PLANETS_INSTANCES) do
        destroySafely(object)
    end
end

if type(ENV.__EPIC_PLANETS_AUDIO) == "table" then
    for _, sound in ipairs(ENV.__EPIC_PLANETS_AUDIO) do
        destroySafely(sound)
    end
end

ENV.__EPIC_PLANETS_CONNECTIONS = {}
ENV.__EPIC_PLANETS_INSTANCES = {}
ENV.__EPIC_PLANETS_AUDIO = {}

local Connections = ENV.__EPIC_PLANETS_CONNECTIONS
local Instances = ENV.__EPIC_PLANETS_INSTANCES
local AudioObjects = ENV.__EPIC_PLANETS_AUDIO

----------------------------------------------------------------
-- 03. SERVICES
----------------------------------------------------------------

local Services = {}

local serviceNames = {
    "Players",
    "RunService",
    "TweenService",
    "UserInputService",
    "Lighting",
    "SoundService",
    "HttpService",
    "StarterGui",
    "GuiService",
    "Workspace",
    "ReplicatedStorage",
    "MarketplaceService"
}

for _, serviceName in ipairs(serviceNames) do
    local ok, service = pcall(function()
        return game:GetService(serviceName)
    end)

    if ok then
        Services[serviceName] = service
    end
end

local Players = Services.Players
local RunService = Services.RunService
local TweenService = Services.TweenService
local UserInputService = Services.UserInputService
local Lighting = Services.Lighting
local SoundService = Services.SoundService
local HttpService = Services.HttpService
local StarterGui = Services.StarterGui
local Workspace = Services.Workspace

local LocalPlayer = Players and Players.LocalPlayer

if not LocalPlayer then
    warn("[EPIC PLANETS] LocalPlayer não encontrado.")
    return
end

----------------------------------------------------------------
-- 04. CONFIGURATION
----------------------------------------------------------------

local Config = {
    Name = "EPIC PLANETS",
    Version = "1.0.0",
    Theme = "Rainbow",
    Background = Color3.fromRGB(12, 12, 18),
    Panel = Color3.fromRGB(20, 20, 29),
    PanelLight = Color3.fromRGB(29, 29, 42),
    Text = Color3.fromRGB(245, 245, 255),
    MutedText = Color3.fromRGB(155, 155, 175),
    Accent = Color3.fromRGB(145, 80, 255),
    BorderTransparency = 0.65,
    AnimationSpeed = 0.25,
    RainbowSpeed = 0.12,
    CornerRadius = 10,
    SidebarWidth = 145,
    HeaderHeight = 43,
    MobileScale = 1,
    IntroEnabled = true,
    Minimized = false,
    RainbowEnabled = true,
    ReduceEffects = false
}

----------------------------------------------------------------
-- 05. TITLES
----------------------------------------------------------------

local RandomTitles = {
    "EPIC PLANETS",
    "Don't touch In builtinmodules",
    "BLUEEEEEE",
    "F up",
    "April!",
    "Dont kill the script"
}

local function randomTitle()
    return RandomTitles[math.random(1, #RandomTitles)]
end

----------------------------------------------------------------
-- 06. COLORS
----------------------------------------------------------------

local Colors = {
    Background = Config.Background,
    Panel = Config.Panel,
    PanelLight = Config.PanelLight,
    Text = Config.Text,
    MutedText = Config.MutedText,
    Accent = Config.Accent,
    Red = Color3.fromRGB(255, 75, 95),
    Green = Color3.fromRGB(80, 230, 155),
    Yellow = Color3.fromRGB(255, 210, 90),
    Blue = Color3.fromRGB(80, 160, 255),
    Purple = Color3.fromRGB(165, 90, 255),
    Cyan = Color3.fromRGB(70, 225, 255),
    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0)
}

local function rainbowColor(offset)
    offset = offset or 0

    local hue = (os.clock() * Config.RainbowSpeed + offset) % 1

    return Color3.fromHSV(hue, 0.82, 1)
end

local function getAccent()
    if Config.RainbowEnabled then
        return rainbowColor()
    end

    return Config.Accent
end

----------------------------------------------------------------
-- 07. GENERAL HELPERS
----------------------------------------------------------------

local function create(className, properties, parent)
    local object = Instance.new(className)

    if properties then
        for property, value in pairs(properties) do
            local ok, err = pcall(function()
                object[property] = value
            end)

            if not ok then
                warn("[EPIC PLANETS] Propriedade ignorada:", property, err)
            end
        end
    end

    if parent then
        object.Parent = parent
    end

    table.insert(Instances, object)

    return object
end

local function addConnection(connection)
    if connection then
        table.insert(Connections, connection)
    end

    return connection
end

local function makeCorner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or Config.CornerRadius)
    }, parent)
end

local function makeStroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or getAccent(),
        Thickness = thickness or 1,
        Transparency = transparency or 0.2
    }, parent)
end

local function makePadding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0)
    }, parent)
end

local function makeList(parent, padding, horizontal)
    return create("UIListLayout", {
        Padding = UDim.new(0, padding or 6),
        FillDirection = horizontal
            and Enum.FillDirection.Horizontal
            or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder
    }, parent)
end

local function makeText(parent, text, size, color)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or Colors.Text,
        TextSize = size or 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = false
    }, parent)
end

local function makeButton(parent, text, size)
    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Colors.PanelLight,
        BorderSizePixel = 0,
        Size = size or UDim2.new(1, 0, 0, 34),
        Text = text or "Button",
        TextColor3 = Colors.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium
    }, parent)

    makeCorner(button, 8)
    makeStroke(button, getAccent(), 1, 0.7)

    addConnection(button.MouseEnter:Connect(function()
        if not Config.ReduceEffects then
            TweenService:Create(button, TweenInfo.new(0.12), {
                BackgroundColor3 = Colors.Panel
            }):Play()
        end
    end))

    addConnection(button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {
            BackgroundColor3 = Colors.PanelLight
        }):Play()
    end))

    return button
end

local function makeTween(object, duration, properties)
    if not object or not properties then
        return
    end

    local tweenInfo = TweenInfo.new(
        duration or Config.AnimationSpeed,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    )

    local ok, tween = pcall(function()
        return TweenService:Create(object, tweenInfo, properties)
    end)

    if ok and tween then
        tween:Play()
        return tween
    end
end

local function notify(title, message, duration)
    local ok = pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or Config.Name,
            Text = message or "",
            Duration = duration or 3
        })
    end)

    if not ok then
        print("[EPIC PLANETS] " .. tostring(title) .. ": "
            .. tostring(message))
    end
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local character = getCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local character = getCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

----------------------------------------------------------------
-- 08. SCREEN GUI
----------------------------------------------------------------

local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

if not PlayerGui then
    local ok, result = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui", 10)
    end)

    if ok then
        PlayerGui = result
    end
end

if not PlayerGui then
    warn("[EPIC PLANETS] PlayerGui não encontrado.")
    return
end

local ScreenGui = create("ScreenGui", {
    Name = "EpicPlanets",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100
}, PlayerGui)

----------------------------------------------------------------
-- 09. MAIN WINDOW
----------------------------------------------------------------

local MainFrame = create("Frame", {
    Name = "MainFrame",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 650, 0, 420),
    BackgroundColor3 = Colors.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, ScreenGui)

makeCorner(MainFrame, 13)
makeStroke(MainFrame, getAccent(), 1.4, 0.15)

local MainScale = create("UIScale", {
    Scale = Config.MobileScale
}, MainFrame)

local Header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, Config.HeaderHeight),
    BackgroundColor3 = Colors.Panel,
    BorderSizePixel = 0
}, MainFrame)

local HeaderTitle = makeText(
    Header,
    randomTitle(),
    15,
    Colors.Text
)

HeaderTitle.Name = "HeaderTitle"
HeaderTitle.Position = UDim2.new(0, 14, 0, 0)
HeaderTitle.Size = UDim2.new(1, -115, 1, 0)
HeaderTitle.Font = Enum.Font.GothamBold

local MinimizeButton = makeButton(
    Header,
    "_",
    UDim2.new(0, 30, 0, 27)
)

MinimizeButton.Name = "MinimizeButton"
MinimizeButton.AnchorPoint = Vector2.new(1, 0.5)
MinimizeButton.Position = UDim2.new(1, -43, 0.5, 0)
MinimizeButton.TextSize = 17

local CloseButton = makeButton(
    Header,
    "X",
    UDim2.new(0, 30, 0, 27)
)

CloseButton.Name = "CloseButton"
CloseButton.AnchorPoint = Vector2.new(1, 0.5)
CloseButton.Position = UDim2.new(1, -8, 0.5, 0)
CloseButton.TextColor3 = Colors.Red

----------------------------------------------------------------
-- 10. SIDEBAR + CONTENT
----------------------------------------------------------------

local Sidebar = create("Frame", {
    Name = "Sidebar",
    Position = UDim2.new(0, 0, 0, Config.HeaderHeight),
    Size = UDim2.new(0, Config.SidebarWidth, 1, -Config.HeaderHeight),
    BackgroundColor3 = Colors.Panel,
    BorderSizePixel = 0
}, MainFrame)

local SidebarPadding = makePadding(Sidebar, 8, 8, 10, 10)

local SidebarLayout = makeList(Sidebar, 5, false)

local Content = create("Frame", {
    Name = "Content",
    Position = UDim2.new(0, Config.SidebarWidth, 0, Config.HeaderHeight),
    Size = UDim2.new(1, -Config.SidebarWidth, 1, -Config.HeaderHeight),
    BackgroundColor3 = Colors.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, MainFrame)

local PageRegistry = {}
local ButtonRegistry = {}
local CurrentPage = nil

----------------------------------------------------------------
-- 11. PAGE SYSTEM
----------------------------------------------------------------

local function createPage(name)
    if PageRegistry[name] then
        return PageRegistry[name]
    end

    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = getAccent(),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false
    }, Content)

    makePadding(page, 12, 12, 12, 12)
    makeList(page, 8, false)

    PageRegistry[name] = page

    return page
end

local function showPage(name)
    local page = PageRegistry[name]

    if not page then
        warn("[EPIC PLANETS] Página não existe:", name)
        return
    end

    for pageName, registeredPage in pairs(PageRegistry) do
        registeredPage.Visible = pageName == name
    end

    for buttonName, button in pairs(ButtonRegistry) do
        local selected = buttonName == name

        button.BackgroundColor3 = selected
            and Colors.PanelLight
            or Colors.Panel
    end

    CurrentPage = name
end

local function createTab(name, iconText)
    local button = makeButton(
        Sidebar,
        (iconText and iconText .. "  " or "") .. name,
        UDim2.new(1, 0, 0, 32)
    )

    button.Name = name .. "Tab"
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.TextSize = 12
    button.LayoutOrder = #Sidebar:GetChildren()

    makePadding(button, 9, 4, 0, 0)

    local page = createPage(name)

    ButtonRegistry[name] = button

    addConnection(button.Activated:Connect(function()
        showPage(name)
    end))

    return page, button
end

----------------------------------------------------------------
-- 12. INITIAL PAGES
----------------------------------------------------------------

local HomePage = createTab("Home", "✦")
local PlayerPage = createTab("Player", "◈")
local AnimationsPage = createTab("ANIMATIONS", "♪")
local EnvironmentPage = createTab("ENVIRONMENT", "☼")
local BuiltinsPage = createTab("BuiltinModules", "◇")
local MovesetsPage = createTab("Movesets", "✧")
local ModelsPage = createTab("Models", "◎")
local SettingsPage = createTab("Settings", "⚙")
local PersonalizationPage = createTab("Personalization", "✿")
local LogsPage = createTab("Logs", "▤")
local CreditsPage = createTab("Credits", "★")

----------------------------------------------------------------
-- 13. HOME PAGE
----------------------------------------------------------------

local HomeTitle = makeText(
    HomePage,
    "EPIC PLANETS",
    23,
    Colors.Text
)

HomeTitle.Size = UDim2.new(1, 0, 0, 35)
HomeTitle.Font = Enum.Font.GothamBlack

local HomeSubtitle = makeText(
    HomePage,
    "A small universe inside your interface.",
    12,
    Colors.MutedText
)

HomeSubtitle.Size = UDim2.new(1, 0, 0, 23)

local StatusCard = create("Frame", {
    Name = "StatusCard",
    Size = UDim2.new(1, 0, 0, 75),
    BackgroundColor3 = Colors.Panel,
    BorderSizePixel = 0
}, HomePage)

makeCorner(StatusCard, 10)
makeStroke(StatusCard, getAccent(), 1, 0.55)
makePadding(StatusCard, 12, 12, 8, 8)

local StatusTitle = makeText(
    StatusCard,
    "SYSTEM STATUS",
    12,
    getAccent()
)

StatusTitle.Size = UDim2.new(1, 0, 0, 20)
StatusTitle.Font = Enum.Font.GothamBold

local StatusText = makeText(
    StatusCard,
    "EPIC PLANETS carregado.",
    12,
    Colors.MutedText
)

StatusText.Position = UDim2.new(0, 0, 0, 27)
StatusText.Size = UDim2.new(1, 0, 0, 25)

local WelcomeText = makeText(
    HomePage,
    "Escolha uma aba na lateral para explorar os módulos.",
    13,
    Colors.Text
)

WelcomeText.Size = UDim2.new(1, 0, 0, 28)
WelcomeText.TextWrapped = true

----------------------------------------------------------------
-- 14. ANIMATIONS PAGE PLACEHOLDER
----------------------------------------------------------------

local AnimationsTitle = makeText(
    AnimationsPage,
    "ANIMATIONS",
    20,
    Colors.Text
)

AnimationsTitle.Size = UDim2.new(1, 0, 0, 32)
AnimationsTitle.Font = Enum.Font.GothamBold

local AnimationsDescription = makeText(
    AnimationsPage,
    "Controles de animação serão conectados na Parte 3.",
    12,
    Colors.MutedText
)

AnimationsDescription.Size = UDim2.new(1, 0, 0, 28)
AnimationsDescription.TextWrapped = true

----------------------------------------------------------------
-- 15. ENVIRONMENT PAGE PLACEHOLDER
----------------------------------------------------------------

local EnvironmentTitle = makeText(
    EnvironmentPage,
    "ENVIRONMENT",
    20,
    Colors.Text
)

EnvironmentTitle.Size = UDim2.new(1, 0, 0, 32)
EnvironmentTitle.Font = Enum.Font.GothamBold

local EnvironmentDescription = makeText(
    EnvironmentPage,
    "Dia/noite, gravidade e ambiente serão ligados na Parte 4.",
    12,
    Colors.MutedText
)

EnvironmentDescription.Size = UDim2.new(1, 0, 0, 34)
EnvironmentDescription.TextWrapped = true

----------------------------------------------------------------
-- 16. SETTINGS PAGE
----------------------------------------------------------------

local SettingsTitle = makeText(
    SettingsPage,
    "SETTINGS",
    20,
    Colors.Text
)

SettingsTitle.Size = UDim2.new(1, 0, 0, 32)
SettingsTitle.Font = Enum.Font.GothamBold

local RainbowToggle = makeButton(
    SettingsPage,
    "Rainbow Aura: ON",
    UDim2.new(1, 0, 0, 36)
)

addConnection(RainbowToggle.Activated:Connect(function()
    Config.RainbowEnabled = not Config.RainbowEnabled

    RainbowToggle.Text = "Rainbow Aura: "
        .. (Config.RainbowEnabled and "ON" or "OFF")

    notify(
        Config.Name,
        "Rainbow Aura " .. (Config.RainbowEnabled and "ativada" or "desativada")
    )
end))

local EffectsToggle = makeButton(
    SettingsPage,
    "Reduce Effects: OFF",
    UDim2.new(1, 0, 0, 36)
)

addConnection(EffectsToggle.Activated:Connect(function()
    Config.ReduceEffects = not Config.ReduceEffects

    EffectsToggle.Text = "Reduce Effects: "
        .. (Config.ReduceEffects and "ON" or "OFF")
end))

----------------------------------------------------------------
-- 17. MINIMIZE / CLOSE
----------------------------------------------------------------

local function setMinimized(state)
    Config.Minimized = state

    Sidebar.Visible = not state
    Content.Visible = not state

    local targetHeight = state and Config.HeaderHeight or 420

    makeTween(MainFrame, 0.2, {
        Size = UDim2.new(0, 650, 0, targetHeight)
    })

    MinimizeButton.Text = state and "+" or "_"
end

addConnection(MinimizeButton.Activated:Connect(function()
    setMinimized(not Config.Minimized)
end))

addConnection(CloseButton.Activated:Connect(function()
    destroySafely(ScreenGui)
end))

----------------------------------------------------------------
-- 18. DRAGGING
----------------------------------------------------------------

local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil

addConnection(Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end))

addConnection(Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        dragInput = input
    end
end))

addConnection(UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging and dragStart and startPosition then
        local delta = input.Position - dragStart

        MainFrame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end))

----------------------------------------------------------------
-- 19. RAINBOW LOOP
----------------------------------------------------------------

local rainbowElapsed = 0

addConnection(RunService.RenderStepped:Connect(function(deltaTime)
    rainbowElapsed = rainbowElapsed + deltaTime

    if rainbowElapsed < 0.04 then
        return
    end

    rainbowElapsed = 0

    local accent = getAccent()

    local mainStroke = MainFrame:FindFirstChildOfClass("UIStroke")

    if mainStroke then
        mainStroke.Color = accent
    end

    local statusStroke = StatusCard:FindFirstChildOfClass("UIStroke")

    if statusStroke then
        statusStroke.Color = accent
    end

    StatusTitle.TextColor3 = accent

    for _, button in pairs(ButtonRegistry) do
        local stroke = button:FindFirstChildOfClass("UIStroke")

        if stroke then
            stroke.Color = accent
        end
    end
end))

----------------------------------------------------------------
-- 20. INITIALIZE
----------------------------------------------------------------

showPage("Home")

notify(
    "EPIC PLANETS",
    "Parte 1 carregada. Interface base pronta!",
    4
)

print("[EPIC PLANETS] Parte 1 inicializada.")
print("[EPIC PLANETS] Páginas criadas:")
for pageName in pairs(PageRegistry) do
    print(" - " .. pageName)
end

-- FIM DA PARTE 1
-- A Parte 2 deve continuar esta mesma estrutura.

----------------------------------------------------------------
-- EPIC PLANETS
-- PARTE 2: COMPONENTES + NAVEGAÇÃO + PÁGINAS
-- Continuação da Parte 1
----------------------------------------------------------------

----------------------------------------------------------------
-- 21. UI COMPONENT HELPERS
----------------------------------------------------------------

local function createSection(parent, title, description)
    local section = create("Frame", {
        Name = title:gsub("%s+", "") .. "Section",
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = Colors.Panel,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y
    }, parent)

    makeCorner(section, 9)
    makeStroke(section, getAccent(), 1, 0.75)
    makePadding(section, 10, 10, 9, 9)

    local layout = makeList(section, 5, false)

    local heading = makeText(section, title, 14, Colors.Text)
    heading.Size = UDim2.new(1, 0, 0, 23)
    heading.Font = Enum.Font.GothamBold
    heading.LayoutOrder = 1

    if description and description ~= "" then
        local desc = makeText(section, description, 11, Colors.MutedText)
        desc.Size = UDim2.new(1, 0, 0, 28)
        desc.TextWrapped = true
        desc.LayoutOrder = 2
    end

    return section
end

local function createActionButton(parent, title, callback)
    local button = makeButton(
        parent,
        title,
        UDim2.new(1, 0, 0, 34)
    )

    if type(callback) == "function" then
        addConnection(button.Activated:Connect(function()
            local ok, err = pcall(callback)

            if not ok then
                warn("[EPIC PLANETS] Ação falhou:", title, err)
                notify("EPIC PLANETS", "Erro na ação: " .. title)
            end
        end))
    end

    return button
end

local function createToggle(parent, title, initialValue, callback)
    local value = initialValue == true

    local button = makeButton(
        parent,
        title .. ": " .. (value and "ON" or "OFF"),
        UDim2.new(1, 0, 0, 34)
    )

    local function update()
        button.Text = title .. ": " .. (value and "ON" or "OFF")
        button.TextColor3 = value and Colors.Green or Colors.Text
    end

    addConnection(button.Activated:Connect(function()
        value = not value
        update()

        if type(callback) == "function" then
            local ok, err = pcall(callback, value)

            if not ok then
                warn("[EPIC PLANETS] Toggle falhou:", title, err)
            end
        end
    end))

    update()

    return {
        Button = button,

        Get = function()
            return value
        end,

        Set = function(newValue)
            value = newValue == true
            update()
        end
    }
end

local function createValueSlider(parent, title, minValue, maxValue, startValue, callback)
    minValue = tonumber(minValue) or 0
    maxValue = tonumber(maxValue) or 100
    startValue = math.clamp(
        tonumber(startValue) or minValue,
        minValue,
        maxValue
    )

    local holder = create("Frame", {
        Name = title:gsub("%s+", "") .. "Slider",
        Size = UDim2.new(1, 0, 0, 65),
        BackgroundTransparency = 1
    }, parent)

    local label = makeText(holder, "", 12, Colors.Text)
    label.Size = UDim2.new(1, 0, 0, 23)

    local track = create("Frame", {
        Name = "Track",
        Position = UDim2.new(0, 0, 0, 34),
        Size = UDim2.new(1, 0, 0, 7),
        BackgroundColor3 = Colors.PanelLight,
        BorderSizePixel = 0
    }, holder)

    makeCorner(track, 5)

    local fill = create("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = getAccent(),
        BorderSizePixel = 0
    }, track)

    makeCorner(fill, 5)

    local knob = create("Frame", {
        Name = "Knob",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 15, 0, 15),
        BackgroundColor3 = Colors.White,
        BorderSizePixel = 0,
        ZIndex = 3
    }, track)

    makeCorner(knob, 8)

    local value = startValue
    local changing = false

    local function update(newValue, fireCallback)
        value = math.clamp(newValue, minValue, maxValue)

        local ratio = 0

        if maxValue > minValue then
            ratio = (value - minValue) / (maxValue - minValue)
        end

        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        label.Text = title .. ": " .. tostring(math.floor(value + 0.5))

        if fireCallback and type(callback) == "function" then
            pcall(callback, value)
        end
    end

    local function setFromX(x)
        local width = track.AbsoluteSize.X

        if width <= 0 then
            return
        end

        local relative = math.clamp(
            (x - track.AbsolutePosition.X) / width,
            0,
            1
        )

        update(
            minValue + relative * (maxValue - minValue),
            true
        )
    end

    addConnection(track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            changing = true
            setFromX(input.Position.X)
        end
    end))

    addConnection(UserInputService.InputChanged:Connect(function(input)
        if changing and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            setFromX(input.Position.X)
        end
    end))

    addConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            changing = false
        end
    end))

    update(startValue, false)

    return {
        Get = function()
            return value
        end,

        Set = function(newValue)
            update(tonumber(newValue) or minValue, true)
        end
    }
end

----------------------------------------------------------------
-- 22. PLAYER PAGE
----------------------------------------------------------------

local PlayerTitle = makeText(
    PlayerPage,
    "PLAYER CONTROLS",
    20,
    Colors.Text
)

PlayerTitle.Size = UDim2.new(1, 0, 0, 32)
PlayerTitle.Font = Enum.Font.GothamBold

local PlayerInfo = makeText(
    PlayerPage,
    "Ajustes locais do personagem.",
    12,
    Colors.MutedText
)

PlayerInfo.Size = UDim2.new(1, 0, 0, 25)

local MovementSection = createSection(
    PlayerPage,
    "Movement",
    "Ajuste a velocidade e o salto do personagem."
)

local speedValue = 16
local jumpValue = 50

createValueSlider(
    MovementSection,
    "WalkSpeed",
    8,
    100,
    speedValue,
    function(value)
        speedValue = value

        local humanoid = getHumanoid()

        if humanoid then
            humanoid.WalkSpeed = value
        end
    end
)

createValueSlider(
    MovementSection,
    "JumpPower",
    20,
    150,
    jumpValue,
    function(value)
        jumpValue = value

        local humanoid = getHumanoid()

        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = value
        end
    end
)

createActionButton(
    MovementSection,
    "Reset movement",
    function()
        speedValue = 16
        jumpValue = 50

        local humanoid = getHumanoid()

        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.UseJumpPower = true
            humanoid.JumpPower = 50
        end

        notify("PLAYER", "Movimento restaurado.")
    end
)

----------------------------------------------------------------
-- 23. BUILTIN MODULES PAGE
----------------------------------------------------------------

local BuiltinsTitle = makeText(
    BuiltinsPage,
    "BUILTIN MODULES",
    20,
    Colors.Text
)

BuiltinsTitle.Size = UDim2.new(1, 0, 0, 32)
BuiltinsTitle.Font = Enum.Font.GothamBold

local BuiltinsInfo = makeText(
    BuiltinsPage,
    "Módulos locais registrados pelo EPIC PLANETS.",
    12,
    Colors.MutedText
)

BuiltinsInfo.Size = UDim2.new(1, 0, 0, 25)

local ModuleRegistry = {}

local function registerModule(name, description, callback)
    ModuleRegistry[name] = {
        Name = name,
        Description = description or "",
        Callback = callback,
        Enabled = false
    }
end

local function renderModule(name)
    local moduleData = ModuleRegistry[name]

    if not moduleData then
        return
    end

    local section = createSection(
        BuiltinsPage,
        moduleData.Name,
        moduleData.Description
    )

    createActionButton(
        section,
        "Run module",
        function()
            if type(moduleData.Callback) ~= "function" then
                notify("BUILTIN MODULES", "Este módulo ainda não foi conectado.")
                return
            end

            moduleData.Callback()
        end
    )
end

registerModule(
    "UI",
    "Controles da interface principal.",
    function()
        if ScreenGui and ScreenGui.Parent then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end
)

registerModule(
    "Audio",
    "Área reservada para os controles de áudio.",
    function()
        notify("AUDIO", "Os controles de áudio serão ligados na Parte 7.")
    end
)

registerModule(
    "Settings",
    "Configurações visuais e comportamento da interface.",
    function()
        notify("SETTINGS", "Abra a aba Settings para ajustar a interface.")
    end
)

registerModule(
    "ModuleLoader",
    "Registro local de módulos do projeto.",
    function()
        local total = 0

        for _ in pairs(ModuleRegistry) do
            total = total + 1
        end

        notify("MODULE LOADER", total .. " módulos registrados.")
    end
)

for moduleName in pairs(ModuleRegistry) do
    renderModule(moduleName)
end

----------------------------------------------------------------
-- 24. MOVESETS PAGE
----------------------------------------------------------------

local MovesetsTitle = makeText(
    MovesetsPage,
    "MOVESETS",
    20,
    Colors.Text
)

MovesetsTitle.Size = UDim2.new(1, 0, 0, 32)
MovesetsTitle.Font = Enum.Font.GothamBold

local MovesetsInfo = makeText(
    MovesetsPage,
    "Ações de movimento e animações serão conectadas aqui.",
    12,
    Colors.MutedText
)

MovesetsInfo.Size = UDim2.new(1, 0, 0, 30)
MovesetsInfo.TextWrapped = true

local MovesetsSection = createSection(
    MovesetsPage,
    "Available actions",
    "Os módulos podem ser registrados pelo próprio projeto."
)

createActionButton(
    MovesetsSection,
    "Refresh character",
    function()
        local character = getCharacter()

        if character then
            notify("MOVESETS", "Personagem encontrado.")
        else
            notify("MOVESETS", "Personagem ainda não carregou.")
        end
    end
)

createActionButton(
    MovesetsSection,
    "List registered modules",
    function()
        for name in pairs(ModuleRegistry) do
            print("[EPIC PLANETS MODULE] " .. name)
        end

        notify("MOVESETS", "Lista enviada ao console.")
    end
)

----------------------------------------------------------------
-- 25. MODELS PAGE
----------------------------------------------------------------

local ModelsTitle = makeText(
    ModelsPage,
    "MODELS",
    20,
    Colors.Text
)

ModelsTitle.Size = UDim2.new(1, 0, 0, 32)
ModelsTitle.Font = Enum.Font.GothamBold

local ModelsInfo = makeText(
    ModelsPage,
    "Gerencie os modelos locais criados pelo hub.",
    12,
    Colors.MutedText
)

ModelsInfo.Size = UDim2.new(1, 0, 0, 27)

local ModelSection = createSection(
    ModelsPage,
    "Model registry",
    "Os objetos criados nesta sessão podem ser acompanhados aqui."
)

createActionButton(
    ModelSection,
    "Count tracked instances",
    function()
        local total = 0

        for _, object in ipairs(Instances) do
            if object and object.Parent then
                total = total + 1
            end
        end

        notify("MODELS", total .. " instâncias acompanhadas.")
    end
)

createActionButton(
    ModelSection,
    "Cleanup tracked audio",
    function()
        for index = #AudioObjects, 1, -1 do
            destroySafely(AudioObjects[index])
            AudioObjects[index] = nil
        end

        notify("MODELS", "Áudio rastreado removido.")
    end
)

----------------------------------------------------------------
-- 26. PERSONALIZATION PAGE
----------------------------------------------------------------

local PersonalizationTitle = makeText(
    PersonalizationPage,
    "PERSONALIZATION",
    20,
    Colors.Text
)

PersonalizationTitle.Size = UDim2.new(1, 0, 0, 32)
PersonalizationTitle.Font = Enum.Font.GothamBold

local PersonalizationInfo = makeText(
    PersonalizationPage,
    "Personalize o visual da interface.",
    12,
    Colors.MutedText
)

PersonalizationInfo.Size = UDim2.new(1, 0, 0, 25)

local AppearanceSection = createSection(
    PersonalizationPage,
    "Appearance",
    "Mude o estilo da interface sem recriar o hub."
)

createActionButton(
    AppearanceSection,
    "Purple accent",
    function()
        Config.RainbowEnabled = false
        Config.Accent = Colors.Purple

        notify("PERSONALIZATION", "Acento roxo selecionado.")
    end
)

createActionButton(
    AppearanceSection,
    "Cyan accent",
    function()
        Config.RainbowEnabled = false
        Config.Accent = Colors.Cyan

        notify("PERSONALIZATION", "Acento ciano selecionado.")
    end
)

createActionButton(
    AppearanceSection,
    "Rainbow accent",
    function()
        Config.RainbowEnabled = true

        notify("PERSONALIZATION", "Aura rainbow ativada.")
    end
)

----------------------------------------------------------------
-- 27. LOGS PAGE
----------------------------------------------------------------

local LogsTitle = makeText(
    LogsPage,
    "RUNTIME LOGS",
    20,
    Colors.Text
)

LogsTitle.Size = UDim2.new(1, 0, 0, 32)
LogsTitle.Font = Enum.Font.GothamBold

local LogsInfo = makeText(
    LogsPage,
    "Mensagens produzidas pelo EPIC PLANETS.",
    12,
    Colors.MutedText
)

LogsInfo.Size = UDim2.new(1, 0, 0, 25)

local LogEntries = {}

local LogContainer = create("Frame", {
    Name = "LogContainer",
    Size = UDim2.new(1, 0, 0, 180),
    BackgroundColor3 = Colors.Panel,
    BorderSizePixel = 0
}, LogsPage)

makeCorner(LogContainer, 8)
makePadding(LogContainer, 8, 8, 8, 8)

local LogLayout = makeList(LogContainer, 4, false)

local function addLog(message)
    message = tostring(message)

    table.insert(LogEntries, 1, message)

    while #LogEntries > 30 do
        table.remove(LogEntries)
    end

    for _, child in ipairs(LogContainer:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    for index, entry in ipairs(LogEntries) do
        local label = makeText(
            LogContainer,
            "[" .. index .. "] " .. entry,
            11,
            Colors.MutedText
        )

        label.Size = UDim2.new(1, 0, 0, 20)
        label.LayoutOrder = index
    end

    LogContainer.AutomaticSize = Enum.AutomaticSize.Y
end

createActionButton(
    LogsPage,
    "Add test log",
    function()
        addLog("Teste de log em " .. os.date("%H:%M:%S"))
    end
)

createActionButton(
    LogsPage,
    "Clear logs",
    function()
        table.clear(LogEntries)

        for _, child in ipairs(LogContainer:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        notify("LOGS", "Logs apagados.")
    end
)

----------------------------------------------------------------
-- 28. CREDITS PAGE
----------------------------------------------------------------

local CreditsTitle = makeText(
    CreditsPage,
    "CREDITS",
    20,
    Colors.Text
)

CreditsTitle.Size = UDim2.new(1, 0, 0, 32)
CreditsTitle.Font = Enum.Font.GothamBold

local CreditsInfo = makeText(
    CreditsPage,
    "EPIC PLANETS | Interface modular",
    13,
    Colors.MutedText
)

CreditsInfo.Size = UDim2.new(1, 0, 0, 28)

local CreditsSection = createSection(
    CreditsPage,
    "Project",
    "Uma interface experimental construída em módulos."
)

createActionButton(
    CreditsSection,
    "Show version",
    function()
        notify("EPIC PLANETS", "Versão " .. Config.Version)
    end
)

createActionButton(
    CreditsSection,
    "Show tracked pages",
    function()
        local total = 0

        for _ in pairs(PageRegistry) do
            total = total + 1
        end

        notify("EPIC PLANETS", total .. " páginas registradas.")
    end
)

----------------------------------------------------------------
-- 29. CHARACTER RESPAWN SUPPORT
----------------------------------------------------------------

addConnection(LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)

    if character and character.Parent then
        addLog("Personagem carregado novamente.")

        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            pcall(function()
                humanoid.UseJumpPower = true
            end)
        end
    end
end))

----------------------------------------------------------------
-- 30. FINISH PART 2
----------------------------------------------------------------

addLog("Parte 2 inicializada.")
addLog("Sistema de páginas conectado.")
addLog("Componentes de interface registrados.")

showPage("Home")

notify(
    "EPIC PLANETS",
    "Parte 2 carregada!",
    4
)

print("[EPIC PLANETS] Parte 2 inicializada.")
print("[EPIC PLANETS] Páginas disponíveis:")

for pageName in pairs(PageRegistry) do
    print(" - " .. pageName)
end

-- FIM DA PARTE 2
----------------------------------------------------------------

----------------------------------------------------------------
-- EPIC PLANETS
-- PARTE 3: ANIMATIONS
----------------------------------------------------------------

----------------------------------------------------------------
-- 31. ANIMATION CONFIG
----------------------------------------------------------------

local AnimationConfig = {
    DefaultSpeed = 1,
    CurrentTrack = nil,
    CurrentAnimationId = nil,
    CustomIds = {},
    Tracks = {},
    Categories = {
        "Dance",
        "Funny",
        "Gestures",
        "Custom"
    }
}

local function normalizeAnimationId(value)
    if value == nil then
        return nil
    end

    local textValue = tostring(value)
    local digits = textValue:match("%d+")

    if not digits or digits == "0" then
        return nil
    end

    return digits
end

----------------------------------------------------------------
-- 32. ANIMATION SERVICE HELPERS
----------------------------------------------------------------

local function getAnimator()
    local humanoid = getHumanoid()

    if not humanoid then
        return nil, "Personagem não encontrado."
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")

    if not animator then
        local ok, result = pcall(function()
            local newAnimator = Instance.new("Animator")
            newAnimator.Parent = humanoid
            return newAnimator
        end)

        if not ok then
            return nil, "Não foi possível obter o Animator."
        end

        animator = result
    end

    return animator
end

local function stopCurrentAnimation(fadeTime)
    local track = AnimationConfig.CurrentTrack

    if track then
        pcall(function()
            track:Stop(fadeTime or 0.15)
        end)

        pcall(function()
            track:Destroy()
        end)
    end

    AnimationConfig.CurrentTrack = nil
    AnimationConfig.CurrentAnimationId = nil
end

local function stopAllTrackedAnimations()
    stopCurrentAnimation()

    for index = #AnimationConfig.Tracks, 1, -1 do
        local track = AnimationConfig.Tracks[index]

        if track then
            pcall(function()
                track:Stop(0.1)
            end)

            pcall(function()
                track:Destroy()
            end)
        end

        AnimationConfig.Tracks[index] = nil
    end

    local humanoid = getHumanoid()
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

    if animator then
        pcall(function()
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0.1)
            end
        end)
    end
end

----------------------------------------------------------------
-- 33. PLAY ANIMATION
----------------------------------------------------------------

local function playAnimation(animationId, speed, looped)
    local normalizedId = normalizeAnimationId(animationId)

    if not normalizedId then
        notify(
            "ANIMATIONS",
            "Configure um ID de animação válido primeiro."
        )

        return false
    end

    local animator, reason = getAnimator()

    if not animator then
        notify("ANIMATIONS", reason or "Animator indisponível.")
        return false
    end

    stopCurrentAnimation(0.12)

    local animation = Instance.new("Animation")
    animation.Name = "EpicPlanetsAnimation"
    animation.AnimationId = "rbxassetid://" .. normalizedId

    local ok, trackOrError = pcall(function()
        return animator:LoadAnimation(animation)
    end)

    if not ok or not trackOrError then
        animation:Destroy()

        notify(
            "ANIMATIONS",
            "Falha ao carregar. Verifique o ID e as permissões."
        )

        warn("[EPIC PLANETS] LoadAnimation:", trackOrError)

        return false
    end

    local track = trackOrError

    local playOk, playError = pcall(function()
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = looped == true
        track:Play(0.15, 1, math.clamp(tonumber(speed) or 1, 0.1, 3))
    end)

    if not playOk then
        pcall(function()
            track:Destroy()
        end)

        animation:Destroy()

        warn("[EPIC PLANETS] Play:", playError)

        notify("ANIMATIONS", "Não foi possível iniciar a animação.")

        return false
    end

    AnimationConfig.CurrentTrack = track
    AnimationConfig.CurrentAnimationId = normalizedId

    table.insert(AnimationConfig.Tracks, track)

    addConnection(track.Stopped:Connect(function()
        if AnimationConfig.CurrentTrack == track then
            AnimationConfig.CurrentTrack = nil
            AnimationConfig.CurrentAnimationId = nil
        end
    end))

    -- A instância Animation já foi carregada pelo Animator.
    -- Mantemos a referência da track para permitir parar a animação.
    task.delay(2, function()
        if animation and animation.Parent == nil then
            pcall(function()
                animation:Destroy()
            end)
        end
    end)

    addLog("Animação iniciada: " .. normalizedId)

    return true
end

----------------------------------------------------------------
-- 34. CUSTOM ANIMATION REGISTRY
----------------------------------------------------------------

local function registerAnimation(name, animationId, category, description)
    if type(name) ~= "string" or name == "" then
        return false
    end

    local normalizedId = normalizeAnimationId(animationId)

    if not normalizedId then
        return false
    end

    AnimationConfig.CustomIds[name] = {
        Name = name,
        Id = normalizedId,
        Category = category or "Custom",
        Description = description or ""
    }

    return true
end

local function playRegisteredAnimation(name, looped)
    local entry = AnimationConfig.CustomIds[name]

    if not entry then
        notify("ANIMATIONS", "Animação não registrada: " .. tostring(name))
        return false
    end

    return playAnimation(entry.Id, AnimationConfig.DefaultSpeed, looped)
end

----------------------------------------------------------------
-- 35. ANIMATIONS PAGE UI
----------------------------------------------------------------

local AnimationHeader = createSection(
    AnimationsPage,
    "Animation Controls",
    "Use IDs de animações que você tenha permissão para executar."
)

local AnimationIdBox = create("TextBox", {
    Name = "AnimationIdBox",
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = Colors.PanelLight,
    BorderSizePixel = 0,
    PlaceholderText = "ID da animação",
    PlaceholderColor3 = Colors.MutedText,
    Text = "",
    TextColor3 = Colors.Text,
    TextSize = 13,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, AnimationHeader)

makeCorner(AnimationIdBox, 8)
makePadding(AnimationIdBox, 10, 10, 0, 0)

local AnimationLoopToggle = createToggle(
    AnimationHeader,
    "Loop",
    false
)

local AnimationSpeedSlider = createValueSlider(
    AnimationHeader,
    "Animation Speed",
    1,
    30,
    10,
    function(value)
        AnimationConfig.DefaultSpeed = value / 10
    end
)

local PlayCustomButton = createActionButton(
    AnimationHeader,
    "▶ Play animation ID",
    function()
        playAnimation(
            AnimationIdBox.Text,
            AnimationConfig.DefaultSpeed,
            AnimationLoopToggle.Get()
        )
    end
)

local StopAnimationButton = createActionButton(
    AnimationHeader,
    "■ Stop current animation",
    function()
        stopCurrentAnimation()
        addLog("Animação atual parada.")
        notify("ANIMATIONS", "Animação parada.")
    end
)

local StopAllButton = createActionButton(
    AnimationHeader,
    "Stop all playing animations",
    function()
        stopAllTrackedAnimations()
        notify("ANIMATIONS", "Animações interrompidas.")
    end
)

----------------------------------------------------------------
-- 36. QUICK ANIMATION CARDS
----------------------------------------------------------------

local QuickAnimationsSection = createSection(
    AnimationsPage,
    "Quick animations",
    "Cadastre os IDs abaixo para criar atalhos personalizados."
)

local function createQuickAnimationButton(name, category)
    return createActionButton(
        QuickAnimationsSection,
        name,
        function()
            local entry = AnimationConfig.CustomIds[name]

            if not entry then
                notify(
                    "ANIMATIONS",
                    "Cadastre um ID para \"" .. name .. "\" primeiro."
                )

                return
            end

            playRegisteredAnimation(name, AnimationLoopToggle.Get())
        end
    )
end

createQuickAnimationButton("Gangnam Style", "Dance")
createQuickAnimationButton("Floss", "Dance")
createQuickAnimationButton("Macarena", "Dance")
createQuickAnimationButton("Point", "Gestures")
createQuickAnimationButton("Laugh", "Funny")

----------------------------------------------------------------
-- 37. REGISTER CUSTOM IDS
----------------------------------------------------------------

local CustomRegistrySection = createSection(
    AnimationsPage,
    "Custom animation registry",
    "Informe um nome e um ID para salvar um atalho nesta sessão."
)

local CustomNameBox = create("TextBox", {
    Name = "CustomAnimationName",
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundColor3 = Colors.PanelLight,
    BorderSizePixel = 0,
    PlaceholderText = "Nome: por exemplo, Minha dança",
    PlaceholderColor3 = Colors.MutedText,
    Text = "",
    TextColor3 = Colors.Text,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, CustomRegistrySection)

makeCorner(CustomNameBox, 8)
makePadding(CustomNameBox, 9, 9, 0, 0)

local CustomIdBox = create("TextBox", {
    Name = "CustomAnimationId",
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundColor3 = Colors.PanelLight,
    BorderSizePixel = 0,
    PlaceholderText = "ID numérico da animação",
    PlaceholderColor3 = Colors.MutedText,
    Text = "",
    TextColor3 = Colors.Text,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, CustomRegistrySection)

makeCorner(CustomIdBox, 8)
makePadding(CustomIdBox, 9, 9, 0, 0)

local CategoryBox = create("TextBox", {
    Name = "CustomAnimationCategory",
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundColor3 = Colors.PanelLight,
    BorderSizePixel = 0,
    PlaceholderText = "Categoria: Dance, Funny, Gestures ou Custom",
    PlaceholderColor3 = Colors.MutedText,
    Text = "Custom",
    TextColor3 = Colors.Text,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, CustomRegistrySection)

makeCorner(CategoryBox, 8)
makePadding(CategoryBox, 9, 9, 0, 0)

createActionButton(
    CustomRegistrySection,
    "＋ Register animation",
    function()
        local name = CustomNameBox.Text
        local id = CustomIdBox.Text
        local category = CategoryBox.Text

        if name == "" then
            notify("ANIMATIONS", "Digite um nome.")
            return
        end

        if not registerAnimation(
            name,
            id,
            category,
            "Animação personalizada"
        ) then
            notify("ANIMATIONS", "ID inválido. Use um ID numérico.")
            return
        end

        notify("ANIMATIONS", "Atalho registrado: " .. name)
        addLog("Animação registrada: " .. name)

        CustomNameBox.Text = ""
        CustomIdBox.Text = ""
    end
)

----------------------------------------------------------------
-- 38. ANIMATION STATUS
----------------------------------------------------------------

local AnimationStatusSection = createSection(
    AnimationsPage,
    "Status",
    "Estado da animação atualmente controlada pelo hub."
)

local AnimationStatusLabel = makeText(
    AnimationStatusSection,
    "Nenhuma animação selecionada.",
    12,
    Colors.MutedText
)

AnimationStatusLabel.Size = UDim2.new(1, 0, 0, 24)

local StatusUpdateConnection = addConnection(
    RunService.Heartbeat:Connect(function()
        local currentId = AnimationConfig.CurrentAnimationId

        if currentId then
            AnimationStatusLabel.Text = "Playing ID: " .. currentId
            AnimationStatusLabel.TextColor3 = Colors.Green
        else
            AnimationStatusLabel.Text = "Nenhuma animação controlada."
            AnimationStatusLabel.TextColor3 = Colors.MutedText
        end
    end)
)

----------------------------------------------------------------
-- 39. CHARACTER CHANGE HANDLING
----------------------------------------------------------------

addConnection(LocalPlayer.CharacterAdded:Connect(function()
    stopCurrentAnimation()

    task.wait(0.5)

    if getHumanoid() then
        addLog("Animator pronto para novo personagem.")
    end
end))

----------------------------------------------------------------
-- 40. FINISH PART 3
----------------------------------------------------------------

addLog("Parte 3: ANIMATIONS registrada.")

notify(
    "EPIC PLANETS",
    "ANIMATIONS carregada. Configure um ID válido para testar.",
    4
)

print("[EPIC PLANETS] Parte 3 inicializada.")
print("[EPIC PLANETS] Recursos: Play, Stop, Loop, Speed e Custom IDs.")

-- FIM DA PARTE 3
----------------------------------------------------------------

----------------------------------------------------------------
-- EPIC PLANETS
-- PARTE 4: ENVIRONMENT
----------------------------------------------------------------

----------------------------------------------------------------
-- 41. SAVE ORIGINAL ENVIRONMENT
----------------------------------------------------------------

local EnvironmentConfig = {
    Original = {},
    DayMode = false,
    NightMode = false,
    ZeroGravity = false,
    FogEnabled = false,
    CustomTime = 14,
    CustomBrightness = 2,
    CustomFogStart = 0,
    CustomFogEnd = 100000,
    CustomGravity = Workspace.Gravity
}

EnvironmentConfig.Original = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogColor = Lighting.FogColor,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    Gravity = Workspace.Gravity
}

----------------------------------------------------------------
-- 42. ENVIRONMENT HELPERS
----------------------------------------------------------------

local function setLightingProperty(property, value)
    local ok, err = pcall(function()
        Lighting[property] = value
    end)

    if not ok then
        warn(
            "[EPIC PLANETS] Falha em Lighting."
                .. tostring(property),
            err
        )
    end

    return ok
end

local function setWorldGravity(value)
    value = tonumber(value)

    if not value then
        return false
    end

    value = math.clamp(value, 0, 500)

    local ok, err = pcall(function()
        Workspace.Gravity = value
    end)

    if not ok then
        warn("[EPIC PLANETS] Falha ao ajustar Gravity:", err)
        return false
    end

    EnvironmentConfig.CustomGravity = value

    return true
end

local function setDay()
    EnvironmentConfig.DayMode = true
    EnvironmentConfig.NightMode = false

    setLightingProperty("ClockTime", 14)
    setLightingProperty("Brightness", 2)
    setLightingProperty("Ambient", Color3.fromRGB(120, 120, 120))
    setLightingProperty("OutdoorAmbient", Color3.fromRGB(150, 150, 150))

    notify("ENVIRONMENT", "Modo dia aplicado localmente.")
    addLog("Environment: modo dia.")
end

local function setNight()
    EnvironmentConfig.DayMode = false
    EnvironmentConfig.NightMode = true

    setLightingProperty("ClockTime", 0)
    setLightingProperty("Brightness", 0.8)
    setLightingProperty("Ambient", Color3.fromRGB(35, 40, 75))
    setLightingProperty("OutdoorAmbient", Color3.fromRGB(25, 30, 55))

    notify("ENVIRONMENT", "Modo noite aplicado localmente.")
    addLog("Environment: modo noite.")
end

local function setCustomTime(value)
    value = tonumber(value)

    if not value then
        return false
    end

    value = math.clamp(value, 0, 24)

    EnvironmentConfig.CustomTime = value
    EnvironmentConfig.DayMode = false
    EnvironmentConfig.NightMode = false

    setLightingProperty("ClockTime", value)

    notify(
        "ENVIRONMENT",
        "Horário definido: " .. string.format("%.1f", value)
    )

    addLog("Environment: horário personalizado.")
    return true
end

local function setZeroGravity(enabled)
    EnvironmentConfig.ZeroGravity = enabled == true

    if EnvironmentConfig.ZeroGravity then
        setWorldGravity(0)
        notify("ENVIRONMENT", "Gravidade local definida como zero.")
        addLog("Environment: gravidade zero ativada.")
    else
        setWorldGravity(EnvironmentConfig.Original.Gravity)
        notify("ENVIRONMENT", "Gravidade original restaurada.")
        addLog("Environment: gravidade restaurada.")
    end
end

local function setFog(enabled)
    EnvironmentConfig.FogEnabled = enabled == true

    if EnvironmentConfig.FogEnabled then
        setLightingProperty("FogStart", 0)
        setLightingProperty("FogEnd", 180)
        setLightingProperty("FogColor", Color3.fromRGB(100, 120, 155))

        notify("ENVIRONMENT", "Neblina ativada.")
    else
        setLightingProperty(
            "FogStart",
            EnvironmentConfig.Original.FogStart
        )

        setLightingProperty(
            "FogEnd",
            EnvironmentConfig.Original.FogEnd
        )

        setLightingProperty(
            "FogColor",
            EnvironmentConfig.Original.FogColor
        )

        notify("ENVIRONMENT", "Neblina restaurada.")
    end
end

local function restoreEnvironment()
    stopCurrentAnimation()

    for property, value in pairs(EnvironmentConfig.Original) do
        if property == "Gravity" then
            setWorldGravity(value)
        else
            setLightingProperty(property, value)
        end
    end

    EnvironmentConfig.DayMode = false
    EnvironmentConfig.NightMode = false
    EnvironmentConfig.ZeroGravity = false
    EnvironmentConfig.FogEnabled = false

    notify("ENVIRONMENT", "Configurações originais restauradas.")
    addLog("Environment: restauração completa.")
end

----------------------------------------------------------------
-- 43. ENVIRONMENT PAGE HEADER
----------------------------------------------------------------

local EnvMainSection = createSection(
    EnvironmentPage,
    "World controls",
    "Ajuste o ambiente visual desta sessão."
)

createActionButton(
    EnvMainSection,
    "☀ Day",
    setDay
)

createActionButton(
    EnvMainSection,
    "☾ Night",
    setNight
)

createActionButton(
    EnvMainSection,
    "↺ Restore original environment",
    restoreEnvironment
)

----------------------------------------------------------------
-- 44. DAY / NIGHT TOGGLES
----------------------------------------------------------------

local DayToggle = createToggle(
    EnvMainSection,
    "Day mode",
    false,
    function(enabled)
        if enabled then
            setDay()
        else
            setLightingProperty(
                "ClockTime",
                EnvironmentConfig.Original.ClockTime
            )

            EnvironmentConfig.DayMode = false
        end
    end
)

local NightToggle = createToggle(
    EnvMainSection,
    "Night mode",
    false,
    function(enabled)
        if enabled then
            setNight()
        else
            setLightingProperty(
                "ClockTime",
                EnvironmentConfig.Original.ClockTime
            )

            EnvironmentConfig.NightMode = false
        end
    end
)

----------------------------------------------------------------
-- 45. CUSTOM TIME SLIDER
----------------------------------------------------------------

local TimeSection = createSection(
    EnvironmentPage,
    "Time of day",
    "Arraste para escolher um horário entre 0 e 24."
)

createValueSlider(
    TimeSection,
    "ClockTime",
    0,
    240,
    140,
    function(value)
        EnvironmentConfig.CustomTime = value / 10

        setLightingProperty(
            "ClockTime",
            EnvironmentConfig.CustomTime
        )

        EnvironmentConfig.DayMode = false
        EnvironmentConfig.NightMode = false
    end
)

----------------------------------------------------------------
-- 46. BRIGHTNESS SLIDER
----------------------------------------------------------------

local BrightnessSection = createSection(
    EnvironmentPage,
    "Brightness",
    "Controle o brilho da iluminação local."
)

createValueSlider(
    BrightnessSection,
    "Brightness",
    0,
    50,
    20,
    function(value)
        EnvironmentConfig.CustomBrightness = value / 10

        setLightingProperty(
            "Brightness",
            EnvironmentConfig.CustomBrightness
        )
    end
)

----------------------------------------------------------------
-- 47. ZERO GRAVITY
----------------------------------------------------------------

local GravitySection = createSection(
    EnvironmentPage,
    "Physics",
    "A gravidade pode ser limitada pelo servidor do jogo."
)

local GravityToggle = createToggle(
    GravitySection,
    "Zero Gravity",
    false,
    function(enabled)
        setZeroGravity(enabled)
    end
)

createValueSlider(
    GravitySection,
    "Gravity",
    0,
    500,
    math.clamp(EnvironmentConfig.Original.Gravity, 0, 500),
    function(value)
        if not EnvironmentConfig.ZeroGravity then
            setWorldGravity(value)
        end
    end
)

createActionButton(
    GravitySection,
    "Restore default gravity",
    function()
        EnvironmentConfig.ZeroGravity = false
        setWorldGravity(EnvironmentConfig.Original.Gravity)
        GravityToggle.Set(false)

        notify("ENVIRONMENT", "Gravidade original restaurada.")
    end
)

----------------------------------------------------------------
-- 48. FOG
----------------------------------------------------------------

local FogSection = createSection(
    EnvironmentPage,
    "Atmosphere",
    "Ative ou desative a neblina tradicional do Lighting."
)

local FogToggle = createToggle(
    FogSection,
    "Fog",
    false,
    function(enabled)
        setFog(enabled)
    end
)

createActionButton(
    FogSection,
    "Clear fog",
    function()
        setFog(false)
        FogToggle.Set(false)
    end
)

----------------------------------------------------------------
-- 49. COLOR PRESETS
----------------------------------------------------------------

local ColorSection = createSection(
    EnvironmentPage,
    "Ambient presets",
    "Altere as cores ambientais locais."
)

createActionButton(
    ColorSection,
    "Blue atmosphere",
    function()
        setLightingProperty(
            "Ambient",
            Color3.fromRGB(35, 65, 130)
        )

        setLightingProperty(
            "OutdoorAmbient",
            Color3.fromRGB(55, 95, 180)
        )

        setLightingProperty(
            "FogColor",
            Color3.fromRGB(40, 75, 145)
        )

        notify("ENVIRONMENT", "Atmosfera azul aplicada.")
    end
)

createActionButton(
    ColorSection,
    "Purple atmosphere",
    function()
        setLightingProperty(
            "Ambient",
            Color3.fromRGB(95, 35, 145)
        )

        setLightingProperty(
            "OutdoorAmbient",
            Color3.fromRGB(130, 55, 185)
        )

        setLightingProperty(
            "FogColor",
            Color3.fromRGB(90, 35, 135)
        )

        notify("ENVIRONMENT", "Atmosfera roxa aplicada.")
    end
)

createActionButton(
    ColorSection,
    "Green atmosphere",
    function()
        setLightingProperty(
            "Ambient",
            Color3.fromRGB(35, 100, 65)
        )

        setLightingProperty(
            "OutdoorAmbient",
            Color3.fromRGB(55, 145, 85)
        )

        setLightingProperty(
            "FogColor",
            Color3.fromRGB(40, 110, 65)
        )

        notify("ENVIRONMENT", "Atmosfera verde aplicada.")
    end
)

----------------------------------------------------------------
-- 50. ENVIRONMENT STATUS
----------------------------------------------------------------

local EnvStatusSection = createSection(
    EnvironmentPage,
    "Environment status",
    "Estado dos principais ajustes."
)

local EnvStatusLabel = makeText(
    EnvStatusSection,
    "Ambiente original.",
    12,
    Colors.MutedText
)

EnvStatusLabel.Size = UDim2.new(1, 0, 0, 24)

local function updateEnvironmentStatus()
    local time = Lighting.ClockTime
    local gravity = Workspace.Gravity

    EnvStatusLabel.Text = string.format(
        "Hora: %.1f | Gravity: %.1f | Fog: %s",
        time,
        gravity,
        EnvironmentConfig.FogEnabled and "ON" or "OFF"
    )

    EnvStatusLabel.TextColor3 = getAccent()
end

addConnection(RunService.Heartbeat:Connect(function()
    updateEnvironmentStatus()
end))

----------------------------------------------------------------
-- 51. FINISH PART 4
----------------------------------------------------------------

addLog("Parte 4: ENVIRONMENT registrada.")

notify(
    "EPIC PLANETS",
    "ENVIRONMENT carregada: Day, Night, Gravity e Fog.",
    4
)

print("[EPIC PLANETS] Parte 4 inicializada.")
print("[EPIC PLANETS] Recursos: Day/Night, Time, Gravity, Fog e presets.")

-- FIM DA PARTE 4
----------------------------------------------------------------

----------------------------------------------------------------
-- EPIC PLANETS
-- PARTE 5: PLAYER + MOVESETS
----------------------------------------------------------------

----------------------------------------------------------------
-- 52. PLAYER CONFIGURATION
----------------------------------------------------------------

local PlayerConfig = {
    DefaultWalkSpeed = 16,
    DefaultJumpPower = 50,
    SprintSpeed = 28,
    SprintEnabled = false,
    InfiniteJumpEnabled = false,
    NoclipEnabled = false,
    Connections = {},
    Original = {},
    CurrentMoveSet = "Default"
}

local function rememberHumanoid(humanoid)
    if not humanoid then
        return
    end

    if not PlayerConfig.Original[humanoid] then
        PlayerConfig.Original[humanoid] = {
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
            UseJumpPower = humanoid.UseJumpPower,
            AutoRotate = humanoid.AutoRotate
        }
    end
end

----------------------------------------------------------------
-- 53. CHARACTER HELPERS
----------------------------------------------------------------

local function getCharacterParts()
    local character = getCharacter()

    if not character then
        return nil, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    return character, humanoid, root
end

local function restorePlayerMovement()
    local character, humanoid = getCharacterParts()

    if not humanoid then
        notify("PLAYER", "Personagem não encontrado.")
        return
    end

    rememberHumanoid(humanoid)

    local original = PlayerConfig.Original[humanoid]

    humanoid.WalkSpeed = original.WalkSpeed
    humanoid.UseJumpPower = original.UseJumpPower
    humanoid.JumpPower = original.JumpPower
    humanoid.AutoRotate = original.AutoRotate

    PlayerConfig.SprintEnabled = false

    notify("PLAYER", "Movimento original restaurado.")
    addLog("Player: movimento restaurado.")
end

----------------------------------------------------------------
-- 54. PLAYER STATUS
----------------------------------------------------------------

local PlayerStatusSection = createSection(
    PlayerPage,
    "Character status",
    "Informações do personagem atual."
)

local PlayerStatusLabel = makeText(
    PlayerStatusSection,
    "Carregando personagem...",
    12,
    Colors.MutedText
)

PlayerStatusLabel.Size = UDim2.new(1, 0, 0, 45)
PlayerStatusLabel.TextWrapped = true

local function updatePlayerStatus()
    local character, humanoid, root = getCharacterParts()

    if not character or not humanoid then
        PlayerStatusLabel.Text = "Personagem indisponível."
        return
    end

    local health = math.floor(humanoid.Health + 0.5)
    local maxHealth = math.floor(humanoid.MaxHealth + 0.5)
    local speed = math.floor(humanoid.WalkSpeed + 0.5)
    local grounded = humanoid.FloorMaterial ~= Enum.Material.Air

    PlayerStatusLabel.Text = string.format(
        "HP: %d/%d | Speed: %d | Grounded: %s",
        health,
        maxHealth,
        speed,
        grounded and "YES" or "NO"
    )
end

addConnection(RunService.Heartbeat:Connect(updatePlayerStatus))

----------------------------------------------------------------
-- 55. SPRINT
----------------------------------------------------------------

local SprintSection = createSection(
    PlayerPage,
    "Sprint",
    "Ative uma velocidade de corrida personalizada."
)

createValueSlider(
    SprintSection,
    "Sprint speed",
    16,
    100,
    PlayerConfig.SprintSpeed,
    function(value)
        PlayerConfig.SprintSpeed = value

        local _, humanoid = getCharacterParts()

        if humanoid and PlayerConfig.SprintEnabled then
            humanoid.WalkSpeed = value
        end
    end
)

local SprintToggle = createToggle(
    SprintSection,
    "Sprint",
    false,
    function(enabled)
        local _, humanoid = getCharacterParts()

        if not humanoid then
            notify("PLAYER", "Personagem não encontrado.")
            return
        end

        rememberHumanoid(humanoid)

        PlayerConfig.SprintEnabled = enabled

        if enabled then
            humanoid.WalkSpeed = PlayerConfig.SprintSpeed
        else
            humanoid.WalkSpeed = PlayerConfig.DefaultWalkSpeed
        end

        addLog("Sprint: " .. (enabled and "ON" or "OFF"))
    end
)

----------------------------------------------------------------
-- 56. JUMP CONTROL
----------------------------------------------------------------

local JumpSection = createSection(
    PlayerPage,
    "Jump control",
    "Ajuste o salto do personagem."
)

createValueSlider(
    JumpSection,
    "Jump power",
    20,
    150,
    PlayerConfig.DefaultJumpPower,
    function(value)
        PlayerConfig.DefaultJumpPower = value

        local _, humanoid = getCharacterParts()

        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = value
        end
    end
)

createActionButton(
    JumpSection,
    "Jump now",
    function()
        local _, humanoid = getCharacterParts()

        if not humanoid then
            notify("PLAYER", "Personagem não encontrado.")
            return
        end

        humanoid.Jump = true
    end
)

----------------------------------------------------------------
-- 57. INFINITE JUMP
----------------------------------------------------------------

local InfiniteJumpSection = createSection(
    PlayerPage,
    "Jump options",
    "Permite solicitar saltos adicionais enquanto estiver no ar."
)

local InfiniteJumpToggle = createToggle(
    InfiniteJumpSection,
    "Air jump",
    false,
    function(enabled)
        PlayerConfig.InfiniteJumpEnabled = enabled

        if enabled then
            notify(
                "PLAYER",
                "Air jump ativado localmente."
            )
        else
            notify(
                "PLAYER",
                "Air jump desativado."
            )
        end
    end
)

addConnection(UserInputService.JumpRequest:Connect(function()
    if not PlayerConfig.InfiniteJumpEnabled then
        return
    end

    local _, humanoid = getCharacterParts()

    if humanoid and humanoid.Health > 0 then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

----------------------------------------------------------------
-- 58. RESET MOVEMENT
----------------------------------------------------------------

createActionButton(
    PlayerPage,
    "Reset movement settings",
    function()
        restorePlayerMovement()

        SprintToggle.Set(false)
        InfiniteJumpToggle.Set(false)

        PlayerConfig.InfiniteJumpEnabled = false
        PlayerConfig.SprintEnabled = false
    end
)

----------------------------------------------------------------
-- 59. MOVESET REGISTRY
----------------------------------------------------------------

local MoveSetRegistry = {}

local function registerMoveSet(name, description, callback)
    if type(name) ~= "string" or name == "" then
        return false
    end

    MoveSetRegistry[name] = {
        Name = name,
        Description = description or "",
        Callback = callback
    }

    return true
end

local function runMoveSet(name)
    local moveset = MoveSetRegistry[name]

    if not moveset then
        notify("MOVESETS", "Moveset não encontrado.")
        return false
    end

    if type(moveset.Callback) ~= "function" then
        notify("MOVESETS", "Este moveset ainda não tem uma ação.")
        return false
    end

    local ok, err = pcall(moveset.Callback)

    if not ok then
        warn("[EPIC PLANETS] Moveset error:", err)
        notify("MOVESETS", "Falha ao executar moveset.")
        return false
    end

    PlayerConfig.CurrentMoveSet = name

    addLog("Moveset executado: " .. name)

    return true
end

----------------------------------------------------------------
-- 60. BUILT-IN MOVESETS
----------------------------------------------------------------

registerMoveSet(
    "Default",
    "Restaura os valores de movimento padrão.",
    function()
        restorePlayerMovement()
    end
)

registerMoveSet(
    "Runner",
    "Aplica uma velocidade de corrida moderada.",
    function()
        local _, humanoid = getCharacterParts()

        if not humanoid then
            return
        end

        rememberHumanoid(humanoid)

        humanoid.WalkSpeed = 28
        PlayerConfig.SprintEnabled = false
    end
)

registerMoveSet(
    "Low Gravity Jump",
    "Aumenta a potência do salto sem alterar o Workspace.Gravity.",
    function()
        local _, humanoid = getCharacterParts()

        if not humanoid then
            return
        end

        rememberHumanoid(humanoid)

        humanoid.UseJumpPower = true
        humanoid.JumpPower = 85
    end
)

registerMoveSet(
    "Careful",
    "Reduz a velocidade para facilitar o controle.",
    function()
        local _, humanoid = getCharacterParts()

        if not humanoid then
            return
        end

        rememberHumanoid(humanoid)

        humanoid.WalkSpeed = 12
        humanoid.JumpPower = 40
    end
)

----------------------------------------------------------------
-- 61. MOVESETS PAGE UI
----------------------------------------------------------------

local MoveSetControlsSection = createSection(
    MovesetsPage,
    "MoveSet presets",
    "Escolha um conjunto de movimento."
)

createActionButton(
    MoveSetControlsSection,
    "Default",
    function()
        runMoveSet("Default")
    end
)

createActionButton(
    MoveSetControlsSection,
    "Runner",
    function()
        runMoveSet("Runner")
    end
)

createActionButton(
    MoveSetControlsSection,
    "Low Gravity Jump",
    function()
        runMoveSet("Low Gravity Jump")
    end
)

createActionButton(
    MoveSetControlsSection,
    "Careful",
    function()
        runMoveSet("Careful")
    end
)

----------------------------------------------------------------
-- 62. MOVESET INFORMATION
----------------------------------------------------------------

local MoveSetInfoSection = createSection(
    MovesetsPage,
    "MoveSet information",
    "Mostra o conjunto selecionado."
)

local MoveSetStatus = makeText(
    MoveSetInfoSection,
    "Current moveset: Default",
    12,
    Colors.MutedText
)

MoveSetStatus.Size = UDim2.new(1, 0, 0, 25)

addConnection(RunService.Heartbeat:Connect(function()
    MoveSetStatus.Text =
        "Current moveset: " .. PlayerConfig.CurrentMoveSet
end))

createActionButton(
    MoveSetInfoSection,
    "List movesets",
    function()
        for name, data in pairs(MoveSetRegistry) do
            print(
                "[EPIC PLANETS MOVESET] "
                .. name
                .. " | "
                .. data.Description
            )
        end

        notify("MOVESETS", "Lista enviada ao console.")
    end
)

----------------------------------------------------------------
-- 63. CUSTOM MOVESET API
----------------------------------------------------------------

ENV.__EPIC_PLANETS_REGISTER_MOVESET = registerMoveSet
ENV.__EPIC_PLANETS_RUN_MOVESET = runMoveSet

----------------------------------------------------------------
-- 64. RESPAWN SUPPORT
----------------------------------------------------------------

addConnection(LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.6)

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        rememberHumanoid(humanoid)

        if PlayerConfig.SprintEnabled then
            humanoid.WalkSpeed = PlayerConfig.SprintSpeed
        end
    end

    addLog("Player: personagem atualizado.")
end))

----------------------------------------------------------------
-- 65. CLEANUP REGISTRATION
----------------------------------------------------------------

table.insert(Connections, {
    Disconnect = function()
        PlayerConfig.InfiniteJumpEnabled = false
        PlayerConfig.SprintEnabled = false

        for humanoid, original in pairs(PlayerConfig.Original) do
            if humanoid and humanoid.Parent then
                pcall(function()
                    humanoid.WalkSpeed = original.WalkSpeed
                    humanoid.JumpPower = original.JumpPower
                    humanoid.UseJumpPower = original.UseJumpPower
                    humanoid.AutoRotate = original.AutoRotate
                end)
            end
        end
    end
})

----------------------------------------------------------------
-- 66. FINISH PART 5
----------------------------------------------------------------

addLog("Parte 5: Player e Movesets registrados.")

notify(
    "EPIC PLANETS",
    "Player + Movesets carregados.",
    4
)

print("[EPIC PLANETS] Parte 5 inicializada.")
print("[EPIC PLANETS] Movesets: Default, Runner, Low Gravity Jump, Careful.")

-- FIM DA PARTE 5
----------------------------------------------------------------

--[[
    EPIC PLANETS
    PARTE 6/6
    BuiltinModules + ModuleLoader

    Cole no final da Parte 5.
    Módulos locais registrados manualmente.
    Sem carregar código remoto ou usar loadstring.
]]

----------------------------------------------------------------
-- MODULE LOADER
----------------------------------------------------------------

local ModuleLoader = {
    Registry = {},
    Loaded = {},
    Errors = {},
    Order = {},
    Started = false,
}

ENV.__EPIC_PLANETS_MODULE_LOADER = ModuleLoader

----------------------------------------------------------------
-- MODULE API
----------------------------------------------------------------

local function moduleNotify(message)
    if type(notify) == "function" then
        pcall(notify, "EPIC PLANETS", tostring(message))
    else
        print("[EPIC PLANETS] " .. tostring(message))
    end
end

local function registerModule(name, description, init, cleanup)
    if type(name) ~= "string" or name == "" then
        return false, "Nome inválido"
    end

    if type(init) ~= "function" then
        return false, "O módulo precisa de uma função init"
    end

    if ModuleLoader.Registry[name] then
        return false, "Já existe um módulo com esse nome"
    end

    ModuleLoader.Registry[name] = {
        Name = name,
        Description = description or "Sem descrição",
        Init = init,
        Cleanup = cleanup,
        Enabled = false,
        State = "Descarregado",
        Instance = nil,
    }

    table.insert(ModuleLoader.Order, name)

    return true
end

local function loadModule(name)
    local module = ModuleLoader.Registry[name]

    if not module then
        return false, "Módulo não encontrado"
    end

    if module.Enabled then
        return true, "O módulo já está carregado"
    end

    local success, result = pcall(module.Init, {
        ENV = ENV,
        Services = Services,
        Notify = moduleNotify,
        Config = Config,
    })

    if not success then
        module.State = "Erro"
        ModuleLoader.Errors[name] = tostring(result)
        warn("[EPIC PLANETS] Falha ao carregar " .. name .. ": " .. tostring(result))
        return false, tostring(result)
    end

    module.Instance = result
    module.Enabled = true
    module.State = "Carregado"
    ModuleLoader.Errors[name] = nil

    return true, "Módulo carregado"
end

local function unloadModule(name)
    local module = ModuleLoader.Registry[name]

    if not module then
        return false, "Módulo não encontrado"
    end

    if not module.Enabled then
        module.State = "Descarregado"
        return true, "O módulo já estava descarregado"
    end

    if type(module.Cleanup) == "function" then
        local success, err = pcall(
            module.Cleanup,
            module.Instance,
            {
                ENV = ENV,
                Services = Services,
                Notify = moduleNotify,
                Config = Config,
            }
        )

        if not success then
            warn("[EPIC PLANETS] Erro ao descarregar " .. name .. ": " .. tostring(err))
        end
    end

    if type(module.Instance) == "table" then
        if type(module.Instance.Disconnect) == "function" then
            pcall(function()
                module.Instance:Disconnect()
            end)
        end

        if type(module.Instance.Destroy) == "function" then
            pcall(function()
                module.Instance:Destroy()
            end)
        end
    end

    module.Instance = nil
    module.Enabled = false
    module.State = "Descarregado"

    return true, "Módulo descarregado"
end

local function reloadModule(name)
    unloadModule(name)
    return loadModule(name)
end

----------------------------------------------------------------
-- BUILTIN MODULES
----------------------------------------------------------------

-- 1. MODULE STATUS
registerModule(
    "ModuleStatus",
    "Mantém um resumo do estado do carregador.",
    function()
        local state = {
            StartedAt = os.clock(),
        }

        return state
    end,
    function()
        return true
    end
)

-- 2. SESSION INFO
registerModule(
    "SessionInfo",
    "Guarda informações básicas desta sessão local.",
    function()
        local playerName = "Indisponível"

        pcall(function()
            playerName = Players.LocalPlayer.Name
        end)

        return {
            PlayerName = playerName,
            StartedAt = os.clock(),
            Version = "EPIC PLANETS 6",
        }
    end,
    function()
        return true
    end
)

-- 3. LOCAL CONFIG
registerModule(
    "LocalConfig",
    "Prepara uma tabela de configurações para módulos locais.",
    function()
        ENV.__EPIC_PLANETS_LOCAL_CONFIG =
            ENV.__EPIC_PLANETS_LOCAL_CONFIG or {
                Animations = {},
                Environment = {},
                Modules = {},
            }

        return {
            Config = ENV.__EPIC_PLANETS_LOCAL_CONFIG,
        }
    end,
    function()
        -- Mantém as configurações para a sessão atual.
        return true
    end
)

----------------------------------------------------------------
-- MODULE MANAGER HELPERS
----------------------------------------------------------------

local function getModuleSummary()
    local total = 0
    local loaded = 0
    local failed = 0

    for _, name in ipairs(ModuleLoader.Order) do
        local module = ModuleLoader.Registry[name]

        if module then
            total += 1

            if module.Enabled then
                loaded += 1
            end

            if module.State == "Erro" then
                failed += 1
            end
        end
    end

    return {
        Total = total,
        Loaded = loaded,
        Failed = failed,
    }
end

local function loadAllModules()
    for _, name in ipairs(ModuleLoader.Order) do
        local module = ModuleLoader.Registry[name]

        if module and not module.Enabled then
            local success, err = loadModule(name)

            if not success then
                warn("[EPIC PLANETS] " .. name .. ": " .. tostring(err))
            end
        end
    end
end

local function unloadAllModules()
    for index = #ModuleLoader.Order, 1, -1 do
        unloadModule(ModuleLoader.Order[index])
    end
end

----------------------------------------------------------------
-- MODULE LOADER API
----------------------------------------------------------------

ENV.EPIC_PLANETS_MODULES = {
    Register = registerModule,
    Load = loadModule,
    Unload = unloadModule,
    Reload = reloadModule,
    LoadAll = loadAllModules,
    UnloadAll = unloadAllModules,
    GetSummary = getModuleSummary,
    Registry = ModuleLoader.Registry,
}

----------------------------------------------------------------
-- BUILTIN MODULES PAGE
----------------------------------------------------------------

local function buildModuleManager()
    if not BuiltinModulesPage then
        warn("[EPIC PLANETS] BuiltinModulesPage não foi encontrada.")
        return
    end

    local ok, err = pcall(function()
        createSection(
            BuiltinModulesPage,
            "MODULE LOADER",
            "Gerencie os módulos registrados nesta sessão."
        )

        createActionButton(
            BuiltinModulesPage,
            "LOAD ALL MODULES",
            function()
                loadAllModules()
                moduleNotify("Carregamento dos módulos concluído.")
            end
        )

        createActionButton(
            BuiltinModulesPage,
            "UNLOAD ALL MODULES",
            function()
                unloadAllModules()
                moduleNotify("Todos os módulos foram descarregados.")
            end
        )

        createActionButton(
            BuiltinModulesPage,
            "REFRESH MODULE STATUS",
            function()
                local summary = getModuleSummary()

                moduleNotify(
                    "Total: " .. summary.Total
                    .. " | Carregados: " .. summary.Loaded
                    .. " | Erros: " .. summary.Failed
                )
            end
        )

        createSection(
            BuiltinModulesPage,
            "REGISTERED MODULES",
            "Ative ou desative cada módulo individualmente."
        )

        for _, moduleName in ipairs(ModuleLoader.Order) do
            local module = ModuleLoader.Registry[moduleName]

            if module then
                createActionButton(
                    BuiltinModulesPage,
                    "LOAD: " .. module.Name,
                    function()
                        local success, message = loadModule(module.Name)
                        moduleNotify(message)

                        if not success then
                            warn("[EPIC PLANETS] " .. tostring(message))
                        end
                    end
                )

                createActionButton(
                    BuiltinModulesPage,
                    "UNLOAD: " .. module.Name,
                    function()
                        local success, message = unloadModule(module.Name)
                        moduleNotify(message)
                    end
                )
            end
        end

        createSection(
            BuiltinModulesPage,
            "MODULE INFORMATION",
            "Os módulos são registrados neste script."
        )

        createActionButton(
            BuiltinModulesPage,
            "SHOW MODULE SUMMARY",
            function()
                local summary = getModuleSummary()

                print("====== EPIC PLANETS MODULES ======")
                print("Total: " .. summary.Total)
                print("Carregados: " .. summary.Loaded)
                print("Com erro: " .. summary.Failed)

                for _, name in ipairs(ModuleLoader.Order) do
                    local module = ModuleLoader.Registry[name]

                    if module then
                        print(
                            module.Name
                            .. " | "
                            .. module.State
                            .. " | "
                            .. module.Description
                        )

                        if ModuleLoader.Errors[name] then
                            warn(ModuleLoader.Errors[name])
                        end
                    end
                end

                print("==================================")
                moduleNotify("Resumo enviado ao console.")
            end
        )
    end)

    if not ok then
        warn("[EPIC PLANETS] Erro ao montar o ModuleLoader: " .. tostring(err))
    end
end

----------------------------------------------------------------
-- INITIALIZATION
----------------------------------------------------------------

if not ModuleLoader.Started then
    ModuleLoader.Started = true

    -- Carrega os módulos básicos registrados acima.
    loadModule("ModuleStatus")
    loadModule("SessionInfo")
    loadModule("LocalConfig")

    buildModuleManager()

    moduleNotify("Parte 6 carregada!")
end

----------------------------------------------------------------
-- END PART 6
----------------------------------------------------------------

--[[
    EPIC PLANETS
    PARTE 7/9
    TETRIS INTEGRADO
    Mobile + Delta

    Reutiliza a GUI existente.
    Não cria outra ScreenGui.
]]

----------------------------------------------------------------
-- TETRIS PAGE
----------------------------------------------------------------

local TetrisPage

if type(Pages) == "table" then
    TetrisPage = Pages["Tetris"]
end

if not TetrisPage and type(createTab) == "function" then
    pcall(function()
        createTab("Tetris", "▦")
    end)

    if type(Pages) == "table" then
        TetrisPage = Pages["Tetris"]
    end
end

if not TetrisPage then
    warn("[EPIC PLANETS] Não foi possível encontrar a página Tetris.")
else

----------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------

local TetrisConnections = {}
local TetrisRunning = false
local TetrisGameOver = false
local TetrisLoopId = 0

local function tetrisConnect(connection)
    table.insert(TetrisConnections, connection)
    return connection
end

local function tetrisCleanup()
    TetrisRunning = false
    TetrisLoopId += 1

    for _, connection in ipairs(TetrisConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(TetrisConnections)
end

if type(ENV.__EPIC_PLANETS_TETRIS_CLEANUP) == "function" then
    pcall(ENV.__EPIC_PLANETS_TETRIS_CLEANUP)
end

ENV.__EPIC_PLANETS_TETRIS_CLEANUP = tetrisCleanup

----------------------------------------------------------------
-- UI
----------------------------------------------------------------

local oldTetris = TetrisPage:FindFirstChild("EPTetrisPanel")

if oldTetris then
    oldTetris:Destroy()
end

local Panel = Instance.new("Frame")
Panel.Name = "EPTetrisPanel"
Panel.Size = UDim2.new(1, -12, 1, -12)
Panel.Position = UDim2.fromOffset(6, 6)
Panel.BackgroundColor3 = Color3.fromRGB(15, 17, 25)
Panel.BorderSizePixel = 0
Panel.Parent = TetrisPage

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = Panel

local PanelLayout = Instance.new("UIListLayout")
PanelLayout.Padding = UDim.new(0, 7)
PanelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
PanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
PanelLayout.Parent = Panel

local function makeLabel(parent, text, height, order)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 0, height)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 240, 255)
    label.TextSize = 15
    label.Font = Enum.Font.GothamBold
    label.LayoutOrder = order or 1
    label.Parent = parent
    return label
end

local function makeButton(parent, text, size, callback)
    local button = Instance.new("TextButton")
    button.Size = size
    button.BackgroundColor3 = Color3.fromRGB(38, 43, 61)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    if callback then
        button.Activated:Connect(callback)
    end

    return button
end

makeLabel(Panel, "EPIC PLANETS  //  TETRIS", 28, 1)

local Status = makeLabel(Panel, "Toque em START para jogar", 22, 2)
Status.TextColor3 = Color3.fromRGB(100, 220, 255)

local Stats = makeLabel(Panel, "Pontos: 0  |  Linhas: 0  |  Nível: 1", 22, 3)

local BoardFrame = Instance.new("Frame")
BoardFrame.Name = "Board"
BoardFrame.Size = UDim2.fromOffset(200, 360)
BoardFrame.BackgroundColor3 = Color3.fromRGB(7, 9, 15)
BoardFrame.BorderSizePixel = 0
BoardFrame.LayoutOrder = 4
BoardFrame.Parent = Panel

local boardCorner = Instance.new("UICorner")
boardCorner.CornerRadius = UDim.new(0, 5)
boardCorner.Parent = BoardFrame

local BOARD_W, BOARD_H = 10, 18
local CELL = 20

local Grid = Instance.new("UIGridLayout")
Grid.CellSize = UDim2.fromOffset(CELL - 1, CELL - 1)
Grid.CellPadding = UDim2.fromOffset(1, 1)
Grid.SortOrder = Enum.SortOrder.LayoutOrder
Grid.Parent = BoardFrame

local Cells = {}

for i = 1, BOARD_W * BOARD_H do
    local cell = Instance.new("Frame")
    cell.Name = "Cell" .. i
    cell.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
    cell.BorderSizePixel = 0
    cell.LayoutOrder = i
    cell.Parent = BoardFrame
    Cells[i] = cell
end

-- A área de jogo pode ser redimensionada pelo layout da GUI.
-- O tab pai deve permitir espaço vertical suficiente.

local Controls = Instance.new("Frame")
Controls.Name = "MobileControls"
Controls.Size = UDim2.new(1, -12, 0, 42)
Controls.BackgroundTransparency = 1
Controls.LayoutOrder = 5
Controls.Parent = Panel

local ControlLayout = Instance.new("UIListLayout")
ControlLayout.FillDirection = Enum.FillDirection.Horizontal
ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ControlLayout.Padding = UDim.new(0, 5)
ControlLayout.Parent = Controls

----------------------------------------------------------------
-- TETRIS DATA
----------------------------------------------------------------

local Shapes = {
    {
        Color = Color3.fromRGB(60, 220, 255),
        Cells = {{1,0},{2,0},{3,0},{4,0}},
    },
    {
        Color = Color3.fromRGB(80, 100, 255),
        Cells = {{0,0},{0,1},{1,1},{2,1}},
    },
    {
        Color = Color3.fromRGB(255, 160, 55),
        Cells = {{2,0},{0,1},{1,1},{2,1}},
    },
    {
        Color = Color3.fromRGB(255, 220, 60),
        Cells = {{1,0},{2,0},{1,1},{2,1}},
    },
    {
        Color = Color3.fromRGB(80, 235, 130),
        Cells = {{1,0},{2,0},{0,1},{1,1}},
    },
    {
        Color = Color3.fromRGB(190, 90, 255),
        Cells = {{1,0},{0,1},{1,1},{2,1}},
    },
    {
        Color = Color3.fromRGB(255, 85, 115),
        Cells = {{0,0},{1,0},{1,1},{2,1}},
    },
}

local Board = {}
local Piece
local Score = 0
local Lines = 0
local Level = 1

local function resetBoard()
    Board = {}

    for y = 1, BOARD_H do
        Board[y] = {}

        for x = 1, BOARD_W do
            Board[y][x] = nil
        end
    end
end

local function cloneCells(cells)
    local result = {}

    for _, point in ipairs(cells) do
        table.insert(result, {point[1], point[2]})
    end

    return result
end

local function spawnPiece()
    local shape = Shapes[math.random(1, #Shapes)]

    Piece = {
        X = 3,
        Y = 1,
        Cells = cloneCells(shape.Cells),
        Color = shape.Color,
    }

    for _, point in ipairs(Piece.Cells) do
        local x = Piece.X + point[1]
        local y = Piece.Y + point[2]

        if Board[y] and Board[y][x] then
            TetrisGameOver = true
            TetrisRunning = false
            Status.Text = "FIM DE JOGO  |  Toque em START"
            return false
        end
    end

    return true
end

local function canPlace(dx, dy, cells)
    if not Piece then
        return false
    end

    for _, point in ipairs(cells or Piece.Cells) do
        local x = Piece.X + dx + point[1]
        local y = Piece.Y + dy + point[2]

        if x < 0 or x >= BOARD_W or y >= BOARD_H then
            return false
        end

        if y >= 0 and Board[y + 1][x + 1] then
            return false
        end
    end

    return true
end

local function rotateCells(cells)
    local rotated = {}

    for _, point in ipairs(cells) do
        table.insert(rotated, {-point[2], point[1]})
    end

    local minX, minY = math.huge, math.huge

    for _, point in ipairs(rotated) do
        minX = math.min(minX, point[1])
        minY = math.min(minY, point[2])
    end

    for _, point in ipairs(rotated) do
        point[1] -= minX
        point[2] -= minY
    end

    return rotated
end

local function updateStats()
    Stats.Text = string.format(
        "Pontos: %d  |  Linhas: %d  |  Nível: %d",
        Score, Lines, Level
    )
end

local function renderBoard()
    for y = 1, BOARD_H do
        for x = 1, BOARD_W do
            local index = (y - 1) * BOARD_W + x
            local cell = Cells[index]

            cell.BackgroundColor3 =
                Board[y][x] or Color3.fromRGB(22, 25, 36)
        end
    end

    if Piece then
        for _, point in ipairs(Piece.Cells) do
            local x = Piece.X + point[1]
            local y = Piece.Y + point[2]

            if x >= 0 and x < BOARD_W
                and y >= 0 and y < BOARD_H then

                local index = y * BOARD_W + x + 1

                if Cells[index] then
                    Cells[index].BackgroundColor3 = Piece.Color
                end
            end
        end
    end
end

local function clearFullLines()
    local cleared = 0

    for y = BOARD_H, 1, -1 do
        local full = true

        for x = 1, BOARD_W do
            if not Board[y][x] then
                full = false
                break
            end
        end

        if full then
            table.remove(Board, y)
            local newRow = {}

            for x = 1, BOARD_W do
                newRow[x] = nil
            end

            table.insert(Board, 1, newRow)
            cleared += 1
            y += 1
        end
    end

    if cleared > 0 then
        Lines += cleared
        Score += ({0, 100, 300, 500, 800})[cleared + 1] or cleared * 200
        Level = math.floor(Lines / 10) + 1
        updateStats()
    end
end

local function lockPiece()
    for _, point in ipairs(Piece.Cells) do
        local x = Piece.X + point[1]
        local y = Piece.Y + point[2]

        if y >= 0 and y < BOARD_H and x >= 0 and x < BOARD_W then
            Board[y + 1][x + 1] = Piece.Color
        end
    end

    clearFullLines()
    spawnPiece()
    renderBoard()
end

local function movePiece(dx, dy)
    if not TetrisRunning or TetrisGameOver or not Piece then
        return
    end

    if canPlace(dx, dy) then
        Piece.X += dx
        Piece.Y += dy
        renderBoard()
    elseif dy > 0 then
        lockPiece()
    end
end

local function rotatePiece()
    if not TetrisRunning or not Piece then
        return
    end

    local rotated = rotateCells(Piece.Cells)

    if canPlace(0, 0, rotated) then
        Piece.Cells = rotated
        renderBoard()
    end
end

local function hardDrop()
    if not TetrisRunning or not Piece then
        return
    end

    while canPlace(0, 1) do
        Piece.Y += 1
        Score += 1
    end

    lockPiece()
    updateStats()
end

----------------------------------------------------------------
-- MOBILE BUTTONS
----------------------------------------------------------------

makeButton(
    Controls,
    "◀",
    UDim2.fromOffset(42, 36),
    function() movePiece(-1, 0) end
)

makeButton(
    Controls,
    "ROTATE",
    UDim2.fromOffset(65, 36),
    rotatePiece
)

makeButton(
    Controls,
    "▼",
    UDim2.fromOffset(42, 36),
    function() movePiece(0, 1) end
)

makeButton(
    Controls,
    "▶",
    UDim2.fromOffset(42, 36),
    function() movePiece(1, 0) end
)

local Actions = Instance.new("Frame")
Actions.Name = "GameActions"
Actions.Size = UDim2.new(1, -12, 0, 36)
Actions.BackgroundTransparency = 1
Actions.LayoutOrder = 6
Actions.Parent = Panel

local ActionLayout = Instance.new("UIListLayout")
ActionLayout.FillDirection = Enum.FillDirection.Horizontal
ActionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ActionLayout.Padding = UDim.new(0, 8)
ActionLayout.Parent = Actions

----------------------------------------------------------------
-- START / PAUSE / RESET
----------------------------------------------------------------

local function startGame()
    tetrisCleanup()

    TetrisRunning = true
    TetrisGameOver = false
    Score = 0
    Lines = 0
    Level = 1

    resetBoard()
    spawnPiece()
    updateStats()
    renderBoard()

    Status.Text = "JOGANDO"
    TetrisLoopId += 1

    local thisLoop = TetrisLoopId

    task.spawn(function()
        while TetrisRunning
            and not TetrisGameOver
            and TetrisLoopId == thisLoop do

            local delayTime = math.max(0.12, 0.65 - (Level - 1) * 0.045)
            task.wait(delayTime)

            if TetrisRunning
                and not TetrisGameOver
                and TetrisLoopId == thisLoop then
                movePiece(0, 1)
            end
        end
    end)
end

makeButton(
    Actions,
    "START / RESTART",
    UDim2.fromOffset(125, 32),
    startGame
)

makeButton(
    Actions,
    "PAUSE",
    UDim2.fromOffset(75, 32),
    function()
        TetrisRunning = not TetrisRunning

        if TetrisRunning and not TetrisGameOver then
            Status.Text = "JOGANDO"
            TetrisLoopId += 1

            local thisLoop = TetrisLoopId

            task.spawn(function()
                while TetrisRunning
                    and not TetrisGameOver
                    and TetrisLoopId == thisLoop do

                    task.wait(math.max(0.12, 0.65 - (Level - 1) * 0.045))

                    if TetrisRunning and TetrisLoopId == thisLoop then
                        movePiece(0, 1)
                    end
                end
            end)
        elseif not TetrisGameOver then
            Status.Text = "PAUSADO"
            TetrisLoopId += 1
        end
    end
)

resetBoard()
renderBoard()

Status.Text = "Pronto para jogar"
moduleNotify("Tetris integrado à página existente.")

end -- TetrisPage

--[[
    EPIC PLANETS
    PARTE 8/9
    EXECUTOR PANEL + LOG CONSOLE
    Delta / Mobile

    Cole no final da Parte 7.
    Reutiliza a GUI existente.
]]

----------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------

if type(ENV.__EPIC_PLANETS_PART8_CLEANUP) == "function" then
    pcall(ENV.__EPIC_PLANETS_PART8_CLEANUP)
end

local Part8Connections = {}
local Part8CleanupDone = false

local function part8Connect(connection)
    table.insert(Part8Connections, connection)
    return connection
end

local function cleanupPart8()
    if Part8CleanupDone then
        return
    end

    Part8CleanupDone = true

    for _, connection in ipairs(Part8Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(Part8Connections)
end

ENV.__EPIC_PLANETS_PART8_CLEANUP = cleanupPart8

----------------------------------------------------------------
-- LOG SYSTEM
----------------------------------------------------------------

local EPLogs = {
    Entries = {},
    MaxEntries = 150,
}

local function addEPLog(level, message)
    local entry = {
        Time = os.date("%H:%M:%S"),
        Level = tostring(level or "INFO"),
        Message = tostring(message),
    }

    table.insert(EPLogs.Entries, entry)

    while #EPLogs.Entries > EPLogs.MaxEntries do
        table.remove(EPLogs.Entries, 1)
    end

    print(
        "[EPIC PLANETS][" .. entry.Time .. "]"
        .. "[" .. entry.Level .. "] "
        .. entry.Message
    )

    return entry
end

ENV.__EPIC_PLANETS_LOGS = EPLogs

----------------------------------------------------------------
-- PAGE LOOKUP
----------------------------------------------------------------

local function getEPPage(name)
    if type(Pages) == "table" then
        return Pages[name]
    end

    return nil
end

local ExecutorPage = getEPPage("Executor")
local LogsPage = getEPPage("Logs")

----------------------------------------------------------------
-- CREATE PAGE IF MISSING
----------------------------------------------------------------

if not ExecutorPage and type(createTab) == "function" then
    pcall(function()
        createTab("Executor", "⌘")
    end)

    ExecutorPage = getEPPage("Executor")
end

if not LogsPage and type(createTab) == "function" then
    pcall(function()
        createTab("Logs", "≡")
    end)

    LogsPage = getEPPage("Logs")
end

----------------------------------------------------------------
-- EXECUTOR COMMAND REGISTRY
----------------------------------------------------------------

local EPCommands = {}

local function registerCommand(name, description, callback)
    if type(name) ~= "string" or type(callback) ~= "function" then
        return false
    end

    EPCommands[string.lower(name)] = {
        Name = name,
        Description = description or "",
        Callback = callback,
    }

    return true
end

local function runEPCommand(line)
    line = tostring(line or "")
    local command, argument = line:match("^%s*(%S+)%s*(.-)%s*$")

    if not command then
        return false, "Digite um comando."
    end

    command = string.lower(command)

    if command == "help" then
        local names = {}

        for name in pairs(EPCommands) do
            table.insert(names, name)
        end

        table.sort(names)
        return true, "Comandos: " .. table.concat(names, ", ")
    end

    local definition = EPCommands[command]

    if not definition then
        return false, "Comando desconhecido: " .. command
    end

    local success, result = pcall(definition.Callback, argument)

    if not success then
        addEPLog("ERROR", result)
        return false, tostring(result)
    end

    if result == nil then
        result = "Comando concluído."
    end

    addEPLog("EXEC", command .. " -> " .. tostring(result))

    return true, tostring(result)
end

----------------------------------------------------------------
-- BUILT-IN DIAGNOSTIC COMMANDS
----------------------------------------------------------------

registerCommand(
    "status",
    "Mostra o estado geral da interface.",
    function()
        local tabCount = 0

        if type(Pages) == "table" then
            for _ in pairs(Pages) do
                tabCount += 1
            end
        end

        return "Páginas registradas: " .. tabCount
    end
)

registerCommand(
    "modules",
    "Mostra o estado do ModuleLoader.",
    function()
        local api = ENV.EPIC_PLANETS_MODULES

        if type(api) ~= "table" or type(api.GetSummary) ~= "function" then
            return "ModuleLoader não encontrado."
        end

        local summary = api.GetSummary()

        return string.format(
            "Total: %d | Carregados: %d | Erros: %d",
            summary.Total,
            summary.Loaded,
            summary.Failed
        )
    end
)

registerCommand(
    "logs",
    "Conta os registros de log.",
    function()
        return "Registros armazenados: " .. #EPLogs.Entries
    end
)

registerCommand(
    "clearlogs",
    "Limpa os registros guardados.",
    function()
        table.clear(EPLogs.Entries)
        return "Histórico limpo."
    end
)

registerCommand(
    "player",
    "Mostra o jogador local.",
    function()
        local success, playerName = pcall(function()
            return Players.LocalPlayer.Name
        end)

        if success then
            return "Jogador local: " .. playerName
        end

        return "Jogador local indisponível."
    end
)

registerCommand(
    "help",
    "Lista os comandos disponíveis.",
    function()
        local names = {}

        for name in pairs(EPCommands) do
            table.insert(names, name)
        end

        table.sort(names)

        return "Comandos: " .. table.concat(names, ", ")
    end
)

----------------------------------------------------------------
-- GUI HELPERS
----------------------------------------------------------------

local function createPart8Section(parent, title, description)
    local section = Instance.new("Frame")
    section.Name = "Part8_" .. title:gsub("%W", "")
    section.Size = UDim2.new(1, -10, 0, 55)
    section.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
    section.BorderSizePixel = 0
    section.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = section

    local heading = Instance.new("TextLabel")
    heading.Size = UDim2.new(1, -12, 0, 23)
    heading.Position = UDim2.fromOffset(6, 3)
    heading.BackgroundTransparency = 1
    heading.Text = title
    heading.TextColor3 = Color3.fromRGB(110, 220, 255)
    heading.Font = Enum.Font.GothamBold
    heading.TextSize = 14
    heading.TextXAlignment = Enum.TextXAlignment.Left
    heading.Parent = section

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -12, 0, 24)
    body.Position = UDim2.fromOffset(6, 27)
    body.BackgroundTransparency = 1
    body.Text = description or ""
    body.TextColor3 = Color3.fromRGB(210, 215, 230)
    body.Font = Enum.Font.Gotham
    body.TextSize = 11
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.Parent = section

    return section
end

local function createPart8Button(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 34)
    button.BackgroundColor3 = Color3.fromRGB(40, 46, 65)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(245, 245, 255)
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    part8Connect(button.Activated:Connect(callback))

    return button
end

local function createPart8TextBox(parent, placeholder, height)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -10, 0, height or 38)
    box.BackgroundColor3 = Color3.fromRGB(9, 11, 18)
    box.BorderSizePixel = 0
    box.TextColor3 = Color3.fromRGB(245, 245, 255)
    box.PlaceholderColor3 = Color3.fromRGB(130, 140, 160)
    box.PlaceholderText = placeholder
    box.Text = ""
    box.TextSize = 13
    box.Font = Enum.Font.Code
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Center
    box.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = box

    return box
end

local function preparePage(page, panelName)
    if not page then
        return nil
    end

    local old = page:FindFirstChild(panelName)

    if old then
        old:Destroy()
    end

    local panel = Instance.new("Frame")
    panel.Name = panelName
    panel.Size = UDim2.new(1, -8, 1, -8)
    panel.Position = UDim2.fromOffset(4, 4)
    panel.BackgroundTransparency = 1
    panel.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = panel

    return panel
end

----------------------------------------------------------------
-- EXECUTOR PAGE
----------------------------------------------------------------

if ExecutorPage then
    local panel = preparePage(ExecutorPage, "EPExecutorPanel")

    if panel then
        createPart8Section(
            panel,
            "EPIC PLANETS COMMAND CENTER",
            "Console local de diagnóstico. Digite help para listar comandos."
        )

        local commandBox = createPart8TextBox(
            panel,
            "Digite um comando, exemplo: status",
            42
        )

        local output = createPart8Section(
            panel,
            "OUTPUT",
            "Aguardando comando..."
        )

        local outputBody = output:FindFirstChildWhichIsA("TextLabel")
        if outputBody then
            outputBody.Text = "Aguardando comando..."
        end

        createPart8Button(panel, "RUN COMMAND", function()
            local success, message = runEPCommand(commandBox.Text)

            if outputBody then
                outputBody.Text = (success and "OK: " or "ERRO: ") .. message
            end

            addEPLog(success and "INFO" or "ERROR", message)
        end)

        createPart8Button(panel, "SHOW HELP", function()
            local _, message = runEPCommand("help")

            if outputBody then
                outputBody.Text = message
            end
        end)

        createPart8Button(panel, "SHOW MODULE STATUS", function()
            local _, message = runEPCommand("modules")

            if outputBody then
                outputBody.Text = message
            end
        end)

        createPart8Button(panel, "CLEAR OUTPUT", function()
            commandBox.Text = ""

            if outputBody then
                outputBody.Text = "Saída limpa."
            end
        end)
    end
else
    warn("[EPIC PLANETS] Aba Executor não encontrada.")
end

----------------------------------------------------------------
-- LOGS PAGE
----------------------------------------------------------------

if LogsPage then
    local panel = preparePage(LogsPage, "EPLogsPanel")

    if panel then
        createPart8Section(
            panel,
            "RUNTIME LOGS",
            "Histórico de comandos e diagnósticos."
        )

        local logDisplay = Instance.new("TextLabel")
        logDisplay.Name = "LogDisplay"
        logDisplay.Size = UDim2.new(1, -10, 0, 230)
        logDisplay.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
        logDisplay.BorderSizePixel = 0
        logDisplay.TextColor3 = Color3.fromRGB(220, 230, 245)
        logDisplay.Font = Enum.Font.Code
        logDisplay.TextSize = 11
        logDisplay.TextXAlignment = Enum.TextXAlignment.Left
        logDisplay.TextYAlignment = Enum.TextYAlignment.Top
        logDisplay.TextWrapped = true
        logDisplay.Text = "Nenhum registro ainda."
        logDisplay.LayoutOrder = 2
        logDisplay.Parent = panel

        local function refreshLogs()
            local lines = {}
            local first = math.max(1, #EPLogs.Entries - 24)

            for index = first, #EPLogs.Entries do
                local entry = EPLogs.Entries[index]

                table.insert(
                    lines,
                    "[" .. entry.Time .. "] "
                    .. "[" .. entry.Level .. "] "
                    .. entry.Message
                )
            end

            logDisplay.Text = #lines > 0
                and table.concat(lines, "\n")
                or "Nenhum registro ainda."
        end

        createPart8Button(panel, "REFRESH LOGS", refreshLogs)

        createPart8Button(panel, "CLEAR LOGS", function()
            table.clear(EPLogs.Entries)
            refreshLogs()
            addEPLog("INFO", "Histórico limpo.")
        end)

        createPart8Button(panel, "ADD TEST LOG", function()
            addEPLog("TEST", "Registro de teste do EPIC PLANETS.")
            refreshLogs()
        end)

        part8Connect(Players.LocalPlayer
            and Players.LocalPlayer:GetPropertyChangedSignal("Name"):Connect(refreshLogs)
            or nil
        )

        refreshLogs()
    end
else
    warn("[EPIC PLANETS] Aba Logs não encontrada.")
end

----------------------------------------------------------------
-- GLOBAL API
----------------------------------------------------------------

ENV.EPIC_PLANETS_CONSOLE = {
    Run = runEPCommand,
    RegisterCommand = registerCommand,
    AddLog = addEPLog,
    GetLogs = function()
        return EPLogs.Entries
    end,
    Commands = EPCommands,
}

----------------------------------------------------------------
-- INITIAL LOGS
----------------------------------------------------------------

addEPLog("INFO", "Parte 8/9 inicializada.")
addEPLog("INFO", "Console de diagnóstico pronto.")

moduleNotify("Parte 8/9 carregada.")

--[[
    EPIC PLANETS
    PARTE 9/9
    FINAL INTEGRATION + EXTRA TABS

    Cole no final da Parte 8.
    Reutiliza a ScreenGui e as páginas existentes.
]]

----------------------------------------------------------------
-- FINAL INTEGRATION
----------------------------------------------------------------

local EP9 = {
    Connections = {},
    OriginalLighting = {},
    OriginalFOV = nil,
    Spectating = false,
    OldCameraSubject = nil,
    OldCameraType = nil,
}

ENV.__EPIC_PLANETS_PART9 = EP9

local function ep9Log(message)
    message = "[EPIC PLANETS] " .. tostring(message)
    print(message)

    if type(ENV.__EPIC_PLANETS_CONSOLE) == "table"
        and type(ENV.__EPIC_PLANETS_CONSOLE.AddLog) == "function" then
        pcall(ENV.__EPIC_PLANETS_CONSOLE.AddLog, "INFO", message)
    end
end

local function ep9Connect(connection)
    table.insert(EP9.Connections, connection)
    return connection
end

----------------------------------------------------------------
-- CREATE MISSING TABS
----------------------------------------------------------------

local ExtraTabs = {
    {"SPECTATE", "👁"},
    {"SOUNDS", "♫"},
    {"SERVER", "🌐"},
    {"TELEPORT", "⌖"},
    {"CHARACTER", "♙"},
    {"CAMERA", "◉"},
    {"CHAT / TAGS", "☷"},
    {"FRIENDS", "♡"},
    {"VISUALS", "◈"},
    {"TROLL", "✦"},
}

for _, data in ipairs(ExtraTabs) do
    local tabName = data[1]

    if type(Pages) == "table" and not Pages[tabName] then
        if type(createTab) == "function" then
            pcall(createTab, tabName, data[2])
        end
    end
end

----------------------------------------------------------------
-- UI HELPERS
----------------------------------------------------------------

local function ep9GetPage(name)
    return type(Pages) == "table" and Pages[name] or nil
end

local function ep9MakePanel(page, name)
    if not page then
        warn("[EPIC PLANETS] Página ausente: " .. name)
        return nil
    end

    local old = page:FindFirstChild("EP9_" .. name)
    if old then
        old:Destroy()
    end

    local panel = Instance.new("Frame")
    panel.Name = "EP9_" .. name
    panel.Size = UDim2.new(1, -8, 1, -8)
    panel.Position = UDim2.fromOffset(4, 4)
    panel.BackgroundTransparency = 1
    panel.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = panel

    return panel
end

local function ep9Section(parent, title, description)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -8, 0, 54)
    section.BackgroundColor3 = Color3.fromRGB(22, 25, 37)
    section.BorderSizePixel = 0
    section.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = section

    local heading = Instance.new("TextLabel")
    heading.Size = UDim2.new(1, -12, 0, 22)
    heading.Position = UDim2.fromOffset(6, 3)
    heading.BackgroundTransparency = 1
    heading.Text = title
    heading.TextColor3 = Color3.fromRGB(100, 220, 255)
    heading.TextSize = 14
    heading.Font = Enum.Font.GothamBold
    heading.TextXAlignment = Enum.TextXAlignment.Left
    heading.Parent = section

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -12, 0, 25)
    body.Position = UDim2.fromOffset(6, 26)
    body.BackgroundTransparency = 1
    body.Text = description or ""
    body.TextColor3 = Color3.fromRGB(225, 230, 240)
    body.TextSize = 11
    body.TextWrapped = true
    body.Font = Enum.Font.Gotham
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.Parent = section

    return section, body
end

local function ep9Button(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -8, 0, 34)
    button.BackgroundColor3 = Color3.fromRGB(38, 44, 64)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(245, 245, 255)
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    ep9Connect(button.Activated:Connect(function()
        local ok, err = pcall(callback)

        if not ok then
            warn("[EPIC PLANETS] " .. tostring(err))
            ep9Log("Erro: " .. tostring(err))
        end
    end))

    return button
end

local function ep9TextBox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -8, 0, 36)
    box.BackgroundColor3 = Color3.fromRGB(10, 12, 19)
    box.BorderSizePixel = 0
    box.Text = ""
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(135, 145, 165)
    box.TextColor3 = Color3.fromRGB(245, 245, 255)
    box.TextSize = 13
    box.Font = Enum.Font.Code
    box.ClearTextOnFocus = false
    box.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = box

    return box
end

----------------------------------------------------------------
-- SPECTATE
----------------------------------------------------------------

local SpectatePage = ep9MakePanel(ep9GetPage("SPECTATE"), "Spectate")

if SpectatePage then
    local _, targetLabel = ep9Section(
        SpectatePage,
        "PLAYER SPECTATE",
        "Observe um jogador e volte à sua câmera quando quiser."
    )

    local targetBox = ep9TextBox(SpectatePage, "Nome do jogador")

    ep9Button(SpectatePage, "SPECTATE CLOSEST", function()
        local localPlayer = Players.LocalPlayer
        local character = localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if not root then
            targetLabel.Text = "Seu personagem não está disponível."
            return
        end

        local closestPlayer
        local closestDistance = math.huge

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character then
                local otherRoot = player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

                if otherRoot and humanoid and humanoid.Health > 0 then
                    local distance = (root.Position - otherRoot.Position).Magnitude

                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end

        if not closestPlayer then
            targetLabel.Text = "Nenhum jogador disponível."
            return
        end

        local camera = workspace.CurrentCamera
        local humanoid = closestPlayer.Character:FindFirstChildOfClass("Humanoid")

        EP9.OldCameraSubject = camera.CameraSubject
        EP9.OldCameraType = camera.CameraType
        EP9.Spectating = true

        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid

        targetLabel.Text = "Assistindo: " .. closestPlayer.Name
        ep9Log("Spectate: " .. closestPlayer.Name)
    end)

    ep9Button(SpectatePage, "SPECTATE BY NAME", function()
        local targetName = string.lower(targetBox.Text)

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer
                and string.sub(string.lower(player.Name), 1, #targetName) == targetName
                and targetName ~= "" then

                local humanoid = player.Character
                    and player.Character:FindFirstChildOfClass("Humanoid")

                if humanoid then
                    local camera = workspace.CurrentCamera

                    EP9.OldCameraSubject = camera.CameraSubject
                    EP9.OldCameraType = camera.CameraType
                    EP9.Spectating = true

                    camera.CameraType = Enum.CameraType.Custom
                    camera.CameraSubject = humanoid

                    targetLabel.Text = "Assistindo: " .. player.Name
                    return
                end
            end
        end

        targetLabel.Text = "Jogador não encontrado ou sem personagem."
    end)

    ep9Button(SpectatePage, "UNSPECTATE", function()
        local camera = workspace.CurrentCamera
        local character = Players.LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            camera.CameraSubject = humanoid
            camera.CameraType = Enum.CameraType.Custom
        elseif EP9.OldCameraSubject then
            camera.CameraSubject = EP9.OldCameraSubject
        end

        EP9.Spectating = false
        targetLabel.Text = "Câmera restaurada."
    end)
end

----------------------------------------------------------------
-- SERVER INFO
----------------------------------------------------------------

local ServerPage = ep9MakePanel(ep9GetPage("SERVER"), "Server")

if ServerPage then
    local _, infoLabel = ep9Section(
        ServerPage,
        "CURRENT SERVER",
        "Informações da sessão atual."
    )

    ep9Button(ServerPage, "REFRESH SERVER INFO", function()
        local count = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers
        local placeId = game.PlaceId
        local jobId = game.JobId

        infoLabel.Text = string.format(
            "Players: %d/%d | PlaceId: %s",
            count,
            maxPlayers,
            tostring(placeId)
        )

        ep9Log("JobId da sessão: " .. tostring(jobId))
    end)

    ep9Button(ServerPage, "COPY SERVER DETAILS TO LOG", function()
        ep9Log("PlaceId: " .. tostring(game.PlaceId))
        ep9Log("JobId: " .. tostring(game.JobId))
        ep9Log("Players: " .. tostring(#Players:GetPlayers()))
        ep9Log("Ping/região podem não estar disponíveis neste cliente.")
    end)

    ep9Section(
        ServerPage,
        "SERVER HOP / REJOIN",
        "Troca de servidor e reentrada dependem de suporte do jogo e do executor."
    )
end

----------------------------------------------------------------
-- CAMERA
----------------------------------------------------------------

local CameraPage = ep9MakePanel(ep9GetPage("CAMERA"), "Camera")

if CameraPage then
    local _, fovLabel = ep9Section(
        CameraPage,
        "FIELD OF VIEW",
        "Ajusta o campo de visão local da câmera."
    )

    local fovBox = ep9TextBox(CameraPage, "FOV entre 50 e 120")

    ep9Button(CameraPage, "APPLY FOV", function()
        local value = tonumber(fovBox.Text)

        if not value then
            fovLabel.Text = "Digite um número válido."
            return
        end

        value = math.clamp(value, 50, 120)

        local camera = workspace.CurrentCamera

        if camera then
            if EP9.OriginalFOV == nil then
                EP9.OriginalFOV = camera.FieldOfView
            end

            camera.FieldOfView = value
            fovLabel.Text = "FOV atual: " .. tostring(value)
        end
    end)

    ep9Button(CameraPage, "RESET FOV", function()
        local camera = workspace.CurrentCamera

        if camera then
            camera.FieldOfView = EP9.OriginalFOV or 70
            fovLabel.Text = "FOV restaurado."
        end
    end)

    ep9Button(CameraPage, "RESTORE CAMERA", function()
        local camera = workspace.CurrentCamera
        local character = Players.LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if camera and humanoid then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = humanoid
        end

        fovLabel.Text = "Câmera restaurada."
    end)
end

----------------------------------------------------------------
-- PLAYER: LOCAL FULLBRIGHT
----------------------------------------------------------------

local PlayerPage = ep9GetPage("Player")

if PlayerPage then
    local _, lightLabel = ep9Section(
        PlayerPage,
        "LOCAL FULLBRIGHT",
        "Aumenta a iluminação visual local."
    )

    ep9Button(PlayerPage, "ENABLE FULLBRIGHT", function()
        local lighting = game:GetService("Lighting")

        if not EP9.OriginalLighting.Saved then
            EP9.OriginalLighting.Saved = true
            EP9.OriginalLighting.Brightness = lighting.Brightness
            EP9.OriginalLighting.ClockTime = lighting.ClockTime
            EP9.OriginalLighting.Ambient = lighting.Ambient
            EP9.OriginalLighting.OutdoorAmbient = lighting.OutdoorAmbient
        end

        lighting.Brightness = 3
        lighting.ClockTime = 14
        lighting.Ambient = Color3.new(1, 1, 1)
        lighting.OutdoorAmbient = Color3.new(1, 1, 1)

        lightLabel.Text = "Fullbright ativado localmente."
    end)

    ep9Button(PlayerPage, "RESTORE LIGHTING", function()
        local lighting = game:GetService("Lighting")
        local saved = EP9.OriginalLighting

        if saved.Saved then
            lighting.Brightness = saved.Brightness
            lighting.ClockTime = saved.ClockTime
            lighting.Ambient = saved.Ambient
            lighting.OutdoorAmbient = saved.OutdoorAmbient
        end

        lightLabel.Text = "Iluminação original restaurada."
    end)
end

----------------------------------------------------------------
-- ENVIRONMENT: GRAVITY
----------------------------------------------------------------

local EnvironmentPage = ep9GetPage("ENVIRONMENT")

if EnvironmentPage then
    local _, gravityLabel = ep9Section(
        EnvironmentPage,
        "GRAVITY STATUS",
        "A gravidade global depende das permissões do servidor."
    )

    ep9Button(EnvironmentPage, "SHOW CURRENT GRAVITY", function()
        gravityLabel.Text = "Workspace.Gravity: "
            .. tostring(workspace.Gravity)
    end)

    ep9Button(EnvironmentPage, "RESTORE DEFAULT GRAVITY", function()
        local defaultGravity = 196.2

        pcall(function()
            if type(ENV.EPIC_PLANETS_MODULES) == "table" then
                ep9Log("Restaurar gravidade pode exigir permissão do servidor.")
            end
        end)

        gravityLabel.Text = "Valor padrão de referência: "
            .. tostring(defaultGravity)
            .. ". O servidor controla a gravidade real."
    end)
end

----------------------------------------------------------------
-- CHARACTER
----------------------------------------------------------------

local CharacterPage = ep9MakePanel(ep9GetPage("CHARACTER"), "Character")

if CharacterPage then
    local _, characterLabel = ep9Section(
        CharacterPage,
        "CHARACTER STATUS",
        "Ferramentas locais de estado do personagem."
    )

    ep9Button(CharacterPage, "REFRESH CHARACTER STATUS", function()
        local character = Players.LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if humanoid and root then
            characterLabel.Text = string.format(
                "HP: %.0f/%.0f | Velocidade: %.1f",
                humanoid.Health,
                humanoid.MaxHealth,
                humanoid.WalkSpeed
            )
        else
            characterLabel.Text = "Personagem não disponível."
        end
    end)

    ep9Button(CharacterPage, "RESTORE MOVEMENT", function()
        local character = Players.LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
            humanoid.AutoRotate = true
            characterLabel.Text = "Movimento padrão restaurado."
        end
    end)
end

----------------------------------------------------------------
-- TELEPORT: SPAWN ONLY
----------------------------------------------------------------

local TeleportPage = ep9MakePanel(ep9GetPage("TELEPORT"), "Teleport")

if TeleportPage then
    local _, teleportLabel = ep9Section(
        TeleportPage,
        "CHARACTER POSITION",
        "Volta ao ponto de spawn quando o jogo o disponibiliza."
    )

    ep9Button(TeleportPage, "TP TO SPAWN", function()
        local character = Players.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if not root then
            teleportLabel.Text = "Personagem indisponível."
            return
        end

        local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)

        if not spawnLocation then
            teleportLabel.Text = "Nenhum SpawnLocation encontrado."
            return
        end

        -- Movimento local; o servidor pode corrigir a posição.
        root.CFrame = spawnLocation.CFrame + Vector3.new(0, 4, 0)
        teleportLabel.Text = "Tentativa de retorno ao spawn enviada."
    end)

    ep9Section(
        TeleportPage,
        "OTHER TELEPORTS",
        "Teleporte para jogadores ou para o mouse pode ser bloqueado pelo servidor."
    )
end

----------------------------------------------------------------
-- SOUNDS
----------------------------------------------------------------

local SoundsPage = ep9MakePanel(ep9GetPage("SOUNDS"), "Sounds")

if SoundsPage then
    local _, soundLabel = ep9Section(
        SoundsPage,
        "AUDIO PLAYER",
        "Toca áudio local autorizado. Não força áudio nos outros jogadores."
    )

    local soundIdBox = ep9TextBox(SoundsPage, "ID de áudio autorizado")

    ep9Button(SoundsPage, "PLAY LOCAL SOUND", function()
        local id = soundIdBox.Text:match("%d+")

        if not id then
            soundLabel.Text = "Digite um ID numérico."
            return
        end

        local sound = Instance.new("Sound")
        sound.Name = "EP9_LocalSound"
        sound.SoundId = "rbxassetid://" .. id
        sound.Volume = 0.5
        sound.Parent = workspace.CurrentCamera

        local ok = pcall(function()
            sound:Play()
        end)

        if ok then
            soundLabel.Text = "Reprodução solicitada. O áudio pode não ter permissão."
            ep9Log("Áudio local solicitado: " .. id)
        else
            sound:Destroy()
            soundLabel.Text = "Não foi possível reproduzir o áudio."
        end
    end)

    ep9Button(SoundsPage, "STOP LOCAL SOUND", function()
        local camera = workspace.CurrentCamera

        if camera then
            for _, child in ipairs(camera:GetChildren()) do
                if child.Name == "EP9_LocalSound" then
                    child:Stop()
                    child:Destroy()
                end
            end
        end

        soundLabel.Text = "Áudios locais interrompidos."
    end)
end

----------------------------------------------------------------
-- FRIENDS
----------------------------------------------------------------

local FriendsPage = ep9MakePanel(ep9GetPage("FRIENDS"), "Friends")

if FriendsPage then
    local _, friendsLabel = ep9Section(
        FriendsPage,
        "FRIENDS",
        "Esta sessão mostra os jogadores presentes no servidor atual."
    )

    ep9Button(FriendsPage, "LIST PLAYERS IN THIS SERVER", function()
        local names = {}

        for _, player in ipairs(Players:GetPlayers()) do
            table.insert(names, player.Name)
        end

        friendsLabel.Text = table.concat(names, ", ")
        ep9Log("Jogadores listados: " .. #names)
    end)

    ep9Section(
        FriendsPage,
        "FRIEND JOIN / MESSAGES",
        "Entrar no servidor de um amigo e enviar mensagens depende das APIs e permissões do Roblox."
    )
end

----------------------------------------------------------------
-- CHAT / TAGS
----------------------------------------------------------------

local ChatPage = ep9MakePanel(ep9GetPage("CHAT / TAGS"), "ChatTags")

if ChatPage then
    local _, chatLabel = ep9Section(
        ChatPage,
        "CHAT TOOLS",
        "Pré-visualização local de uma tag personalizada."
    )

    local tagBox = ep9TextBox(ChatPage, "Tag, exemplo: [EPIC]")

    ep9Button(ChatPage, "PREVIEW CUSTOM TAG", function()
        local tag = tagBox.Text

        if tag == "" then
            tag = "[EPIC]"
        end

        chatLabel.Text = tag .. " " .. Players.LocalPlayer.Name .. ": Olá!"
    end)

    ep9Section(
        ChatPage,
        "CHAT LIMITS",
        "Envio repetitivo ou alterar mensagens de outras pessoas não é implementado."
    )
end

----------------------------------------------------------------
-- VISUALS
----------------------------------------------------------------

local VisualsPage = ep9MakePanel(ep9GetPage("VISUALS"), "Visuals")

if VisualsPage then
    local _, visualsLabel = ep9Section(
        VisualsPage,
        "VISUAL OPTIONS",
        "Opções de visualização que não revelam jogadores através de paredes."
    )

    ep9Button(VisualsPage, "SHOW PLAYER COUNT", function()
        visualsLabel.Text = "Players visíveis na sessão: "
            .. tostring(#Players:GetPlayers())
    end)

    ep9Button(VisualsPage, "DISABLE EXTRA VISUALS", function()
        visualsLabel.Text = "Nenhum efeito visual adicional está ativo."
    end)
end

----------------------------------------------------------------
-- TROLL
----------------------------------------------------------------

local TrollPage = ep9MakePanel(ep9GetPage("TROLL"), "Troll")

if TrollPage then
    local _, trollLabel = ep9Section(
        TrollPage,
        "FUN EFFECTS",
        "Efeitos locais de interface, sem lançar outros jogadores."
    )

    ep9Button(TrollPage, "RAINBOW LABEL", function()
        local hue = math.random()
        trollLabel.TextColor3 = Color3.fromHSV(hue, 0.8, 1)
        trollLabel.Text = "EPIC PLANETS 🌈"
    end)

    ep9Button(TrollPage, "RESET LABEL COLOR", function()
        trollLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
        trollLabel.Text = "Efeitos locais restaurados."
    end)
end

----------------------------------------------------------------
-- CLEANUP API
----------------------------------------------------------------

function EP9.Cleanup()
    for _, connection in ipairs(EP9.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(EP9.Connections)

    local camera = workspace.CurrentCamera

    if camera and EP9.OriginalFOV then
        camera.FieldOfView = EP9.OriginalFOV
    end

    if camera then
        local character = Players.LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = humanoid
        end
    end
end

ep9Log("Parte 9/9 carregada.")
ep9Log("Integração final concluída.")

if type(notify) == "function" then
    pcall(notify, "EPIC PLANETS", "Parte 9/9 carregada!")
end

--[[
    EPIC PLANETS
    PARTE 10/9 EXTRA
    CHAT / TAGS + FRIENDS + SERVER + PLAYER
    Cole DEPOIS da Parte 9.
]]

local ENV = (type(getgenv) == "function" and getgenv()) or _G

if ENV.__EPIC_PLANETS_PART10 then
    pcall(function()
        if ENV.__EPIC_PLANETS_PART10.Cleanup then
            ENV.__EPIC_PLANETS_PART10.Cleanup()
        end
    end)
end

local P10 = {
    Connections = {},
    Running = true,
}

ENV.__EPIC_PLANETS_PART10 = P10

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

local function p10log(message)
    if type(ENV.__EPIC_PLANETS_LOG) == "function" then
        pcall(ENV.__EPIC_PLANETS_LOG, tostring(message))
    end
    print("[EPIC PLANETS P10] " .. tostring(message))
end

local function p10button(pageName, title, callback)
    if type(ep9Button) == "function" then
        return ep9Button(pageName, title, callback)
    end
    p10log("Botão não criado: " .. title ..
        ". Verifique se os helpers da Parte 9 estão disponíveis.")
end

local function p10section(pageName, title)
    if type(ep9Section) == "function" then
        return ep9Section(pageName, title)
    end
end

local function getPage(name)
    if type(Pages) == "table" then
        return Pages[name]
    end
    return nil
end

-- =========================================================
-- CHAT / TAGS
-- =========================================================

if getPage("CHAT / TAGS") then
    p10section("CHAT / TAGS", "LOCAL TAG PREVIEW")

    p10button("CHAT / TAGS", "Set tag preview: EPIC", function()
        ENV.__EPIC_PLANETS_TAG_PREVIEW = "[EPIC]"
        p10log("Tag local definida como [EPIC].")
    end)

    p10button("CHAT / TAGS", "Set tag preview: PLANET", function()
        ENV.__EPIC_PLANETS_TAG_PREVIEW = "[PLANET]"
        p10log("Tag local definida como [PLANET].")
    end)

    p10button("CHAT / TAGS", "Clear tag preview", function()
        ENV.__EPIC_PLANETS_TAG_PREVIEW = nil
        p10log("Prévia de tag removida.")
    end)

    p10button("CHAT / TAGS", "Show current tag preview", function()
        p10log("Tag: " ..
            tostring(ENV.__EPIC_PLANETS_TAG_PREVIEW or "(nenhuma)"))
    end)
end

-- Tags acima são apenas uma configuração local.
-- Tags reais sobre o nome de jogadores exigem suporte do próprio jogo.

-- =========================================================
-- FRIENDS / PLAYERS ONLINE
-- =========================================================

if getPage("FRIENDS") then
    p10section("FRIENDS", "PLAYERS IN THIS SERVER")

    p10button("FRIENDS", "Refresh player list", function()
        local count = #Players:GetPlayers()
        p10log("Jogadores neste servidor: " .. count)

        for _, player in ipairs(Players:GetPlayers()) do
            p10log(player.Name .. "  |  Display: " ..
                player.DisplayName .. "  |  UserId: " ..
                tostring(player.UserId))
        end
    end)

    p10button("FRIENDS", "Show my account", function()
        p10log("Username: " .. LocalPlayer.Name)
        p10log("DisplayName: " .. LocalPlayer.DisplayName)
        p10log("UserId: " .. tostring(LocalPlayer.UserId))
    end)
end

-- A lista acima mostra quem está na partida atual.
-- Não é a lista completa de amizades da conta Roblox.

-- =========================================================
-- SERVER
-- =========================================================

if getPage("SERVER") then
    p10section("SERVER", "SERVER INFORMATION")

    p10button("SERVER", "Show server info", function()
        p10log("PlaceId: " .. tostring(game.PlaceId))
        p10log("GameId: " .. tostring(game.GameId))
        p10log("JobId: " .. tostring(game.JobId))
        p10log("Players: " .. tostring(#Players:GetPlayers()))
        p10log("MaxPlayers: " ..
            tostring(Players.MaxPlayers))
        p10log("Client: " ..
            (RunService:IsClient() and "Client" or "Other"))
    end)

    p10button("SERVER", "Measure client ping", function()
        local ok, result = pcall(function()
            local stats = game:GetService("Stats")
            return stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)

        if ok then
            p10log("Data Ping: " .. tostring(math.floor(result)) .. " ms")
        else
            p10log("Ping indisponível nesta versão.")
        end
    end)

    p10button("SERVER", "Rejoin current experience", function()
        p10log("Solicitando retorno ao servidor atual...")

        local ok, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)

        if not ok then
            p10log("Teleport bloqueado ou indisponível: " ..
                tostring(err))
        end
    end)
end

-- TeleportService pode ser bloqueado pelo ambiente ou pelo jogo.
-- Rejoin não garante que você voltará ao mesmo servidor.

-- =========================================================
-- PLAYER
-- =========================================================

if getPage("PLAYER") then
    p10section("PLAYER", "MOVEMENT OPTIONS")

    p10button("PLAYER", "Infinite Jump: toggle", function()
        ENV.__EPIC_PLANETS_INFINITE_JUMP =
            not ENV.__EPIC_PLANETS_INFINITE_JUMP

        p10log("Infinite Jump local: " ..
            tostring(ENV.__EPIC_PLANETS_INFINITE_JUMP))
    end)

    p10button("PLAYER", "Noclip: toggle", function()
        ENV.__EPIC_PLANETS_NOCLIP =
            not ENV.__EPIC_PLANETS_NOCLIP

        p10log("Noclip local: " ..
            tostring(ENV.__EPIC_PLANETS_NOCLIP))
    end)

    p10button("PLAYER", "Reset movement toggles", function()
        ENV.__EPIC_PLANETS_INFINITE_JUMP = false
        ENV.__EPIC_PLANETS_NOCLIP = false
        p10log("Toggles desativados.")
    end)
end

-- Esses botões guardam o estado das opções.
-- Eles só terão efeito se o loop de movimento da sua GUI
-- consultar essas variáveis e implementar os controles.

-- =========================================================
-- CLEANUP
-- =========================================================

function P10.Cleanup()
    if not P10.Running then
        return
    end

    P10.Running = false

    for _, connection in ipairs(P10.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(P10.Connections)
end

p10log("Parte 10/9 carregada.")

--[[
    EPIC PLANETS - PARTE 11/12
    Abas:
      1. ANIMATIONS
      2. TELEPORT
      3. CHARACTER
      4. CAMERA

    Cole depois da Parte 10.
]]

local ENV = (type(getgenv) == "function" and getgenv()) or _G

if ENV.__EPIC_PLANETS_PART11 then
    pcall(function()
        ENV.__EPIC_PLANETS_PART11.Cleanup()
    end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

local P11 = {
    Connections = {},
    Running = true,
    Freecam = false,
    Noclip = false,
    OldFOV = nil,
    OldLighting = nil,
    OldCameraType = nil,
    OldCameraSubject = nil,
}

ENV.__EPIC_PLANETS_PART11 = P11

local function log11(msg)
    print("[EPIC PLANETS P11] " .. tostring(msg))
end

local function addConnection(connection)
    table.insert(P11.Connections, connection)
    return connection
end

local function pageExists(name)
    return type(Pages) == "table" and Pages[name] ~= nil
end

local function button11(page, title, callback)
    if type(ep9Button) == "function" and pageExists(page) then
        return ep9Button(page, title, callback)
    end
    log11("Página/helper não encontrado: " .. page)
end

local function section11(page, title)
    if type(ep9Section) == "function" and pageExists(page) then
        return ep9Section(page, title)
    end
end

local function character()
    return LP.Character
end

local function humanoid()
    local c = character()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function root()
    local c = character()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- =========================================================
-- 1. ANIMATIONS
-- =========================================================

if pageExists("ANIMATIONS") then
    section11("ANIMATIONS", "ANIMATION PLAYER")

    local animationIds = {
        ["Floss"] = "",
        ["Macarena"] = "",
        ["Gangnam Style"] = "",
        ["Custom Animation"] = "",
    }

    local currentTrack

    local function stopAnimation()
        if currentTrack then
            pcall(function()
                currentTrack:Stop(0.15)
                currentTrack:Destroy()
            end)
            currentTrack = nil
        end
        log11("Animação parada.")
    end

    local function playAnimation(name)
        local id = animationIds[name]
        if not id or id == "" then
            log11(name .. ": falta um ID válido de animação.")
            return
        end

        local h = humanoid()
        if not h then
            log11("Personagem/Humanoid não encontrado.")
            return
        end

        local animator = h:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = h
        end

        stopAnimation()

        local animation = Instance.new("Animation")
        animation.AnimationId = id

        local ok, track = pcall(function()
            return animator:LoadAnimation(animation)
        end)

        if not ok or not track then
            animation:Destroy()
            log11("Não foi possível carregar. Verifique o ID e as permissões.")
            return
        end

        currentTrack = track
        track.Priority = Enum.AnimationPriority.Action
        track:Play(0.15)
        log11("Reprodução solicitada: " .. name)
    end

    for name in pairs(animationIds) do
        button11("ANIMATIONS", "Play: " .. name, function()
            playAnimation(name)
        end)
    end

    button11("ANIMATIONS", "Stop Animation", stopAnimation)

    button11("ANIMATIONS", "Set Custom Animation ID", function()
        log11("Edite animationIds['Custom Animation'] no código e informe um ID válido.")
    end)

    P11.StopAnimation = stopAnimation
end

-- =========================================================
-- 2. TELEPORT
-- =========================================================

if pageExists("TELEPORT") then
    section11("TELEPORT", "CHARACTER TELEPORT")

    button11("TELEPORT", "Teleport to Spawn", function()
        local r = root()
        if not r then
            log11("RootPart não encontrado.")
            return
        end

        local spawnLocation
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("SpawnLocation") then
                spawnLocation = obj
                break
            end
        end

        if not spawnLocation then
            log11("Nenhum SpawnLocation encontrado.")
            return
        end

        r.CFrame = spawnLocation.CFrame + Vector3.new(0, 4, 0)
        log11("Tentativa de teleporte ao spawn.")
    end)

    button11("TELEPORT", "Teleport to Mouse Position", function()
        local r = root()
        if not r then
            log11("RootPart não encontrado.")
            return
        end

        local hit = Mouse.Hit
        if hit then
            r.CFrame = CFrame.new(hit.Position + Vector3.new(0, 4, 0))
            log11("Tentativa de teleporte ao ponto do mouse.")
        end
    end)

    button11("TELEPORT", "List Player Names", function()
        for _, player in ipairs(Players:GetPlayers()) do
            log11(player.Name .. " | " .. player.DisplayName)
        end
    end)

    button11("TELEPORT", "Teleport to Selected Player", function()
        log11("Selecione um nome no código em P11.TargetPlayer.")
        local targetName = P11.TargetPlayer
        if type(targetName) ~= "string" then
            log11("Defina P11.TargetPlayer = 'Username'.")
            return
        end

        local target = Players:FindFirstChild(targetName)
        local tr = target and target.Character
            and target.Character:FindFirstChild("HumanoidRootPart")
        local r = root()

        if tr and r then
            r.CFrame = tr.CFrame + Vector3.new(3, 0, 0)
        else
            log11("Jogador ou personagem não encontrado.")
        end
    end)
end

-- =========================================================
-- 3. CHARACTER
-- =========================================================

if pageExists("CHARACTER") then
    section11("CHARACTER", "CHARACTER SIZE")

    local originalScales = {}

    local function setScale(scale)
        local h = humanoid()
        if not h then
            log11("Humanoid não encontrado.")
            return
        end

        local scaleNames = {
            "BodyHeightScale",
            "BodyWidthScale",
            "BodyDepthScale",
            "HeadScale",
        }

        local found = false
        for _, name in ipairs(scaleNames) do
            local value = h:FindFirstChild(name)
            if value and value:IsA("NumberValue") then
                if originalScales[name] == nil then
                    originalScales[name] = value.Value
                end
                value.Value = scale
                found = true
            end
        end

        if found then
            log11("Escala local ajustada para " .. scale ..
                ". O jogo pode ignorar ou corrigir a mudança.")
        else
            log11("Este avatar não expõe escalas compatíveis.")
        end
    end

    button11("CHARACTER", "Giant Mode", function()
        setScale(1.5)
    end)

    button11("CHARACTER", "Tiny Mode", function()
        setScale(0.6)
    end)

    button11("CHARACTER", "Restore Character Size", function()
        local h = humanoid()
        if not h then return end

        for name, oldValue in pairs(originalScales) do
            local value = h:FindFirstChild(name)
            if value and value:IsA("NumberValue") then
                value.Value = oldValue
            end
        end

        table.clear(originalScales)
        log11("Tentativa de restaurar as escalas.")
    end)

    button11("CHARACTER", "Invisible Mode Info", function()
        log11("Invisibilidade real depende do jogo/servidor. Não é garantida por uma alteração local.")
    end)

    button11("CHARACTER", "Walk on Air Info", function()
        log11("Walk on Air requer uma implementação específica para o jogo e pode ser bloqueado.")
    end)
end

-- =========================================================
-- 4. CAMERA
-- =========================================================

if pageExists("CAMERA") then
    section11("CAMERA", "FIELD OF VIEW")

    button11("CAMERA", "FOV 70", function()
        local cam = workspace.CurrentCamera
        if cam then
            P11.OldFOV = P11.OldFOV or cam.FieldOfView
            cam.FieldOfView = 70
        end
    end)

    button11("CAMERA", "FOV 90", function()
        local cam = workspace.CurrentCamera
        if cam then
            P11.OldFOV = P11.OldFOV or cam.FieldOfView
            cam.FieldOfView = 90
        end
    end)

    button11("CAMERA", "FOV 110", function()
        local cam = workspace.CurrentCamera
        if cam then
            P11.OldFOV = P11.OldFOV or cam.FieldOfView
            cam.FieldOfView = 110
        end
    end)

    button11("CAMERA", "Restore FOV", function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.FieldOfView = P11.OldFOV or 70
            P11.OldFOV = nil
        end
    end)

    section11("CAMERA", "LOCAL FULLBRIGHT")

    button11("CAMERA", "Enable Fullbright", function()
        if not P11.OldLighting then
            P11.OldLighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
        end

        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        log11("Fullbright local ativado.")
    end)

    button11("CAMERA", "Restore Lighting", function()
        local old = P11.OldLighting
        if not old then
            log11("Não há iluminação salva.")
            return
        end

        for property, value in pairs(old) do
            pcall(function()
                Lighting[property] = value
            end)
        end

        P11.OldLighting = nil
        log11("Iluminação restaurada.")
    end)

    button11("CAMERA", "Freecam Info", function()
        log11("Freecam completa precisa de controles de câmera e entrada móvel; não está implementada neste bloco.")
    end)
end

-- =========================================================
-- CLEANUP
-- =========================================================

function P11.Cleanup()
    if not P11.Running then return end
    P11.Running = false

    if P11.StopAnimation then
        pcall(P11.StopAnimation)
    end

    for _, connection in ipairs(P11.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(P11.Connections)

    local cam = workspace.CurrentCamera
    if cam and P11.OldFOV then
        cam.FieldOfView = P11.OldFOV
    end

    if P11.OldLighting then
        for property, value in pairs(P11.OldLighting) do
            pcall(function()
                Lighting[property] = value
            end)
        end
    end
end

log11("Parte 11 carregada. Verifique o console para mensagens.")

--[[
    EPIC PLANETS - PARTE 12/12
    SOUNDS + SERVER + FRIENDS + PLAYER
    Cole depois da Parte 11.

    Reutiliza Pages e os helpers da Parte 9.
]]

local ENV = (type(getgenv) == "function" and getgenv()) or _G

if ENV.__EPIC_PLANETS_PART12 then
    pcall(function()
        ENV.__EPIC_PLANETS_PART12.Cleanup()
    end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local LP = Players.LocalPlayer

local P12 = {
    Running = true,
    Connections = {},
    Noclip = false,
    InfiniteJump = false,
    OldLighting = nil,
    Rainbow = false,
}

ENV.__EPIC_PLANETS_PART12 = P12

local function log12(message)
    print("[EPIC PLANETS P12] " .. tostring(message))
end

local function hasPage(name)
    return type(Pages) == "table" and Pages[name] ~= nil
end

local function section12(page, title)
    if hasPage(page) and type(ep9Section) == "function" then
        return ep9Section(page, title)
    end
end

local function button12(page, title, callback)
    if hasPage(page) and type(ep9Button) == "function" then
        return ep9Button(page, title, callback)
    end
    log12("Página ou helper ausente: " .. page)
end

local function character()
    return LP.Character
end

local function humanoid()
    local c = character()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function root()
    local c = character()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- =========================================================
-- 5. SOUNDS
-- =========================================================

if hasPage("SOUNDS") then
    section12("SOUNDS", "LOCAL SOUND PLAYER")

    local sound = Instance.new("Sound")
    sound.Name = "EPIC_PLANETS_LocalSound"
    sound.Volume = 0.5
    sound.Looped = false
    sound.Parent = workspace.CurrentCamera

    P12.Sound = sound

    button12("SOUNDS", "Play Custom Sound ID", function()
        log12("Edite P12.Sound.SoundId com um asset de áudio permitido.")
        log12("Exemplo: P12.Sound.SoundId = 'rbxassetid://ID_VALIDO'")
    end)

    button12("SOUNDS", "Play Sound", function()
        if not sound.SoundId or sound.SoundId == "" then
            log12("Nenhum SoundId configurado.")
            return
        end

        local ok, err = pcall(function()
            sound:Play()
        end)

        if not ok then
            log12("Não foi possível reproduzir: " .. tostring(err))
        end
    end)

    button12("SOUNDS", "Stop Sound", function()
        pcall(function()
            sound:Stop()
        end)
    end)

    button12("SOUNDS", "Volume 25%", function()
        sound.Volume = 0.25
        log12("Volume local: 25%")
    end)

    button12("SOUNDS", "Volume 50%", function()
        sound.Volume = 0.5
        log12("Volume local: 50%")
    end)

    button12("SOUNDS", "Volume 100%", function()
        sound.Volume = 1
        log12("Volume local: 100%")
    end)
end

-- O áudio é local e depende das permissões do asset.
-- Não força som nos dispositivos dos outros jogadores.

-- =========================================================
-- 6. SERVER
-- =========================================================

if hasPage("SERVER") then
    section12("SERVER", "SERVER INFORMATION")

    button12("SERVER", "Refresh Server Info", function()
        log12("PlaceId: " .. tostring(game.PlaceId))
        log12("JobId: " .. tostring(game.JobId))
        log12("Players: " .. tostring(#Players:GetPlayers()))
        log12("MaxPlayers: " .. tostring(Players.MaxPlayers))
    end)

    button12("SERVER", "Rejoin Current Experience", function()
        local ok, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, LP)
        end)

        if not ok then
            log12("Rejoin indisponível: " .. tostring(err))
        end
    end)

    button12("SERVER", "Server Hop", function()
        log12("Server Hop automático exige uma fonte de servidores públicos compatível.")
        log12("Esta versão não inventa IDs de servidores nem promete encontrar outro servidor.")
    end)

    button12("SERVER", "Prepare Auto-Execute", function()
        local queue = ENV.queue_on_teleport
            or ENV.queueonteleport
            or ENV.queue_on_tp

        if type(queue) ~= "function" then
            log12("Comando queue_on_teleport não encontrado neste ambiente.")
            return
        end

        local source = [[
            -- EPIC PLANETS Auto-Execute
            -- Insira aqui o código de inicialização
            -- ou a chamada ao loader confiável do seu script.
            print("[EPIC PLANETS] Teleporte concluído.")
        ]]

        local ok, err = pcall(queue, source)
        if ok then
            log12("Código de teste colocado na fila de teleporte.")
        else
            log12("Falha ao enfileirar: " .. tostring(err))
        end
    end)
end

-- queue_on_teleport só prepara o código para a transição.
-- O comando não garante que o executor continuará ativo.

-- =========================================================
-- 7. FRIENDS
-- =========================================================

if hasPage("FRIENDS") then
    section12("FRIENDS", "CURRENT SERVER PLAYERS")

    button12("FRIENDS", "List Players", function()
        for _, player in ipairs(Players:GetPlayers()) do
            log12(player.Name .. " | " .. player.DisplayName)
        end
    end)

    button12("FRIENDS", "Find Player by Username", function()
        local targetName = P12.TargetUsername
        if type(targetName) ~= "string" or targetName == "" then
            log12("Defina P12.TargetUsername = 'Username' no código.")
            return
        end

        local target = Players:FindFirstChild(targetName)
        if target then
            log12("Encontrado: " .. target.Name ..
                " | UserId: " .. tostring(target.UserId))
        else
            log12("Esse jogador não está nesta partida.")
        end
    end)

    button12("FRIENDS", "Friend List Info", function()
        log12("A lista completa de amizades exige acesso à API de amizades do Roblox.")
        log12("Esta página mostra apenas jogadores da partida atual.")
    end)
end

-- =========================================================
-- 8. PLAYER
-- =========================================================

if hasPage("PLAYER") then
    section12("PLAYER", "MOVEMENT CONTROLS")

    button12("PLAYER", "Toggle Infinite Jump", function()
        P12.InfiniteJump = not P12.InfiniteJump
        log12("Infinite Jump: " .. tostring(P12.InfiniteJump))
    end)

    button12("PLAYER", "Toggle Noclip", function()
        P12.Noclip = not P12.Noclip
        log12("Noclip: " .. tostring(P12.Noclip))
    end)

    button12("PLAYER", "Toggle Rainbow Walk", function()
        P12.Rainbow = not P12.Rainbow
        log12("Rainbow Walk: " .. tostring(P12.Rainbow))
    end)

    button12("PLAYER", "Restore Movement", function()
        P12.InfiniteJump = false
        P12.Noclip = false
        P12.Rainbow = false
        log12("Opções de movimento desativadas.")
    end)

    section12("PLAYER", "LOCAL FULLBRIGHT")

    button12("PLAYER", "Enable Fullbright", function()
        if not P12.OldLighting then
            P12.OldLighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
        end

        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)

        log12("Fullbright local ativado.")
    end)

    button12("PLAYER", "Restore Fullbright", function()
        if not P12.OldLighting then
            log12("Nenhuma iluminação salva.")
            return
        end

        for property, value in pairs(P12.OldLighting) do
            pcall(function()
                Lighting[property] = value
            end)
        end

        P12.OldLighting = nil
        log12("Iluminação restaurada.")
    end)
end

-- =========================================================
-- CLEANUP
-- =========================================================

function P12.Cleanup()
    if not P12.Running then
        return
    end

    P12.Running = false
    P12.InfiniteJump = false
    P12.Noclip = false
    P12.Rainbow = false

    for _, connection in ipairs(P12.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(P12.Connections)

    if P12.Sound then
        pcall(function()
            P12.Sound:Stop()
            P12.Sound:Destroy()
        end)
    end

    if P12.OldLighting then
        for property, value in pairs(P12.OldLighting) do
            pcall(function()
                Lighting[property] = value
            end)
        end
    end
end

log12("Parte 12 carregada.")
