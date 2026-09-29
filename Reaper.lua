local Reaper = {
    Version = "1.0.0",
    Flags = {},
    Options = {},
    Config = {Enabled = false, Folder = "Reaper", File = "default"},
    Theme = {
        Background = Color3.fromRGB(6, 6, 6),
        Panel = Color3.fromRGB(12, 12, 12),
        Element = Color3.fromRGB(20, 20, 20),
        Stroke = Color3.fromRGB(52, 52, 52),
        Text = Color3.fromRGB(245, 245, 245),
        TextDark = Color3.fromRGB(115, 115, 115),
        Accent = Color3.fromRGB(255, 255, 255),
        Accent2 = Color3.fromRGB(90, 90, 90),
        Enabled = Color3.fromRGB(255, 255, 255)
    }
}

Reaper.Icons = {
    ["home"] = "rbxassetid://10723407389",
    ["settings"] = "rbxassetid://10734950309",
    ["swords"] = "rbxassetid://10734975692",
    ["sword"] = "rbxassetid://10734975486",
    ["eye"] = "rbxassetid://10723346959",
    ["eye-off"] = "rbxassetid://10723346871",
    ["skull"] = "rbxassetid://10734962068",
    ["ghost"] = "rbxassetid://10723396107",
    ["crosshair"] = "rbxassetid://10709818534",
    ["target"] = "rbxassetid://10734977012",
    ["activity"] = "rbxassetid://10709752035",
    ["shield"] = "rbxassetid://10734951847",
    ["shield-off"] = "rbxassetid://10734951684",
    ["lock"] = "rbxassetid://10723434711",
    ["unlock"] = "rbxassetid://10747366027",
    ["key"] = "rbxassetid://10723416652",
    ["heart"] = "rbxassetid://10723406885",
    ["star"] = "rbxassetid://10734966248",
    ["flag"] = "rbxassetid://10723375890",
    ["map"] = "rbxassetid://10734886202",
    ["bell"] = "rbxassetid://10709775704",
    ["user"] = "rbxassetid://10747373176",
    ["users"] = "rbxassetid://10747373426",
    ["search"] = "rbxassetid://10734943674",
    ["menu"] = "rbxassetid://10734887784",
    ["x"] = "rbxassetid://10747384394",
    ["check"] = "rbxassetid://10709790644",
    ["plus"] = "rbxassetid://10734924532",
    ["minus"] = "rbxassetid://10734896206",
    ["sun"] = "rbxassetid://10734974297",
    ["moon"] = "rbxassetid://10734897102",
    ["flame"] = "rbxassetid://10723376114",
    ["snowflake"] = "rbxassetid://10734964600",
    ["cloud"] = "rbxassetid://10709806740",
    ["code"] = "rbxassetid://10709810463",
    ["terminal"] = "rbxassetid://10734982144",
    ["bug"] = "rbxassetid://10709782845",
    ["hammer"] = "rbxassetid://10723405360",
    ["wrench"] = "rbxassetid://10747383470",
    ["gauge"] = "rbxassetid://10723395708",
    ["gamepad"] = "rbxassetid://10723395215",
    ["bomb"] = "rbxassetid://10709781460",
    ["crown"] = "rbxassetid://10709818626",
    ["gem"] = "rbxassetid://10723396000",
    ["rocket"] = "rbxassetid://10734934585",
    ["compass"] = "rbxassetid://10709811445",
    ["layers"] = "rbxassetid://10723424505",
    ["database"] = "rbxassetid://10709818996",
    ["wifi"] = "rbxassetid://10747382504",
    ["radio"] = "rbxassetid://10734931596",
    ["camera"] = "rbxassetid://10709789686",
    ["clock"] = "rbxassetid://10709805144"
}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Player = Players.LocalPlayer

local Flags = Reaper.Flags
local Connections = {}
local function bind(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end
local Elements = {}
local Tabs = {}
local ActiveTab = nil
local Opened = false

local setPanelVisible, closeMenu, setMinimized, closeTab, placePanel

local function protect(gui)
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then
        gui.Parent = hui
    else
        pcall(function() gui.Parent = game:GetService("CoreGui") end)
        if not gui.Parent then gui.Parent = Player:WaitForChild("PlayerGui") end
    end
end

local function safeCall(fn, ...)
    if not fn then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[Reaper] Ошибка в callback: " .. tostring(err))
    end
end

local function tween(obj, info, props)
    local tw = TweenService:Create(obj, TweenInfo.new(unpack(info)), props)
    tw:Play()
    return tw
end

local function round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
    return c
end

local function stroke(obj, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Reaper.Theme.Stroke
    s.Transparency = transparency or 0
    s.Thickness = thickness or 1
    s.Parent = obj
    return s
end

local AnimGradients = {}

local function makeSeq(kind, c1, c2)
    if kind == "mirror" then
        return ColorSequence.new{
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(0.5, c2),
            ColorSequenceKeypoint.new(1, c1)
        }
    end
    return ColorSequence.new{
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2)
    }
end

-- animMode: nil (статичный), "spin" (вращение), "sweep" (плавное скольжение)
local function gradient(obj, c1, c2, rotation, animMode, speed, theme)
    local g = Instance.new("UIGradient")
    g.Color = makeSeq(animMode == "spin" and "mirror" or "linear", c1, c2)
    g.Rotation = rotation or 90
    g.Parent = obj
    if animMode then
        table.insert(AnimGradients, {g = g, mode = animMode, speed = speed or 1, base = g.Rotation, theme = theme})
    end
    return g
end

local function strokeGradient(s, speed)
    return gradient(s, Reaper.Theme.Accent, Reaper.Theme.Accent2, 0, "spin", speed, true)
end

bind(RunService.RenderStepped, function()
    local t = os.clock()
    for i = #AnimGradients, 1, -1 do
        local a = AnimGradients[i]
        if not a.g.Parent then
            table.remove(AnimGradients, i)
        elseif a.mode == "spin" then
            a.g.Rotation = (a.base + t * 90 * a.speed) % 360
        else
            a.g.Offset = Vector2.new(math.sin(t * 1.6 * a.speed) * 0.45, 0)
        end
    end
end)

local function makeDraggable(dragHandle, dragTarget, canDrag)
    local dragging = false
    local moved = false
    local dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if canDrag and not canDrag() then return end
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = dragTarget.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    bind(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) + math.abs(delta.Y) > 6 then moved = true end
            dragTarget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    return function() return moved end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Reaper"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Enabled = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
protect(ScreenGui)

-- ===== Конфиги =====
local Loaded = {}          -- значения, прочитанные с диска (для элементов, созданных позже)
local saveQueued = false

local function cfgPath(name)
    return Reaper.Config.Folder .. "/" .. (name or Reaper.Config.File) .. ".json"
end

local function encodeValue(v)
    if typeof(v) == "Color3" then return {__t = "Color3", r = v.R, g = v.G, b = v.B} end
    if type(v) == "table" then
        local o = {}
        for k, x in pairs(v) do o[k] = encodeValue(x) end
        return o
    end
    return v
end

local function decodeValue(v)
    if type(v) == "table" then
        if v.__t == "Color3" then return Color3.new(v.r, v.g, v.b) end
        local o = {}
        for k, x in pairs(v) do o[k] = decodeValue(x) end
        return o
    end
    return v
end

local function readConfigFile(name)
    if not (readfile and isfile) then return nil end
    local ok, data = pcall(function()
        local path = cfgPath(name)
        if not isfile(path) then return nil end
        return HttpService:JSONDecode(readfile(path))
    end)
    if ok and type(data) == "table" then
        local out = {}
        for k, v in pairs(data) do out[k] = decodeValue(v) end
        return out
    end
    return nil
end

local function resolveKey(k)
    if typeof(k) == "EnumItem" then return k end
    if type(k) == "string" then
        local ok, kc = pcall(function() return Enum.KeyCode[k] end)
        if ok then return kc end
    end
    return nil
end

function Reaper:SaveConfig(name)
    if not writefile then return false end
    local ok = pcall(function()
        if makefolder and isfolder and not isfolder(Reaper.Config.Folder) then makefolder(Reaper.Config.Folder) end
        local data = {}
        for k, v in pairs(Reaper.Flags) do data[k] = encodeValue(v) end
        writefile(cfgPath(name), HttpService:JSONEncode(data))
    end)
    return ok
end

function Reaper:LoadConfig(name)
    local data = readConfigFile(name)
    if not data then return false end
    for flag, v in pairs(data) do
        local el = Reaper.Options[flag]
        if el then el:Set(v) else Loaded[flag] = v end
    end
    return true
end

function Reaper:ListConfigs()
    local out = {}
    pcall(function()
        if listfiles and isfolder and isfolder(Reaper.Config.Folder) then
            for _, path in ipairs(listfiles(Reaper.Config.Folder)) do
                local n = tostring(path):match("([^/\\]+)%.json$")
                if n then table.insert(out, n) end
            end
        end
    end)
    return out
end

function Reaper:DeleteConfig(name)
    local ok = pcall(function()
        if delfile and isfile(cfgPath(name)) then delfile(cfgPath(name)) end
    end)
    return ok
end

-- автосохранение с задержкой, чтобы не писать файл на каждое движение слайдера
local function queueSave()
    if not Reaper.Config.Enabled or saveQueued then return end
    saveQueued = true
    task.delay(0.6, function()
        saveQueued = false
        if not Reaper.Destroyed then Reaper:SaveConfig() end
    end)
end

function Reaper:Notify(data)
    data = data or {}
    local holder = ScreenGui:FindFirstChild("NotifyHolder")
    if not holder then
        holder = Instance.new("Frame")
        holder.Name = "NotifyHolder"
        holder.Size = UDim2.new(0, 280, 1, -20)
        holder.Position = UDim2.new(1, -300, 0, 10)
        holder.BackgroundTransparency = 1
        holder.Parent = ScreenGui
        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 8)
        list.VerticalAlignment = Enum.VerticalAlignment.Top
        list.Parent = holder
    end
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 64)
    notif.BackgroundColor3 = Reaper.Theme.Panel
    notif.BackgroundTransparency = 1
    notif.BorderSizePixel = 0
    notif.Parent = holder
    round(notif, 10)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Reaper.Theme.Accent),
        ColorSequenceKeypoint.new(1, Reaper.Theme.Accent2)
    }
    grad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.85),
        NumberSequenceKeypoint.new(0.03, 1),
        NumberSequenceKeypoint.new(1, 1)
    }
    grad.Parent = notif
    stroke(notif, Reaper.Theme.Stroke)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 22)
    title.Position = UDim2.new(0, 12, 0, 8)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Reaper.Theme.Text
    local typePrefix = ({success = "✓  ", warning = "⚠  ", error = "✕  "})[data.Type or ""] or ""
    title.Text = typePrefix .. tostring(data.Title or "Reaper")
    title.TextTransparency = 1
    title.Parent = notif
    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -16, 0, 30)
    content.Position = UDim2.new(0, 12, 0, 30)
    content.BackgroundTransparency = 1
    content.Font = Enum.Font.Gotham
    content.TextSize = 12
    content.TextWrapped = true
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.TextColor3 = Reaper.Theme.TextDark
    content.Text = data.Content or ""
    content.TextTransparency = 1
    content.Parent = notif
    tween(notif, {0.3, Enum.EasingStyle.Quint}, {BackgroundTransparency = 0})
    tween(title, {0.3}, {TextTransparency = 0})
    tween(content, {0.3}, {TextTransparency = 0})
    task.delay(data.Duration or 4, function()
        tween(notif, {0.3}, {BackgroundTransparency = 1})
        tween(title, {0.3}, {TextTransparency = 1})
        tween(content, {0.3}, {TextTransparency = 1})
        task.wait(0.35)
        notif:Destroy()
    end)
