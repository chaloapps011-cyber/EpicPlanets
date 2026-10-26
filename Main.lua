
--[[
    EPIC PLANETS
    Dark modular UI inspired by Uhhhhhh Reanimate's section-based layout.
    Delta / Android. The title is randomized on every launch.
]]

local ENV = (type(getgenv) == "function" and getgenv()) or _G

-- Clean up an older copy so rerunning the HTTPS loader does not stack GUIs.
if type(ENV.__EPIC_PLANETS_CONNECTIONS) == "table" then
    for _, connection in ipairs(ENV.__EPIC_PLANETS_CONNECTIONS) do
        pcall(function() connection:Disconnect() end)
    end
end
if ENV.__EPIC_PLANETS_GUI then
    pcall(function() ENV.__EPIC_PLANETS_GUI:Destroy() end)
end
if type(ENV.__EPIC_PLANETS_MODELS) == "table" then
    for _, oldModel in ipairs(ENV.__EPIC_PLANETS_MODELS) do
        if typeof(oldModel) == "Instance" and oldModel.Parent then
            pcall(function() oldModel:Destroy() end)
        end
    end
end
ENV.__EPIC_PLANETS_RUNNING = true
ENV.__EPIC_PLANETS_CONNECTIONS = {}

local function findExecutorFunction(name)
    local fn
    pcall(function() fn = ENV[name] end)
    if type(fn) ~= "function" then
        pcall(function() fn = _G[name] end)
    end
    return type(fn) == "function" and fn or nil
end

local function executorCall(name, ...)
    local fn = findExecutorFunction(name)
    if not fn then
        return false, "Executor API unavailable: " .. name
    end
    local ok, result = pcall(fn, ...)
    return ok, result
end

