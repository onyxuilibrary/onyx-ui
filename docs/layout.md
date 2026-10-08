# Tabs, sections and groups

## Tabs

```lua
local tab = window:CreateTab({ name = "Visuals", icon = 4483362458 })
```

| option | default | |
|---|---|---|
| `name` | | tab text |
| `icon` | | asset id |
| `columns` | `2` | 1 to 3 columns of group boxes |

The first tab you create opens automatically. Tabs have `:Select()`, `:Deselect()` and `:Remove()`.

With `sidebarLayout = true` the tabs go down the left side. `window:CreateSection("Combat")` adds a small heading there that groups the tabs created after it.

## Sections (group boxes)

```lua
local players = tab:CreateSection("Players")
local world = tab:CreateSection({ name = "World", side = "right", icon = 123 })
```

Each section is a box with a title. New sections go into whichever column is shorter, so things stay balanced. Pass `side = "left"` or `"right"` (or a column number) to put it somewhere specific.

You can add things to a section directly, or through the tab. Going through the tab puts them in the most recent section:

```lua
players:CreateToggle({ name = "Boxes" })
tab:CreateToggle({ name = "Names" })     -- also ends up in "World", the latest section
```

If you add elements to a tab before making any section, they go into an untitled box. A tab with only one box uses the full width.

Section handles have `:Set(name)`, `:Remove()`, the move methods, and every `Create...` method.

## Groups

Groups let you put things side by side, or nest little columns inside a box.

```lua
local row = world:CreateGroup({ direction = "row" })
row:CreateButton({ name = "Day" })
row:CreateButton({ name = "Night" })

local column = world:CreateGroup({ direction = "column" })
column:CreateSection("Fog")             -- small sub heading
column:CreateSlider({ name = "Density" })
```

- `direction`: `"row"` (default) or `"column"`. `"horizontal"` and `"vertical"` work too
- `perRow`: how many fit in a row before wrapping, default 3

Rows can hold buttons, toggles, sliders and stats (stats go compact automatically). Anything wider (inputs, dropdowns, keybinds, colour pickers, text, dividers, consoles, progress bars) gets refused with a warning, put those in a column or straight in the section.

## Moving things around

Every element and section can be reordered after it's made:

```lua
toggle:MoveToTop()
toggle:MoveToBottom()
toggle:MoveUp()
toggle:MoveDown()
toggle:MoveTo(3)
toggle:Remove()
```