end

local MainButton = Instance.new("TextButton")
MainButton.Name = "MainButton"
MainButton.Size = UDim2.new(0, 56, 0, 56)
MainButton.Position = UDim2.new(0.5, -28, 0.5, -28)
MainButton.BackgroundColor3 = Reaper.Theme.Panel
MainButton.Text = "☠"
MainButton.TextColor3 = Reaper.Theme.Accent
MainButton.TextSize = 26
MainButton.Font = Enum.Font.GothamBold
MainButton.AutoButtonColor = false
MainButton.Parent = ScreenGui
round(MainButton, 28)
local mbStroke = stroke(MainButton, Color3.new(1, 1, 1), 0.4, 1.5)
strokeGradient(mbStroke, 1)
local mbGrad = Instance.new("UIGradient")
mbGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 28)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 8))
}
mbGrad.Parent = MainButton
local mbDragged = makeDraggable(MainButton, MainButton, function() return not Opened end)

local Menu = Instance.new("Frame")
Menu.Name = "Menu"
Menu.Size = UDim2.new(0, 0, 0, 0)
Menu.Position = UDim2.new(0.5, 0, 0.5, 0)
Menu.AnchorPoint = Vector2.new(0.5, 0.5)
Menu.BackgroundColor3 = Reaper.Theme.Background
Menu.BackgroundTransparency = 0.15
Menu.BorderSizePixel = 0
Menu.ClipsDescendants = true
Menu.Visible = false
Menu.Parent = ScreenGui
round(Menu, 200)
local menuStroke = stroke(Menu, Color3.new(1, 1, 1), 0.5, 1.5)
strokeGradient(menuStroke, 0.8)
gradient(Menu, Color3.fromRGB(30, 30, 30), Color3.fromRGB(4, 4, 4), 45, "spin", 0.2)

local CenterDot = Instance.new("Frame")
CenterDot.Size = UDim2.new(0, 52, 0, 52)
CenterDot.Position = UDim2.new(0.5, -26, 0.5, -26)
CenterDot.BackgroundColor3 = Reaper.Theme.Panel
CenterDot.BorderSizePixel = 0
CenterDot.Parent = Menu
round(CenterDot, 26)
gradient(CenterDot, Color3.fromRGB(24, 24, 24), Color3.fromRGB(10, 10, 10), 90)
local cdStroke = stroke(CenterDot, Reaper.Theme.Accent, 0.3)

local CenterTitle = Instance.new("TextLabel")
CenterTitle.Size = UDim2.new(1, 0, 1, 0)
CenterTitle.BackgroundTransparency = 1
CenterTitle.Font = Enum.Font.GothamBold
CenterTitle.TextSize = 11
CenterTitle.TextWrapped = true
CenterTitle.TextColor3 = Reaper.Theme.Text
CenterTitle.Text = "REAPER"
gradient(CenterTitle, Reaper.Theme.Accent, Reaper.Theme.Accent2, 0, "sweep", 1, true)
CenterTitle.Parent = CenterDot

local Ring = Instance.new("Frame")
Ring.Size = UDim2.new(1, 0, 1, 0)
Ring.BackgroundTransparency = 1
Ring.Parent = Menu

-- Полоски-разделители между вкладками (как секторы колеса), максимум 5 вкладок
Reaper.MaxTabs = 5
local Dividers = {}

local function rebuildDividers()
    for _, d in ipairs(Dividers) do d:Destroy() end
    Dividers = {}
    local n = #Tabs
    if n < 2 then return end
    for i = 1, n do
        local angle = -90 + (i - 0.5) * (360 / n)
        local rad = math.rad(angle)
        local rMid, len = 74, 88
        local d = Instance.new("Frame")
        d.Name = "Divider"
        d.AnchorPoint = Vector2.new(0.5, 0.5)
        d.Size = UDim2.new(0, len, 0, 2)
        d.Position = UDim2.new(0.5, math.cos(rad) * rMid, 0.5, math.sin(rad) * rMid)
        d.Rotation = angle
        d.BackgroundColor3 = Reaper.Theme.Accent
        d.BackgroundTransparency = Opened and 0 or 1
        d.BorderSizePixel = 0
        d.ZIndex = 2
        d.Parent = Ring
        round(d, 1)
        local g = Instance.new("UIGradient")
        g.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.25),
            NumberSequenceKeypoint.new(1, 1)
        }
        g.Parent = d
        table.insert(Dividers, d)
    end
end

local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = UDim2.new(0, 320, 0, 380)
Panel.Position = UDim2.new(0.5, 60, 0.5, -190)
Panel.BackgroundColor3 = Reaper.Theme.Panel
Panel.BackgroundTransparency = 1
Panel.BorderSizePixel = 0
Panel.Visible = false
Panel.ClipsDescendants = true
Panel.ZIndex = 3
Panel.Parent = ScreenGui
round(Panel, 14)
local panelStroke = stroke(Panel, Color3.new(1, 1, 1))
strokeGradient(panelStroke, 0.7)
panelStroke.Transparency = 1
gradient(Panel, Color3.fromRGB(22, 22, 22), Color3.fromRGB(6, 6, 6), 115, "spin", 0.15)

local PanelTitle = Instance.new("TextLabel")
PanelTitle.Size = UDim2.new(1, -24, 0, 40)
PanelTitle.Position = UDim2.new(0, 16, 0, 4)
PanelTitle.BackgroundTransparency = 1
PanelTitle.Font = Enum.Font.GothamBold
PanelTitle.TextSize = 18
PanelTitle.TextXAlignment = Enum.TextXAlignment.Left
PanelTitle.TextColor3 = Reaper.Theme.Accent
PanelTitle.Text = ""
PanelTitle.TextTransparency = 1
PanelTitle.ZIndex = 4
gradient(PanelTitle, Reaper.Theme.Accent, Reaper.Theme.Accent2, 0, "sweep", 1, true)
PanelTitle.Parent = Panel

local PanelLine = Instance.new("Frame")
PanelLine.Size = UDim2.new(1, -32, 0, 1)
PanelLine.Position = UDim2.new(0, 16, 0, 44)
PanelLine.BackgroundColor3 = Reaper.Theme.Stroke
PanelLine.BorderSizePixel = 0
PanelLine.ZIndex = 4
PanelLine.Parent = Panel
local panelLineGrad = Instance.new("UIGradient")
panelLineGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Reaper.Theme.Accent),
    ColorSequenceKeypoint.new(0.5, Reaper.Theme.Accent2),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(52, 52, 52))
}
panelLineGrad.Parent = PanelLine
table.insert(AnimGradients, {g = panelLineGrad, mode = "sweep", speed = 0.8})

local DragBar = Instance.new("Frame")
DragBar.Name = "DragBar"
DragBar.Size = UDim2.new(1, 0, 0, 48)
DragBar.BackgroundTransparency = 1
DragBar.BorderSizePixel = 0
DragBar.ZIndex = 5
DragBar.Parent = Panel

local function windowDot(color, offsetX, callback)
    local d = Instance.new("TextButton")
    d.Size = UDim2.new(0, 14, 0, 14)
    d.AnchorPoint = Vector2.new(0.5, 0.5)
    d.Position = UDim2.new(1, offsetX + 7, 0, 20)
    d.BackgroundColor3 = color
    d.BorderSizePixel = 0
    d.Text = ""
    d.AutoButtonColor = false
    d.ZIndex = 10
    d.Parent = Panel
    round(d, 7)
    d.MouseEnter:Connect(function() tween(d, {0.15}, {Size = UDim2.new(0, 17, 0, 17)}) end)
    d.MouseLeave:Connect(function() tween(d, {0.15}, {Size = UDim2.new(0, 14, 0, 14)}) end)
    d.MouseButton1Click:Connect(function() safeCall(callback) end)
    Panel:GetPropertyChangedSignal("Visible"):Connect(function()
        if not Panel.Visible then d.Size = UDim2.new(0, 14, 0, 14) end
    end)
