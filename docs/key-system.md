# Key system

![key system](images/keysystem.png)

Add `keySystem` to the window and a key prompt shows up before anything else. `CreateWindow` doesn't return until a valid key goes in, so none of your script below it runs without one.

```lua
local window = Onyx:CreateWindow({
	name = "my hub",
	keySystem = {
		keys = { "ONYX-1234", "ONYX-5678" },
		note = "Get a key in our discord.",
		url = "https://discord.gg/yourinvite",
		saveKey = true,
	},
})

-- only runs after a correct key
local tab = window:CreateTab({ name = "Main" })
```

## Options

| option | default | |
|---|---|---|
| `keys` | | list of valid keys (or `key` for a single one) |
| `validate` | | `function(key) return true/false end` for your own check |
| `grabKeyFromSite` | `false` | treat each entry in `keys` as a URL and use whatever it returns as the key |
| `url` | | link the "get key" button copies |
| `note` | | text under the title |
| `title` | window name | |
| `subtitle` | `"key system"` | |
| `placeholder` | `"enter key"` | |
| `saveKey` | `true` | remember the key so the prompt is skipped next time |
| `fileName` | window name | file in `Onyx/Keys/` the key is saved to |

Whitespace around the key is trimmed, so pasting with a trailing space is fine.

## Checking keys on a server

`validate` can yield, so you can hit your own API:

```lua
keySystem = {
	url = "https://example.com/getkey",
	validate = function(key)
		local ok, res = pcall(function()
			return game:HttpGet("https://example.com/check?key=" .. key)
		end)
		return ok and res == "valid"
	end,
}
```

If you give both `keys` and `validate`, a key passes if either one accepts it.

## Saved keys

With `saveKey` on, the working key gets written to `Onyx/Keys/<fileName>.txt`. Next time it gets checked again (so a key you removed from your list stops working) and if it's still good the prompt is skipped.

## Closing the prompt

The x closes the prompt and removes the UI. The script just stops there, nothing after `CreateWindow` runs.

## Old style

```lua
Onyx:CreateWindow({
	Name = "hub",
	KeySystem = true,
	KeySettings = {
		Title = "hub",
		Subtitle = "key system",
		Note = "join the discord",
		FileName = "hubkey",
		SaveKey = true,
		GrabKeyFromSite = false,
		Key = { "hello" },
	},
})
```
