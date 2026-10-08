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
- unload button (asks first)
- configurations: name box, saved list, save / load / delete / refresh (only if `configuration` is set)
- about: script status, library version, executor name

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