end

windowDot(Color3.fromRGB(190, 190, 190), -44, function()
    setMinimized(nil)
end)
windowDot(Color3.fromRGB(110, 110, 110), -22, function()
    closeTab()
end)

local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, 0, 1, -56)
Container.Position = UDim2.new(0, 0, 0, 52)
Container.BackgroundTransparency = 1
Container.BorderSizePixel = 0
Container.ScrollBarThickness = 3
Container.ScrollBarImageColor3 = Reaper.Theme.Accent
Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Container.ZIndex = 4
Container.Parent = Panel

local containerList = Instance.new("UIListLayout")
containerList.Padding = UDim.new(0, 6)
containerList.SortOrder = Enum.SortOrder.LayoutOrder
containerList.HorizontalAlignment = Enum.HorizontalAlignment.Center
containerList.Parent = Container

local containerPad = Instance.new("UIPadding")
containerPad.PaddingTop = UDim.new(0, 6)
containerPad.PaddingBottom = UDim.new(0, 10)
containerPad.Parent = Container

local Minimized = false
local PanelH = 380
local PanelPos = Vector2.new(0, 0)
local panelDragging = false

local function screenSize()
    local size = ScreenGui.AbsoluteSize
    if size.X < 10 or size.Y < 10 then
        local cam = workspace.CurrentCamera
        if cam then size = cam.ViewportSize end
    end
    return size
end

local function clampPanel(p)
    local size = screenSize()
    local h = Minimized and 48 or PanelH
    return Vector2.new(
        math.clamp(p.X, 0, math.max(0, size.X - 320)),
        math.clamp(p.Y, 0, math.max(0, size.Y - h))
    )
end

-- Панель открывается по центру экрана (рядом с кольцом меню)
placePanel = function()
    local size = screenSize()
    PanelH = math.clamp(size.Y - 24, 200, 380)
    Panel.Size = UDim2.new(0, 320, 0, Minimized and 48 or PanelH)
    local cx, cy = size.X / 2, size.Y / 2
    local x = cx + 146
    if x + 320 > size.X - 8 then
        x = cx - 146 - 320
        if x < 8 then x = cx - 160 end
    end
    PanelPos = clampPanel(Vector2.new(x, cy - PanelH / 2))
end

setMinimized = function(v)
    if v == nil then v = not Minimized end
    if Minimized == v then return end
    Minimized = v
    if v then
        tween(Panel, {0.25, Enum.EasingStyle.Quint}, {Size = UDim2.new(0, 320, 0, 48)})
        task.delay(0.25, function()
            if Minimized then Container.Visible = false end
        end)
    else
        Container.Visible = true
        tween(Panel, {0.3, Enum.EasingStyle.Back}, {Size = UDim2.new(0, 320, 0, PanelH)})
    end
end

-- Перетаскивание панели пальцем / мышью за шапку
do
    local dragStart, dragOrigin
    DragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            panelDragging = true
            dragStart = input.Position
            dragOrigin = PanelPos
            tween(Panel, {0.15}, {BackgroundTransparency = 0.12})
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    panelDragging = false
                    tween(Panel, {0.2}, {BackgroundTransparency = 0})
                end
            end)
        end
    end)
    bind(UserInputService.InputChanged, function(input)
        if panelDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            PanelPos = clampPanel(Vector2.new(dragOrigin.X + d.X, dragOrigin.Y + d.Y))
        end
    end)
end

local panelShift = Instance.new("NumberValue")
panelShift.Value = 40

setPanelVisible = function(v)
    if v then
        if not Panel.Visible then placePanel() end
        Panel.Visible = true
        tween(Panel, {0.3, Enum.EasingStyle.Quint}, {BackgroundTransparency = 0})
        tween(panelStroke, {0.3}, {Transparency = 0.35})
        tween(PanelTitle, {0.3}, {TextTransparency = 0})
        TweenService:Create(panelShift, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Value = 0}):Play()
    else
        tween(Panel, {0.25, Enum.EasingStyle.Quint}, {BackgroundTransparency = 1})
        tween(panelStroke, {0.25}, {Transparency = 1})
        tween(PanelTitle, {0.25}, {TextTransparency = 1})
        TweenService:Create(panelShift, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Value = 40}):Play()
        task.delay(0.25, function()
            if panelShift.Value > 30 then
                Panel.Visible = false
                Minimized = false
                Container.Visible = true
                Panel.Size = UDim2.new(0, 320, 0, PanelH)
            end
        end)
    end
end

bind(RunService.RenderStepped, function()
    if not panelDragging then PanelPos = clampPanel(PanelPos) end
    Panel.Position = UDim2.new(0, math.floor(PanelPos.X), 0, math.floor(PanelPos.Y + panelShift.Value))
    -- «дыхание» обводки центра и кнопки
    local k = (math.sin(os.clock() * 2) + 1) / 2
    cdStroke.Transparency = 0.15 + 0.45 * k
    if not Opened then mbStroke.Transparency = 0.2 + 0.4 * k end
end)

local ringTween
local CENTER_BTN = UDim2.new(0.5, 0, 0.5, 0)      -- центр для кнопок вкладок (AnchorPoint 0.5)
local MB_CENTER = UDim2.new(0.5, -28, 0.5, -28)   -- центр для MainButton (56x56)

local function openMenu()
    Opened = true
    Menu.Visible = true
    Ring.Rotation = -70
    ringTween = tween(Ring, {0.6, Enum.EasingStyle.Quint}, {Rotation = 0})
    tween(Menu, {0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out}, {Size = UDim2.new(0, 260, 0, 260)})
    -- кнопка всегда возвращается в центр экрана, чтобы меню было по центру
    tween(MainButton, {0.35, Enum.EasingStyle.Quint}, {Position = MB_CENTER, Rotation = 45, TextColor3 = Reaper.Theme.Accent2})
    mbStroke.Transparency = 0.4
    for i, d in ipairs(Dividers) do
        d.BackgroundTransparency = 1
        task.delay(0.2 + i * 0.05, function()
            if Opened and d.Parent then
                tween(d, {0.45, Enum.EasingStyle.Quint}, {BackgroundTransparency = 0})
            end
        end)
    end
    for i, tab in ipairs(Tabs) do
        task.delay(i * 0.05, function()
            if not Opened then return end
            local b = tab.Button
            b.Position = CENTER_BTN
            b.Size = UDim2.new(0, 14, 0, 14)
            b.BackgroundTransparency = 1
            b.Visible = true
            tween(b, {0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out}, {
                Position = tab.TargetPos,
                Size = UDim2.new(0, 54, 0, 54)
            })
            if tab.IconObj then
                if tab.IconObj:IsA("ImageLabel") then
                    tab.IconObj.ImageTransparency = 1
                    tween(tab.IconObj, {0.4}, {ImageTransparency = 0})
                else
                    tab.IconObj.TextTransparency = 1
                    tween(tab.IconObj, {0.4}, {TextTransparency = 0})
                end
            end
        end)
    end
    if ActiveTab then setPanelVisible(true) end
end

closeMenu = function()
    Opened = false
    setPanelVisible(false)
    ringTween = tween(Ring, {0.3, Enum.EasingStyle.Quint}, {Rotation = 60})
    for _, d in ipairs(Dividers) do tween(d, {0.2}, {BackgroundTransparency = 1}) end
    tween(Menu, {0.3, Enum.EasingStyle.Quint}, {Size = UDim2.new(0, 0, 0, 0)})
    tween(MainButton, {0.3}, {Rotation = 0, TextColor3 = Reaper.Theme.Accent})
    for _, tab in ipairs(Tabs) do
        tween(tab.Button, {0.25, Enum.EasingStyle.Quint}, {
            Position = CENTER_BTN,
            Size = UDim2.new(0, 14, 0, 14),
            BackgroundTransparency = 1
        })
        if tab.IconObj then
            if tab.IconObj:IsA("ImageLabel") then
                tween(tab.IconObj, {0.15}, {ImageTransparency = 1})
            else
                tween(tab.IconObj, {0.15}, {TextTransparency = 1})
            end
        end
    end
    task.delay(0.35, function() if not Opened then Menu.Visible = false end end)
end

-- ===== Пасхалка: раскрути колесо меню =====
-- Схвати кольцо и раскрути: обычный толчок - колесо покрутится и вернётся,
-- сильный - вкладки поедут по кругу и займут новые места (и останутся там).
-- Зажать центр (~0.6 с) - вкладки возвращаются на свои места. Короткий тап по центру закрывает меню.
local GuiService = game:GetService("GuiService")
local EGG_SPEED = 600  -- градусов в секунду
local HOLD_TIME = 0.6  -- сколько держать центр
local spin = {grab = false, inertia = false, released = false, busy = false, moved = false, vel = 0, last = 0, lastT = 0, accum = 0}

-- Невидимая подложка под кольцом: ловит касания по кругу меню и не даёт камере крутиться
local SpinPad = Instance.new("TextButton")
SpinPad.Name = "SpinPad"
SpinPad.Size = UDim2.new(1, 0, 1, 0)
SpinPad.BackgroundTransparency = 1
SpinPad.Text = ""
SpinPad.AutoButtonColor = false
SpinPad.ZIndex = 0
SpinPad.Parent = Menu

local function pointerPos(input)
    local inset = GuiService:GetGuiInset()
    return Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
