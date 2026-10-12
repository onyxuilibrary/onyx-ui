# Images

Pictures in your menu, for things like skin changers. Any image spot takes:

| you pass | example |
|---|---|
| an asset id | `123456789` or `"rbxassetid://123456789"` |
| a web link | `"https://raw.githubusercontent.com/you/repo/main/skins/fade.png"` |
| a file in the executor's workspace | `"MyHub/skins/fade.png"` |

![skins](images/skins.png)

*the knives here are placeholder pictures, yours show whatever your links point to*

## Web links (downloaded images)

Roblox can't show an image straight from a website. So Onyx downloads it once with `game:HttpGet`, saves it in the executor's workspace under `Onyx/Images`, and shows it with `getcustomasset`. That's the same thing every skin changer does, and it works on Delta, Wave, Volt, Potassium and other executors that have `getcustomasset` + `writefile`.

- The next time the script runs, the image comes from the saved file, no download.
- The same link used in several places only downloads once.
- At most 3 download at a time, so big skin lists don't freeze phones.
- While a picture loads, its spot says "Loading...". If it can't load it shows an `x` and prints a warning, nothing breaks.
- PNG and JPG work. Keep them small (256px or so is plenty for a tile), big images take longer on mobile data.
- GitHub works well for hosting: put the pictures in your repo and use the **Raw** links.

If the executor can't do custom assets at all, you get one warning in the console and web images just stay empty. Asset ids still work there.

## A single image

```lua
local preview = section:CreateImage({
	image = "https://raw.githubusercontent.com/you/repo/main/skins/fade.png",
	height = 120,          -- default 120
	scaleType = "Fit",     -- Fit (default), Crop or Stretch
	name = "Preview",      -- optional label above it
})

preview:Set("https://raw.githubusercontent.com/you/repo/main/skins/howl.png")   -- swap it
preview:Set(nil)                                                                -- clear it
```

## Image gallery (skin picker)

A grid of picture tiles. Tap one to pick it.

```lua
local knife = section:CreateImageGallery({
	name = "Knife skin",
	flag = "KnifeSkin",        -- saved with configs like everything else
	columns = 3,               -- default 3 on pc, 2 on mobile
	tileHeight = 76,           -- default 76 on pc, 92 on mobile
	items = {
		{ name = "Dragon Lore", image = "https://.../dragon.png", color = Color3.fromRGB(235, 75, 75) },
		{ name = "Fade", image = "https://.../fade.png", color = Color3.fromRGB(211, 44, 230) },
		{ name = "Default" },  -- no picture is fine too
		"Vanilla",             -- or just a name
	},
	value = "Fade",            -- starting pick
	callback = function(name, item)
		-- item is the table you passed in, so you can keep your own data on it
		print("picked", name)
	end,
})
```

- `color` draws a thin strip along the bottom of the tile, handy for rarity.
- Tapping the picked tile again un-picks it.
- Galleries with more than 12 items get a search box. Force it with `search = true` / `false`.
- `multi = true` lets people pick several. The callback then gets a list of names.

```lua
knife:Set("Dragon Lore")       -- pick from code (add true as a 2nd argument to skip the callback)
print(knife.value[1])          -- current pick
knife:GetItem("Fade")          -- the item table you passed in
knife:Refresh(newItems)        -- swap the whole list (pass true as a 2nd argument to keep the pick)
```

## Icons anywhere

Tab icons, section icons, element icons, notification icons, the launcher icon and the loading screen logo all go through the same loader, so links and files work there too:

```lua
window:CreateTab({ name = "Skins", icon = "https://.../knife-icon.png" })
window:Notify({ title = "Applied", content = "Fade", icon = "https://.../fade.png" })
```

## Downloading up front

If you have a lot of pictures, grab them while the [loading screen](window.md#loading-screen) is up so the menu opens with everything ready:

```lua
local window = Onyx:CreateWindow({
	name = "my hub",
	loadingScreen = {
		images = { "https://.../dragon.png", "https://.../fade.png", "https://.../howl.png" },
	},
})
```

The bar shows "Loading images 2/3" while it goes.

Or do it yourself whenever (these wait until they're done):

```lua
local loaded, total = window:PreloadImages(listOfLinks)   -- updates the loading screen if it's up
local loaded, total = Onyx:PreloadImages(listOfLinks, function(done, total) print(done, total) end)
```

## Your own ImageLabels

```lua
local id = Onyx:GetImage("https://.../fade.png")   -- waits, then gives you something for .Image (nil if it failed)
myImageLabel.Image = id

Onyx:SetImage(myImageLabel, "https://.../fade.png") -- or let Onyx fill it in when it's ready

Onyx:ClearImageCache()       -- forget what's loaded this session
Onyx:ClearImageCache(true)   -- also delete the Onyx/Images folder
```
