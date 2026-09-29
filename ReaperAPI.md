# Reaper UI Library — API

A Roblox user-interface library with a circular menu, tabs (up to 5), and a panel containing UI elements.
The API style is similar to Rayfield: `CreateWindow` → `CreateTab` → `Create<Element>`.

```lua
local Reaper = loadstring(readfile("Reaper_4_.lua"))()
local Window = Reaper:CreateWindow({ Name = "REAPER" })
local Tab    = Window:CreateTab({ Name = "Main", Icon = "home" })
Tab:CreateButton({ Name = "Hello", Callback = function() print("hi") end })
```

See `Reaper_Example.lua` for a complete example.

---

## 1. Window

`Reaper:CreateWindow(options)` — creates a window once and returns `Window`.

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"REAPER"` | Title displayed in the center of the ring |
| `Icon` | string | `"☠"` | Symbol displayed on the circular button |
| `ToggleKey` | KeyCode / string | `RightShift` | Show or hide the entire interface |
| `AutoOpen` | bool | `true` | Open the menu immediately |
| `Accent` | `{Color3, Color3}` | white → gray | Gradient colors |
| `LoadingTitle`, `LoadingSubtitle` | string | — | Notification shown on startup |
| `ConfigurationSaving` | table | disabled | `{Enabled, FolderName, FileName}` |

### Window Methods

| Method | Description |
|---|---|
| `Window:CreateTab(options)` | Create a tab (maximum 5). You can also use `CreateTab("Name", "icon")` |
| `Window:SelectTab(tabOrName)` | Open a tab by object or name |
| `Window:Notify(options)` | Show a notification (same as `Reaper:Notify`) |
| `Window:SetTitle(text)` / `SetIcon(text)` | Change the title or button symbol |
| `Window:SetAccent(c1, c2)` | Change the gradient colors |
| `Window:SetToggleKey(key)` | Change the visibility toggle key |
| `Window:Show()` / `Hide()` / `Toggle()` | Show, hide, or toggle the interface |
| `Window:Open()` / `Close()` | Open or close the radial menu |
| `Window:SaveConfig(name)` / `LoadConfig(name)` | Save or load a configuration |
| `Window:ListConfigs()` / `DeleteConfig(name)` | List or delete configurations |
| `Window:Destroy()` | Completely unload the library |

---

## 2. Tab

```lua
Window:CreateTab({ Name = "Main", Icon = "home" })
```

**Icon** can be:
- a name from `Reaper.Icons` (`home`, `swords`, `eye`, `wrench`, `settings`, `skull`, `shield`, `star`, …);
- an asset ID such as `"rbxassetid://123456"` or simply the number `123456`;
- any character or emoji (`"★"`).

Custom icons:

```lua
Reaper:AddIcon("my_icon", 123456)
```

Tab methods include `Tab:Select()`, `Tab:Clear()` (remove all elements from the tab), and all `Create...` methods listed below.

---

## 3. Elements

**Every** element provides the same methods:

| Method | Description |
|---|---|
| `el:Set(value, silent)` | Set the value. `silent = true` skips the `Callback` |
| `el:Get()` | Get the current value |
| `el:OnChanged(fn)` | Add another listener; returns an unsubscribe function |
| `el:SetName(text)` | Change the element name |
| `el:SetVisible(bool)` | Show or hide the element |
| `el:Destroy()` | Remove the element |

Common options: `Name`, `Callback`, `Flag`.
**`Flag`** is a unique name. When specified, the value is saved to the configuration, stored in `Reaper.Flags[Flag]`, and the element itself is available at `Reaper.Options[Flag]`.

### Button

```lua
local b = Tab:CreateButton({ Name = "Click me", Callback = function() end })
b:Fire()            -- trigger it from code
```

### Toggle

```lua
local t = Tab:CreateToggle({ Name = "Fly", Flag = "Fly", CurrentValue = false,
    Callback = function(value) end })
