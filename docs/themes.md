# Themes

Built in: `default` (green with the rainbow bar), `cobalt`, `ember`, `amethyst`, `frost`, `rose`.

```lua
Onyx:CreateWindow({ name = "hub", theme = "ember" })
window:ChangeTheme("cobalt")   -- fades over
```

Players can also switch theme from the Settings tab.

![ember](images/sidebar.png)

## Custom themes

Pass a table. Anything you leave out comes from the default theme.

```lua
Onyx:CreateWindow({
	name = "hub",
	theme = {
		Accent = Color3.fromRGB(255, 60, 60),
		Background = Color3.fromRGB(10, 10, 10),
		Rainbow = false,
	},
})
```

Passing a table to `ChangeTheme` only changes the keys you give, the rest stays as is:

```lua
window:ChangeTheme({ Accent = Color3.fromRGB(255, 120, 40) })
```

## Keys

| key | what it colours |
|---|---|
| `Accent` | toggles, sliders, active tab, title, highlights |
| `Background` | window background |
| `Header` | title bar, tab bar, sidebar |
| `Panel` | group boxes, popups, notifications |
| `Element` | buttons, slider tracks, inputs, dropdowns |
| `ElementHover` | hover state |
| `Border` | box rims and dividers |
| `BorderLight` | outer window rim, hover outlines |
| `Outline` | the 1px black outline around everything |
| `Text` | main text |
| `TextDim` | labels that are off, descriptions |
| `Placeholder` | placeholders, faint text |
| `Error` / `Success` | red and green bits (errors, stat changes, danger buttons) |
| `Font` | a `Font` or `Enum.Font`, default `Code` |
| `Rainbow` | `true` for the multicolour top bar, `false` uses the accent |
| `LiveAnimation` | `false` stops the top bar from scrolling |

Some other common names work too and get mapped over, for example `AccentColor`, `WindowColor`, `ContentColor`, `ElementStroke`, `PlaceholderColor` and `ErrorColor`.

Setting `Accent` turns `Rainbow` off unless you set `Rainbow` yourself.
