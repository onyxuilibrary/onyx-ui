# Elements

Every element takes `name`, `description` (grey text underneath) and `icon` (asset id).

Value elements (toggle, slider, dropdown, input, keybind, colour picker) also take `flag` and `forgetState`, and have `.value` and `:Set(value, skipCallback)`.

All elements can be locked:

```lua
farm:Lock("needs premium")   -- greyed out, reason replaces the description
farm:Unlock()
farm:IsLocked()
```

A locked element ignores clicks but `:Set()` from code still works.

---

## Button

```lua
section:CreateButton({
	name = "Rejoin",
	description = "hops to a new server",
	callback = function()
		game:GetService("TeleportService"):Teleport(game.PlaceId)
	end,
})
```

`button:Set("new text")` renames it, `button:Fire()` runs the callback.

## Toggle

```lua
local esp = section:CreateToggle({
	name = "ESP",
	value = false,
	callback = function(on) end,
})
esp:Set(true)
```

`CreateSwitch` is the same thing.

## Slider

```lua
section:CreateSlider({
	name = "Field of view",
	range = { 70, 120 },
	increment = 1,
	value = 90,
	suffix = "°",
	callback = function(value, dragging)
		camera.FieldOfView = value
		if not dragging then
			print("let go at", value)
		end
	end,
})
```

| option | default | |
|---|---|---|
| `range` | `{ 0, 100 }` | min and max |
| `increment` | `1` | step size. min and max are always reachable even if the step doesn't line up |
| `value` | min | |
| `suffix` | | shown after the number |
| `minimal` | `false` | just the bar, no label |

The callback gets `dragging = true` while held and one last call with `false` when you let go. Use that if you only want to do expensive stuff on release. `slider:SetRange(min, max)` changes the range later.

## Dropdown

```lua
local mode = section:CreateDropdown({
	name = "Mode",
	options = { "Legit", "Rage", "Off" },
	value = "Legit",
	callback = function(choice) print(choice) end,
})

local parts = section:CreateDropdown({
	name = "Hitboxes",
	options = { "Head", "Torso", "Legs" },
	multiSelect = true,
	value = { "Head" },
	callback = function(list) print(table.concat(list, ", ")) end,
})
```

- the callback gets a string, or a table with `multiSelect`
- `.value` is always a table
- lists with more than 8 options get a search box
- `placeholder` is shown when nothing is picked

```lua
mode:Refresh({ "Legit", "Rage", "Spin" })   -- replace the options, drops picks that are gone
mode:Add("Custom")
mode:Remove("Spin")
mode:Set("Rage")
```

## Input

```lua
section:CreateInput({
	name = "Walk speed",
	placeholder = "16",
	numeric = true,
	callback = function(text) humanoid.WalkSpeed = tonumber(text) end,
})
```

- fires on Enter or when you click away, not every keystroke
- `numeric = true` rejects anything that isn't a number (it flashes red and puts the old value back)
- `clearOnFocus = true` empties it when clicked

## Keybind

```lua
section:CreateKeybind({
	name = "Fly",
	value = Enum.KeyCode.F,
	callback = function() toggleFly() end,
})

section:CreateKeybind({
	name = "Aim",
	value = "MB2",
	hold = true,
	callback = function(held) aiming = held end,
})
```

- `value` can be a `KeyCode`, a mouse button, or a string like `"E"`, `"LeftShift"`, `"MB2"`
- click the bind then press a key to change it. Escape cancels, Backspace clears it
- `hold = true`: callback gets `true` after `holdThreshold` seconds (default 0.2) and `false` on release, quick taps are ignored
- `onChanged = function(key)` runs when someone rebinds it
- binds don't fire while you're typing in a text box
- you can't bind the menu key

## Colour picker

```lua
local box = section:CreateColorPicker({
	name = "Box colour",
	color = Color3.fromRGB(255, 80, 80),   -- or "#FF5050"
	alpha = 1,
	callback = function(color, alpha) end,
})
box:Set(Color3.new(0, 1, 0))
box:SetAlpha(0.5)
```

Click the swatch to open it: saturation square, hue bar, alpha bar and a hex box.

## Stat

A number with a change indicator, nice for session stats.

```lua
local kills = section:CreateStat({ name = "Kills", value = 0 })
kills:Set(kills.value + 1)
```

Options: `prefix`, `suffix`, `compact`, `display` (`"value"` or `"change"`, compact only), `changeMode` (`"percentage"` or `"absolute"`), `changeBaseline` (`"previous"` or `"initial"`), `numberEasing`. `kills:ResetBaseline()` zeroes the change.

## Progress

```lua
local level = section:CreateProgress({ name = "Level", range = { 0, 100 }, value = 35 })
level:Set(80)

section:CreateProgress({ name = "Setup", steps = 5, value = 2 })          -- segmented
section:CreateProgress({ name = "Loading", indeterminate = true })       -- sweeping bar
section:CreateProgress({
	name = "Files",
	range = { 0, 200 },
	format = function(value, min, max) return value .. "/" .. max end,
})
```

Methods: `Set`, `Get`, `GetPercentage`, `SetRange`, `SetText(text)` (call with nothing to go back to the percentage), `SetIndeterminate(bool)`.

## Console

A scrolling log box.

```lua
local log = section:CreateConsole({ name = "Log", height = 120, follow = true, maxLines = 200 })
log:Append("joined server")
log:Set("cleared and replaced")
log:Clear()
print(log:Get())
log:Copy()          -- needs setclipboard
log:SetHeight(200)
```

## Text

```lua
local info = section:CreateText({ name = "Status", text = "waiting..." })
info:Set("connected")
info:SetTitle("")
```

Either part can be empty. `CreateLabel("text")` and `CreateParagraph({ Title, Content })` also work.

## Status

The script status row (working / updating / patched), for when you make your own settings tab. It follows `window:SetStatus` and `statusUrl` on its own.

```lua
local about = settings:CreateSection("About")
about:CreateStatus()                                   -- shows whatever the window status is
about:CreateStatus({ state = "updating", note = "fixing esp" })   -- sets it too
about:CreateStatus({ name = "Script" })                -- different label
```

See [status](status.md) for the rest.

## Discord

A button with the discord logo. Copies the invite (and opens it in discord where the executor allows).

```lua
section:CreateDiscord({ invite = "https://discord.gg/yourcode" })
section:CreateDiscord({ invite = "yourcode", name = "Support server" })
section:CreateDiscord()   -- uses the window's discord option
```

## Divider

```lua
section:CreateDivider()
section:CreateDivider({ text = "danger zone" })
section:CreateDivider({ line = false, spacing = 20 })   -- just a gap
```