end

local function menuCenter()
    return Menu.AbsolutePosition + Menu.AbsoluteSize / 2
end

local function wrap180(a)
    while a > 180 do a = a - 360 end
    while a < -180 do a = a + 360 end
    return a
end

local function slotAngle(i, n)
    return -90 + (i - 1) * (360 / n)
end

local function springBack()
    local target = math.floor(Ring.Rotation / 360 + 0.5) * 360
    ringTween = tween(Ring, {0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out}, {Rotation = target})
end

local function shockwave()
    local w = Instance.new("Frame")
    w.AnchorPoint = Vector2.new(0.5, 0.5)
    w.Position = UDim2.new(0.5, 0, 0.5, 0)
    w.Size = UDim2.new(0, 40, 0, 40)
    w.BackgroundTransparency = 1
    w.ZIndex = 3
    w.Parent = Menu
    round(w, 200)
    local st = stroke(w, Reaper.Theme.Accent, 0, 2)
    tween(w, {0.7, Enum.EasingStyle.Quint}, {Size = UDim2.new(0, 260, 0, 260)})
    tween(st, {0.7}, {Transparency = 1})
    task.delay(0.8, function() w:Destroy() end)
end

local function captureAngles()
    local n = #Tabs
    local angles = {}
    for i, t in ipairs(Tabs) do angles[t] = slotAngle(i, n) end
    return angles
end

local function applyTargets()
    local n = #Tabs
    for i, t in ipairs(Tabs) do
        local rad = math.rad(slotAngle(i, n))
        t.TargetPos = UDim2.new(0.5, math.cos(rad) * 96, 0.5, math.sin(rad) * 96)
    end
end

-- Вкладки плавно едут по кругу со старых мест на новые (dir > 0 по часовой, < 0 против)
local function orbitTabs(oldAngles, dir, duration)
    local n = #Tabs
    for i, t in ipairs(Tabs) do
        local a0 = oldAngles[t]
        local d = (slotAngle(i, n) - a0) % 360
        if d >= 0.5 and d <= 359.5 then
            if dir < 0 then d = d - 360 end
            local val = Instance.new("NumberValue")
            val.Value = a0
            local dip = (i % 2 == 1) and -16 or 6
            val.Changed:Connect(function(v)
                if not Opened then return end
                local prog = math.clamp((v - a0) / d, 0, 1)
                local r = 96 + dip * math.sin(prog * math.pi)
                local rad = math.rad(v)
                t.Button.Position = UDim2.new(0.5, math.cos(rad) * r, 0.5, math.sin(rad) * r)
            end)
            local tw = tween(val, {duration, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut}, {Value = a0 + d})
            tw.Completed:Connect(function()
                val:Destroy()
                if Opened then t.Button.Position = t.TargetPos end
            end)
        end
    end
end

local function triggerEgg(dir)
    local n = #Tabs
    if n < 2 then springBack() return end
    spin.busy = true
    local ok, err = pcall(function()
        shockwave()
        local cur = Ring.Rotation
        local target = (dir > 0 and math.ceil(cur / 360) + 2 or math.floor(cur / 360) - 2) * 360
        ringTween = tween(Ring, {1.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out}, {Rotation = target})
        local oldAngles = captureAngles()
        -- новая расстановка: у каждой вкладки другое место
        local perm
        repeat
            local pool = {}
            for i = 1, n do pool[i] = i end
            perm = {}
            for i = 1, n do perm[i] = table.remove(pool, math.random(#pool)) end
            local same = false
            for i = 1, n do
                if perm[i] == i then same = true end
            end
        until not same
        local old = {}
        for i, t in ipairs(Tabs) do old[i] = t end
        for i, t in ipairs(old) do Tabs[perm[i]] = t end
        applyTargets()
        orbitTabs(oldAngles, dir, 1.3)
    end)
    if not ok then warn("[Reaper] Пасхалка: " .. tostring(err)) end
    task.delay(1.9, function()
        Ring.Rotation = 0
        spin.busy = false
    end)
end

-- Возвращает вкладки на исходные места (зажать центр)
local function restoreTabs()
    if spin.busy or not Opened then return end
    shockwave()
    local inOrder = true
    for i, t in ipairs(Tabs) do
        if t.OrigIndex ~= i then inOrder = false end
    end
    if inOrder then return end
    spin.busy = true
    local ok, err = pcall(function()
        local cur = Ring.Rotation
        ringTween = tween(Ring, {1.3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut}, {Rotation = (math.floor(cur / 360) - 1) * 360})
        local oldAngles = captureAngles()
        table.sort(Tabs, function(x, y) return (x.OrigIndex or 0) < (y.OrigIndex or 0) end)
        applyTargets()
        orbitTabs(oldAngles, -1, 1.2)
    end)
    if not ok then warn("[Reaper] Возврат вкладок: " .. tostring(err)) end
    task.delay(1.5, function()
        Ring.Rotation = 0
        spin.busy = false
    end)
end

local function beginSpin(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    if not spin.grab then spin.moved = false end
    if not Opened or spin.busy then return end
    local c = menuCenter()
    local p = pointerPos(input)
    if ringTween then ringTween:Cancel() end
    spin.grab = true
    spin.inertia = false
    spin.released = false
    spin.vel = 0
    spin.accum = 0
    spin.last = math.deg(math.atan2(p.Y - c.Y, p.X - c.X))
    spin.lastT = os.clock()
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End and spin.grab then
            spin.grab = false
            spin.inertia = true
            spin.released = true
        end
    end)
end

-- Центр: тап закрывает меню, удержание возвращает вкладки на места.
-- Это отдельная кнопка (нажатие определяется самим GUI, без пересчёта координат).
local centerHold = {id = 0, down = false, fired = false}

local CenterBtn = Instance.new("TextButton")
CenterBtn.Name = "CenterBtn"
CenterBtn.AnchorPoint = Vector2.new(0.5, 0.5)
CenterBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
CenterBtn.Size = UDim2.new(0, 64, 0, 64)
CenterBtn.BackgroundTransparency = 1
CenterBtn.Text = ""
CenterBtn.AutoButtonColor = false
CenterBtn.ZIndex = 7
CenterBtn.Parent = Menu

CenterBtn.InputBegan:Connect(function(input)
    if not Opened then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    centerHold.id = centerHold.id + 1
    local myId = centerHold.id
    centerHold.down = true
    centerHold.fired = false
    tween(cdStroke, {HOLD_TIME}, {Thickness = 4})
    task.delay(HOLD_TIME, function()
        if centerHold.down and centerHold.id == myId and Opened then
            centerHold.fired = true
            tween(cdStroke, {0.25}, {Thickness = 1})
            restoreTabs()
        end
    end)
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End and centerHold.id == myId then
            centerHold.down = false
            if not centerHold.fired then tween(cdStroke, {0.2}, {Thickness = 1}) end
        end
    end)
end)

CenterBtn.MouseButton1Click:Connect(function()
    if centerHold.fired then
        centerHold.fired = false
        return
    end
    if Opened then closeMenu() end
end)

SpinPad.InputBegan:Connect(function(input)
    if not Opened then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    beginSpin(input)
end)

bind(UserInputService.InputChanged, function(input)
    if not spin.grab then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local c = menuCenter()
    local p = pointerPos(input)
    if (p - c).Magnitude < 24 then return end
    local a = math.deg(math.atan2(p.Y - c.Y, p.X - c.X))
    local d = wrap180(a - spin.last)
    spin.last = a
    local now = os.clock()
    local dt = math.max(now - spin.lastT, 1 / 240)
    spin.lastT = now
    Ring.Rotation = Ring.Rotation + d
    spin.accum = spin.accum + math.abs(d)
    if spin.accum > 12 then spin.moved = true end
    spin.vel = spin.vel * 0.6 + (d / dt) * 0.4
end)

bind(RunService.RenderStepped, function(dt)
    -- иконки всегда остаются ровными, пока колесо крутится
    for _, t in ipairs(Tabs) do
        if t.Button then t.Button.Rotation = -Ring.Rotation end
    end
    if spin.grab then
        if os.clock() - spin.lastT > 0.08 then spin.vel = 0 end
    elseif spin.inertia then
        if spin.released then
            spin.released = false
            if spin.moved and math.abs(spin.vel) >= EGG_SPEED then
                spin.inertia = false
                triggerEgg(spin.vel > 0 and 1 or -1)
                return
            end
        end
        Ring.Rotation = Ring.Rotation + spin.vel * dt
        spin.vel = spin.vel * (0.06 ^ dt)
        if math.abs(spin.vel) < 15 then
            spin.inertia = false
            springBack()
        end
    end
end)

MainButton.MouseButton1Click:Connect(function()
    if mbDragged() then return end
    if Opened then closeMenu() else openMenu() end
end)

local function selectTab(tab)
    local changed = ActiveTab ~= tab
    ActiveTab = tab
    if changed then
        PanelTitle.TextTransparency = 1
        Container.CanvasPosition = Vector2.new(0, 0)
        containerPad.PaddingTop = UDim.new(0, 26)
        tween(containerPad, {0.4, Enum.EasingStyle.Quint}, {PaddingTop = UDim.new(0, 6)})
    end
    PanelTitle.Text = tab.Name
    for _, t in ipairs(Tabs) do
        local active = t == tab
        if t.IconObj then
            local key = t.IconObj:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
            tween(t.IconObj, {0.2}, {[key] = active and Reaper.Theme.Accent or Reaper.Theme.TextDark})
        end
        if t.Indicator then
            tween(t.Indicator, {0.25, Enum.EasingStyle.Quint}, {Size = active and UDim2.new(0, 18, 0, 3) or UDim2.new(0, 0, 0, 3)})
        end
    end
    for _, el in ipairs(Elements) do
        el.Frame.Visible = (el.Tab == tab) and not el.Hidden
    end
    setMinimized(false)
    setPanelVisible(true)
end

-- Закрывает только вкладку (панель), кольцо меню остаётся
closeTab = function()
    ActiveTab = nil
    for _, t in ipairs(Tabs) do
        if t.IconObj then
            local key = t.IconObj:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
            tween(t.IconObj, {0.2}, {[key] = Reaper.Theme.TextDark})
        end
        if t.Indicator then
            tween(t.Indicator, {0.25, Enum.EasingStyle.Quint}, {Size = UDim2.new(0, 0, 0, 3)})
        end
    end
    setPanelVisible(false)
end

local function createTabButton(tab, index, total)
    local angle = -90 + (index - 1) * (360 / total)
    local rad = math.rad(angle)
    local radius = 96
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 54, 0, 54)
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.Position = UDim2.new(0.5, 0, 0.5, 0)
    btn.BackgroundColor3 = Reaper.Theme.Element
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Visible = false
    btn.ZIndex = 5
    btn.Parent = Ring
    local iconAsset = Reaper.Icons[tab.Icon]
    if not iconAsset and type(tab.Icon) == "number" then iconAsset = "rbxassetid://" .. tab.Icon end
    if not iconAsset and type(tab.Icon) == "string" and tab.Icon:find("^rbxassetid://") then iconAsset = tab.Icon end
    if iconAsset then
        local img = Instance.new("ImageLabel")
        img.Name = "Icon"
        img.Size = UDim2.new(0, 34, 0, 34)
        img.Position = UDim2.new(0.5, -17, 0.5, -17)
        img.BackgroundTransparency = 1
        img.Image = iconAsset
        img.ImageColor3 = Reaper.Theme.TextDark
        img.ZIndex = 6
        img.Parent = btn
        tab.IconObj = img
    else
        local tl = Instance.new("TextLabel")
        tl.Name = "Icon"
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Text = tostring(tab.Icon)
        tl.TextSize = 32
        tl.Font = Enum.Font.GothamBold
        tl.TextColor3 = Reaper.Theme.TextDark
        tl.ZIndex = 6
        tl.Parent = btn
        tab.IconObj = tl
    end
    round(btn, 27)
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 0, 0, 3)
    indicator.Position = UDim2.new(0.5, 0, 1, -6)
    indicator.AnchorPoint = Vector2.new(0.5, 0)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 6
    indicator.Parent = btn
    gradient(indicator, Reaper.Theme.Accent, Reaper.Theme.Accent2, 0)
    round(indicator, 2)
    tab.Indicator = indicator
    local target = UDim2.new(0.5, math.cos(rad) * radius, 0.5, math.sin(rad) * radius)
    btn.InputBegan:Connect(beginSpin)
    btn.MouseButton1Click:Connect(function()
        if spin.moved then return end
        selectTab(tab)
        tween(btn, {0.12}, {Size = UDim2.new(0, 46, 0, 46)})
        task.delay(0.12, function()
            tween(btn, {0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out}, {Size = UDim2.new(0, 54, 0, 54)})
        end)
    end)
    btn.MouseEnter:Connect(function()
        if tab.IconObj then
            local key = tab.IconObj:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
            tween(tab.IconObj, {0.15}, {[key] = Reaper.Theme.Accent})
        end
        if Opened then tween(btn, {0.2, Enum.EasingStyle.Quint}, {Size = UDim2.new(0, 60, 0, 60)}) end
    end)
    btn.MouseLeave:Connect(function()
        if tab.IconObj then
            local key = tab.IconObj:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
            tween(tab.IconObj, {0.15}, {[key] = ActiveTab == tab and Reaper.Theme.Accent or Reaper.Theme.TextDark})
        end
        if Opened then tween(btn, {0.2, Enum.EasingStyle.Quint}, {Size = UDim2.new(0, 54, 0, 54)}) end
    end)
    tab.Button = btn
    tab.TargetPos = target
