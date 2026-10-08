# Window

```lua
local window = Onyx:CreateWindow({
	name = "onyx",
	subtitle = "my hub",
	theme = "default",
	status = "working",
	configuration = { autoSave = true, autoLoad = true, fileName = "my-hub" },
})
```

## Options

| option | default | what it does |
|---|---|---|
| `name` | `"Onyx"` | title, shown in the accent colour |
| `subtitle` | | grey text after the title |
| `icon` | | asset id shown before the title |
| `theme` | `"default"` | theme name or table, see [themes](themes.md) |
| `sidebarLayout` | `false` | tabs down the left with your avatar at the bottom |
| `profile` | | small line under your name in the sidebar |
| `toggleKey` | `RightShift` | key that hides/shows the menu |
| `size` | 580x440 (660x440 sidebar) | `UDim2` or `Vector2` |
| `configuration` | | `{ autoSave, autoLoad, fileName, customFolder }`, see [saving](saving.md) |
| `settingsTab` | `true` | adds the Settings tab |
| `status` | | `"working"`, `"updating"`, `"patched"` or a table, see [status](status.md) |
| `statusNote` | | text under the status in settings |
| `statusUrl` | | link to a text file with the status, so you can change it without updating the script |
| `statusRefresh` | | re-check `statusUrl` every N seconds while the menu is open |
| `statusTag` | `true` | show the status pill next to the title |
| `discord` | | invite link or code. Adds a discord button to the title bar and settings |
| `infoBar` | | `true` or a table: little bar with fps, ping, executor and time, see below |
| `keySystem` | | key prompt before the menu opens, see [key system](key-system.md) |
| `notice` | | popup shown when the script runs, see [messages](messages.md) |
| `changelog` | | changelog shown when the script runs |
| `mobile` | auto | force the mobile layout on/off |
| `scale` | auto | fixed UI scale, normally it shrinks itself to fit the screen |
| `showName` | window name | text on the launcher button |
| `showIcon` | | icon on the launcher button |
| `showIconOnly` | `false` | launcher shows just the icon |
| `showPill` | `true` | `false` turns the launcher off completely |
| `locale`, `translations`, `translator` | | see below |

## Methods

```lua
window:CreateTab({ name = "Main", icon = 4483362458, columns = 2 })
window:CreateSection("Combat")           -- heading in the sidebar (sidebar layout only)
window:CreateTag({ text = "beta", color = Color3.fromRGB(80, 200, 120) })

window:Show()
window:Hide()
window:ToggleHide()
window:ToggleMinimise()                  -- collapses to just the title bar
window:Navigate("Settings")              -- tab handle or name

window:SetStatus("updating", "fixing aimbot")
window:SetInfoBar(false)                 -- hide / show the info bar
window:OpenDiscord()                     -- same as clicking the discord button
window:ChangeTheme("ember")
window:SetProfile("premium")

window:Notify({ title = "hi" })
window:Toast({ title = "saved" })
window:Popup({ title = "sure?" })
window:ShowNotice({ content = "..." })
window:ShowChangelog({ entries = { ... } })

window:Save("legit")
window:Load("legit")
window:Get("WalkSpeed")
window:Set("WalkSpeed", 50)
window.Flags.WalkSpeed = 50

window:Unload()                          -- removes everything, window.unloaded becomes true
```

## Tags

Small coloured pills next to the title. The text colour picks itself (black or white) based on the background.

```lua
local tag = window:CreateTag({ text = "us-east", color = Color3.fromRGB(255, 175, 15), order = 1 })
tag:SetText("eu-west")
tag:SetColor(Color3.fromRGB(80, 200, 120))
tag:Set({ text = "offline", color = Color3.fromRGB(200, 60, 60) })
tag:Remove()
```

## Settings tab

Added automatically unless you pass `settingsTab = false`. It has:

- menu key bind
- theme picker
- info bar on/off
- unload button (asks first)
- configurations: name box, saved list, save / load / delete / refresh (only if `configuration` is set)
- about: script status, library version, executor name, discord button (if `discord` is set)

## Info bar

The little bar in the top right with your hub name, fps, ping, region, executor and the time. It stays up when the menu is hidden, and you can drag it anywhere.

About the region: Roblox doesn't tell scripts where the server actually is. What the bar shows is the country Roblox matches you from (like `US` or `GB`). Roblox normally puts you in a server near that, so it's a good guide, and ping tells you if you ended up somewhere far away. If you have your own way of finding the server location, pass it as `region` (see below).

```lua
Onyx:CreateWindow({ name = "my hub", infoBar = true })

-- or pick what it shows
Onyx:CreateWindow({
	name = "my hub",
	infoBar = {
		title = "my hub v2",                                  -- defaults to the window name
		fields = { "fps", "ping", "region", "executor", "time", "player" }, -- any order, leave out what you don't want
		position = "top-left",                                -- top-right (default), top-left, bottom-left, bottom-right
		region = "EU West",                                   -- optional: your own text (or a function) instead of the lookup
	},
})
```

You can also put functions in `fields` for your own stuff, they get called every half second:

```lua
infoBar = { fields = { "fps", "ping", function() return #game.Players:GetPlayers() .. " players" end } }
```

There's also a toggle for it in the settings tab, and it gets saved with configs.

## Discord

```lua
Onyx:CreateWindow({ name = "my hub", discord = "https://discord.gg/yourcode" })
```

That puts a discord logo button in the title bar and a "Join our Discord" button in settings. Clicking either copies the invite and, on executors that support it, opens the invite straight in the discord app. `discord.gg/code`, `discord.com/invite/code` and just `code` all work.

Want the button somewhere else? Use [`section:CreateDiscord()`](elements.md#discord).

## Translations

Tab names, section names, element names, descriptions and placeholders all go through the translator, and update live when you switch.

```lua
window:RegisterTranslations({
	["pt-br"] = { Aimbot = "Mira", Enabled = "Ativado" },
})
window:SetLocale("pt-br")

-- or do it yourself
window:SetTranslator(function(text, locale)
	return myLookup[locale] and myLookup[locale][text] or text
end)
```

The default locale is the player's `LocaleId`.

## Library-level helpers

These act on the last window you made, handy for older scripts:

```lua
Onyx:Notify({ title = "hi" })
Onyx:SetVisibility(false)
Onyx:IsVisible()
Onyx:LoadConfiguration()
Onyx:Destroy()      -- unloads every window
Onyx.Flags.Thing
```