t:Toggle()
```

### Slider

```lua
local s = Tab:CreateSlider({ Name = "Speed", Flag = "Speed",
    Range = {16, 200}, Increment = 1, Suffix = " studs/s", CurrentValue = 16,
    Callback = function(value) end })
s:SetRange(0, 500)  -- change the range
```

### Dropdown

```lua
local d = Tab:CreateDropdown({ Name = "Mode", Flag = "Mode",
    Options = {"A", "B", "C"}, CurrentOption = "A",
    Callback = function(option) end })

-- With multiple options: the value is a table
Tab:CreateDropdown({ Name = "Targets", Options = {"A", "B"},
    MultipleOptions = true, CurrentOption = {"A"},
    Callback = function(list) end })

d:Refresh({"X", "Y"}, true)   -- new list; true = keep the selected value if available
```

### Input

```lua
Tab:CreateInput({ Name = "Username", Flag = "Target", Placeholder = "Enter username",
    CurrentValue = "", NumbersOnly = false, ClearTextOnFocus = false,
    RemoveTextAfterFocusLost = false,
    Callback = function(text) end })     -- called after Enter or focus is lost
```

When `NumbersOnly = true`, the `Callback` receives a number.

### Keybind

```lua
Tab:CreateKeybind({ Name = "Attack", Flag = "AttackKey", CurrentKeybind = "E",
    HoldToInteract = false,
    Callback = function(keyOrState) end })
```

- `Callback` runs when the key is **pressed**; with `HoldToInteract = true`, it receives `true` when pressed and `false` when released.
- Change the keybind through `el:OnChanged(fn)`. Pressing `Escape` or `Backspace` while selecting a key resets it to `"None"`.
- `el:Press()` — invoke the `Callback` from code.

### ColorPicker

```lua
Tab:CreateColorPicker({ Name = "Color", Flag = "EspColor", Color = Color3.new(1, 1, 1),
    Callback = function(color3) end })
```

Click the element to expand the H / S / V sliders.

### Layout Elements

```lua
Tab:CreateSection("Section title")
Tab:CreateLabel("Text line")                 -- or { Name = "...", Color = Color3 }
Tab:CreateParagraph({ Title = "Title", Content = "Long text…" })
Tab:CreateDivider()
```

For a Label: `el:Set(text, color)`. For a Paragraph: `el:Set(title, content)`.

---

## 4. Notifications

```lua
Reaper:Notify({ Title = "Done", Content = "Text", Duration = 4, Type = "success" })
```

`Type` can be `"success"`, `"warning"`, `"error"`, or omitted. Create a window first; notifications are not visible before that.

---

## 5. Flags and Configurations

```lua
Reaper.Flags.Speed           -- value
Reaper.Options.Speed:Set(80) -- the element itself
Reaper:GetFlag("Speed")
Reaper:SetFlag("Speed", 80)  -- same as Options.Speed:Set(80)
```

When `ConfigurationSaving` is enabled in `CreateWindow`, values of elements with a `Flag`:
- are saved automatically, after a short delay, to `FolderName/FileName.json`;
- are loaded on the next launch, and their `Callback` is called.

Manual control:

```lua
Window:SaveConfig("name")
Window:LoadConfig("name")
Window:ListConfigs()
Window:DeleteConfig("name")
```

---

## 6. Miscellaneous

- The interface can be hidden with `ToggleKey` (`RightShift` by default).
- You can spin the menu wheel with your finger: a strong swipe rearranges the tabs, **holding the center** restores their original positions, and a short tap on the center closes the menu.
- The panel can be dragged by its header; the yellow dot minimizes it, while the dark dot closes the tab.
- An error inside your `Callback` does not break the interface — it is printed to the console as `[Reaper] Callback error`.
- `Reaper.Version` contains the library version, and `Reaper.MaxTabs` contains the tab limit (5).