end

--=====================================================================
--  ЭЛЕМЕНТЫ
--  Tab:CreateButton / CreateToggle / CreateSlider / CreateDropdown / CreateInput /
--      CreateKeybind / CreateColorPicker / CreateLabel / CreateParagraph /
--      CreateSection / CreateDivider
--  У всех элементов одинаковые методы:
--      :Set(value, silent)  :Get()  :OnChanged(fn)  :SetName(text)
--      :SetVisible(bool)    :Destroy()
--=====================================================================
local LABEL_W = 280
local PARA_W = 272
local layoutCounter = 0

local function textHeight(text, size, font, width)
    local ok, v = pcall(function()
        return TextService:GetTextSize(text, size, font, Vector2.new(width, 10000))
    end)
    if ok then return v.Y end
    return size + 4
end

local ElementBase = {}
ElementBase.__index = ElementBase

function ElementBase:Get()
    return self.Value
end

function ElementBase:Bind(signal, fn)
    local c = signal:Connect(fn)
    table.insert(self.Conns, c)
    return c
end

function ElementBase:SetVisible(v)
    self.Hidden = not v
    self.Frame.Visible = v and ActiveTab == self.Tab
end

function ElementBase:SetName(text)
    self.Name = text
    if self.NameLabel then self.NameLabel.Text = tostring(text) end
end

function ElementBase:OnChanged(fn)
    table.insert(self.Listeners, fn)
    return function()
        local i = table.find(self.Listeners, fn)
        if i then table.remove(self.Listeners, i) end
    end
end

function ElementBase:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    for _, c in ipairs(self.Conns) do pcall(function() c:Disconnect() end) end
    local i = table.find(Elements, self)
    if i then table.remove(Elements, i) end
    if self.Flag and Reaper.Options[self.Flag] == self then
        Reaper.Options[self.Flag] = nil
        Reaper.Flags[self.Flag] = nil
    end
    self.Frame:Destroy()
end

local function newElement(tab, height, elType, data, plain)
    data = data or {}
    layoutCounter = layoutCounter + 1
    local f = Instance.new("Frame")
    f.Name = elType
    f.Size = UDim2.new(1, -24, 0, height)
    f.BackgroundColor3 = Reaper.Theme.Element
    f.BackgroundTransparency = plain and 1 or 0
    f.BorderSizePixel = 0
    f.LayoutOrder = layoutCounter
    f.ZIndex = 5
    f.Visible = ActiveTab == tab
    f.Parent = Container
    if not plain then
        round(f, 8)
        stroke(f, Reaper.Theme.Stroke, 0.5)
    end
    local el = setmetatable({
        Type = elType, Tab = tab, Frame = f, Name = data.Name,
        Conns = {}, Listeners = {}, Hidden = false, Destroyed = false
    }, ElementBase)
    table.insert(Elements, el)
    if tab.Elements then table.insert(tab.Elements, el) end
    return f, el
end

-- Значение из сохранённого конфига (если есть) или значение по умолчанию
local function resolveInitial(flag, default)
    if flag and Loaded[flag] ~= nil then
        local v = Loaded[flag]
        Loaded[flag] = nil
        return v, true
    end
    return default, false
end

-- Записывает значение, сохраняет конфиг, вызывает Callback и OnChanged
local function commit(el, data, v, silent)
    el.Value = v
    if el.Flag then
        Reaper.Flags[el.Flag] = v
        queueSave()
    end
    if not silent then
        if data.Callback then safeCall(data.Callback, v) end
        for _, fn in ipairs(el.Listeners) do safeCall(fn, v) end
    end
end

-- Регистрирует Flag; если значение пришло из конфига - повторно вызывает Callback
local function finish(el, data, wasLoaded)
    if el.Flag then
        if Reaper.Options[el.Flag] and Reaper.Options[el.Flag] ~= el then
            warn("[Reaper] Flag «" .. el.Flag .. "» уже используется, старый элемент заменён")
        end
        Reaper.Options[el.Flag] = el
    end
    if wasLoaded then
        task.defer(function()
            if not el.Destroyed then commit(el, data, el.Value, false) end
        end)
    end
    return el
end

local TabFuncs = {}

---------------------------------------------------------------- Button
function TabFuncs:CreateButton(data)
    if type(data) == "string" then data = {Name = data} end
    data = data or {}
    local f, el = newElement(self, 36, "Button", data)
    gradient(f, Color3.fromRGB(24, 24, 24), Color3.fromRGB(16, 16, 16), 115)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 1, 0)
    b.BackgroundTransparency = 1
    b.Text = data.Name or "Button"
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 13
    b.TextColor3 = Reaper.Theme.Text
    b.ZIndex = 6
    b.Parent = f
    el.NameLabel = b
    b.MouseEnter:Connect(function() tween(f, {0.15}, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}) end)
    b.MouseLeave:Connect(function() tween(f, {0.15}, {BackgroundColor3 = Reaper.Theme.Element}) end)
    local function fire()
        tween(f, {0.1}, {BackgroundColor3 = Reaper.Theme.Accent})
        task.delay(0.1, function()
            if not el.Destroyed then tween(f, {0.15}, {BackgroundColor3 = Reaper.Theme.Element}) end
        end)
        if data.Callback then safeCall(data.Callback) end
        for _, fn in ipairs(el.Listeners) do safeCall(fn) end
    end
    b.MouseButton1Click:Connect(fire)
    el.Fire = function() fire() end
    el.Set = function(_, txt) el:SetName(txt) end
    return el
end

