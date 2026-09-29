
local Reaper = loadstring(readfile("Reaper_4_.lua"))()

local Window = Reaper:CreateWindow({
    Name = "REAPER",
    Icon = "☠",
    ToggleKey = Enum.KeyCode.RightShift,
    LoadingTitle = "Reaper",
    LoadingSubtitle = "Loaded",
    ConfigurationSaving = {Enabled = true, FolderName = "Reaper", FileName = "Example"},
})


local Main = Window:CreateTab({Name = "Main", Icon = "home"})

Main:CreateSection("Buttons and toggles")

Main:CreateButton({
    Name = "Show notification",
    Callback = function()
        Reaper:Notify({Title = "Hello", Content = "This is a notification", Type = "success", Duration = 3})
    end,
})

local Fly = Main:CreateToggle({
    Name = "Fly",
    Flag = "Fly",
    CurrentValue = false,
    Callback = function(value) print("Fly:", value) end,
})

Main:CreateSlider({
    Name = "Speed",
    Flag = "Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = " studs/s",
    CurrentValue = 16,
    Callback = function(value)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = value end
    end,
})


local Combat = Window:CreateTab({Name = "Combat", Icon = "swords"})

Combat:CreateSection("Selection")

local Mode = Combat:CreateDropdown({
    Name = "Mode",
    Flag = "Mode",
    Options = {"Easy", "Medium", "Hard"},
    CurrentOption = "Medium",
    Callback = function(option) print("Mode:", option) end,
})

Combat:CreateDropdown({
    Name = "Targets (multiple)",
    Flag = "Targets",
    Options = {"Players", "Bots", "Bosses"},
    MultipleOptions = true,
    CurrentOption = {"Players"},
    Callback = function(list) print("Targets:", table.concat(list, ", ")) end,
})

Combat:CreateKeybind({
    Name = "Attack key",
    Flag = "AttackKey",
    CurrentKeybind = "E",
    Callback = function(key) print("Pressed", key) end,
})

Combat:CreateInput({
    Name = "Target username",
    Flag = "Target",
    Placeholder = "Enter a username and press Enter",
    Callback = function(text) print("Target:", text) end,
})


local Visuals = Window:CreateTab({Name = "Visuals", Icon = "eye"})

Visuals:CreateColorPicker({
    Name = "ESP color",
    Flag = "EspColor",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(color) print("Color:", color) end,
})

Visuals:CreateParagraph({Title = "Hint", Content = "Spin the menu wheel to rearrange the tabs. Hold the center to restore them."})
Visuals:CreateDivider()
Visuals:CreateLabel("Regular text line")


local Settings = Window:CreateTab({Name = "Settings", Icon = "settings"})

Settings:CreateSection("Configurations")
Settings:CreateButton({Name = "Save configuration", Callback = function()
    Window:SaveConfig("manual")
    Reaper:Notify({Title = "Configuration", Content = "Saved: manual", Type = "success"})
end})
Settings:CreateButton({Name = "Load configuration", Callback = function()
    local ok = Window:LoadConfig("manual")
    Reaper:Notify({Title = "Configuration", Content = ok and "Loaded" or "File not found", Type = ok and "success" or "error"})
end})

Settings:CreateSection("Interface controls")
Settings:CreateButton({Name = "Unload Reaper", Callback = function() Window:Destroy() end})