local success, fatalError = pcall(function()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local World = game:GetService("Workspace")

    local player = Players.LocalPlayer
    if not player then
        error("LocalPlayer não encontrado. Execute dentro de uma sessão do Roblox.")
    end

    local playerGui = player:WaitForChild("PlayerGui")
    local connections = ENV.__EPIC_PLANETS_CONNECTIONS
    local rainbowStrokes = {}

    local function bind(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    local function make(className, properties, parent)
        local object = Instance.new(className)
        for property, value in pairs(properties or {}) do
            object[property] = value
        end
        object.Parent = parent
        return object
    end

    local COLORS = {
        background = Color3.fromRGB(8, 8, 11),
        panel = Color3.fromRGB(17, 17, 22),
        panelAlt = Color3.fromRGB(26, 26, 33),
        panelHover = Color3.fromRGB(38, 38, 47),
        text = Color3.fromRGB(240, 240, 245),
        muted = Color3.fromRGB(157, 157, 170),
        red = Color3.fromRGB(245, 65, 75),
        green = Color3.fromRGB(72, 220, 145),
        blue = Color3.fromRGB(55, 145, 255),
        purple = Color3.fromRGB(173, 96, 255),
    }

    local titles = {
        {name = "Epic Planets", color = COLORS.text},
        {name = "please don't touch In builtinmodules", color = COLORS.text},
        {name = "BLUEEEEEE", color = Color3.fromRGB(0, 135, 255)},
        {name = "F up", color = COLORS.red},
        {name = "April!", color = COLORS.green},
        {name = "Dont kill the script", color = COLORS.text},
    }

    math.randomseed(os.time() + math.floor(os.clock() * 100000))
    local previousTitle = tonumber(ENV.__EPIC_PLANETS_LAST_TITLE)
    local titleIndex = math.random(1, #titles)

    -- Avoid repeating the last title when this script is re-executed.
    if #titles > 1 and titleIndex == previousTitle then
        repeat
            titleIndex = math.random(1, #titles)
        until titleIndex ~= previousTitle
    end
    ENV.__EPIC_PLANETS_LAST_TITLE = titleIndex

    local function round(object, radius)
        make("UICorner", {
            CornerRadius = UDim.new(0, radius or 8),
        }, object)
    end

    local function outline(object, thickness, transparency)
        local stroke = make("UIStroke", {
            Thickness = thickness or 1,
            Transparency = transparency or 0.12,
            Color = COLORS.blue,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }, object)

        table.insert(rainbowStrokes, stroke)
        return stroke
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

    local function textLabel(parent, text, height, color, size)
        return make("TextLabel", {
            Size = UDim2.new(1, -4, 0, height or 32),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = color or COLORS.text,
            TextSize = size or 13,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
        }, parent)
    end

    local function statusButton(parent, label, callback, height)
        local button = make("TextButton", {
            Size = UDim2.new(1, -4, 0, height or 40),
            BackgroundColor3 = COLORS.panelAlt,
            BorderSizePixel = 0,
            AutoButtonColor = true,
            Text = label,
            TextColor3 = COLORS.text,
            TextSize = 12,
            Font = Enum.Font.GothamSemibold,
            TextWrapped = true,
        }, parent)

        round(button, 7)
        outline(button, 1, 0.35)

        bind(button.Activated, function()
            local ok, err = pcall(callback, button)
            if not ok then
                warn("[EPIC PLANETS] Button error: " .. tostring(err))
            end
        end)

        return button
    end

    local function addListLayout(parent, padding)
        make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, padding or 7),
        }, parent)
    end

    -- Delta file-manager path, not Roblox Workspace.
    local ROOT = "workspace/epicplanets"
    local MODULES = ROOT .. "/Modules"

    local function ensureFolders()
        for _, folder in ipairs({"workspace", ROOT, MODULES}) do
            local folderExists = false
            local ok, result = executorCall("isfolder", folder)

            if ok and result == true then
                folderExists = true
            end

            if not folderExists then
                executorCall("makefolder", folder)
            end
        end
    end

    pcall(ensureFolders)

    local gui = make("ScreenGui", {
        Name = "EPIC_PLANETS_GUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, playerGui)

    ENV.__EPIC_PLANETS_GUI = gui

    ----------------------------------------------------------------------
    -- INTRO: full screen only during the opening animation.
    ----------------------------------------------------------------------

    local intro = make("Frame", {
        Name = "IntroScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = COLORS.background,
        BorderSizePixel = 0,
        Active = false,
    }, gui)

    for i = 1, 65 do
        local star = make("Frame", {
            Position = UDim2.fromScale(
                math.random(1, 99) / 100,
                math.random(1, 99) / 100
            ),
            Size = UDim2.fromOffset(
                math.random(1, 3),
                math.random(1, 3)
            ),
            BackgroundColor3 = (i % 5 == 0) and COLORS.blue or COLORS.text,
            BackgroundTransparency = math.random(25, 75) / 100,
            BorderSizePixel = 0,
        }, intro)

        round(star, 3)
    end

    local introTitle = make("TextLabel", {
        Position = UDim2.new(0, 8, 0, 17),
        Size = UDim2.new(1, -16, 0, 34),
        BackgroundTransparency = 1,
        Text = titles[titleIndex].name,
        TextColor3 = titles[titleIndex].color,
        TextSize = 21,
        Font = Enum.Font.GothamBlack,
        TextWrapped = true,
    }, intro)

    local introPanel = make("Frame", {
        Name = "IntroPanel",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.53),
        Size = UDim2.new(0.86, 0, 0.66, 0),
        BackgroundColor3 = COLORS.panel,
        BorderSizePixel = 0,
    }, intro)

    make("UISizeConstraint", {
        MinSize = Vector2.new(275, 350),
        MaxSize = Vector2.new(480, 530),
    }, introPanel)

    round(introPanel, 12)
    outline(introPanel, 1, 0.08)

    local introStatus = make("TextLabel", {
        Position = UDim2.new(0, 12, 0, 9),
        Size = UDim2.new(1, -24, 0, 23),
        BackgroundTransparency = 1,
        Text = "ASSEMBLING 321 FRAGMENTS",
        TextColor3 = COLORS.text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, introPanel)

    local orbit = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 37),
        Size = UDim2.fromOffset(150, 108),
        BackgroundTransparency = 1,
    }, introPanel)

    local core = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = COLORS.text,
        BorderSizePixel = 0,
    }, orbit)

    round(core, 30)
    outline(core, 1, 0.05)

    local planetColors = {
        COLORS.blue,
        COLORS.purple,
        COLORS.green,
        Color3.fromRGB(255, 170, 65),
    }

    local planets = {}

    for i = 1, 4 do
        local planet = make("Frame", {
            Name = "Planet" .. i,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(
                i % 2 == 0 and 16 or 12,
                i % 2 == 0 and 16 or 12
            ),
            BackgroundColor3 = planetColors[i],
            BorderSizePixel = 0,
        }, orbit)

        round(planet, 20)
        outline(planet, 1, 0.35)
        planets[i] = planet
    end

    local ring = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(92, 72),
        BackgroundTransparency = 1,
    }, orbit)

    round(ring, 40)
    outline(ring, 1, 0.55)

    local fragmentArea = make("Frame", {
        Position = UDim2.new(0, 10, 0, 151),
        Size = UDim2.new(1, -20, 0, 105),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, introPanel)

    local fragments = {}

    for i = 1, 321 do
        local fragmentSize = math.random(2, 5)

        local fragment = make("Frame", {
            Name = "Fragment" .. i,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(math.random(), math.random()),
            Size = UDim2.fromOffset(fragmentSize, fragmentSize),
            BackgroundColor3 = i % 6 == 0 and COLORS.purple or COLORS.blue,
            BorderSizePixel = 0,
        }, fragmentArea)

        round(fragment, 4)
        fragments[i] = fragment
    end

    local progressBack = make("Frame", {
        Position = UDim2.new(0, 14, 1, -43),
        Size = UDim2.new(1, -28, 0, 5),
        BackgroundColor3 = COLORS.panelAlt,
        BorderSizePixel = 0,
    }, introPanel)

    round(progressBack, 4)

    local progress = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = COLORS.blue,
        BorderSizePixel = 0,
    }, progressBack)

    round(progress, 4)

    local fragmentCount = make("TextLabel", {
        Position = UDim2.new(0, 0, 1, -32),
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = "0 / 321",
        TextColor3 = COLORS.muted,
        TextSize = 10,
        Font = Enum.Font.Code,
    }, introPanel)

    local tapIn = make("TextButton", {
        Name = "TapIn",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -50),
        Size = UDim2.new(0.7, 0, 0, 40),
        BackgroundColor3 = COLORS.panelAlt,
        BorderSizePixel = 0,
        Text = "T A P   I N",
        TextColor3 = COLORS.text,
        TextSize = 14,
        Font = Enum.Font.GothamBlack,
        Visible = false,
    }, introPanel)

    round(tapIn, 7)
    outline(tapIn, 1, 0.08)

    ----------------------------------------------------------------------
    -- MAIN WINDOW: dark window with a left navigation column.
    ----------------------------------------------------------------------

    local hub = make("Frame", {
        Name = "MainHub",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.51),
        Size = UDim2.new(0.91, 0, 0.74, 0),
        BackgroundColor3 = COLORS.panel,
        BorderSizePixel = 0,
        Visible = false,
    }, gui)

    make("UISizeConstraint", {
        MinSize = Vector2.new(300, 370),
        MaxSize = Vector2.new(640, 590),
    }, hub)

    round(hub, 11)
    outline(hub, 1, 0.05)

    local titleText = make("TextLabel", {
        Position = UDim2.new(0, 12, 0, 7),
        Size = UDim2.new(1, -92, 0, 28),
        BackgroundTransparency = 1,
        Text = titles[titleIndex].name,
        TextColor3 = titles[titleIndex].color,
        TextSize = 17,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, hub)

    local subtitle = make("TextLabel", {
        Position = UDim2.new(0, 13, 0, 29),
        Size = UDim2.new(1, -100, 0, 14),
        BackgroundTransparency = 1,
        Text = "CLIENT PANEL  /  EP-01",
        TextColor3 = COLORS.muted,
        TextSize = 8,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, hub)

    local minimizeButton = make("TextButton", {
        Position = UDim2.new(1, -42, 0, 8),
        Size = UDim2.fromOffset(30, 28),
        BackgroundColor3 = COLORS.panelAlt,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = COLORS.text,
        TextSize = 19,
        Font = Enum.Font.GothamBold,
    }, hub)

    round(minimizeButton, 6)
    outline(minimizeButton, 1, 0.25)

    make("Frame", {
        Position = UDim2.new(0, 10, 0, 43),
        Size = UDim2.new(1, -20, 0, 1),
        BackgroundColor3 = COLORS.panelAlt,
        BorderSizePixel = 0,
    }, hub)

    local sidebar = make("Frame", {
        Name = "Sidebar",
        Position = UDim2.new(0, 10, 0, 51),
        Size = UDim2.new(0, 102, 1, -85),
        BackgroundColor3 = COLORS.background,
        BorderSizePixel = 0,
    }, hub)

    round(sidebar, 7)
    outline(sidebar, 1, 0.55)

    make("UIPadding", {
        PaddingTop = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    }, sidebar)

    addListLayout(sidebar, 6)

    local pageHost = make("Frame", {
        Name = "PageHost",
        Position = UDim2.new(0, 120, 0, 51),
        Size = UDim2.new(1, -130, 1, -85),
        BackgroundColor3 = COLORS.background,
        BorderSizePixel = 0,
    }, hub)

    round(pageHost, 7)
    outline(pageHost, 1, 0.55)

    local statusLine = make("TextLabel", {
        Position = UDim2.new(0, 12, 1, -25),
        Size = UDim2.new(1, -24, 0, 17),
        BackgroundTransparency = 1,
        Text = "Status: Ready",
        TextColor3 = COLORS.muted,
        TextSize = 9,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, hub)

    local mini = make("TextButton", {
        Name = "EP_MiniIcon",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 12, 0.56, 0),
        Size = UDim2.fromOffset(42, 42),
        BackgroundColor3 = COLORS.background,
        BorderSizePixel = 0,
        Text = "EP",
        TextColor3 = COLORS.text,
        TextSize = 13,
        Font = Enum.Font.GothamBlack,
        Visible = false,
        ZIndex = 100,
    }, gui)

    round(mini, 10)
    outline(mini, 2, 0.02)

    local function setStatus(message)
        statusLine.Text = "Status: " .. tostring(message)
    end

    local pages = {}
    local navButtons = {}

    local function makePage(name)
        local page = make("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = COLORS.blue,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
        }, pageHost)

        make("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        }, page)

        addListLayout(page, 7)
        pages[name] = page
        return page
    end

    local function addInfo(parent, text, height, color)
        return textLabel(parent, text, height or 42, color or COLORS.muted, 11)
    end

    local function showPage(name)
        if not pages[name] then return end

        for pageName, page in pairs(pages) do
            page.Visible = pageName == name
        end

        for tabName, button in pairs(navButtons) do
            button.BackgroundColor3 =
                tabName == name and COLORS.panelHover or COLORS.panelAlt
            button.TextColor3 =
                tabName == name and COLORS.text or COLORS.muted
        end

        setStatus("Opened " .. name)
    end

    local function addTab(name, label, order)
        local button = make("TextButton", {
            Name = "Tab_" .. name,
            LayoutOrder = order,
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundColor3 = COLORS.panelAlt,
            BorderSizePixel = 0,
            Text = label,
            TextColor3 = COLORS.muted,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            TextWrapped = true,
        }, sidebar)

        round(button, 6)
        outline(button, 1, 0.65)
        navButtons[name] = button
        bind(button.Activated, function()
            showPage(name)
        end)

        return button
    end

    local homePage = makePage("Home")
    local playerPage = makePage("Player")
    local reanimatePage = makePage("Reanimate")
    local movesetsPage = makePage("Movesets")
    local modelsPage = makePage("Models")
    local settingsPage = makePage("Settings")

    addTab("Home", "HOME", 1)
    addTab("Player", "PLAYER", 2)
    addTab("Reanimate", "REANIMATE", 3)
    addTab("Movesets", "MOVESETS", 4)
    addTab("Models", "MODEL STORE", 5)
    addTab("Settings", "SETTINGS", 6)

    ----------------------------------------------------------------------
    -- HOME
    ----------------------------------------------------------------------

    textLabel(homePage, "EPIC PLANETS", 26, COLORS.text, 16).Font =
        Enum.Font.GothamBlack

    addInfo(
        homePage,
        "A compact, mobile-friendly control panel. Use the left tabs to open each section.",
        52
    )

    addInfo(homePage, "Player: " .. player.Name, 24, COLORS.text)
    addInfo(homePage, "Place ID: " .. tostring(game.PlaceId), 22)

    statusButton(homePage, "REFRESH MODULE LIST", function()
        showPage("Movesets")
        setStatus("Movesets opened. Tap REFRESH MODULES to scan files.")
    end)

    statusButton(homePage, "MINIMIZE TO EP ICON", function()
        hub.Visible = false
        mini.Visible = true
        setStatus("Minimized to EP icon")
    end)

    ----------------------------------------------------------------------
    -- PLAYER TOOLS
    ----------------------------------------------------------------------

    textLabel(playerPage, "PLAYER CONTROLS", 26, COLORS.text, 14).Font =
        Enum.Font.GothamBold

    addInfo(
        playerPage,
        "These are client-side movement changes. The game may override them.",
        43
    )

    local speedEnabled = false
    local jumpEnabled = false
    local flyEnabled = false
    local originalWalkSpeed = nil
    local originalJumpPower = nil
    local originalJumpHeight = nil
    local flyVelocity = nil
    local flyGyro = nil
    local flyVertical = 0
    local flyButton, speedButton, jumpButton

    local function getCharacterParts()
        local character = player.Character
        if not character then return nil, nil end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local root = character:FindFirstChild("HumanoidRootPart")
        return humanoid, root
    end

    local function setSpeed(enabled)
        local humanoid = getCharacterParts()

        if not humanoid then
            speedEnabled = false
            setStatus("Character/Humanoid not ready")
            return
        end

        if enabled then
            originalWalkSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = 32
            speedEnabled = true
        else
            if originalWalkSpeed then
                humanoid.WalkSpeed = originalWalkSpeed
            end
            speedEnabled = false
        end

        speedButton.Text =
            "Speed: " .. (speedEnabled and "ON (32)" or "OFF")

        setStatus(speedEnabled and "Speed enabled" or "Speed restored")
    end

    local function setJump(enabled)
        local humanoid = getCharacterParts()

        if not humanoid then
            jumpEnabled = false
            setStatus("Character/Humanoid not ready")
            return
        end

        if enabled then
            originalJumpPower = humanoid.JumpPower
            originalJumpHeight = humanoid.JumpHeight

            if humanoid.UseJumpPower then
                humanoid.JumpPower = 100
            else
                humanoid.JumpHeight = 50
            end

            jumpEnabled = true
        else
            if humanoid.UseJumpPower then
                if originalJumpPower then
                    humanoid.JumpPower = originalJumpPower
                end
            else
                if originalJumpHeight then
                    humanoid.JumpHeight = originalJumpHeight
                end
            end

            jumpEnabled = false
        end

        jumpButton.Text =
            "High Jump: " .. (jumpEnabled and "ON" or "OFF")

        setStatus(jumpEnabled and "High jump enabled" or "Jump restored")
    end

    local function setFly(enabled)
        local humanoid, root = getCharacterParts()

        if enabled and (not humanoid or not root) then
            flyEnabled = false
            setStatus("Character/HumanoidRootPart not ready")
            return
        end

        if enabled then
            if flyVelocity then
                pcall(function() flyVelocity:Destroy() end)
            end
            if flyGyro then
                pcall(function() flyGyro:Destroy() end)
            end

            flyVelocity = make("BodyVelocity", {
                Name = "EP_FlyVelocity",
                MaxForce = Vector3.new(1000000000, 1000000000, 1000000000),
                P = 12000,
                Velocity = Vector3.zero,
            }, root)

            flyGyro = make("BodyGyro", {
                Name = "EP_FlyGyro",
                MaxTorque = Vector3.new(1000000000, 1000000000, 1000000000),
                P = 9000,
                CFrame = root.CFrame,
            }, root)

            humanoid.AutoRotate = false
            flyVertical = 0
            flyEnabled = true
        else
            flyEnabled = false
            flyVertical = 0

            if flyVelocity then
                pcall(function() flyVelocity:Destroy() end)
            end
            if flyGyro then
                pcall(function() flyGyro:Destroy() end)
            end

            flyVelocity = nil
            flyGyro = nil

            if humanoid then
                humanoid.AutoRotate = true
            end
        end

        flyButton.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
        setStatus(
            flyEnabled
                and "Fly enabled. Use joystick + UP/DOWN."
                or "Fly disabled"
        )
    end

    flyButton = statusButton(playerPage, "Fly: OFF", function()
        setFly(not flyEnabled)
    end)

    speedButton = statusButton(playerPage, "Speed: OFF", function()
        setSpeed(not speedEnabled)
    end)

    jumpButton = statusButton(playerPage, "High Jump: OFF", function()
        setJump(not jumpEnabled)
    end)

    local verticalRow = make("Frame", {
        Size = UDim2.new(1, -4, 0, 42),
        BackgroundTransparency = 1,
    }, playerPage)

    local upButton = make("TextButton", {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.49, 0, 1, 0),
        BackgroundColor3 = COLORS.panelAlt,
        BorderSizePixel = 0,
        Text = "HOLD UP",
        TextColor3 = COLORS.text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
    }, verticalRow)

    round(upButton, 6)
    outline(upButton, 1, 0.4)

    local downButton = make("TextButton", {
        Position = UDim2.new(0.51, 0, 0, 0),
        Size = UDim2.new(0.49, 0, 1, 0),
        BackgroundColor3 = COLORS.panelAlt,
        BorderSizePixel = 0,
        Text = "HOLD DOWN",
        TextColor3 = COLORS.text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
    }, verticalRow)

    round(downButton, 6)
    outline(downButton, 1, 0.4)

    local function holdVertical(button, value)
        bind(button.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then

                if flyEnabled then
                    flyVertical = value
                else
                    setStatus("Ative Fly primeiro")
                end
            end
        end)

        bind(button.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then

                if flyVertical == value then
                    flyVertical = 0
                end
            end
        end)
    end

    holdVertical(upButton, 1)
    holdVertical(downButton, -1)

    addInfo(
        playerPage,
        "Tip: activate Fly, then steer with the Roblox joystick. Hold UP or DOWN for altitude.",
        44
    )

    ----------------------------------------------------------------------
    -- MODULES / MOVESETS
    ----------------------------------------------------------------------

    textLabel(movesetsPage, "MOVESETS / MODULES", 26, COLORS.text, 14).Font =
        Enum.Font.GothamBold

    addInfo(
        movesetsPage,
        "Local Lua files are read from Delta's file manager folder:",
        36
    )

    addInfo(movesetsPage, MODULES, 26, COLORS.text)

    local moduleList = make("Frame", {
        Name = "ModuleList",
        Size = UDim2.new(1, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, movesetsPage)

    addListLayout(moduleList, 6)

    local function runLocalModule(path)
        local readOK, source = executorCall("readfile", path)

        if not readOK or type(source) ~= "string" then
            setStatus("Could not read " .. tostring(path))
            return
        end

        local loadFn = findExecutorFunction("loadstring")

        if not loadFn then
            setStatus("This Delta environment has no loadstring")
            return
        end

        local compileOK, chunk = pcall(loadFn, source)

        if not compileOK or type(chunk) ~= "function" then
            setStatus("Lua compile error: " .. tostring(chunk))
            return
        end

        local runOK, runError = pcall(chunk)

        if not runOK then
            setStatus("Module error: " .. tostring(runError))
            return
        end

        setStatus("Module executed: " .. tostring(path):match("[^/\\]+$"))
    end

    local function refreshModules()
        for _, child in ipairs(moduleList:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end

        local listFn = findExecutorFunction("listfiles")

        if not listFn then
            addInfo(
                moduleList,
                "Delta does not expose listfiles in this environment.",
                42,
                COLORS.red
            )
            setStatus("listfiles API unavailable")
            return
        end

        local listOK, files = pcall(listFn, MODULES)

        if not listOK or type(files) ~= "table" then
            addInfo(
                moduleList,
                "Folder could not be scanned. Check the path in Delta's file manager.",
                48,
                COLORS.red
            )
            setStatus("Could not scan Modules folder")
            return
        end

        local found = 0

        for _, path in ipairs(files) do
            if type(path) == "string"
                and string.lower(path):sub(-4) == ".lua" then

                found = found + 1
                local filePath = path
                local shortName = path:match("[^/\\]+$") or path

                statusButton(moduleList, "RUN  " .. shortName, function()
                    runLocalModule(filePath)
                end, 38)
            end
        end

        if found == 0 then
            addInfo(
                moduleList,
                "No .lua files found yet. Put your modules in the folder above, then refresh.",
                54
            )
            setStatus("No Lua modules found")
        else
            setStatus("Found " .. tostring(found) .. " Lua module(s)")
        end
    end

    statusButton(movesetsPage, "REFRESH MODULES", refreshModules)

    ----------------------------------------------------------------------
    -- REANIMATION: uses only a module placed in the user's own folder.
    ----------------------------------------------------------------------

    textLabel(reanimatePage, "REANIMATION", 26, COLORS.text, 14).Font =
        Enum.Font.GothamBold

    addInfo(
        reanimatePage,
        "This interface does not bundle Uhhhhhh's reanimation engine. To connect your own compatible module, place LimbReanimation.lua in the Modules folder.",
        78
    )

    addInfo(reanimatePage, "Module path:", 22)
    addInfo(reanimatePage, MODULES .. "/LimbReanimation.lua", 34, COLORS.text)

    statusButton(reanimatePage, "LOAD LIMB REANIMATION MODULE", function()
        local path = MODULES .. "/LimbReanimation.lua"
        local ok, result = executorCall("isfile", path)

        if not ok or result ~= true then
            setStatus("LimbReanimation.lua not found in Modules")
            return
        end

        runLocalModule(path)
    end)

    statusButton(reanimatePage, "OPEN MOVESETS", function()
        showPage("Movesets")
        refreshModules()
    end)

    ----------------------------------------------------------------------
    -- MODEL STORE: local visual demo + copy-only external reference.
    ----------------------------------------------------------------------

    textLabel(modelsPage, "MODEL STORE", 26, COLORS.text, 14).Font =
        Enum.Font.GothamBold

    addInfo(
        modelsPage,
        "Install small client-side visual models. They are local to your client.",
        45
    )

    local installedModels = {}
    ENV.__EPIC_PLANETS_MODELS = {}

    local function removeAllModels()
        for _, entry in ipairs(installedModels) do
            if entry.model and entry.model.Parent then
                pcall(function() entry.model:Destroy() end)
            end
        end

        for _, model in ipairs(ENV.__EPIC_PLANETS_MODELS or {}) do
            if typeof(model) == "Instance" and model.Parent then
                pcall(function() model:Destroy() end)
            end
        end

        for i = #installedModels, 1, -1 do
            installedModels[i] = nil
        end

        ENV.__EPIC_PLANETS_MODELS = {}
        setStatus("Removed all EPIC PLANETS models")
    end

    local function createOrbitalCore()
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if not root then
            setStatus("Character root not ready")
            return
        end

        local model = Instance.new("Model")
        model.Name = "EP_OrbitalCore"
        model.Parent = World

        local centerPart = Instance.new("Part")
        centerPart.Name = "Core"
        centerPart.Shape = Enum.PartType.Ball
        centerPart.Size = Vector3.new(1.7, 1.7, 1.7)
        centerPart.Anchored = true
        centerPart.CanCollide = false
        centerPart.Material = Enum.Material.Neon
        centerPart.Color = COLORS.blue
        centerPart.Parent = model

        local orbitParts = {}

        for i = 1, 4 do
            local part = Instance.new("Part")
            part.Name = "Planet" .. i
            part.Shape = Enum.PartType.Ball
            part.Size = Vector3.new(0.55, 0.55, 0.55)
            part.Anchored = true
            part.CanCollide = false
            part.Material = Enum.Material.Neon
            part.Color = planetColors[i]
            part.Parent = model
            orbitParts[i] = part
        end

        model.PrimaryPart = centerPart
        table.insert(installedModels, {
            model = model,
            center = centerPart,
            planets = orbitParts,
        })
        table.insert(ENV.__EPIC_PLANETS_MODELS, model)

        setStatus("Orbital Core installed")
    end

    statusButton(modelsPage, "INSTALL ORBITAL CORE", createOrbitalCore)
    statusButton(modelsPage, "REMOVE ALL INSTALLED MODELS", removeAllModels)

    local xesterURL =
        "https://scriptblox.com/raw/Universal-Script-Xester-V1-46145"

    statusButton(modelsPage, "COPY XESTER V1 SOURCE URL", function()
        local clipboard =
            findExecutorFunction("setclipboard")
            or findExecutorFunction("toclipboard")

        if not clipboard then
            setStatus("Clipboard API unavailable. URL: " .. xesterURL)
            return
        end

        local ok, err = pcall(clipboard, xesterURL)

        if ok then
            setStatus("Xester V1 URL copied; source was not executed")
        else
            setStatus("Copy failed: " .. tostring(err))
        end
    end)

    ----------------------------------------------------------------------
    -- SETTINGS
    ----------------------------------------------------------------------

    textLabel(settingsPage, "SETTINGS", 26, COLORS.text, 14).Font =
        Enum.Font.GothamBold

    addInfo(
        settingsPage,
        "The title is randomized on launch. This button draws another title immediately.",
        48
    )

    local function chooseRandomTitle()
        local oldIndex = titleIndex

        if #titles > 1 then
            repeat
                titleIndex = math.random(1, #titles)
            until titleIndex ~= oldIndex
        end

        ENV.__EPIC_PLANETS_LAST_TITLE = titleIndex

        local selected = titles[titleIndex]
        titleText.Text = selected.name
        titleText.TextColor3 = selected.color
        introTitle.Text = selected.name
        introTitle.TextColor3 = selected.color

        setStatus("Random title: " .. selected.name)
    end

    statusButton(settingsPage, "RANDOMIZE SCRIPT TITLE", chooseRandomTitle)

    statusButton(settingsPage, "REFRESH MOVESETS", function()
        showPage("Movesets")
        refreshModules()
    end)

    statusButton(settingsPage, "MINIMIZE TO EP ICON", function()
        hub.Visible = false
        mini.Visible = true
        setStatus("Minimized to EP icon")
    end)

    addInfo(
        settingsPage,
        "Theme: dark panels with a smooth rainbow border. Intro background disappears when you tap in.",
        54
    )

    ----------------------------------------------------------------------
    -- EVENTS / INTERACTION
    ----------------------------------------------------------------------

    bind(tapIn.Activated, function()
        introStatus.Text = "SYSTEMS READY"

        tween(introPanel, 0.22, {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.48),
        })

        task.wait(0.23)

        -- Hide the entire intro overlay, not just its central panel.
        intro.Visible = false
        hub.Visible = true
        hub.Size = UDim2.new(0.84, 0, 0.68, 0)
        hub.BackgroundTransparency = 1

        tween(hub, 0.28, {
            Size = UDim2.new(0.91, 0, 0.74, 0),
            BackgroundTransparency = 0,
        }, Enum.EasingStyle.Back)

        showPage("Home")
        setStatus("Ready")
    end)

    bind(minimizeButton.Activated, function()
        hub.Visible = false
        mini.Visible = true
        setStatus("Minimized to EP icon")
    end)

    bind(mini.Activated, function()
        mini.Visible = false
        hub.Visible = true
        setStatus("Window restored")
    end)

    -- Drag the panel by holding its title.
    local dragging = false
    local dragStart = nil
    local startPosition = nil

    bind(titleText.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then

            dragging = true
            dragStart = input.Position
            startPosition = hub.Position

            bind(input.Changed, function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    bind(UserInputService.InputChanged, function(input)
        if not dragging then return end

        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement then

            local delta = input.Position - dragStart

            hub.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    ----------------------------------------------------------------------
    -- INTRO ANIMATION: 321 fragments converge, flash once, then fade out.
    ----------------------------------------------------------------------

    task.spawn(function()
        local total = #fragments

        for i, fragment in ipairs(fragments) do
            if not gui.Parent then return end

            local x = ((i - 1) % 29) / 28
            local y = math.floor((i - 1) / 29) / 11

            tween(fragment, 0.38 + math.random() * 0.42, {
                Position = UDim2.fromScale(x, math.clamp(y, 0, 1)),
            }, Enum.EasingStyle.Quint)

            if i % 5 == 0 or i == total then
                tween(progress, 0.12, {
                    Size = UDim2.new(i / total, 0, 1, 0),
                })
                fragmentCount.Text = tostring(i) .. " / " .. tostring(total)
            end

            task.wait(0.002)
        end

        task.wait(0.55)
        introStatus.Text = "ALL FRAGMENTS CONNECTED"

        for _, fragment in ipairs(fragments) do
            fragment.BackgroundColor3 = COLORS.text
        end

        tween(introPanel, 0.08, {
            BackgroundColor3 = Color3.fromRGB(90, 95, 115),
        })

        task.wait(0.1)

        tween(introPanel, 0.16, {
            BackgroundColor3 = COLORS.panel,
        })

        for _, fragment in ipairs(fragments) do
            tween(fragment, 1.45, {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 0),
            }, Enum.EasingStyle.Sine)
        end

        tween(progress, 1.45, {BackgroundTransparency = 1})
        tween(fragmentCount, 1.45, {TextTransparency = 1})

        task.wait(1.55)

        if not gui.Parent then return end

        fragmentArea.Visible = false
        introStatus.Text = "ALL SYSTEMS READY"
        tapIn.Visible = true
        tapIn.BackgroundTransparency = 1
        tapIn.TextTransparency = 1

        tween(tapIn, 0.45, {
            BackgroundTransparency = 0,
            TextTransparency = 0,
        })
    end)

    ----------------------------------------------------------------------
    -- SMOOTH RAINBOW AURA, PLANET ORBIT AND LOCAL MODEL ANIMATION.
    ----------------------------------------------------------------------

    local installedModels = {}

    -- Shared tracking table is created here before any model is installed.
    ENV.__EPIC_PLANETS_MODELS = ENV.__EPIC_PLANETS_MODELS or {}

    bind(RunService.RenderStepped, function()
        local t = os.clock()
        local hue = (t * 0.12) % 1

        for _, stroke in ipairs(rainbowStrokes) do
            if stroke and stroke.Parent then
                stroke.Color = Color3.fromHSV(
                    (hue + 0.025) % 1,
                    0.88,
                    1
                )
            end
        end

        if intro.Visible then
            for i, planet in ipairs(planets) do
                local angle =
                    t * (0.75 + i * 0.12) + (i - 1) * math.pi / 2

                planet.Position = UDim2.fromOffset(
                    75 + math.cos(angle) * 42,
                    54 + math.sin(angle) * 32
                )
            end

            core.Rotation = (t * 35) % 360
        end

        if flyEnabled then
            local humanoid, root = getCharacterParts()

            if not humanoid or not root
                or not flyVelocity or not flyVelocity.Parent then

                setFly(false)
            else
                local direction = humanoid.MoveDirection

                flyVelocity.Velocity =
                    direction * 48 + Vector3.new(0, flyVertical * 38, 0)

                local camera = World.CurrentCamera

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

            if not entry.model or not entry.model.Parent then
                table.remove(installedModels, i)
            else
                local character = player.Character
                local root = character
                    and character:FindFirstChild("HumanoidRootPart")

                if root and entry.center and entry.center.Parent then
                    local base = root.CFrame * CFrame.new(0, 4.5, -6)
                    entry.center.CFrame = base

                    for index, planet in ipairs(entry.planets) do
                        local angle = t * 1.1 + (index - 1) * math.pi / 2
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

    bind(player.CharacterAdded, function()
        task.wait(0.8)

        local humanoid = getCharacterParts()

        if humanoid then
            if speedEnabled then
                originalWalkSpeed = humanoid.WalkSpeed
                humanoid.WalkSpeed = 32
            end

            if jumpEnabled then
                originalJumpPower = humanoid.JumpPower
                originalJumpHeight = humanoid.JumpHeight

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

    showPage("Home")
    setStatus("Loading intro")

    print("[EPIC PLANETS] GUI loaded.")
    print("[EPIC PLANETS] Modules folder: " .. MODULES)
end)

if not success then
    warn("[EPIC PLANETS] Fatal error: " .. tostring(fatalError))
    ENV.__EPIC_PLANETS_RUNNING = nil
    ENV.__EPIC_PLANETS_GUI = nil
end