---------------------------------------------------------------- Label
function TabFuncs:CreateLabel(data)
    if type(data) == "string" then data = {Name = data} end
    data = data or {}
    local f, el = newElement(self, 32, "Label", data)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -16, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = tostring(data.Name or "")
    l.Font = Enum.Font.Gotham
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = data.Color or Reaper.Theme.TextDark
    l.TextWrapped = true
    l.ZIndex = 6
    l.Parent = f
    el.NameLabel = l
    local function resize()
        f.Size = UDim2.new(1, -24, 0, math.max(32, textHeight(l.Text, 12, Enum.Font.Gotham, LABEL_W) + 14))
    end
    resize()
    el.Value = l.Text
    el.Set = function(_, txt, color)
        l.Text = tostring(txt)
        if color then l.TextColor3 = color end
        el.Value = l.Text
        resize()
    end
    el.SetName = function(_, txt) el:Set(txt) end
    return el
end

---------------------------------------------------------------- Paragraph
function TabFuncs:CreateParagraph(data)
    data = data or {}
    local f, el = newElement(self, 56, "Paragraph", data)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -24, 0, 20)
    t.Position = UDim2.new(0, 12, 0, 6)
    t.BackgroundTransparency = 1
    t.Text = data.Title or ""
    t.Font = Enum.Font.GothamBold
    t.TextSize = 13
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextColor3 = Reaper.Theme.Accent
    t.ZIndex = 6
    t.Parent = f
    el.NameLabel = t
    local c = Instance.new("TextLabel")
    c.Size = UDim2.new(1, -24, 1, -32)
    c.Position = UDim2.new(0, 12, 0, 26)
    c.BackgroundTransparency = 1
    c.Text = data.Content or ""
    c.Font = Enum.Font.Gotham
    c.TextSize = 12
    c.TextWrapped = true
    c.TextXAlignment = Enum.TextXAlignment.Left
    c.TextYAlignment = Enum.TextYAlignment.Top
    c.TextColor3 = Reaper.Theme.TextDark
    c.ZIndex = 6
    c.Parent = f
    local function resize()
        f.Size = UDim2.new(1, -24, 0, 26 + textHeight(c.Text, 12, Enum.Font.Gotham, PARA_W) + 12)
    end
    resize()
    el.Set = function(_, title, content)
        if type(title) == "table" then title, content = title.Title, title.Content end
        if title ~= nil then t.Text = tostring(title) end
        if content ~= nil then c.Text = tostring(content) end
        resize()
    end
    return el
end

---------------------------------------------------------------- Section / Divider
function TabFuncs:CreateSection(data)
    if type(data) == "string" then data = {Name = data} end
    data = data or {}
    local f, el = newElement(self, 26, "Section", data, true)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 0, 16)
    l.Position = UDim2.new(0, 4, 0, 6)
    l.BackgroundTransparency = 1
    l.Text = string.upper(tostring(data.Name or ""))
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Reaper.Theme.TextDark
    l.ZIndex = 6
    l.Parent = f
    el.SetName = function(_, txt)
        el.Name = txt
        l.Text = string.upper(tostring(txt))
    end
    el.Set = function(_, txt) el:SetName(txt) end
    return el
end

function TabFuncs:CreateDivider()
    local f, el = newElement(self, 8, "Divider", nil, true)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -8, 0, 1)
    line.Position = UDim2.new(0, 4, 0.5, 0)
    line.BackgroundColor3 = Reaper.Theme.Stroke
    line.BorderSizePixel = 0
    line.ZIndex = 6
    line.Parent = f
    return el
end

---------------------------------------------------------------- Toggle
function TabFuncs:CreateToggle(data)
    data = data or {}
    local f, el = newElement(self, 36, "Toggle", data)
    el.Flag = data.Flag
    local start, loaded = resolveInitial(data.Flag, data.CurrentValue or false)
    start = start and true or false
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -60, 1, 0)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = data.Name or "Toggle"
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Reaper.Theme.Text
    l.ZIndex = 6
    l.Parent = f
    el.NameLabel = l
    local switch = Instance.new("Frame")
    switch.Size = UDim2.new(0, 36, 0, 20)
    switch.Position = UDim2.new(1, -46, 0.5, -10)
    switch.BackgroundColor3 = Reaper.Theme.Stroke
    switch.BorderSizePixel = 0
    switch.ZIndex = 6
    switch.Parent = f
    round(switch, 10)
    local switchGrad = gradient(switch, Reaper.Theme.Accent, Reaper.Theme.Accent2, 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 7
    knob.Parent = switch
    round(knob, 8)
    local function render(v, animate)
        local kp = v and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local sc = v and Reaper.Theme.Enabled or Reaper.Theme.Stroke
        if animate then
            tween(knob, {0.2, Enum.EasingStyle.Quint}, {Position = kp})
            tween(switch, {0.2}, {BackgroundColor3 = sc})
        else
            knob.Position = kp
            switch.BackgroundColor3 = sc
        end
        switchGrad.Enabled = v
    end
    el.Set = function(_, v, silent)
        v = v and true or false
        render(v, true)
        commit(el, data, v, silent)
    end
    el.Toggle = function() el:Set(not el.Value) end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 8
    btn.Parent = f
    btn.MouseButton1Click:Connect(function() el:Set(not el.Value) end)
    render(start, false)
    commit(el, data, start, true)
    return finish(el, data, loaded)
end

---------------------------------------------------------------- Slider
function TabFuncs:CreateSlider(data)
    data = data or {}
    local range = data.Range or {0, 100}
    local min, max = range[1], range[2]
    local inc = data.Increment or 1
    local suffix = data.Suffix or ""
    local decimals = #(tostring(inc):match("%.(%d+)") or "")
    local f, el = newElement(self, 52, "Slider", data)
    el.Flag = data.Flag
    local function snap(v)
        v = math.clamp(v, min, max)
        v = min + math.floor((v - min) / inc + 0.5) * inc
        v = math.clamp(v, min, max)
        return tonumber(string.format("%." .. decimals .. "f", v))
    end
    local start, loaded = resolveInitial(data.Flag, data.CurrentValue or min)
    start = snap(tonumber(start) or min)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6, 0, 0, 20)
    l.Position = UDim2.new(0, 12, 0, 5)
    l.BackgroundTransparency = 1
    l.Text = data.Name or "Slider"
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Reaper.Theme.Text
    l.ZIndex = 6
    l.Parent = f
    el.NameLabel = l
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.4, -12, 0, 20)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextColor3 = Reaper.Theme.Accent
    valueLabel.ZIndex = 6
    valueLabel.Parent = f
    local barBack = Instance.new("Frame")
    barBack.Size = UDim2.new(1, -24, 0, 6)
    barBack.Position = UDim2.new(0, 12, 0, 34)
    barBack.BackgroundColor3 = Reaper.Theme.Stroke
    barBack.BorderSizePixel = 0
    barBack.ZIndex = 6
    barBack.Parent = f
    round(barBack, 3)
    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Reaper.Theme.Accent
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 6
    barFill.Parent = barBack
    round(barFill, 3)
    gradient(barFill, Reaper.Theme.Accent, Reaper.Theme.Accent2, 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(1, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 7
    knob.Parent = barFill
    round(knob, 7)
    local function render(v)
        local alpha = (max == min) and 0 or (v - min) / (max - min)
        barFill.Size = UDim2.new(alpha, 0, 1, 0)
        valueLabel.Text = tostring(v) .. suffix
    end
    el.Set = function(_, v, silent)
        v = snap(tonumber(v) or min)
        render(v)
        commit(el, data, v, silent)
    end
    el.SetRange = function(_, newMin, newMax, newInc)
        min, max = newMin, newMax
        if newInc then inc = newInc decimals = #(tostring(inc):match("%.(%d+)") or "") end
        el:Set(el.Value, true)
    end
    local dragging = false
    local function fromX(x)
        local alpha = math.clamp((x - barBack.AbsolutePosition.X) / math.max(barBack.AbsoluteSize.X, 1), 0, 1)
        local v = snap(min + (max - min) * alpha)
        if v ~= el.Value then el:Set(v) end
    end
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 24)
    hit.Position = UDim2.new(0, 0, 0.5, -12)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 8
    hit.Parent = barBack
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromX(input.Position.X)
        end
    end)
    el:Bind(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    el:Bind(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromX(input.Position.X)
        end
    end)
    render(start)
    commit(el, data, start, true)
    return finish(el, data, loaded)
end

---------------------------------------------------------------- Dropdown (обычный и с несколькими вариантами)
function TabFuncs:CreateDropdown(data)
    data = data or {}
    local options = data.Options or {}
    local multi = data.MultipleOptions == true
    local f, el = newElement(self, 36, "Dropdown", data)
    el.Flag = data.Flag
    f.ClipsDescendants = true

    local function clone(t)
        local o = {}
        for i, x in ipairs(t) do o[i] = x end
        return o
    end
    local function normalize(v)
        if multi then
            local out = {}
            if type(v) == "table" then
                for _, x in ipairs(v) do
                    if table.find(options, x) and not table.find(out, x) then table.insert(out, x) end
                end
            elseif v ~= nil and table.find(options, v) then
                out[1] = v
            end
            return out
        end
        if type(v) == "table" then v = v[1] end
        if v ~= nil and table.find(options, v) then return v end
        return nil
    end

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.5, -12, 0, 36)
    nameLabel.Position = UDim2.new(0, 12, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.Name or "Dropdown"
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = Reaper.Theme.Text
    nameLabel.ZIndex = 6
    nameLabel.Parent = f
    el.NameLabel = nameLabel
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.5, -34, 0, 36)
    valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
    valueLabel.TextColor3 = Reaper.Theme.TextDark
    valueLabel.ZIndex = 6
    valueLabel.Parent = f
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 36)
    arrow.Position = UDim2.new(1, -26, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextSize = 10
    arrow.TextColor3 = Reaper.Theme.TextDark
    arrow.ZIndex = 6
    arrow.Parent = f
    local list = Instance.new("ScrollingFrame")
    list.Position = UDim2.new(0, 8, 0, 40)
    list.Size = UDim2.new(1, -16, 0, 0)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 2
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ZIndex = 6
    list.Parent = f
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list

    local current
    local expanded = false

    local function updateDisplay()
        if multi then
            local parts = {}
            for _, x in ipairs(current) do table.insert(parts, tostring(x)) end
            valueLabel.Text = #parts > 0 and table.concat(parts, ", ") or "—"
        else
            valueLabel.Text = current ~= nil and tostring(current) or "—"
        end
    end
    local function applyExpand()
        local h = math.min(#options * 28, 140)
        tween(list, {0.2, Enum.EasingStyle.Quint}, {Size = UDim2.new(1, -16, 0, expanded and h or 0)})
        tween(f, {0.2, Enum.EasingStyle.Quint}, {Size = UDim2.new(1, -24, 0, 36 + (expanded and h + 8 or 0))})
        tween(arrow, {0.2}, {Rotation = expanded and 180 or 0})
    end
    local function isSelected(opt)
        if multi then return table.find(current, opt) ~= nil end
        return current == opt
    end
    local function rebuild()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, opt in ipairs(options) do
            local sel = isSelected(opt)
            local ob = Instance.new("TextButton")
            ob.LayoutOrder = i
            ob.Size = UDim2.new(1, 0, 0, 26)
            ob.BackgroundColor3 = Reaper.Theme.Panel
            ob.BorderSizePixel = 0
            ob.AutoButtonColor = false
            ob.Text = tostring(opt)
            ob.Font = sel and Enum.Font.GothamBold or Enum.Font.Gotham
            ob.TextSize = 12
            ob.TextColor3 = sel and Reaper.Theme.Accent or Reaper.Theme.TextDark
            ob.ZIndex = 7
            ob.Parent = list
            round(ob, 6)
            ob.MouseButton1Click:Connect(function()
                if multi then
                    local nv = clone(current)
                    local idx = table.find(nv, opt)
                    if idx then table.remove(nv, idx) else table.insert(nv, opt) end
                    el:Set(nv)
                else
                    el:Set(opt)
                    expanded = false
                    applyExpand()
                end
            end)
        end
    end

    el.Set = function(_, v, silent)
        local nv = normalize(v)
        if nv == nil then return end
        current = nv
        updateDisplay()
        rebuild()
        commit(el, data, multi and clone(current) or current, silent)
    end
    el.Get = function()
        return multi and clone(current) or current
    end
    -- Заменить список вариантов. keepSelection = true оставляет выбранное, если оно ещё есть в списке
    el.Refresh = function(_, newOptions, keepSelection)
        options = newOptions or {}
        local nv = keepSelection and normalize(current) or nil
        if multi then
            current = nv or {}
        else
            current = nv or options[1]
        end
        updateDisplay()
        rebuild()
        commit(el, data, multi and clone(current) or current, true)
        if expanded then applyExpand() end
    end

    local start, loaded = resolveInitial(data.Flag, data.CurrentOption)
    current = normalize(start)
    if current == nil then current = multi and {} or options[1] end
    updateDisplay()
    rebuild()
    commit(el, data, multi and clone(current) or current, true)

    local head = Instance.new("TextButton")
    head.Size = UDim2.new(1, 0, 0, 36)
    head.BackgroundTransparency = 1
    head.Text = ""
    head.ZIndex = 8
    head.Parent = f
    head.MouseButton1Click:Connect(function()
        if #options == 0 then return end
        expanded = not expanded
        applyExpand()
    end)
    return finish(el, data, loaded)
end

---------------------------------------------------------------- Input
function TabFuncs:CreateInput(data)
    data = data or {}
    local f, el = newElement(self, 36, "Input", data)
    el.Flag = data.Flag
    local start, loaded = resolveInitial(data.Flag, data.CurrentValue or "")
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 1, -8)
    box.Position = UDim2.new(0, 8, 0, 4)
    box.BackgroundTransparency = 1
    box.PlaceholderText = data.Placeholder or data.Name or "Ввод..."
    box.PlaceholderColor3 = Reaper.Theme.TextDark
    box.Text = tostring(start)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextColor3 = Reaper.Theme.Text
    box.ClearTextOnFocus = data.ClearTextOnFocus == true
    box.ZIndex = 6
    box.Parent = f
    el.NameLabel = box
    el.SetName = function(_, txt)
        el.Name = txt
        box.PlaceholderText = tostring(txt)
    end
    local numbers = data.NumbersOnly == true
    local function parse(text)
        if numbers then return tonumber(text) or 0 end
        return text
    end
    if numbers then
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local clean = box.Text:gsub("[^%d%.%-]", "")
            if clean ~= box.Text then box.Text = clean end
        end)
    end
    el.Set = function(_, v, silent)
        box.Text = tostring(v == nil and "" or v)
        commit(el, data, parse(box.Text), silent)
    end
    box.FocusLost:Connect(function()
        commit(el, data, parse(box.Text), false)
        if data.RemoveTextAfterFocusLost then box.Text = "" end
    end)
    commit(el, data, parse(box.Text), true)
    return finish(el, data, loaded)
