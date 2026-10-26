--[[
    EPIC PLANETS
    GUI + 321 Fragments + 4 Orbiting Planets
    Delta Executor | Android
]]

local ENV = (type(getgenv) == "function" and getgenv()) or _G

-- ANTI-DUPLICAÇÃO
if ENV.__EPIC_PLANETS_RUNNING then
    local oldGui = ENV.__EPIC_PLANETS_GUI
    if oldGui and oldGui.Parent then
        oldGui.Enabled = true
    end
    return
end
ENV.__EPIC_PLANETS_RUNNING = true

local success, err = pcall(function()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local HttpService = game:GetService("HttpService")

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local old = playerGui:FindFirstChild("EPIC_PLANETS_GUI")
    if old then old:Destroy() end

    -- CONFIGURAÇÃO DE ARQUIVOS
    local ROOT = "EpicPlanets"
    local MODULES = ROOT .. "/Movesets"
    local SETTINGS = ROOT .. "/settings.json"

    local function fileCall(name, ...)
        local fn = ENV[name] or _G[name]
        if type(fn) ~= "function" then return false end
        return pcall(fn, ...)
    end

    pcall(function()
        if type(isfolder) ~= "function" or not isfolder(ROOT) then
            fileCall("makefolder", ROOT)
        end
        if type(isfolder) ~= "function" or not isfolder(MODULES) then
            fileCall("makefolder", MODULES)
        end
    end)

    local C = {
        bg = Color3.fromRGB(7, 9, 19),
        panel = Color3.fromRGB(17, 21, 38),
        panel2 = Color3.fromRGB(26, 33, 55),
        blue = Color3.fromRGB(35, 145, 255),
        white = Color3.fromRGB(240, 245, 255),
        muted = Color3.fromRGB(150, 165, 190),
        red = Color3.fromRGB(255, 55, 70),
        green = Color3.fromRGB(65, 240, 140),
        purple = Color3.fromRGB(175, 95, 255),
    }

    local titles = {
        {name = "Epic Planets", color = C.blue},
        {name = "please don't touch In builtinmodules", color = C.white},
        {name = "BLUEEEEEE", color = Color3.fromRGB(0, 125, 255)},
        {name = "F up", color = C.red},
        {name = "April!", color = C.green},
        {name = "Dont kill the script", color = C.white},
    }

    local titleIndex = 1

    -- RECUPERAR TÍTULO SALVO
    pcall(function()
        if type(isfile) == "function"
            and type(readfile) == "function"
            and isfile(SETTINGS) then

            local data = HttpService:JSONDecode(readfile(SETTINGS))
            local idx = tonumber(data.titleIndex)

            if idx and titles[idx] then
                titleIndex = idx
            end
        end
    end)

    local function saveTitle()
        pcall(function()
            fileCall("writefile", SETTINGS, HttpService:JSONEncode({
                titleIndex = titleIndex,
                title = titles[titleIndex].name,
            }))
        end)
    end

    -- GUI HELPERS
    local function make(class, props, parent)
        local obj = Instance.new(class)
        for k, v in pairs(props or {}) do
            obj[k] = v
        end
        obj.Parent = parent
        return obj
    end

    local function round(obj, radius)
        make("UICorner", {
            CornerRadius = UDim.new(0, radius or 10)
        }, obj)
    end

    local function outline(obj, color, transparency)
        make("UIStroke", {
            Color = color or C.blue,
            Thickness = 1,
            Transparency = transparency or 0.3
        }, obj)
    end

    local function tween(obj, duration, props, style)
        local t = TweenService:Create(
            obj,
            TweenInfo.new(
                duration,
                style or Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            ),
            props
        )
        t:Play()
        return t
    end

    local gui = make("ScreenGui", {
        Name = "EPIC_PLANETS_GUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, playerGui)

    ENV.__EPIC_PLANETS_GUI = gui

    local bg = make("Frame", {
        Name = "Background",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
    }, gui)

    -- ESTRELAS
    for i = 1, 65 do
        local dot = make("Frame", {
            Position = UDim2.fromScale(
                math.random(1, 99) / 100,
                math.random(1, 99) / 100
            ),
            Size = UDim2.fromOffset(
                math.random(1, 3),
                math.random(1, 3)
            ),
            BackgroundColor3 = i % 4 == 0 and C.blue or C.white,
            BackgroundTransparency = math.random(20, 70) / 100,
            BorderSizePixel = 0,
        }, bg)
        round(dot, 5)
    end

    -- CABEÇALHO ASCII
    make("TextLabel", {
        Position = UDim2.new(0, 0, 0, 8),
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = 1,
        Text = [[
 _____ ____ ___ ____   ____  _       ____  _       _   _ _____ _____
        ]],
        TextColor3 = C.blue,
        TextSize = 9,
        Font = Enum.Font.Code,
    }, bg)

    local titleLabel = make("TextLabel", {
        Position = UDim2.new(0, 8, 0, 43),
        Size = UDim2.new(1, -16, 0, 32),
        BackgroundTransparency = 1,
        Text = titles[titleIndex].name,
        TextColor3 = titles[titleIndex].color,
        TextSize = 21,
        Font = Enum.Font.GothamBlack,
    }, bg)

    local panel = make("Frame", {
        Name = "IntroPanel",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.53),
        Size = UDim2.new(0.88, 0, 0.68, 0),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
    }, bg)

    make("UISizeConstraint", {
        MinSize = Vector2.new(270, 350),
        MaxSize = Vector2.new(460, 560),
    }, panel)

    round(panel, 18)
    outline(panel, C.blue)

    local status = make("TextLabel", {
        Position = UDim2.new(0, 12, 0, 10),
        Size = UDim2.new(1, -24, 0, 24),
        BackgroundTransparency = 1,
        Text = "INITIALIZING EPIC PLANETS...",
        TextColor3 = C.white,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
    }, panel)

    -- QUATRO PLANETAS ORBITANDO
    local orbit = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 43),
        Size = UDim2.fromOffset(150, 115),
        BackgroundTransparency = 1,
    }, panel)

    local center = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(27, 27),
        BackgroundColor3 = C.blue,
        BorderSizePixel = 0,
    }, orbit)
    round(center, 20)
    outline(center, C.white)

    local planetColors = {
        C.blue,
        C.purple,
        C.green,
        Color3.fromRGB(255, 180, 60),
    }

    local planets = {}

    for i = 1, 4 do
        local p = make("Frame", {
            Name = "Planet" .. i,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(13 + (i % 2) * 3, 13 + (i % 2) * 3),
            BackgroundColor3 = planetColors[i],
            BorderSizePixel = 0,
        }, orbit)
        round(p, 20)
        outline(p, C.white, 0.5)
        planets[i] = p
    end

    local orbitRing = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(95, 75),
        BackgroundTransparency = 1,
    }, orbit)
    round(orbitRing, 50)
    outline(orbitRing, C.blue, 0.65)

    -- 321 FRAGMENTOS
    local fragmentArea = make("Frame", {
        Name = "Fragments",
        Position = UDim2.new(0, 10, 0, 165),
        Size = UDim2.new(1, -20, 0, 105),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, panel)

    local fragments = {}

    for i = 1, 321 do
        local size = math.random(2, 5)

        local f = make("Frame", {
            Name = "Fragment" .. i,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(
                math.random(0, 100) / 100,
                math.random(0, 100) / 100
            ),
            Size = UDim2.fromOffset(size, size),
            BackgroundColor3 = i % 5 == 0 and C.purple or C.blue,
            BorderSizePixel = 0,
        }, fragmentArea)

        round(f, 5)
        fragments[i] = f
    end

    local progressBack = make("Frame", {
        Position = UDim2.new(0, 15, 1, -42),
        Size = UDim2.new(1, -30, 0, 6),
        BackgroundColor3 = C.panel2,
        BorderSizePixel = 0,
    }, panel)
    round(progressBack, 5)

    local progress = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.blue,
        BorderSizePixel = 0,
    }, progressBack)
    round(progress, 5)

    local countLabel = make("TextLabel", {
        Position = UDim2.new(0, 0, 1, -31),
        Size = UDim2.new(1, 0, 0, 17),
        BackgroundTransparency = 1,
        Text = "0 / 321",
        TextColor3 = C.muted,
        TextSize = 10,
        Font = Enum.Font.Code,
    }, panel)

    -- ÁUDIO OPCIONAL:
    -- Um MP3 local do Android não pode ser usado diretamente como SoundId.
    -- Coloque aqui um áudio autorizado e publicado no Roblox.
    local MUSIC_ID = ""

    if MUSIC_ID ~= "" then
        local sound = make("Sound", {
            Name = "IntroMusic",
            SoundId = MUSIC_ID,
            Volume = 0.7,
        }, gui)
        pcall(function() sound:Play() end)
    end

    -- BOTÃO TAP IN
    local tapIn = make("TextButton", {
        Name = "TapIn",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -51),
        Size = UDim2.new(0.72, 0, 0, 42),
        BackgroundColor3 = C.blue,
        BorderSizePixel = 0,
        Text = "T A P   I N",
        TextColor3 = C.white,
        TextSize = 15,
        Font = Enum.Font.GothamBlack,
        Visible = false,
    }, panel)
    round(tapIn, 10)

    -- ANIMAÇÃO DE CONEXÃO DOS 321 FRAGMENTOS
    task.spawn(function()
        local total = #fragments

        for i, f in ipairs(fragments) do
            local x = ((i - 1) % 29) / 28
            local y = math.floor((i - 1) / 29) / 11

            tween(f, 0.45 + math.random() * 0.45, {
                Position = UDim2.fromScale(x, math.clamp(y, 0, 1)),
            }, Enum.EasingStyle.Quint)

            if i % 5 == 0 or i == total then
                tween(progress, 0.1, {
                    Size = UDim2.new(i / total, 0, 1, 0),
                })
                countLabel.Text = i .. " / " .. total
            end

            task.wait(0.002)
        end

        task.wait(0.65)
        status.Text = "ALL FRAGMENTS CONNECTED"

        -- FLASH DE CONEXÃO
        for _, f in ipairs(fragments) do
            f.BackgroundColor3 = C.white
        end

        tween(panel, 0.07, {
            BackgroundColor3 = Color3.fromRGB(100, 125, 185),
        })

        task.wait(0.09)

        tween(panel, 0.15, {
            BackgroundColor3 = C.panel,
        })

        -- SOMENTE FADE-OUT LENTO
        for _, f in ipairs(fragments) do
            tween(f, 1.8, {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 0),
            }, Enum.EasingStyle.Sine)
        end

        tween(progress, 1.8, {BackgroundTransparency = 1})
        tween(countLabel, 1.8, {TextTransparency = 1})

        task.wait(1.9)
        fragmentArea.Visible = false
        status.Text = "ALL SYSTEMS READY"

        tapIn.Visible = true
        tapIn.BackgroundTransparency = 1
        tapIn.TextTransparency = 1

        tween(tapIn, 0.5, {
            BackgroundTransparency = 0,
            TextTransparency = 0,
        })
    end)

    -- HUB PRINCIPAL
    local hub = make("Frame", {
        Name = "MainHub",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.52),
        Size = UDim2.new(0.88, 0, 0.72, 0),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 20,
    }, bg)

    make("UISizeConstraint", {
        MinSize = Vector2.new(270, 370),
        MaxSize = Vector2.new(460, 590),
    }, hub)

    round(hub, 18)
    outline(hub, C.blue)

    local hubTitle = make("TextLabel", {
        Position = UDim2.new(0, 12, 0, 9),
        Size = UDim2.new(1, -62, 0, 30),
        BackgroundTransparency = 1,
        Text = titles[titleIndex].name,
        TextColor3 = titles[titleIndex].color,
        TextSize = 19,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, hub)

    local close = make("TextButton", {
        Position = UDim2.new(1, -43, 0, 9),
        Size = UDim2.fromOffset(31, 29),
        BackgroundColor3 = Color3.fromRGB(75, 30, 45),
        Text = "×",
        TextColor3 = C.white,
        TextSize = 22,
        Font = Enum.Font.GothamBold,
        ZIndex = 22,
    }, hub)
    round(close, 8)

    local titleButton = make("TextButton", {
        Position = UDim2.new(0, 12, 0, 44),
        Size = UDim2.new(1, -24, 0, 30),
        BackgroundColor3 = C.panel2,
        Text = "CHANGE TITLE",
        TextColor3 = C.white,
        TextSize = 11,
        Font = Enum.Font.GothamSemibold,
        ZIndex = 21,
    }, hub)
    round(titleButton, 8)

    local list = make("ScrollingFrame", {
        Name = "Options",
        Position = UDim2.new(0, 12, 0, 84),
        Size = UDim2.new(1, -24, 1, -135),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = C.blue,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 21,
    }, hub)

    make("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, list)

    local function addButton(text, order, color)
        local b = make("TextButton", {
            Name = "Option" .. order,
            LayoutOrder = order,
            Size = UDim2.new(1, 0, 0, 41),
            BackgroundColor3 = color or C.panel2,
            Text = text,
            TextColor3 = C.white,
            TextSize = 13,
            Font = Enum.Font.GothamSemibold,
            AutoButtonColor = true,
            ZIndex = 22,
        }, list)
        round(b, 9)
        outline(b, C.blue, 0.75)
        return b
    end

    local flyButton = addButton("Fly", 1)
    local speedButton = addButton("Speed", 2)
    local jumpButton = addButton("Jump", 3)
    local limbButton = addButton("Limb Reanimation  [RISKY]", 4)
    local modulesButton = addButton("Modules / Movesets", 5)
    local storeButton = addButton("Models Store", 6)
    local removeButton = addButton(
        "REMOVER TODOS OS MODELOS",
        7,
        Color3.fromRGB(85, 27, 40)
    )

    local function setStatus(text)
        status.Text = text
    end

    flyButton.Activated:Connect(function()
        setStatus("Fly ainda não foi implementado.")
    end)

    speedButton.Activated:Connect(function()
        setStatus("Speed ainda não foi implementado.")
    end)

    jumpButton.Activated:Connect(function()
        setStatus("Jump ainda não foi implementado.")
    end)

    limbButton.Activated:Connect(function()
        setStatus("Limb Reanimation é arriscado e ainda não foi implementado.")
    end)

    modulesButton.Activated:Connect(function()
        setStatus("Movesets: pasta " .. MODULES)
    end)

    storeButton.Activated:Connect(function()
        setStatus("Loja: Xester V1 listado; código externo não executado.")
    end)

    -- O hub remove somente modelos registrados por ele.
    ENV.__EPIC_PLANETS_MODELS = ENV.__EPIC_PLANETS_MODELS or {}

    removeButton.Activated:Connect(function()
        local removed = 0

        for _, obj in ipairs(ENV.__EPIC_PLANETS_MODELS) do
            if typeof(obj) == "Instance" and obj.Parent then
                pcall(function()
                    obj:Destroy()
                end)
                removed += 1
            end
        end

        table.clear(ENV.__EPIC_PLANETS_MODELS)
        setStatus("Modelos registrados removidos: " .. removed)
    end)

    titleButton.Activated:Connect(function()
        titleIndex = (titleIndex % #titles) + 1

        local selected = titles[titleIndex]

        titleLabel.Text = selected.name
        titleLabel.TextColor3 = selected.color

        hubTitle.Text = selected.name
        hubTitle.TextColor3 = selected.color
        titleButton.Text = selected.name
        titleButton.TextColor3 = selected.color

        saveTitle()
    end)

    tapIn.Activated:Connect(function()
        tween(panel, 0.25, {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.47),
        })

        task.wait(0.27)

        panel.Visible = false
        hub.Visible = true
        hub.BackgroundTransparency = 1
        hub.Size = UDim2.new(0.82, 0, 0.66, 0)

        tween(hub, 0.3, {
            BackgroundTransparency = 0,
            Size = UDim2.new(0.88, 0, 0.72, 0),
        }, Enum.EasingStyle.Back)
    end)

    close.Activated:Connect(function()
        tween(bg, 0.25, {BackgroundTransparency = 1})
        task.wait(0.27)
        gui.Enabled = false
    end)

    -- ÓRBITA CONTÍNUA
    local orbitConnection
    orbitConnection = RunService.RenderStepped:Connect(function()
        if not gui.Parent then
            orbitConnection:Disconnect()
            return
        end

        local t = os.clock()

        for i, p in ipairs(planets) do
            local angle = t * (0.8 + i * 0.12)
                + (i - 1) * (math.pi * 2 / 4)

            p.Position = UDim2.fromOffset(
                75 + math.cos(angle) * 43,
                57 + math.sin(angle) * 34
            )
        end

        center.Rotation = (t * 35) % 360
    end)

    -- ARRASTAR JANELA NO CELULAR
    local function draggable(frame, handle)
        local dragging = false
        local startInput
        local startPosition

        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then

                dragging = true
                startInput = input.Position
                startPosition = frame.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end

            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseMovement then

                local delta = input.Position - startInput

                frame.Position = UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale,
                    startPosition.Y.Offset + delta.Y
                )
            end
        end)
    end

    draggable(hub, hubTitle)
    draggable(panel, status)

    print("[EPIC PLANETS] GUI carregada.")
    print("[EPIC PLANETS] Pasta de Movesets: " .. MODULES)
end)

if not success then
    warn("[EPIC PLANETS] Erro: " .. tostring(err))
    ENV.__EPIC_PLANETS_RUNNING = nil
    ENV.__EPIC_PLANETS_GUI = nil
end
