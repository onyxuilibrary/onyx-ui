# Saving and flags

Turn on saving with `configuration`:

```lua
Onyx:CreateWindow({
	name = "my hub",
	configuration = {
		autoSave = true,       -- save shortly after anything changes
		autoLoad = true,       -- load the file when the window opens
		fileName = "my-hub",
		customFolder = "hubs", -- optional sub folder
	},
})
```

Files end up in `Onyx/Configurations/[customFolder/]<fileName>.json`. Your executor needs the usual file functions (`writefile`, `readfile`, `isfile`, `makefolder`...). Without them saving just does nothing.

## How values get saved

Every value element (toggle, slider, dropdown, input, keybind, colour picker) saves under a flag. If you don't give one it uses the element's name. Duplicate names get ` (2)`, ` (3)` added.

```lua
section:CreateToggle({ name = "ESP", flag = "EspEnabled" })   -- explicit flag
section:CreateToggle({ name = "Secret", forgetState = true })  -- never saved
```

Give important stuff an explicit flag. Then you can rename the element later without breaking people's configs.

With `autoLoad`, saved values are applied as each element gets created, and the callback fires so the feature actually turns on. Elements you create later (like after loading something from the server) still pick up their saved value.

## Reading and writing by flag

```lua
print(window.Flags.EspEnabled)
window.Flags.EspEnabled = false        -- updates the toggle and runs its callback

window:Get("EspEnabled")
window:Set("EspEnabled", true)          -- returns false if there's no such flag

for flag, value in window.Flags do
	print(flag, value)
end
```

## Named configs

```lua
window:Save("legit")
window:Load("legit")
print(window:ListConfigs())   -- { "legit", "my-hub" }
window:DeleteConfig("legit")
window:Save()                 -- no name = the default file
print(window:GetPath())       -- folder, full path
```

The Settings tab has all of this built in, so players can make their own configs without you writing anything.