end

---------------------------------------------------------------- Keybind
function TabFuncs:CreateKeybind(data)
    data = data or {}
    local f, el = newElement(self, 36, "Keybind", data)
    el.Flag = data.Flag
    local start, loaded = resolveInitial(data.Flag, data.CurrentKeybind or "None")
    local current = tostring(start)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6, 0, 1, 0)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = data.Name or "Keybind"
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Reaper.Theme.Text
    l.ZIndex = 6
    l.Parent = f
    el.NameLabel = l
    local kb = Instance.new("TextButton")
    kb.Size = UDim2.new(0, 90, 0, 24)
    kb.Position = UDim2.new(1, -100, 0.5, -12)
    kb.BackgroundColor3 = Reaper.Theme.Panel
    kb.Text = current
    kb.Font = Enum.Font.GothamBold
    kb.TextSize = 11
    kb.TextColor3 = Reaper.Theme.Accent
    kb.AutoButtonColor = false
    kb.ZIndex = 6
    kb.Parent = f
    round(kb, 6)
    stroke(kb, Reaper.Theme.Stroke)
    local listening = false
    local holding = false
    -- Set меняет саму клавишу. Callback вызывается при НАЖАТИИ клавиши, а не при смене привязки
    el.Set = function(_, key, silent)
        if typeof(key) == "EnumItem" then key = key.Name end
        current = tostring(key or "None")
        kb.Text = current
        kb.TextColor3 = Reaper.Theme.Accent
        commit(el, {}, current, silent)
    end
    el.Press = function()
        if data.Callback then safeCall(data.Callback, current) end
    end
    kb.MouseButton1Click:Connect(function()
        listening = true
        kb.Text = "..."
        kb.TextColor3 = Reaper.Theme.Accent2
    end)
    el:Bind(UserInputService.InputBegan, function(input, gpe)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                    el:Set("None")
                else
                    el:Set(input.KeyCode.Name)
                end
            end
        elseif not gpe and current ~= "None" and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == current then
            if data.HoldToInteract then
                holding = true
                if data.Callback then safeCall(data.Callback, true) end
            else
                if data.Callback then safeCall(data.Callback, current) end
            end
        end
    end)
    el:Bind(UserInputService.InputEnded, function(input)
        if data.HoldToInteract and holding and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == current then
            holding = false
            if data.Callback then safeCall(data.Callback, false) end
        end
    end)
    commit(el, {}, current, true)
    return finish(el, {}, false)
end

---------------------------------------------------------------- ColorPicker
function TabFuncs:CreateColorPicker(data)
    data = data or {}
    local f, el = newElement(self, 36, "ColorPicker", data)
    el.Flag = data.Flag
    f.ClipsDescendants = true
    local start, loaded = resolveInitial(data.Flag, data.Color or data.CurrentValue or Color3.new(1, 1, 1))
    if typeof(start) ~= "Color3" then start = Color3.new(1, 1, 1) end
    local h, s, v = start:ToHSV()

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -70, 0, 36)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = data.Name or "Color"
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Reaper.Theme.Text
    l.ZIndex = 6
    l.Parent = f
    el.NameLabel = l
    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.new(0, 38, 0, 20)
    swatch.Position = UDim2.new(1, -50, 0, 8)
    swatch.BackgroundColor3 = start
    swatch.BorderSizePixel = 0
    swatch.ZIndex = 6
    swatch.Parent = f
    round(swatch, 6)
    stroke(swatch, Reaper.Theme.Stroke)

    local bars = {}
    local active
    local function refresh()
        local c = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = c
        bars.H.knob.Position = UDim2.new(h, 0, 0.5, 0)
        bars.S.knob.Position = UDim2.new(s, 0, 0.5, 0)
        bars.V.knob.Position = UDim2.new(v, 0, 0.5, 0)
        bars.S.grad.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
        bars.V.grad.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(h, s, 1))
        return c
    end
    local function fromX(bar, x)
        local alpha = math.clamp((x - bar.track.AbsolutePosition.X) / math.max(bar.track.AbsoluteSize.X, 1), 0, 1)
        if bar.key == "H" then h = alpha elseif bar.key == "S" then s = alpha else v = alpha end
        commit(el, data, refresh(), false)
    end
    local function makeBar(key, y)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 14, 0, 20)
        lbl.Position = UDim2.new(0, 12, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = key
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextColor3 = Reaper.Theme.TextDark
        lbl.ZIndex = 6
        lbl.Parent = f
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -56, 0, 8)
        track.Position = UDim2.new(0, 32, 0, y + 6)
        track.BackgroundColor3 = Color3.new(1, 1, 1)
        track.BorderSizePixel = 0
        track.ZIndex = 6
        track.Parent = f
        round(track, 4)
        local g = Instance.new("UIGradient")
        g.Parent = track
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.new(0, 0, 0.5, 0)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.ZIndex = 7
        knob.Parent = track
        round(knob, 6)
        stroke(knob, Color3.new(0, 0, 0), 0.3, 1)
        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 0, 22)
        hit.Position = UDim2.new(0, 0, 0.5, -11)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.ZIndex = 8
        hit.Parent = track
        local bar = {key = key, track = track, knob = knob, grad = g}
        hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                active = bar
                fromX(bar, input.Position.X)
            end
        end)
        bars[key] = bar
    end
    makeBar("H", 40)
    makeBar("S", 64)
    makeBar("V", 88)
    local hue = {}
    for i = 0, 6 do
        table.insert(hue, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, 0.999), 1, 1)))
    end
    bars.H.grad.Color = ColorSequence.new(hue)

    el:Bind(UserInputService.InputChanged, function(input)
        if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromX(active, input.Position.X)
        end
    end)
    el:Bind(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then active = nil end
    end)

    el.Set = function(_, c, silent)
        if typeof(c) ~= "Color3" then return end
        h, s, v = c:ToHSV()
        commit(el, data, refresh(), silent)
    end

    local expanded = false
    local head = Instance.new("TextButton")
    head.Size = UDim2.new(1, 0, 0, 36)
    head.BackgroundTransparency = 1
    head.Text = ""
    head.ZIndex = 8
    head.Parent = f
    head.MouseButton1Click:Connect(function()
        expanded = not expanded
        tween(f, {0.25, Enum.EasingStyle.Quint}, {Size = UDim2.new(1, -24, 0, expanded and 118 or 36)})
    end)

    commit(el, data, refresh(), true)
    return finish(el, data, loaded)
end

-- Свои методы для вкладки
function TabFuncs:Select()
    selectTab(self)
    return self
end

function TabFuncs:Clear()
    for _, el in ipairs({table.unpack(self.Elements or {})}) do el:Destroy() end
    self.Elements = {}
end

--=====================================================================
--  ОКНО
--=====================================================================
local WindowFuncs = {}
Reaper.TabList = {}

local function dummyElement()
    return setmetatable({}, {__index = function() return function() end end})
end

local function popInTab(tab)
    local b = tab.Button
    b.Position = CENTER_BTN
    b.Size = UDim2.new(0, 14, 0, 14)
    b.BackgroundTransparency = 1
    b.Visible = true
    tween(b, {0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out}, {Position = tab.TargetPos, Size = UDim2.new(0, 54, 0, 54)})
    if tab.IconObj then
        if tab.IconObj:IsA("ImageLabel") then
            tab.IconObj.ImageTransparency = 1
            tween(tab.IconObj, {0.4}, {ImageTransparency = 0})
        else
            tab.IconObj.TextTransparency = 1
            tween(tab.IconObj, {0.4}, {TextTransparency = 0})
        end
    end
end

-- Window:CreateTab({Name = "Main", Icon = "home"})  или  Window:CreateTab("Main", "home")
function WindowFuncs:CreateTab(data, icon)
    if type(data) == "string" then data = {Name = data, Icon = icon} end
    data = data or {}
    local name = data.Name or "Tab"
    if #Tabs >= Reaper.MaxTabs then
        warn("[Reaper] Максимум вкладок: " .. Reaper.MaxTabs .. ". Вкладка «" .. name .. "» не добавлена")
        return setmetatable({}, {__index = function()
            return function() return dummyElement() end
        end})
    end
    local tab = setmetatable({Name = name, Icon = data.Icon or "◆", Elements = {}}, {__index = TabFuncs})
    table.insert(Tabs, tab)
    tab.OrigIndex = #Tabs
    createTabButton(tab, #Tabs, math.max(#Tabs, 3))
    for i, t in ipairs(Tabs) do
        local angle = -90 + (i - 1) * (360 / #Tabs)
        local rad = math.rad(angle)
        t.TargetPos = UDim2.new(0.5, math.cos(rad) * 96, 0.5, math.sin(rad) * 96)
        if Opened and t ~= tab then tween(t.Button, {0.4, Enum.EasingStyle.Quint}, {Position = t.TargetPos}) end
    end
    rebuildDividers()
    if Opened then popInTab(tab) end
    Reaper.TabList[name] = tab
    return tab
end

function WindowFuncs:SelectTab(tab)
    if type(tab) == "string" then tab = Reaper.TabList[tab] end
    if tab and table.find(Tabs, tab) then selectTab(tab) end
end

function WindowFuncs:Notify(data) Reaper:Notify(data) end
function WindowFuncs:SetTitle(text) CenterTitle.Text = tostring(text) end
function WindowFuncs:SetIcon(text) MainButton.Text = tostring(text) end
function WindowFuncs:Show() ScreenGui.Enabled = true end
function WindowFuncs:Hide() ScreenGui.Enabled = false end
function WindowFuncs:Toggle() ScreenGui.Enabled = not ScreenGui.Enabled end
function WindowFuncs:Open() if not Opened then openMenu() end end
function WindowFuncs:Close() if Opened then closeMenu() end end
function WindowFuncs:SetToggleKey(key) Reaper.ToggleKey = resolveKey(key) or Reaper.ToggleKey end
function WindowFuncs:SaveConfig(name) return Reaper:SaveConfig(name) end
function WindowFuncs:LoadConfig(name) return Reaper:LoadConfig(name) end
function WindowFuncs:ListConfigs() return Reaper:ListConfigs() end
function WindowFuncs:DeleteConfig(name) return Reaper:DeleteConfig(name) end
function WindowFuncs:Destroy() Reaper:Destroy() end

function WindowFuncs:SetAccent(c1, c2)
    Reaper.Theme.Accent = c1 or Reaper.Theme.Accent
    Reaper.Theme.Accent2 = c2 or Reaper.Theme.Accent2
    for _, a in ipairs(AnimGradients) do
        if a.theme and a.g.Parent then
            a.g.Color = makeSeq(a.mode == "spin" and "mirror" or "linear", Reaper.Theme.Accent, Reaper.Theme.Accent2)
        end
    end
end

function Reaper:GetFlag(flag)
    return Reaper.Flags[flag]
end

function Reaper:SetFlag(flag, value, silent)
    local el = Reaper.Options[flag]
    if el then el:Set(value, silent) return true end
    return false
end

function Reaper:Destroy()
    if Reaper.Destroyed then return end
    Reaper.Destroyed = true
    if Reaper.Config.Enabled then Reaper:SaveConfig() end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    for _, el in ipairs(Elements) do
        for _, c in ipairs(el.Conns) do pcall(function() c:Disconnect() end) end
    end
    pcall(function() ScreenGui:Destroy() end)
    Reaper.Window = nil
end

function Reaper:AddIcon(name, assetId)
    if type(assetId) == "number" then assetId = "rbxassetid://" .. assetId end
    Reaper.Icons[name] = assetId
end

--[[
    Reaper:CreateWindow({
        Name = "REAPER",                        -- заголовок в центре кольца
        Icon = "☠",                             -- символ на круглой кнопке
        ToggleKey = Enum.KeyCode.RightShift,    -- показать/скрыть весь интерфейс
        AutoOpen = true,                        -- открыть меню сразу
        Accent = {Color3, Color3},              -- цвета градиента (необязательно)
        LoadingTitle = "...", LoadingSubtitle = "...",  -- стартовое уведомление
        ConfigurationSaving = {Enabled = true, FolderName = "Reaper", FileName = "MyScript"},
    })
]]
function Reaper:CreateWindow(data)
    if Reaper.Destroyed then
        warn("[Reaper] Библиотека выгружена (Destroy). Загрузи её заново.")
        return nil
    end
    if Reaper.Window then
        warn("[Reaper] Окно уже создано, возвращаю существующее")
        return Reaper.Window
    end
    data = data or {}

    local cs = data.ConfigurationSaving
    if cs and cs.Enabled ~= false then
        Reaper.Config.Enabled = true
        Reaper.Config.Folder = cs.FolderName or Reaper.Config.Folder
        Reaper.Config.File = cs.FileName or Reaper.Config.File
        local saved = readConfigFile()
        if saved then
            for k, v in pairs(saved) do Loaded[k] = v end
        end
    end

    CenterTitle.Text = tostring(data.Name or "REAPER")
    MainButton.Text = tostring(data.Icon or "☠")
    Reaper.ToggleKey = resolveKey(data.ToggleKey) or Enum.KeyCode.RightShift
    ScreenGui.Enabled = true

    local Window = setmetatable({}, {__index = WindowFuncs})
    Reaper.Window = Window
    if data.Accent then Window:SetAccent(data.Accent[1], data.Accent[2]) end
    if data.LoadingTitle then
        Reaper:Notify({Title = data.LoadingTitle, Content = data.LoadingSubtitle or "", Duration = 3})
    end
    if data.AutoOpen ~= false then
        -- откладываем, чтобы все вкладки из основного скрипта успели создаться
        task.defer(function()
            if Reaper.Destroyed then return end
            if Tabs[1] and not ActiveTab then selectTab(Tabs[1]) end
            if not Opened then openMenu() end
        end)
    end
    return Window
end

bind(UserInputService.InputBegan, function(input, gpe)
    if not gpe and Reaper.Window and Reaper.ToggleKey and input.KeyCode == Reaper.ToggleKey then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

return Reaper
